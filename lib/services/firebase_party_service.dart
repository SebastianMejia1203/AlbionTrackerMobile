import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import '../models/firebase_party_models.dart';

/// HOST (Windows)  → escribe vía REST API (PUT/PATCH/DELETE cada 10 s)
/// GUEST (Windows) → lee vía Firebase SSE (streaming HTTP, conexión única persistente)
/// HOST/GUEST (Android/iOS) → SDK nativo WebSocket (tiempo real completo)
///
/// Costos optimizados:
///  - Listener solo en parties/{code}, nunca en raíz
///  - SSE reutiliza la conexión, sin overhead de reconexión
///  - Listener se cancela al cerrar/salir de la party
class FirebasePartyService {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _rand = Random.secure();

  // ── Cambia aquí la URL si reconfiguras el proyecto Firebase ──────────────
  static const _rtdbBase =
      'https://albion-stats-6a0e4-default-rtdb.firebaseio.com';

  /// true  → REST + SSE  (Windows)
  /// false → SDK nativo  (Android / iOS)
  static bool get _useRest => !kIsWeb && Platform.isWindows;

  // ─── Code generation ──────────────────────────────────────────────────────

  String generateCode() {
    return String.fromCharCodes(
      List.generate(6, (_) => _chars.codeUnitAt(_rand.nextInt(_chars.length))),
    );
  }

  // ─── Host: create ─────────────────────────────────────────────────────────

