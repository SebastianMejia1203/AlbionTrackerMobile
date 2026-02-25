import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/dungeon_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_image_widget.dart';
import '../../utils/formatters.dart';
import '../../widgets/ad_widgets.dart';

class DungeonTab extends StatefulWidget {
  const DungeonTab({super.key});

  @override
  State<DungeonTab> createState() => _DungeonTabState();
}

class _DungeonTabState extends State<DungeonTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestDungeons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DungeonProvider>();

    if (provider.dungeons.isEmpty) {
      return const EmptyState(
        icon: Icons.castle_outlined,
        message: 'Sin datos de dungeons',
        submessage: 'Los datos aparecerán cuando entres en un dungeon',
      );
    }

    // Sort newest first
    final sorted = List<DungeonFragment>.from(provider.dungeons)
      ..sort((a, b) => b.enterDungeonFirstTime.compareTo(a.enterDungeonFirstTime));

    return Column(
      children: [
        _buildStatsHeader(provider.stats),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: itemCountWithAds(sorted.length),
            itemBuilder: (context, index) {
              if (isAdIndex(index)) return const InlineBannerAd();
              final realIdx = realItemIndex(index);
              if (realIdx >= sorted.length) return const SizedBox.shrink();
              final dungeon = sorted[realIdx];
              return Dismissible(
                key: Key(dungeon.dungeonHash),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                confirmDismiss: (_) => _confirmDeleteDungeon(dungeon),
                onDismissed: (_) => _deleteDungeon(dungeon),
                child: _buildDungeonCard(dungeon),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Stats header ───────────────────────────────────────────────

  Widget _buildStatsHeader(DungeonStats stats) {
    final provider = context.read<DungeonProvider>();
    final allDungeons = provider.dungeons;

    // Compute summed extra stats from fragment list
    final totalMight = allDungeons.fold<double>(0, (s, d) => s + d.might);
    final totalFavor = allDungeons.fold<double>(0, (s, d) => s + d.favor);
    final totalReSpec = stats.total.reSpec;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _headerStat('Total', '${stats.total.enteredDungeon}', Icons.castle, null),
                _headerStat('Fama', Formatters.fame(stats.total.fame), Icons.star, const Color(0xFFFFD700)),
                _headerStat('Plata', Formatters.silver(stats.total.silver), Icons.monetization_on, Colors.grey[300]),
                if (totalReSpec > 0)
                  _headerStat('ReSpec', Formatters.fame(totalReSpec), Icons.auto_awesome, const Color(0xFFCE93D8)),
                if (totalMight > 0)
                  _headerStatImg('Might', Formatters.fame(totalMight), 'assets/icons/might.png', const Color(0xFFEF5350)),
                if (totalFavor > 0)
                  _headerStatImg('Favor', Formatters.fame(totalFavor), 'assets/icons/favor.png', const Color(0xFF42A5F5)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'Opciones',
            onSelected: _onDungeonMenuOption,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reset', child: Row(children: [Icon(Icons.refresh, size: 18), SizedBox(width: 8), Text('Reiniciar rastreo')])),
              PopupMenuItem(value: 'zero_fame', child: Row(children: [Icon(Icons.star_border, size: 18), SizedBox(width: 8), Text('Eliminar sin fama')])),
              PopupMenuItem(value: 'today', child: Row(children: [Icon(Icons.today, size: 18), SizedBox(width: 8), Text('Eliminar de hoy')])),
            ],
          ),
        ],
      ),
    );
  }

  void _onDungeonMenuOption(String value) async {
    final service = context.read<ConnectionProvider>().service;
    String message;
    switch (value) {
      case 'reset':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reiniciar rastreo'),
            content: const Text('¿Eliminar todos los dungeons registrados?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
        if (!confirm) return;
        await service.resetDungeonTracking();
        message = 'Rastreo reiniciado';
        break;
      case 'zero_fame':
        await service.deleteDungeonsWithZeroFame();
        message = 'Dungeons sin fama eliminados';
        break;
      case 'today':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar de hoy'),
            content: const Text('¿Eliminar todos los dungeons de hoy?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ?? false;
        if (!confirm) return;
        await service.deleteDungeonsFromToday();
        message = 'Dungeons de hoy eliminados';
        break;
      default:
        return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      service.requestDungeons();
    }
  }

  Widget _headerStat(String label, String value, IconData icon, Color? color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[400]),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color ?? Colors.white),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _headerStatImg(String label, String value, String assetPath, Color color) {
    return Column(
      children: [
        Image.asset(assetPath, width: 16, height: 16,
            errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 16, color: color)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  Future<bool> _confirmDeleteDungeon(DungeonFragment dungeon) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar dungeon'),
        content: Text('¿Eliminar "${dungeon.mainMapName.isNotEmpty ? dungeon.mainMapName : 'Dungeon'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _deleteDungeon(DungeonFragment dungeon) {
    context.read<DungeonProvider>().removeDungeonLocally(dungeon.dungeonHash);
    context.read<ConnectionProvider>().service.removeDungeon(dungeon.dungeonHash);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dungeon eliminado'), duration: Duration(seconds: 2)),
    );
  }

  int _parseTier(String tier) => int.tryParse(tier.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Color _tierColor(int tier) {
    switch (tier) {
      case 4: return Colors.blue;
      case 5: return Colors.red;
      case 6: return Colors.orange;
      case 7: return const Color(0xFFFFD700); // gold-yellow
      case 8: return Colors.white;
      default: return Colors.grey;
    }
  }

  Color _levelColor(int level) {
    switch (level) {
      case 0: return Colors.grey;
      case 1: return const Color(0xFF4FC3F7);
      case 2: return const Color(0xFF66BB6A);
      case 3: return const Color(0xFFAB47BC);
      case 4: return const Color(0xFFFFB300);
      default: return Colors.grey;
    }
  }

  String _modeLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'solo': return 'Solo';
      case 'standard': return 'Grupal';
      case 'avalon': return 'Avalon (20)';
      case 'corrupted': return 'Corrupta';
      case 'hellgate': return 'Puerta Infernal';
      case 'expedition': return 'Expedición';
      case 'mists': return 'Nieblas';
      case 'mistsdungeon': return 'Mazmorra Nieblas';
      case 'abyssaldepths': return 'Abismo';
      default: return mode.isEmpty || mode.toLowerCase() == 'unknown' ? 'Sin Información' : mode;
    }
  }

  String _modeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'solo': return 'assets/icons/solo_dungeon.png';
      case 'standard': return 'assets/icons/group_dungeon.png';
      case 'avalon': return 'assets/icons/raid_dungeon.png';
      case 'corrupted': return 'assets/icons/corrupted_banner.png';
      case 'hellgate': return 'assets/icons/hellgate_banner.png';
      case 'expedition': return 'assets/icons/dungeon.png';
      case 'mists': return 'assets/icons/mists_banner.png';
      case 'mistsdungeon': return 'assets/icons/mists_dungeon.png';
      case 'abyssaldepths': return 'assets/icons/abyssal_depths.png';
      default: return 'assets/icons/dungeon.png';
    }
  }

  // ─── Dungeon card ───────────────────────────────────────────────

  Widget _buildDungeonCard(DungeonFragment dungeon) {
    final tierInt = _parseTier(dungeon.tier);
    final tierCol = _tierColor(tierInt);
    final levelCol = _levelColor(dungeon.level);
    final chestCount = dungeon.events.where((e) => e.isChest).length;
    final shrineCount = dungeon.events.where((e) => e.isShrine).length;
    final isActive = dungeon.status.toLowerCase() == 'active';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDungeonDetail(dungeon),
        child: Stack(
          children: [
            // Faint faction banner watermark (right side)
            if (dungeon.factionBannerAsset != null)
              Positioned(
                right: -10,
                top: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.06,
                  child: Image.asset(dungeon.factionBannerAsset!, height: 100, fit: BoxFit.contain),
                ),
              ),
            // Active indicator (pulsing left border)
            if (isActive)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            // Card content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Icon cluster + name + time ──
                  Row(
                    children: [
                      // Tier+butterfly badge
                      _buildTierBadge(tierInt, dungeon.level, tierCol, levelCol, dungeon.butterflyAsset),
                      const SizedBox(width: 10),
                      // Map name + mode subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            dungeon.mainMapName.isNotEmpty && dungeon.mainMapName != 'Unknown' ? dungeon.mainMapName : 'Dungeon ${dungeon.tierDisplay}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Image.asset(_modeIcon(dungeon.mode), width: 14, height: 14,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.castle, size: 14)),
                                const SizedBox(width: 4),
                                Text(_modeLabel(dungeon.mode),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                if (dungeon.faction.isNotEmpty && dungeon.faction != 'Unknown') ...[
                                  Text(' · ', style: TextStyle(color: Colors.grey[600])),
                                  if (dungeon.factionBannerAsset != null) ...[
                                    Image.asset(dungeon.factionBannerAsset!, width: 12, height: 12,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                    const SizedBox(width: 3),
                                  ],
                                  Flexible(
                                    child: Text(dungeon.faction,
                                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Date + duration + floors
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Formatters.dateTime(dungeon.enterDungeonFirstTime),
                              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          if (isActive)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text('En curso',
                                    style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                              ],
                            )
                          else
                            Text(dungeon.formattedRunTime,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          if (dungeon.numberOfFloors > 1)
                            Text('${dungeon.numberOfFloors} pisos',
                                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Row 2: Stats chips ──
                  Row(
                    children: [
                      _iconStatChip('assets/icons/fame.png', Formatters.fame(dungeon.fame), const Color(0xFFFFD700)),
                      const SizedBox(width: 12),
                      _iconStatChip('assets/icons/silver.png', Formatters.silver(dungeon.silver), Colors.grey[300]!),
                      const SizedBox(width: 12),
                      _iconStatChip('assets/icons/respec.png', Formatters.fame(dungeon.reSpec), const Color(0xFFCE93D8)),
                      const Spacer(),
                      // Event summary badges
                      if (chestCount > 0)
                        _eventBadge('assets/icons/chest_open_standard.png', chestCount),
                      if (shrineCount > 0) ...[
                        const SizedBox(width: 6),
                        _eventBadge('assets/icons/shrine_fame.png', shrineCount),
                      ],
                      if (dungeon.killStatus.isNotEmpty && dungeon.killStatus != 'Unknown') ...[
                        const SizedBox(width: 6),
                        if (dungeon.killStatus == 'Killed')
                          Image.asset('assets/icons/skull_red.png', width: 14, height: 14,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.dangerous, size: 14, color: Colors.red))
                        else
                          Text('⚔',
                              style: const TextStyle(fontSize: 13, color: Colors.green)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(int tier, int level, Color tierCol, Color levelCol, String? butterflyAsset) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tierCol.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tierCol.withValues(alpha: 0.4)),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'T$tier',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tierCol),
            ),
          ),
          // Butterfly in bottom-right corner if level is known
          if (butterflyAsset != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Image.asset(butterflyAsset, width: 18, height: 18,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          // Level badge top-right
          if (level >= 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: levelCol.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(9),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Text(
                  '.$level',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconStatChip(String assetPath, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(assetPath, width: 14, height: 14,
            errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 14, color: color)),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _eventBadge(String assetPath, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(assetPath, width: 14, height: 14,
              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 14)),
          const SizedBox(width: 3),
          Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Detail bottom sheet ────────────────────────────────────────

  void _showDungeonDetail(DungeonFragment dungeon) {
    final tierInt = _parseTier(dungeon.tier);
    final tierCol = _tierColor(tierInt);
    final halfW = (MediaQuery.of(context).size.width - 56) / 2;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Header ───────────────────
                _buildDetailHeader(dungeon, tierInt, tierCol),
                const SizedBox(height: 20),

                // ── Primary stats ────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatCard(label: 'Fama', value: Formatters.fame(dungeon.fame), icon: Icons.star, valueColor: const Color(0xFFFFD700), width: halfW),
                    StatCard(label: 'Plata', value: Formatters.silver(dungeon.silver), icon: Icons.monetization_on, width: halfW),
                    StatCard(label: 'Respec', value: Formatters.fame(dungeon.reSpec), icon: Icons.recycling, valueColor: const Color(0xFFCE93D8), width: halfW),
                    StatCard(label: 'Duración', value: dungeon.formattedRunTime, icon: Icons.timer, width: halfW),
                  ],
                ),

                // ── Secondary stats (might, favor, factions) ──
                if (dungeon.might > 0 || dungeon.favor > 0 || dungeon.factionCoins > 0 || dungeon.factionFlags > 0) ...[
                  const SizedBox(height: 12),
                  _buildSecondaryStats(dungeon),
                ],

                // ── Per-hour stats ───────────
                if (dungeon.famePerHour > 0 || dungeon.silverPerHour > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (dungeon.famePerHour > 0) _labeledValue('Fama/h', Formatters.fame(dungeon.famePerHour), const Color(0xFFFFD700)),
                        if (dungeon.silverPerHour > 0) _labeledValue('Plata/h', Formatters.silver(dungeon.silverPerHour), Colors.grey[300]),
                        if (dungeon.reSpecPerHour > 0) _labeledValue('Respec/h', Formatters.fame(dungeon.reSpecPerHour), const Color(0xFFCE93D8)),
                      ],
                    ),
                  ),
                ],

                // ── Events (chests & shrines) ──
                if (dungeon.events.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Eventos',
                    icon: Icons.event_note,
                    trailing: Text('${dungeon.events.length}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ),
                  ...dungeon.events.map((e) => _buildEventTile(e)),
                ],

                // ── Loot ─────────────────────
                if (dungeon.loot.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Loot',
                    icon: Icons.inventory_2,
                    trailing: Text('${dungeon.loot.length} items', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ),
                  ...dungeon.loot.map((l) => _buildLootTile(l)),
                ],

                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailHeader(DungeonFragment dungeon, int tierInt, Color tierCol) {
    return Row(
      children: [
        // Butterfly / tier large badge
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: tierCol.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tierCol.withValues(alpha: 0.35)),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(dungeon.tierDisplay, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tierCol)),
              ),
              if (dungeon.butterflyAsset != null)
                Positioned(
                  right: 0, bottom: 0,
                  child: Image.asset(dungeon.butterflyAsset!, width: 24, height: 24,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dungeon.mainMapName.isNotEmpty && dungeon.mainMapName != 'Unknown' ? dungeon.mainMapName : 'Dungeon ${dungeon.tierDisplay}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _chip(Image.asset(_modeIcon(dungeon.mode), width: 14, height: 14,
                      errorBuilder: (_, __, ___) => const Icon(Icons.castle, size: 14)), _modeLabel(dungeon.mode)),
                  if (dungeon.faction.isNotEmpty && dungeon.faction != 'Unknown')
                    _chip(
                      dungeon.factionBannerAsset != null
                          ? Image.asset(dungeon.factionBannerAsset!, width: 14, height: 14,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink())
                          : null,
                      dungeon.faction,
                    ),
                  if (dungeon.numberOfFloors > 1)
                    _chip(const Icon(Icons.layers, size: 13, color: Colors.white70), '${dungeon.numberOfFloors} pisos'),
                  _chip(const Icon(Icons.timer_outlined, size: 13, color: Colors.white70), dungeon.formattedRunTime),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(Widget? leading, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 4)],
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSecondaryStats(DungeonFragment dungeon) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (dungeon.might > 0) _assetStatCard('assets/icons/might.png', 'Might', Formatters.fame(dungeon.might), const Color(0xFFEF5350)),
        if (dungeon.favor > 0) _assetStatCard('assets/icons/favor.png', 'Favor', Formatters.fame(dungeon.favor), const Color(0xFF42A5F5)),
        if (dungeon.factionCoins > 0) _assetStatCard('assets/icons/silver.png', 'F. Coins', Formatters.fame(dungeon.factionCoins), const Color(0xFFFFCA28)),
        if (dungeon.factionFlags > 0) _assetStatCard('assets/icons/fame.png', 'F. Flags', Formatters.fame(dungeon.factionFlags), const Color(0xFF66BB6A)),
      ],
    );
  }

  Widget _assetStatCard(String asset, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 20, height: 20,
              errorBuilder: (_, __, ___) => Icon(Icons.circle, size: 20, color: color)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _labeledValue(String label, String value, Color? color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color ?? Colors.white)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  // ─── Event tile ─────────────────────────────────────────────────

  Widget _buildEventTile(DungeonEvent event) {
    final assetPath = event.chestAsset ?? event.shrineAsset;
    final Color accentColor;
    if (event.isBossChest) {
      accentColor = const Color(0xFFFFD700);
    } else if (event.isChest) {
      accentColor = _rarityColor(event.rarity);
    } else if (event.isShrine) {
      accentColor = _shrineColor(event.shrineBuff);
    } else {
      accentColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          // Event image
          if (assetPath != null)
            Image.asset(assetPath, width: 28, height: 28,
                errorBuilder: (_, __, ___) => Icon(Icons.help_outline, size: 28, color: accentColor))
          else
            Icon(Icons.question_mark, size: 28, color: accentColor),
          const SizedBox(width: 10),
          // Event info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (event.isChest)
                  Text(
                    event.isBossChest ? 'Cofre de jefe' : _rarityLabel(event.rarity),
                    style: TextStyle(fontSize: 10, color: accentColor),
                  ),
              ],
            ),
          ),
          // Open/close status
          if (event.isChest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: event.isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(event.isOpen ? Icons.lock_open : Icons.lock, size: 12,
                      color: event.isOpen ? Colors.green : Colors.grey),
                  const SizedBox(width: 3),
                  Text(event.isOpen ? 'Abierto' : 'Cerrado',
                      style: TextStyle(fontSize: 10, color: event.isOpen ? Colors.green : Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': return Colors.grey[400]!;
      case 'uncommon': return const Color(0xFF4FC3F7);
      case 'rare': return const Color(0xFF66BB6A);
      case 'legendary': return const Color(0xFFFFB300);
      default: return Colors.grey;
    }
  }

  String _rarityLabel(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common': return 'Común';
      case 'uncommon': return 'Poco común';
      case 'rare': return 'Raro';
      case 'legendary': return 'Legendario';
      default: return '';
    }
  }

  Color _shrineColor(String buff) {
    switch (buff.toLowerCase()) {
      case 'fame': return const Color(0xFFFFD700);
      case 'silver': return Colors.grey[300]!;
      case 'combat': return const Color(0xFFEF5350);
      default: return Colors.blueGrey;
    }
  }

  // ─── Loot tile ──────────────────────────────────────────────────

  Widget _buildLootTile(DungeonLoot loot) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: ItemImageWidget(uniqueName: loot.uniqueName, size: 36),
      title: Text(
        loot.itemName.isNotEmpty ? loot.itemName : loot.uniqueName,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('x${loot.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (loot.estimatedMarketValue > 0)
            Text(Formatters.silver(loot.estimatedMarketValue),
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
