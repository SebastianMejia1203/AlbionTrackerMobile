import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/damage_meter_provider.dart';
import '../providers/dungeon_provider.dart';
import '../providers/trade_provider.dart';
import '../providers/gathering_provider.dart';
import '../providers/party_provider.dart';
import '../providers/guild_provider.dart';
import '../providers/logging_provider.dart';
import '../providers/map_history_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/damage_meter_tab.dart';
import 'tabs/dungeon_tab.dart';
import 'tabs/trade_tab.dart';
import 'tabs/gathering_tab.dart';
import 'tabs/party_tab.dart';
import 'tabs/guild_tab.dart';
import 'tabs/logging_tab.dart';
import 'tabs/map_history_tab.dart';
import 'tabs/player_info_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _initialized = false;

  final List<_TabConfig> _tabs = const [
    _TabConfig('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _TabConfig('DPS Meter', Icons.local_fire_department_outlined, Icons.local_fire_department),
    _TabConfig('Dungeons', Icons.castle_outlined, Icons.castle),
    _TabConfig('Trades', Icons.swap_horiz_outlined, Icons.swap_horiz),
    _TabConfig('Gathering', Icons.park_outlined, Icons.park),
    _TabConfig('Party', Icons.group_outlined, Icons.group),
    _TabConfig('Guild', Icons.shield_outlined, Icons.shield),
    _TabConfig('Mapa', Icons.explore_outlined, Icons.explore),
    _TabConfig('Logging', Icons.list_alt_outlined, Icons.list_alt),
    _TabConfig('Jugador', Icons.person_outlined, Icons.person),
    _TabConfig('Ajustes', Icons.settings_outlined, Icons.settings),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final conn = context.read<ConnectionProvider>();
      final service = conn.service;
      context.read<DashboardProvider>().listen(service);
      context.read<DamageMeterProvider>().listen(service);
      context.read<DungeonProvider>().listen(service);
      context.read<TradeProvider>().listen(service);
      context.read<GatheringProvider>().listen(service);
      context.read<PartyProvider>().listen(service);
      context.read<GuildProvider>().listen(service);
      context.read<MapHistoryProvider>().listen(service);
      context.read<LoggingProvider>().listen(service);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = context.watch<ConnectionProvider>();
    final isConnected = connectionProvider.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_tabs[_currentIndex].label),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          // Logging button (always visible)
          IconButton(
            icon: Icon(
              _currentIndex == 8 ? Icons.list_alt : Icons.list_alt_outlined,
              color: _currentIndex == 8
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => setState(() => _currentIndex = 8),
            tooltip: 'Logging',
          ),
          // Party button (always visible)
          _buildPartyAppBarButton(),
          // Settings button (always visible)
          IconButton(
            icon: Icon(
              _currentIndex == 10 ? Icons.settings : Icons.settings_outlined,
              color: _currentIndex == 10
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () => setState(() => _currentIndex = 10),
            tooltip: 'Ajustes',
          ),
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                final conn = context.read<ConnectionProvider>();
                conn.service.requestDashboard();
              },
              tooltip: 'Actualizar',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardTab(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
          const DamageMeterTab(),
          const DungeonTab(),
          const TradeTab(),
          const GatheringTab(),
          const PartyTab(),
          const GuildTab(),
          const MapHistoryTab(),
          const LoggingTab(),
          const PlayerInfoTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    // Use a horizontal scrolling row for 8 tabs
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isSelected = _currentIndex == index;
                return InkWell(
                  onTap: () {
                    if (index == 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Party no disponible en esta versión'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    setState(() => _currentIndex = index);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 5, // show ~5 at once
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          size: 24,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartyAppBarButton() {
    return const IconButton(
      icon: Icon(Icons.share_location_outlined),
      tooltip: 'Party no disponible',
      onPressed: null,
    );
  }

}

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabConfig(this.label, this.icon, this.activeIcon);
}