  Future<void> createParty({
    required String code,
    required String hostName,
    required int maxMembers,
    required int pushIntervalSeconds,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final body = {
      'meta': FbPartyMeta(
        hostName: hostName,
        createdAt: now,
        lastPushAt: now,
        maxMembers: maxMembers,
        pushIntervalSeconds: pushIntervalSeconds,
      ).toMap(),
      'members': <String, dynamic>{},
    };

    if (_useRest) {
      final res = await http.put(
        _restUri('parties/$code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _checkRest(res);
    } else {
      await _sdkRef(code).set(body);
    }
  }

  // ─── Host: push members ───────────────────────────────────────────────────
  // Solo el HOST escribe periódicamente (timer en FirebasePartyProvider).
  // Los guests NO sondean — reciben cambios en tiempo real (SSE / WebSocket).

  Future<void> pushMembers({
    required String code,
    required List<FbPartyMember> members,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_useRest) {
      final Map<String, dynamic> patch = {
        'meta': {'lastPushAt': now},
        'members': {
          for (final m in members) _sanitize(m.name): m.toMap(),
        },
      };
      final res = await http.patch(
        _restUri('parties/$code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(patch),
      );
      _checkRest(res);
    } else {
      final Map<String, dynamic> updates = {'meta/lastPushAt': now};
      for (final m in members) {
        updates['members/${_sanitize(m.name)}'] = m.toMap();
      }
      await _sdkRef(code).update(updates);
    }
  }

  // ─── Host: regenerate code ────────────────────────────────────────────────

  Future<void> regenerateCode({
    required String oldCode,
    required String newCode,
    required String hostName,
    required int maxMembers,
    required int pushIntervalSeconds,
  }) async {
    Map<dynamic, dynamic>? memberData;

    if (_useRest) {
      final res = await http.get(_restUri('parties/$oldCode/members'));
      if (res.statusCode == 200 && res.body != 'null') {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) memberData = decoded;
      }
    } else {
      final snap = await _sdkRef(oldCode).child('members').get();
      if (snap.exists) memberData = snap.value as Map<dynamic, dynamic>?;
    }

    await deleteParty(oldCode);

    final now = DateTime.now().millisecondsSinceEpoch;
    final body = {
      'meta': FbPartyMeta(
        hostName: hostName,
        createdAt: now,
        lastPushAt: now,
        maxMembers: maxMembers,
        pushIntervalSeconds: pushIntervalSeconds,
      ).toMap(),
      'members': memberData ?? <String, dynamic>{},
    };

    if (_useRest) {
      final res = await http.put(
        _restUri('parties/$newCode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      _checkRest(res);
    } else {
      await _sdkRef(newCode).set(body);
    }
  }

  // ─── Host: delete ─────────────────────────────────────────────────────────

  Future<void> deleteParty(String code) async {
    if (_useRest) {
      final res = await http.delete(_restUri('parties/$code'));
      _checkRest(res);
    } else {
      await _sdkRef(code).remove();
    }
  }

  // ─── Guest: fetch (one-shot, solo para validar código al unirse) ──────────

  Future<FbPartySnapshot?> fetchParty(String code) async {
    if (_useRest) {
      final res = await http.get(_restUri('parties/$code'));
      if (res.statusCode != 200 || res.body == 'null') return null;
      final data = jsonDecode(res.body);
      if (data is! Map) return null;
      return _parseMap(data);
    } else {
      final snap = await _sdkRef(code).get();
      if (!snap.exists) return null;
      return _parseMap(snap.value as Map<dynamic, dynamic>);
    }
  }

  // ─── Guest: watch members only (stream tiempo real, sin meta) ─────────────
  // OPTIMIZACIÓN: meta (hostName, maxMembers…) nunca cambia tras crear la party.
  // Solo nos suscribimos al nodo /members → mucho menos tráfico por push.
  // El host escribe cada 10 s → solo ese delta llega al guest.
  //
  // Windows → Firebase SSE sobre parties/{code}/members
  // Android → SDK onValue sobre parties/{code}/members

  Stream<List<FbPartyMember>?> watchMembers(String code) {
    if (_useRest) {
      return _watchMembersViaSSE(code);
    } else {
      return FirebaseDatabase.instance
          .ref('parties/$code/members')
          .onValue
          .map((event) {
        if (!event.snapshot.exists) return null;
        final raw = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
        return _membersFromMap(raw);
      });
    }
  }

  Stream<List<FbPartyMember>?> _watchMembersViaSSE(String code) async* {
    final uri = Uri.parse('$_rtdbBase/parties/$code/members.json');
    final request = http.Request('GET', uri)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache';

    final client = http.Client();
    try {
      final response = await client.send(request);
      final stream = response.stream.transform(utf8.decoder);

      String eventType = '';
      final buffer = StringBuffer();
      // Estado acumulado local para poder aplicar patches
      Map<String, dynamic> localMembers = {};
      // true tras recibir el primer evento con datos reales
      bool hasSeenData = false;

      await for (final chunk in stream) {
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('event:')) {
            eventType = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            buffer.write(trimmed.substring(5).trim());
          } else if (trimmed.isEmpty && buffer.isNotEmpty) {
            try {
              final json = jsonDecode(buffer.toString()) as Map;
              final path = json['path'] as String? ?? '/';
              final data = json['data'];

              if (eventType == 'put') {
                if (data == null) {
                  if (hasSeenData) {
                    // Party eliminada después de haber tenido miembros
                    yield null;
                  } else {
                    // Primera conexión: nodo /members aún no existe (party recién creada)
                    localMembers = {};
                    yield [];
                  }
                } else if (path == '/') {
                  hasSeenData = true;
                  localMembers = Map<String, dynamic>.from(data as Map);
                  yield _membersFromMap(localMembers);
                } else {
                  hasSeenData = true;
                  final key = path.replaceFirst('/', '');
                  localMembers[key] = data;
                  yield _membersFromMap(localMembers);
                }
              } else if (eventType == 'patch' && data is Map) {
                hasSeenData = true;
                if (path == '/') {
                  // PATCH en la raíz de /members: merge nivel superior
                  data.forEach((k, v) => localMembers[k as String] = v);
                } else {
                  // PATCH en un miembro específico (ej. "/{name}"): deep-merge
                  final key = path.replaceFirst('/', '');
                  if (localMembers.containsKey(key) && localMembers[key] is Map) {
                    final existing =
                        Map<String, dynamic>.from(localMembers[key] as Map);
                    data.forEach((k, v) => existing[k as String] = v);
                    localMembers[key] = existing;
                  } else {
                    localMembers[key] =
                        Map<String, dynamic>.from(data);
                  }
                }
                yield _membersFromMap(localMembers);
              } else if (eventType == 'cancel') {
                yield null;
                return;
              }
            } catch (_) {}
            buffer.clear();
            eventType = '';
          }
        }
      }
    } finally {
      client.close();
    }
  }

  List<FbPartyMember> _membersFromMap(Map<dynamic, dynamic> raw) {
    return raw.entries
        .where((e) => e.value is Map)
        .map((e) => FbPartyMember.fromMap(
            _desanitize(e.key as String),
            e.value as Map<dynamic, dynamic>))
        .toList();
  }

  // ─── Guest: watch (stream) — mantener por compatibilidad ─────────────────
  Stream<FbPartySnapshot?> watchParty(String code) {
    if (_useRest) {
      return _watchViaSSE(code);
    } else {
      return _sdkRef(code).onValue.map((event) {
        if (!event.snapshot.exists) return null;
        return _parseMap(event.snapshot.value as Map<dynamic, dynamic>);
      });
    }
  }

  /// Firebase REST SSE: GET con Accept: text/event-stream
  /// Formato de respuesta:
  ///   event: put
  ///   data: {"path":"/","data":{...}}
  Stream<FbPartySnapshot?> _watchViaSSE(String code) async* {
    final uri = _restUri('parties/$code');
    final request = http.Request('GET', uri)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache';

    final client = http.Client();
    try {
      final response = await client.send(request);
      final stream = response.stream.transform(utf8.decoder);

      String eventType = '';
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        for (final line in chunk.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('event:')) {
            eventType = trimmed.substring(6).trim();
          } else if (trimmed.startsWith('data:')) {
            buffer.write(trimmed.substring(5).trim());
          } else if (trimmed.isEmpty && buffer.isNotEmpty) {
            // Línea vacía = fin de evento SSE
            if (eventType == 'put' || eventType == 'patch') {
              try {
                final json = jsonDecode(buffer.toString()) as Map;
                final data = json['data'];
                if (data == null) {
                  yield null; // Party eliminada
                } else if (data is Map) {
                  // 'put' en path '/' trae el objeto completo
                  yield _parseMap(data);
                }
              } catch (_) {
                // Ignorar eventos malformados
              }
            } else if (eventType == 'cancel') {
              yield null;
              return;
            }
            buffer.clear();
            eventType = '';
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  DatabaseReference _sdkRef(String code) =>
      FirebaseDatabase.instance.ref('parties/$code');

  Uri _restUri(String path) => Uri.parse('$_rtdbBase/$path.json');

  void _checkRest(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Firebase REST ${res.statusCode}: ${res.body}');
    }
  }

  FbPartySnapshot? _parseMap(Map<dynamic, dynamic> data) {
    try {
      final metaMap = data['meta'] as Map<dynamic, dynamic>?;
      if (metaMap == null) return null;
      final meta = FbPartyMeta.fromMap(metaMap);
      if (meta.isStale) return null;

      final membersMap = data['members'] as Map<dynamic, dynamic>? ?? {};
      final members = membersMap.entries
          .map((e) => FbPartyMember.fromMap(
              _desanitize(e.key as String),
              e.value as Map<dynamic, dynamic>))
          .toList();

      return FbPartySnapshot(meta: meta, members: members);
    } catch (_) {
      return null;
    }
  }

  /// Firebase keys no pueden contener . # $ [ ]
  String _sanitize(String name) => name
      .replaceAll('.', '_dt_')
      .replaceAll('#', '_hs_')
      .replaceAll('\$', '_dl_')
      .replaceAll('[', '_lb_')
      .replaceAll(']', '_rb_');

  String _desanitize(String key) => key
      .replaceAll('_dt_', '.')
      .replaceAll('_hs_', '#')
      .replaceAll('_dl_', '\$')
      .replaceAll('_lb_', '[')
      .replaceAll('_rb_', ']');
}
