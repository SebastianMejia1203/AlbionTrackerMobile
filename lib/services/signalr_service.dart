import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../models/models.dart';

/// Service that manages the SignalR connection to the PC host.
/// Provides streams for real-time data updates and methods to invoke server actions.
class SignalRService {
  HubConnection? _hubConnection;
  bool _isConnected = false;
  String _serverUrl = '';

  // Stream controllers for each data type
  final _dashboardController = StreamController<DashboardData>.broadcast();
  final _damageMeterController = StreamController<DamageMeterData>.broadcast();
  final _dungeonsController = StreamController<DungeonListData>.broadcast();
  final _tradesController = StreamController<TradeListData>.broadcast();
  final _gatheringController = StreamController<GatheringListData>.broadcast();
  final _partyController = StreamController<PartyData>.broadcast();
  final _guildController = StreamController<GuildData>.broadcast();
  final _loggingController = StreamController<LoggingNotification>.broadcast();
  final _loggingListController = StreamController<List<LoggingNotification>>.broadcast();
  final _serverStatusController = StreamController<ServerStatus>.broadcast();
  final _clusterChangedController = StreamController<ClusterChanged>.broadcast();
  final _playerInfoController = StreamController<PlayerInfo>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _mapHistoryController = StreamController<MapHistoryData>.broadcast();
  final _gatheringStatusController = StreamController<bool>.broadcast();
  final _loggingSettingsController = StreamController<LoggingSettingsData>.broadcast();

  // Public streams
  Stream<DashboardData> get dashboardStream => _dashboardController.stream;
  Stream<DamageMeterData> get damageMeterStream => _damageMeterController.stream;
  Stream<DungeonListData> get dungeonsStream => _dungeonsController.stream;
  Stream<TradeListData> get tradesStream => _tradesController.stream;
  Stream<GatheringListData> get gatheringStream => _gatheringController.stream;
  Stream<PartyData> get partyStream => _partyController.stream;
  Stream<GuildData> get guildStream => _guildController.stream;
  Stream<LoggingNotification> get loggingStream => _loggingController.stream;
  Stream<List<LoggingNotification>> get loggingListStream => _loggingListController.stream;
  Stream<ServerStatus> get serverStatusStream => _serverStatusController.stream;
  Stream<ClusterChanged> get clusterChangedStream => _clusterChangedController.stream;
  Stream<PlayerInfo> get playerInfoStream => _playerInfoController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<MapHistoryData> get mapHistoryStream => _mapHistoryController.stream;
  Stream<bool> get gatheringStatusStream => _gatheringStatusController.stream;
  Stream<LoggingSettingsData> get loggingSettingsStream => _loggingSettingsController.stream;

  bool get isConnected => _isConnected;
  String get serverUrl => _serverUrl;

