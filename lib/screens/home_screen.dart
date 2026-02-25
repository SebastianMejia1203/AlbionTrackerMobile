import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../providers/firebase_party_provider.dart';
import '../models/firebase_party_models.dart';
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
import '../widgets/ad_widgets.dart';

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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(), // persistent 320×50 banner
          _buildBottomNav(context),
        ],
      ),
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
                  onTap: () => setState(() => _currentIndex = index),
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
    final fb = context.watch<FirebasePartyProvider>();

    if (!fb.isActive) {
      return IconButton(
        icon: const Icon(Icons.share_location_outlined),
        tooltip: 'Crear Party compartida',
        onPressed: () => _showCreatePartyDialog(),
      );
    }

    // Party activa → chip verde con el código
    return GestureDetector(
      onTap: () => _showPartyActiveDialog(fb),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                fb.code ?? '',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartyActiveDialog(FirebasePartyProvider fb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('Party Activa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Código para compartir:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: fb.code ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado'),
                        duration: Duration(seconds: 1)));
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fb.code ?? '',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Theme.of(context).colorScheme.primary,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Icon(Icons.copy, size: 18,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('${fb.snapshot?.memberCount ?? 0}/${fb.maxMembers} miembros conectados',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<FirebasePartyProvider>().closeParty();
            },
            child: const Text('Terminar Party'),
          ),
        ],
      ),
    );
  }

  void _showCreatePartyDialog() {
    int maxMembers = 5;
    // ── Frecuencia fija de push en segundos.
    // Para cambiarla, edita el valor de pushInterval en createParty() más abajo.
    const int pushIntervalSeconds = 10;

    final conn = context.read<ConnectionProvider>();
    final hostName = conn.playerInfo.username.isNotEmpty
        ? conn.playerInfo.username
        : 'Host';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share_location,
                      size: 28, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),
                const Text('Nueva Party Compartida',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Host: $hostName',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 24),

                // Máximo de miembros
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined, size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Máximo de miembros',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: maxMembers > 2 ? () => setDlg(() => maxMembers--) : null,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 28,
                        child: Text('$maxMembers',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: maxMembers < 20 ? () => setDlg(() => maxMembers++) : null,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final fb = context.read<FirebasePartyProvider>();
                          final dps = context.read<DamageMeterProvider>();
                          final dash = context.read<DashboardProvider>();
                          fb.onGetMembers = () {
                            final currentSnap = fb.snapshot;
                            return dps.fragments.map((f) {
                              final isHost = f.name == hostName;
                              final existing = currentSnap?.members.firstWhere(
                                (m) => m.name == f.name,
                                orElse: () => FbPartyMember(
                                    name: f.name, damage: 0, dps: 0,
                                    fame: 0, silver: 0, lastUpdated: 0),
                              );
                              return FbPartyMember(
                                name: f.name,
                                damage: f.damage.toDouble(),
                                dps: f.dps,
                                fame: isHost
                                    ? dash.data.totalGainedFameInSession
                                    : (existing?.fame ?? 0),
                                silver: isHost
                                    ? dash.data.totalGainedSilverInSession
                                    : (existing?.silver ?? 0),
                                weapon: f.causerMainHand?.uniqueName ?? '',
                                lastUpdated: DateTime.now().millisecondsSinceEpoch,
                              );
                            }).toList();
                          };
                          final ok = await fb.createParty(
                            hostName: hostName,
                            maxMembers: maxMembers,
                            pushInterval: pushIntervalSeconds, // ← editar aquí para cambiar frecuencia
                          );
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(fb.error ?? 'Error desconocido')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Crear Party',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabConfig(this.label, this.icon, this.activeIcon);
}
