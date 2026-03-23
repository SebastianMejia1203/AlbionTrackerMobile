import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/game_icon.dart';
import '../../utils/formatters.dart';
import '../../utils/zone_utils.dart';

class DashboardTab extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final conn = context.watch<ConnectionProvider>();
    final data = dash.data;
    final pi = conn.playerInfo;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConnectionProvider>().service.requestDashboard();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          // Player + Map compact header (tap player → Jugador tab, tap map → Mapa tab)
          if (pi.username.isNotEmpty)
            _buildCompactHeader(pi, theme, isDark, widget.onNavigateToTab),
          const SizedBox(height: 10),

          // Fame/Silver/ReSpec row (compact)
          _buildMainStatsRow(data, isDark),
          const SizedBox(height: 10),

          // Per-hour rates row
          _buildRatesRow(data, isDark),
          const SizedBox(height: 12),

          // Session Progression Chart
          if (dash.history.length > 1) ...[
            _buildProgressionChart(dash, theme, isDark),
            const SizedBox(height: 12),
          ],

          // Kill/Death compact row
          _buildCombatRow(data, isDark),
          const SizedBox(height: 10),

          // Additional stats grid
          _buildAdditionalStats(data, isDark),
          const SizedBox(height: 10),

          // Chests (compact)
          if (data.lootedChests.total > 0) ...[
            _buildChestsCompact(data.lootedChests, isDark),
            const SizedBox(height: 10),
          ],

          // Faction points
          if (data.factionPointStats.isNotEmpty)
            _buildFactionCompact(data.factionPointStats, isDark),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(PlayerInfo pi, ThemeData theme, bool isDark, void Function(int)? onNavigateToTab) {
    final zoneColor = ZoneUtils.clusterModeColor(pi.clusterMode, isDark: isDark);
    final modeLabel = pi.clusterMode.isNotEmpty
        ? ZoneUtils.clusterModeLabel(pi.clusterMode)
        : '';
    final displayName = pi.mapDisplayName.isNotEmpty
        ? pi.mapDisplayName
        : pi.currentMap;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            pi.clusterMode.isNotEmpty
                ? zoneColor.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Player avatar + name (tap → Jugador tab index 9)
          GestureDetector(
            onTap: () => onNavigateToTab?.call(9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    pi.username.isNotEmpty ? pi.username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pi.username,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: Colors.grey[500]),
                      ],
                    ),
                    if (pi.guild.isNotEmpty)
                      Text(
                        pi.alliance.isNotEmpty
                            ? '[${pi.alliance}] ${pi.guild}'
                            : pi.guild,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Map info (tap → Mapa tab index 7)
          if (displayName.isNotEmpty)
            GestureDetector(
              onTap: () => onNavigateToTab?.call(7),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pi.tier.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: zoneColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(pi.tier,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: zoneColor)),
                      ),
                    Text(
                      displayName.length > 18
                          ? '${displayName.substring(0, 18)}...'
                          : displayName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (modeLabel.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: zoneColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(modeLabel,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: zoneColor)),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_right, size: 14, color: Colors.grey[500]),
                  ],
                ),
              ],
            ),
            ),
        ],
      ),
    );
  }

  // Adaptive colors — darker variants for light mode
  static Color _fameColor(bool isDark) =>
      isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00);
  static Color _silverColor(bool isDark) =>
      isDark ? Colors.grey[400]! : Colors.grey[700]!;
  static Color _reSpecColor(bool isDark) =>
      isDark ? const Color(0xFFCE93D8) : const Color(0xFF9C27B0);
  static Color _mightColor(bool isDark) =>
      isDark ? Colors.orange[300]! : Colors.orange[800]!;
  static Color _favorColor(bool isDark) =>
      isDark ? Colors.red[300]! : Colors.red[700]!;
  static Color _repairColor(bool isDark) =>
      isDark ? Colors.red[200]! : Colors.red[600]!;
  static Color _killColor(bool isDark) =>
      isDark ? Colors.green[400]! : Colors.green[700]!;
  static Color _deathColor(bool isDark) =>
      isDark ? Colors.red[400]! : Colors.red[700]!;
  static Color _soloColor(bool isDark) =>
      isDark ? Colors.amber[400]! : Colors.amber[800]!;

  Widget _buildMainStatsRow(DashboardData data, bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _miniStatCard(
          'Fama',
          Formatters.fame(data.totalGainedFameInSession),
          const GameIcon(name: 'fame', size: 16),
          _fameColor(isDark),
          isDark,
        )),
        const SizedBox(width: 6),
        Expanded(
            child: _miniStatCard(
          'Plata',
          Formatters.silver(data.totalGainedSilverInSession),
          const GameIcon(name: 'silver', size: 16),
          _silverColor(isDark),
          isDark,
        )),
        const SizedBox(width: 6),
        Expanded(
            child: _miniStatCard(
          'ReSpec',
          Formatters.fame(data.totalGainedReSpecPointsInSession),
          const GameIcon(name: 'respec', size: 16),
          _reSpecColor(isDark),
          isDark,
        )),
      ],
    );
  }

  Widget _buildRatesRow(DashboardData data, bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _rateChip(
                Formatters.fame(data.famePerHour), '/h',
                _fameColor(isDark), isDark)),
        const SizedBox(width: 6),
        Expanded(
            child: _rateChip(
                Formatters.silver(data.silverPerHour), '/h',
                _silverColor(isDark), isDark)),
        const SizedBox(width: 6),
        Expanded(
            child: _rateChip(
                Formatters.fame(data.reSpecPointsPerHour), '/h',
                _reSpecColor(isDark), isDark)),
      ],
    );
  }

  Widget _rateChip(String value, String suffix, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              TextSpan(
                text: suffix,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, Widget icon, Color color,
      bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!.withValues(alpha: 0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildProgressionChart(
      DashboardProvider dash, ThemeData theme, bool isDark) {
    final history = dash.history;
    if (history.length < 2) return const SizedBox.shrink();

    final startTime = history.first.time;
    final totalSpanSeconds =
        history.last.time.difference(startTime).inSeconds.toDouble();

    // Choose best unit: < 2 minutes → seconds, < 2 hours → minutes, else hours
    String Function(double) formatTimeLabel;
    double Function(DateTime) timeToX;

    if (totalSpanSeconds < 120) {
      // seconds mode
      timeToX = (t) => t.difference(startTime).inSeconds.toDouble();
      formatTimeLabel = (v) {
        final s = v.toInt();
        return '${s}s';
      };
    } else if (totalSpanSeconds < 7200) {
      // minutes mode
      timeToX = (t) => t.difference(startTime).inSeconds / 60.0;
      formatTimeLabel = (v) {
        final m = v.toInt();
        return '${m}m';
      };
    } else {
      // hours mode
      timeToX = (t) => t.difference(startTime).inSeconds / 3600.0;
      formatTimeLabel = (v) {
        final h = v.toInt();
        final m = ((v - h) * 60).toInt();
        return m > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${h}h';
      };
    }

    // Build spots
    final fameSpots = <FlSpot>[];
    final silverSpots = <FlSpot>[];
    for (final point in history) {
      final x = timeToX(point.time);
      fameSpots.add(FlSpot(x, point.fame));
      silverSpots.add(FlSpot(x, point.silver));
    }

    // Find max Y
    double maxY = 1;
    for (final h in history) {
      if (h.fame > maxY) maxY = h.fame;
      if (h.silver > maxY) maxY = h.silver;
    }
    maxY *= 1.1;

    final maxX = fameSpots.last.x;
    final double xInterval = maxX > 0 ? (maxX / 4).ceilToDouble().clamp(1.0, double.infinity) : 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('Progresión de sesión',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
              const Spacer(),
              _legendDot(isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00), 'Fama'),
              const SizedBox(width: 8),
              _legendDot(isDark ? Colors.grey[400]! : Colors.grey[700]!, 'Plata'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark ? Colors.grey[800] : Colors.grey[200])!,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            Formatters.compact(value),
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: xInterval,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0 || value >= maxX) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(formatTimeLabel(value),
                              style: TextStyle(
                                  fontSize: 8, color: Colors.grey[500])),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: fameSpots,
                    isCurved: false,
                    color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: silverSpots,
                    isCurved: false,
                    color: isDark ? Colors.grey[400]! : Colors.grey[700]!,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.grey.withValues(alpha: 0.06),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final color = spot.barIndex == 0
                            ? (isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00))
                            : (isDark ? Colors.grey[400]! : Colors.grey[700]!);
                        final label = spot.barIndex == 0 ? 'Fama' : 'Plata';
                        return LineTooltipItem(
                          '$label: ${Formatters.compact(spot.y)}\n${formatTimeLabel(spot.x)}',
                          TextStyle(fontSize: 11, color: color),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildCombatRow(DashboardData data, bool isDark) {
    return Container(
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
          // K/D Today
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⚔',
                    style: TextStyle(fontSize: 14, color: _killColor(isDark))),
                const SizedBox(width: 4),
                Text('${data.killsToday}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _killColor(isDark))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('/',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600])),
                ),
                Text('${data.deathsToday}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _deathColor(isDark))),
                const SizedBox(width: 4),
                Image.asset('assets/icons/skull_red.png', width: 14, height: 14,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.dangerous, size: 14, color: _deathColor(isDark))),
              ],
            ),
          ),
          Container(
              width: 1,
              height: 24,
              color: isDark ? Colors.grey[700] : Colors.grey[300]),
          // Solo kills
          Expanded(
            child: Column(
              children: [
                Text('${data.soloKillsToday}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _soloColor(isDark))),
                Text('Solo Kills',
                    style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
              width: 1,
              height: 24,
              color: isDark ? Colors.grey[700] : Colors.grey[300]),
          // K/D Ratio
          Expanded(
            child: Column(
              children: [
                Text(
                  data.deathsToday > 0
                      ? (data.killsToday / data.deathsToday)
                          .toStringAsFixed(1)
                      : '${data.killsToday}.0',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary),
                ),
                Text('K/D Ratio',
                    style: TextStyle(fontSize: 9, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalStats(DashboardData data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!.withValues(alpha: 0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _inlineStatImg('assets/icons/might.png', 'Poderio',
                      Formatters.fame(data.totalGainedMightInSession),
                      _mightColor(isDark))),
              Expanded(
                  child: _inlineStatImg('assets/icons/favor.png', 'Favor',
                      Formatters.fame(data.totalGainedFavorInSession),
                      _favorColor(isDark))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _inlineStatImg('assets/icons/might.png', 'Poderio/h',
                      Formatters.fame(data.mightPerHour), _mightColor(isDark))),
              Expanded(
                  child: _inlineStatImg('assets/icons/favor.png', 'Favor/h',
                      Formatters.fame(data.favorPerHour), _favorColor(isDark))),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                  child: _inlineStat(Icons.build, 'Reparación hoy',
                      Formatters.silver(data.repairCostsToday),
                      _repairColor(isDark))),
              Expanded(
                  child: _inlineStat(Icons.build_circle, 'Reparación 7d',
                      Formatters.silver(data.repairCostsLast7Days),
                      _repairColor(isDark))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inlineStat(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _inlineStatImg(String assetPath, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Image.asset(assetPath, width: 13, height: 13,
              errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 13, color: color)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildChestsCompact(LootedChestsData chests, bool isDark) {
    return Container(
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
          Icon(Icons.lock_open, size: 16, color: Colors.blue[300]),
          const SizedBox(width: 8),
          Text('Cofres',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87)),
          const Spacer(),
          _chestBadge('${chests.openedCommon}', Colors.grey[400]!),
          _chestBadge('${chests.openedUncommon}', Colors.green),
          _chestBadge('${chests.openedRare}', Colors.blue),
          _chestBadge('${chests.openedLegendary}', Colors.purple),
        ],
      ),
    );
  }

  Widget _chestBadge(String count, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(count,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildFactionCompact(List<FactionPointStat> stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!.withValues(alpha: 0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, size: 16, color: Colors.indigo[300]),
              const SizedBox(width: 6),
              Text('Facción',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          ...stats.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(s.cityFaction,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]))),
                    Text(Formatters.fame(s.value),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.indigo[300])),
                    const SizedBox(width: 8),
                    Text('${Formatters.fame(s.valuePerHour)}/h',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
