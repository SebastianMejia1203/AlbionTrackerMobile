import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/firebase_party_models.dart';
import '../services/firebase_party_service.dart';

class FirebasePartyProvider extends ChangeNotifier {
  final FirebasePartyService _service = FirebasePartyService();

  // ─── State ────────────────────────────────────────────────────────────────
  FbPartyRole _role = FbPartyRole.none;
  String? _code;
  FbPartySnapshot? _snapshot;
  FbPartyMeta? _cachedMeta;   // meta se carga una vez y se cachea
  String? _error;
  bool _loading = false;

  // Host config
  int _maxMembers = 5;
  int _pushIntervalSeconds = 10;

  // Push timer (host only)
  Timer? _pushTimer;
  StreamSubscription? _watchSub;

  // Callback: host supplies current player data
  List<FbPartyMember> Function()? onGetMembers;

  // ─── Getters ──────────────────────────────────────────────────────────────
  FbPartyRole get role => _role;
  String? get code => _code;
  FbPartySnapshot? get snapshot => _snapshot;
  String? get error => _error;
  bool get loading => _loading;
  int get maxMembers => _maxMembers;
  int get pushIntervalSeconds => _pushIntervalSeconds;
  bool get isHost => _role == FbPartyRole.host;
  bool get isGuest => _role == FbPartyRole.guest;
  bool get isActive => _role != FbPartyRole.none && _code != null;

  // ─── Host: create party ──────────────────────────────────────────────────

  Future<bool> createParty({
    required String hostName,
    int? maxMembers,
    int? pushInterval,
  }) async {
    _setLoading(true);
    _maxMembers = maxMembers ?? _maxMembers;
    _pushIntervalSeconds = pushInterval ?? _pushIntervalSeconds;

    try {
      final code = _service.generateCode();
      await _service.createParty(
        code: code,
        hostName: hostName,
        maxMembers: _maxMembers,
        pushIntervalSeconds: _pushIntervalSeconds,
      );
      _code = code;
      _role = FbPartyRole.host;
      _error = null;
      _cachedMeta = FbPartyMeta(
        hostName: hostName,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastPushAt: DateTime.now().millisecondsSinceEpoch,
        maxMembers: _maxMembers,
        pushIntervalSeconds: _pushIntervalSeconds,
      );
      _startPushTimer();
      // Push inmediato para que los guests vean al host al instante
      Future.delayed(const Duration(milliseconds: 500), _doPush);
      // Host observa solo /members para ver cuántos guests se conectaron
      _startWatchMembers(code);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al crear party: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> regenerateCode() async {
    if (!isHost || _code == null) return false;
    _setLoading(true);
    try {
      final oldCode = _code!;
      final newCode = _service.generateCode();
      final snap = _snapshot;
      await _service.regenerateCode(
        oldCode: oldCode,
        newCode: newCode,
        hostName: snap?.meta.hostName ?? '',
        maxMembers: _maxMembers,
        pushIntervalSeconds: _pushIntervalSeconds,
      );
      _code = newCode;
      _watchSub?.cancel();
      _startWatchMembers(newCode);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al regenerar código: $e';
      _setLoading(false);
      return false;
    }
  }

  void updateHostConfig({int? maxMembers, int? pushInterval}) {
    if (maxMembers != null) _maxMembers = maxMembers;
    if (pushInterval != null) {
      _pushIntervalSeconds = pushInterval;
      if (isHost) {
        _pushTimer?.cancel();
        _startPushTimer();
      }
    }
    notifyListeners();
  }

  // ─── Guest: join party ───────────────────────────────────────────────────

  Future<bool> joinParty(String code) async {
    _setLoading(true);
    try {
      final snap = await _service.fetchParty(code.toUpperCase().trim());
      if (snap == null) {
        _error = 'Código inválido o la party ya no está activa';
        _setLoading(false);
        return false;
      }
      _code = code.toUpperCase().trim();
      _role = FbPartyRole.guest;
      _cachedMeta = snap.meta;   // meta cacheada — no vuelve a descargarse
      _snapshot = snap;
      _error = null;
      // Solo escucha /members: Firebase empuja solo los deltas, sin re-descargar meta
      _startWatchMembers(_code!);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al unirse: $e';
      _setLoading(false);
      return false;
    }
  }

  // ─── Leave / close ────────────────────────────────────────────────────────

  Future<void> closeParty() async {
    if (isHost && _code != null) {
      await _service.deleteParty(_code!);
    }
    _reset();
  }

  void leaveParty() {
    _reset();
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _startPushTimer() {
    _pushTimer?.cancel();
    _pushTimer = Timer.periodic(
      Duration(seconds: _pushIntervalSeconds),
      (_) => _doPush(),
    );
  }

  /// Push inmediato (útil tras reset del medidor de daño)
  Future<void> pushNow() => _doPush();

  Future<void> _doPush() async {
    if (!isHost || _code == null || onGetMembers == null) return;
    try {
      final members = onGetMembers!();
      await _service.pushMembers(code: _code!, members: members);
    } catch (_) {
      // Silent — host will retry on next tick
    }
  }

  // ─── Self-reporting (guests reportan su propia fama/plata) ───────────────

  /// Inicia un timer periódico para que el guest reporte sus propios stats.
  /// Llama a [onGetSelfStats] y hace PATCH únicamente en su entrada de /members.
  void _startWatchMembers(String code) {
    _watchSub?.cancel();
    // Distingue nodo /members inexistente (party recién creada)
    // de nodo eliminado (host cerró la party)
    bool hasSeenMembers = false;
    _watchSub = _service.watchMembers(code).listen((members) {
      if (members == null) {
        if (hasSeenMembers) {
          // El nodo existió y fue eliminado → host cerró la party
          if (isGuest) _reset();
        } else {
          // Primera respuesta: nodo /members aún no existe → lista vacía, party activa
          final meta = _cachedMeta;
          if (meta != null) {
            _snapshot = FbPartySnapshot(meta: meta, members: []);
            notifyListeners();
          }
        }
        return;
      }
      hasSeenMembers = true;
      final meta = _cachedMeta;
      if (meta == null) return;
      _snapshot = FbPartySnapshot(meta: meta, members: members);
      notifyListeners();
    });
  }


  void _reset() {
    _pushTimer?.cancel();
    _pushTimer = null;
    _watchSub?.cancel();
    _watchSub = null;
    _role = FbPartyRole.none;
    _code = null;
    _snapshot = null;
    _cachedMeta = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    _watchSub?.cancel();
    super.dispose();
  }
}
