import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/firebase_party_models.dart';

class FirebasePartyProvider extends ChangeNotifier {
  static const String _firebaseUnavailableMessage =
      'Firebase no disponible en esta versión';

  // ─── State ────────────────────────────────────────────────────────────────
  FbPartyRole _role = FbPartyRole.none;
  String? _code;
  FbPartySnapshot? _snapshot;
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
    _error = _firebaseUnavailableMessage;
    _setLoading(false);
    return false;
  }

  Future<bool> regenerateCode() async {
    _error = _firebaseUnavailableMessage;
    notifyListeners();
    return false;
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
    _error = _firebaseUnavailableMessage;
    _setLoading(false);
    return false;
  }

  // ─── Leave / close ────────────────────────────────────────────────────────

  Future<void> closeParty() async {
    _error = _firebaseUnavailableMessage;
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
    return;
  }

  void _reset() {
    _pushTimer?.cancel();
    _pushTimer = null;
    _watchSub?.cancel();
    _watchSub = null;
    _role = FbPartyRole.none;
    _code = null;
    _snapshot = null;
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
