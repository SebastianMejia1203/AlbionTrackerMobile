import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/connection_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/party_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/game_icon.dart';
import '../../utils/formatters.dart';
import '../../utils/zone_utils.dart';

class PlayerInfoTab extends StatefulWidget {
  const PlayerInfoTab({super.key});

  @override
  State<PlayerInfoTab> createState() => _PlayerInfoTabState();
}

class _PlayerInfoTabState extends State<PlayerInfoTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<ConnectionProvider>().service;
      service.requestPlayerInfo();
      service.requestDashboard();
      service.requestParty();
    });
  }

  PartyPlayerData? _findLocalPlayer(PartyData party) {
    try {
      return party.players.firstWhere((p) => p.isLocalPlayer);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    final dash = context.watch<DashboardProvider>();
    final party = context.watch<PartyProvider>();
    final pi = conn.playerInfo;
    final data = dash.data;
    final localPlayer = party.data != null ? _findLocalPlayer(party.data!) : null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (pi.username.isEmpty) {
      return const EmptyState(
        icon: Icons.person_outline,
        message: 'Sin información del jugador',
        submessage: 'Esperando datos del servidor...',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final service = context.read<ConnectionProvider>().service;
        service.requestPlayerInfo();
        service.requestDashboard();
        service.requestParty();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Player Header Card
          _buildPlayerHeader(pi, localPlayer, theme, isDark),
          const SizedBox(height: 16),

          // Current Location
          if (pi.currentMap.isNotEmpty || pi.mapDisplayName.isNotEmpty) ...[
            _buildLocationCard(pi, theme),
            const SizedBox(height: 16),
          ],

          // Equipment
          if (localPlayer != null) ...[
            _buildEquipmentSection(localPlayer, theme, isDark),
            const SizedBox(height: 16),
          ],

          // Combat Stats
          _buildCombatStats(data, isDark),
          const SizedBox(height: 16),

          // Session Economy
          _buildEconomyStats(data, isDark),
          const SizedBox(height: 16),

          // Repair Costs
          _buildRepairCosts(data, isDark),
          const SizedBox(height: 16),

          // Looted Chests
          if (data.lootedChests.total > 0) ...[
            _buildChestsSection(data.lootedChests, isDark),
            const SizedBox(height: 16),
          ],

          // Faction Points
          if (data.factionPointStats.isNotEmpty) ...[
            _buildFactionStats(data.factionPointStats, isDark),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(
      PlayerInfo pi, PartyPlayerData? local, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Avatar + Name
          CircleAvatar(
            radius: 36,
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.25),
            child: Text(
              pi.username.isNotEmpty ? pi.username[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pi.username,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (pi.guild.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  pi.alliance.isNotEmpty
                      ? '[${pi.alliance}] ${pi.guild}'
                      : pi.guild,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ],

          // IP display from party
          if (local != null && local.averageItemPower > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ipChip('IP', local.averageItemPower, Colors.amber),
                const SizedBox(width: 12),
                _ipChip('Base IP', local.averageBasicItemPower,
                    Colors.blue[300]!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _ipChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${value.toStringAsFixed(0)} $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(PlayerInfo pi, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final zoneColor = ZoneUtils.clusterModeColor(pi.clusterMode, isDark: isDark);
    final textColor = ZoneUtils.clusterModeTextColor(pi.clusterMode);
    final displayName =
        pi.mapDisplayName.isNotEmpty ? pi.mapDisplayName : pi.currentMap;
    final modeLabel = pi.clusterMode.isNotEmpty
        ? ZoneUtils.clusterModeLabel(pi.clusterMode)
        : '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            zoneColor.withValues(alpha: 0.18),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zoneColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: zoneColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: pi.tier.isNotEmpty
                  ? Text(pi.tier,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor))
                  : Icon(Icons.map, color: textColor, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    if (modeLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: zoneColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(modeLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: zoneColor)),
                      ),
                    if (pi.mapTypeString.isNotEmpty &&
                        pi.mapTypeString != 'Unknown') ...[
                      const SizedBox(width: 6),
                      Text(pi.mapTypeString,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.location_on, color: zoneColor, size: 22),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection(
      PartyPlayerData local, ThemeData theme, bool isDark) {
    final eq = local.equipment;
    final slots = eq.allSlots;
    final namesEs = [
      'Arma', 'Sec.', 'Cabeza', 'Pecho', 'Botas',
      'Bolsa', 'Capa', 'Montura', 'Poción', 'Comida'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Equipamiento', icon: Icons.inventory),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.7,
          ),
          itemCount: slots.length,
          itemBuilder: (context, i) {
            final item = slots[i];
            return _buildEquipmentSlot(item, namesEs[i], theme, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildEquipmentSlot(
      ItemData? item, String slotName, ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item != null
                  ? _tierColor(item.tier).withValues(alpha: 0.5)
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
          ),
          child: item != null && item.uniqueName.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.help_outline,
                          size: 22,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (item.tier > 0)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: _tierColor(item.tier).withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4)),
                            ),
                            child: Text(
                              item.tierString,
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Icon(Icons.remove, size: 18, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          slotName,
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _tierColor(int tier) {
    switch (tier) {
      case 1:
      case 2:
      case 3:
        return Colors.grey;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      case 6:
        return Colors.purple;
      case 7:
        return Colors.orange;
      case 8:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCombatStats(DashboardData data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Combate', icon: Icons.gps_fixed),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: [
              // Kills - Deaths - Solo Kills header row
              Row(
                children: [
                  const Expanded(
                      flex: 2,
                      child: SizedBox()),
                  Expanded(
                    child: Center(
                      child: Text('Kills',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[400])),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Muertes',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[400])),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Solo K.',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[400])),
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),
              _combatRow('Hoy', data.killsToday, data.deathsToday,
                  data.soloKillsToday),
              _combatRow('Semana', data.killsThisWeek, data.deathsThisWeek,
                  data.soloKillsThisWeek),
              _combatRow('Mes', data.killsThisMonth, data.deathsThisMonth,
                  data.soloKillsThisMonth),
              const Divider(height: 12),
              // Average IP
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                        'IP al Matar',
                        data.averageItemPowerWhenKilling.toStringAsFixed(0),
                        Colors.green[300]!),
                  ),
                  Expanded(
                    child: _miniStat(
                        'IP Enemigos',
                        data.averageItemPowerOfTheKilledEnemies
                            .toStringAsFixed(0),
                        Colors.orange[300]!),
                  ),
                  Expanded(
                    child: _miniStat(
                        'IP al Morir',
                        data.averageItemPowerWhenDying.toStringAsFixed(0),
                        Colors.red[300]!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _combatRow(String label, int kills, int deaths, int soloKills) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          Expanded(
            child: Center(
              child: Text(Formatters.number(kills),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[400])),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(Formatters.number(deaths),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[400])),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(Formatters.number(soloKills),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[400])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildEconomyStats(DashboardData data, bool isDark) {
    final thirdWidth = (MediaQuery.of(context).size.width - 48) / 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Economía de sesión',
            iconWidget: GameIcon(name: 'silver', size: 20)),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            StatCard(
              label: 'Fama',
              value: Formatters.fame(data.totalGainedFameInSession),
              icon: Icons.star,
              valueColor: const Color(0xFFFFD700),
              width: thirdWidth,
            ),
            StatCard(
              label: 'Fama/h',
              value: Formatters.fame(data.famePerHour),
              icon: Icons.speed,
              valueColor: const Color(0xFFFFD700),
              width: thirdWidth,
            ),
            StatCard(
              label: 'Plata',
              value: Formatters.silver(data.totalGainedSilverInSession),
              icon: Icons.monetization_on,
              valueColor: Colors.grey[300],
              width: thirdWidth,
            ),
            StatCard(
              label: 'Plata/h',
              value: Formatters.silver(data.silverPerHour),
              icon: Icons.speed,
              valueColor: Colors.grey[300],
              width: thirdWidth,
            ),
            StatCard(
              label: 'ReSpec',
              value: Formatters.fame(data.totalGainedReSpecPointsInSession),
              icon: Icons.recycling,
              valueColor: const Color(0xFFCE93D8),
              width: thirdWidth,
            ),
            StatCard(
              label: 'ReSpec/h',
              value: Formatters.fame(data.reSpecPointsPerHour),
              icon: Icons.speed,
              valueColor: const Color(0xFFCE93D8),
              width: thirdWidth,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepairCosts(DashboardData data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Costos de Reparación', icon: Icons.build),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _miniStat('Hoy',
                    Formatters.silver(data.repairCostsToday), Colors.red[300]!),
              ),
              Container(width: 1, height: 30, color: Colors.grey[700]),
              Expanded(
                child: _miniStat('7 días',
                    Formatters.silver(data.repairCostsLast7Days), Colors.red[300]!),
              ),
              Container(width: 1, height: 30, color: Colors.grey[700]),
              Expanded(
                child: _miniStat('30 días',
                    Formatters.silver(data.repairCostsLast30Days), Colors.red[300]!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChestsSection(LootedChestsData chests, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Cofres Abiertos', icon: Icons.lock_open),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.grey[800]!.withValues(alpha: 0.5)
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              _chestStat(
                  'Común', chests.openedCommon, Colors.grey[400]!),
              _chestStat(
                  'Poco Común', chests.openedUncommon, Colors.green),
              _chestStat('Raro', chests.openedRare, Colors.blue),
              _chestStat(
                  'Legendario', chests.openedLegendary, Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chestStat(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFactionStats(List<FactionPointStat> stats, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Puntos de Facción', icon: Icons.flag),
        ...stats.map((stat) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.grey[800]!.withValues(alpha: 0.5)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag, size: 18, color: Colors.indigo[300]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(stat.cityFaction,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Formatters.fame(stat.value),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo[300])),
                      Text('${Formatters.fame(stat.valuePerHour)}/h',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