  /// Connect to the PC host's SignalR server.
  Future<void> connect(String host, int port) async {
    _serverUrl = 'http://$host:$port/mobilehub';

    _hubConnection = HubConnectionBuilder()
        .withUrl(_serverUrl)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 30000])
        .build();

    // Register handlers for server-pushed messages
    _registerHandlers();

    // Connection state callbacks
    _hubConnection!.onclose(({error}) {
      _isConnected = false;
      _connectionStateController.add(false);
      print('SignalR connection closed: $error');
    });

    _hubConnection!.onreconnecting(({error}) {
      _isConnected = false;
      _connectionStateController.add(false);
      print('SignalR reconnecting: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _isConnected = true;
      _connectionStateController.add(true);
      print('SignalR reconnected: $connectionId');
      // Request fresh data after reconnection
      requestAllData();
    });

    try {
      final startFuture = _hubConnection!.start();
      await (startFuture ?? Future.value()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('No se pudo conectar en 10s. ¿El servidor móvil está encendido?');
        },
      );
      _isConnected = true;
      _connectionStateController.add(true);
      print('SignalR connected to $_serverUrl');
    } catch (e) {
      _isConnected = false;
      _connectionStateController.add(false);
      rethrow;
    }
  }

  void _registerHandlers() {
    final hub = _hubConnection!;

    hub.on('DashboardUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _dashboardController.add(DashboardData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('DamageMeterUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _damageMeterController.add(DamageMeterData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('DungeonsUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _dungeonsController.add(DungeonListData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('TradesUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _tradesController.add(TradeListData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('GatheringUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _gatheringController.add(GatheringListData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('PartyUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _partyController.add(PartyData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('GuildUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _guildController.add(GuildData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('ServerStatus', (args) {
      if (args != null && args.isNotEmpty) {
        _serverStatusController.add(ServerStatus.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('ClusterChanged', (args) {
      if (args != null && args.isNotEmpty) {
        _clusterChangedController.add(ClusterChanged.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('PlayerInfoUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _playerInfoController.add(PlayerInfo.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('NewLoggingNotification', (args) {
      if (args != null && args.isNotEmpty) {
        _loggingController.add(LoggingNotification.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('LoggingUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        final list = (args[0] as List).map((e) => LoggingNotification.fromJson(e as Map<String, dynamic>)).toList();
        _loggingListController.add(list);
      }
    });

    hub.on('DamageMeterSnapshotsUpdate', (args) {
      // Handled directly in the provider
    });

    hub.on('MapHistoryUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _mapHistoryController.add(MapHistoryData.fromJson(args[0] as Map<String, dynamic>));
      }
    });

    hub.on('GatheringStatusUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _gatheringStatusController.add(args[0] as bool);
      }
    });

    hub.on('LoggingSettingsUpdate', (args) {
      if (args != null && args.isNotEmpty) {
        _loggingSettingsController.add(LoggingSettingsData.fromJson(args[0] as Map<String, dynamic>));
      }
    });
  }

  /// Request all data from the server (used on initial connection or reconnection)
  Future<void> requestAllData() async {
    if (!_isConnected) return;
    await Future.wait([
      requestDashboard(),
      requestDamageMeter(),
      requestDungeons(),
      requestTrades(),
      requestGathering(),
      requestParty(),
      requestGuild(),
      requestPlayerInfo(),
      requestLogging(),
      requestServerStatus(),
      requestMapHistory(),
    ]);
  }

  // === Request methods (pull data from server) ===

  Future<void> requestDashboard() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestDashboard');
  }

  Future<void> requestDamageMeter() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestDamageMeter');
  }

  Future<void> requestDungeons() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestDungeons');
  }

  Future<void> requestTrades() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestTrades');
  }

  Future<void> requestGathering() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestGathering');
  }

  Future<void> requestParty() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestParty');
  }

  Future<void> requestGuild() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestGuild');
  }

  Future<void> requestPlayerInfo() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestPlayerInfo');
  }

  Future<void> requestLogging({int count = 100}) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestLogging', args: [count]);
  }

  Future<void> requestServerStatus() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestServerStatus');
  }

  Future<void> requestMapHistory() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestMapHistory');
  }

  // === Action methods (send commands to server) ===

  Future<void> resetDamageMeter() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('ResetDamageMeter');
  }

  Future<void> toggleDeathAlert(String playerGuid, bool isActive) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('ToggleDeathAlert', args: [playerGuid, isActive]);
  }

  Future<void> takeDamageMeterSnapshot() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('TakeDamageMeterSnapshot');
  }

  Future<void> changeDamageMeterSort(String sortType) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('ChangeDamageMeterSort', args: [sortType]);
  }

  Future<void> removeDungeon(String dungeonHash) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RemoveDungeon', args: [dungeonHash]);
  }

  Future<void> resetDungeonTracking() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('ResetDungeonTracking');
  }

  Future<void> deleteDungeonsWithZeroFame() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('DeleteDungeonsWithZeroFame');
  }

  Future<void> deleteDungeonsFromToday() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('DeleteDungeonsFromToday');
  }

  Future<void> setDamageMeterResetOnMapChange(bool active) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('SetDamageMeterResetOnMapChange', args: [active]);
  }

  Future<void> requestLoggingSettings() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestLoggingSettings');
  }

  Future<void> setLoggingSettings({required bool isTrackingSilver, required bool isTrackingFame, required bool isTrackingMobLoot}) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('SetLoggingSettings', args: [isTrackingSilver, isTrackingFame, isTrackingMobLoot]);
  }

  Future<void> requestGatheringStatus() async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RequestGatheringStatus');
  }

  Future<void> setGatheringActive(bool active) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('SetGatheringActive', args: [active]);
  }

  Future<void> removeGatheringEntries(List<String> guids) async {
    if (!_isConnected) return;
    await _hubConnection!.invoke('RemoveGatheringEntries', args: [guids]);
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _isConnected = false;
      _connectionStateController.add(false);
    }
  }

  /// Dispose all resources.
  void dispose() {
    _dashboardController.close();
    _damageMeterController.close();
    _dungeonsController.close();
    _tradesController.close();
    _gatheringController.close();
    _partyController.close();
    _guildController.close();
    _loggingController.close();
    _loggingListController.close();
    _serverStatusController.close();
    _clusterChangedController.close();
    _playerInfoController.close();
    _connectionStateController.close();
    _mapHistoryController.close();
    _gatheringStatusController.close();
    _loggingSettingsController.close();
    disconnect();
  }
}
