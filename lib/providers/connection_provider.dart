import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/signalr_service.dart';

/// Manages the SignalR connection lifecycle and exposes connection state.
class ConnectionProvider extends ChangeNotifier {
  final SignalRService _service = SignalRService();
  bool _isConnecting = false;
  String _error = '';
  ServerStatus _serverStatus = ServerStatus();
  PlayerInfo _playerInfo = PlayerInfo();

  SignalRService get service => _service;
  bool get isConnected => _service.isConnected;
  bool get isConnecting => _isConnecting;
  String get error => _error;
  ServerStatus get serverStatus => _serverStatus;
  PlayerInfo get playerInfo => _playerInfo;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<ServerStatus>? _statusSub;
  StreamSubscription<PlayerInfo>? _playerInfoSub;
  StreamSubscription<ClusterChanged>? _clusterChangedSub;

  ConnectionProvider() {
    _connectionSub = _service.connectionStateStream.listen((connected) {
      notifyListeners();
    });
    _statusSub = _service.serverStatusStream.listen((status) {
      _serverStatus = status;
      notifyListeners();
    });
    _playerInfoSub = _service.playerInfoStream.listen((info) {
      // PlayerInfoUpdate always carries the latest data from WPF (same CurrentCluster).
      // Accept all fields.
      _playerInfo = info;
      notifyListeners();
    });
    // ClusterChanged arrives when the WPF app completes cluster resolution.
    // It carries a snapshot of the exact moment, so immediately update map fields.
    _clusterChangedSub = _service.clusterChangedStream.listen((cluster) {
      _playerInfo = PlayerInfo(
        username: _playerInfo.username,
        guild: _playerInfo.guild,
        alliance: _playerInfo.alliance,
        currentMap: cluster.index,
        currentMapType: cluster.mapType,
        mapDisplayName: cluster.mapDisplayName,
        clusterMode: cluster.clusterMode,
        tier: cluster.tier,
        mapTypeString: cluster.mapTypeString,
        instanceName: cluster.instanceName,
      );
      notifyListeners();
    });
  }

  Future<bool> connect(String host, int port) async {
    _isConnecting = true;
    _error = '';
    notifyListeners();

    try {
      await _service.connect(host, port);
      // Only request data if actually connected
      if (_service.isConnected) {
        await _service.requestAllData().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            // Not critical — data will arrive via broadcasts
          },
        );
      }
      _isConnecting = false;
      notifyListeners();
      return _service.isConnected;
    } on TimeoutException catch (e) {
      _isConnecting = false;
      _error = e.message ?? 'Tiempo de espera agotado';
      notifyListeners();
      return false;
    } catch (e) {
      _isConnecting = false;
      _error = _friendlyError(e.toString());
      notifyListeners();
      return false;
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Connection refused') || raw.contains('No connection')) {
      return 'Conexión rechazada. Verifica que el servidor móvil esté encendido (icono de teléfono en la app de PC).';
    }
    if (raw.contains('TimeoutException') || raw.contains('timeout')) {
      return 'Tiempo de espera agotado. El servidor no respondió.';
    }
    if (raw.contains('SocketException')) {
      return 'Error de red. Verifica que el PC y el dispositivo estén en la misma red.';
    }
    return raw;
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _playerInfoSub?.cancel();
    _clusterChangedSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
