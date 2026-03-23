import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/map_history_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/zone_utils.dart';

class MapHistoryTab extends StatefulWidget {
  const MapHistoryTab({super.key});

  @override
  State<MapHistoryTab> createState() => _MapHistoryTabState();
}

class _MapHistoryTabState extends State<MapHistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestMapHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapHistoryProvider>();

    if (provider.entries.isEmpty) {
      return const EmptyState(
        icon: Icons.explore_outlined,
        message: 'Sin historial de mapas',
        submessage: 'El historial aparecerá cuando cambies de zona',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConnectionProvider>().service.requestMapHistory();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: provider.entries.length,
        itemBuilder: (context, index) {
          return _buildHistoryEntry(provider.entries[index], index);
        },
      ),
    );
  }

  String _formatTimestamp(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Hoy';
      }
      return DateFormat('dd/MM').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildHistoryEntry(MapHistoryEntry entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zoneColor =
        ZoneUtils.clusterModeColor(entry.clusterMode, isDark: isDark);
    final textColor = ZoneUtils.clusterModeTextColor(entry.clusterMode);
    final displayName = entry.mapDisplayName.isNotEmpty
        ? entry.mapDisplayName
        : (entry.uniqueClusterName.isNotEmpty
            ? entry.uniqueClusterName
            : entry.index);
    final modeLabel = ZoneUtils.clusterModeLabel(entry.clusterMode);
    final time = _formatTimestamp(entry.enteredAt);
    final date = _formatDate(entry.enteredAt);
    final isCurrent = index == 0;

    // Build subtitle chips
    final chips = <_ChipData>[];

    // Zone mode chip
    chips.add(_ChipData(
      label: modeLabel,
      color: zoneColor,
    ));

    // MapType chip (only if meaningful, with dungeon-type fallback)
    final effectiveMapType = _resolveMapType(entry);
    final effectiveMapTypeLabel = effectiveMapType.isNotEmpty 
        ? ZoneUtils.mapTypeLabel(effectiveMapType) 
        : '';
    if (effectiveMapType.isNotEmpty && effectiveMapType != 'Unknown') {
      chips.add(_ChipData(
        label: effectiveMapTypeLabel,
        icon: ZoneUtils.mapTypeIcon(effectiveMapType),
        color: Colors.blueGrey,
      ));
    }

    // Mists rarity chip
    final mistsLabel = ZoneUtils.mistsRarityLabel(entry.mistsRarity);
    if (mistsLabel.isNotEmpty) {
      chips.add(_ChipData(
        label: mistsLabel,
        color: ZoneUtils.mistsRarityColor(entry.mistsRarity),
      ));
    }

    // Avalon tunnel type
    if (entry.avalonTunnelType.isNotEmpty &&
        entry.avalonTunnelType != 'Unknown') {
      chips.add(_ChipData(
        label: entry.avalonTunnelType,
        color: const Color(0xFF00BFA5),
      ));
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: isCurrent
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isCurrent
            ? BorderSide(
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDetailSheet(entry, isCurrent),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Zone color indicator + tier
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: zoneColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: zoneColor.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: entry.tier.isNotEmpty && entry.tier != 'T?'
                      ? Text(
                          entry.tier,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        )
                      : Icon(ZoneUtils.mapTypeIcon(entry.mapType),
                          size: 20, color: textColor),
                ),
              ),
              const SizedBox(width: 12),
              // Map name + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight:
                                  isCurrent ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTUAL',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Chips row
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: chips
                          .map((c) => _buildChip(c.label, c.color,
                              icon: c.icon))
                          .toList(),
                    ),
                    // Lethality label
                    if (ZoneUtils.lethalityLabel(entry.clusterMode).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            _lethalityIcon(entry.clusterMode),
                            size: 10,
                            color: ZoneUtils.lethalityColor(entry.clusterMode),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            ZoneUtils.lethalityLabel(entry.clusterMode),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: ZoneUtils.lethalityColor(entry.clusterMode),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                  if (date.isNotEmpty && date != 'Hoy')
                    Text(
                      date,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _lethalityIcon(String mode) {
    switch (mode) {
      case 'SafeArea':
      case 'Yellow':
      case 'Island':
      case 'Hideout':
        return Icons.shield_outlined;
      case 'Red':
        return Icons.warning_amber;
      case 'Black':
      case 'AvalonTunnel':
      case 'Mists':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }

  String _resolveMapType(MapHistoryEntry entry) {
    if (entry.mapType.isNotEmpty && entry.mapType != 'Unknown') {
      return entry.mapType;
    }
    // Infer from worldJsonType
    final wjt = entry.worldJsonType.toUpperCase();
    if (wjt.contains('RANDOMDUNGEON')) return 'RandomDungeon';
    if (wjt.contains('CORRUPTED')) return 'CorruptedDungeon';
    if (wjt.contains('EXPEDITION')) return 'Expedition';
    if (wjt.contains('HELLGATE')) return 'HellGate';
    if (wjt.contains('MISTS') && wjt.contains('DUNGEON')) return 'MistsDungeon';
    // Infer from uniqueName
    final un = entry.uniqueName.toUpperCase();
    if (un.contains('RANDOMDUNGEON')) return 'RandomDungeon';
    if (un.contains('CORRUPTED')) return 'CorruptedDungeon';
    if (un.contains('EXPEDITION')) return 'Expedition';
    if (un.contains('HELLGATE')) return 'HellGate';
    return entry.mapType;
  }

  void _showDetailSheet(MapHistoryEntry entry, bool isCurrent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zoneColor =
        ZoneUtils.clusterModeColor(entry.clusterMode, isDark: isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final displayName = entry.mapDisplayName.isNotEmpty
            ? entry.mapDisplayName
            : (entry.uniqueClusterName.isNotEmpty
                ? entry.uniqueClusterName
                : entry.index);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: zoneColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: zoneColor.withValues(alpha: 0.5)),
                        ),
                        child: Center(
                          child: entry.tier.isNotEmpty && entry.tier != 'T?'
                              ? Text(entry.tier,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: zoneColor))
                              : Icon(ZoneUtils.mapTypeIcon(entry.mapType),
                                  size: 24, color: zoneColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(
                              ZoneUtils.clusterModeLabel(entry.clusterMode),
                              style: TextStyle(
                                  color: zoneColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Chip(
                          label: const Text('ACTUAL',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                          backgroundColor: Theme.of(ctx)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  // Detail rows
                  if (entry.uniqueName.isNotEmpty)
                    _detailRow('ID del Mapa', entry.uniqueName),
                  if (entry.uniqueClusterName.isNotEmpty)
                    _detailRow('Región', entry.uniqueClusterName),
                  _detailRow('Tipo de zona',
                      ZoneUtils.clusterModeLabel(entry.clusterMode)),
                  if (entry.mapType.isNotEmpty && entry.mapType != 'Unknown')
                    _detailRow('Tipo de mapa',
                        ZoneUtils.mapTypeLabel(_resolveMapType(entry))),
                  if (entry.tier.isNotEmpty && entry.tier != 'T?')
                    _detailRow('Tier', entry.tier),
                  if (entry.worldJsonType.isNotEmpty)
                    _detailRow('Mundo',
                        ZoneUtils.worldJsonTypeLabel(entry.worldJsonType)),
                  if (entry.avalonTunnelType.isNotEmpty &&
                      entry.avalonTunnelType != 'Unknown')
                    _detailRow('Tipo Avalon', entry.avalonTunnelType),
                  if (ZoneUtils.mistsRarityLabel(entry.mistsRarity).isNotEmpty)
                    _detailRow('Rareza Nieblas',
                        ZoneUtils.mistsRarityLabel(entry.mistsRarity)),
                  if (entry.instanceName.isNotEmpty)
                    _detailRow('Instancia', entry.instanceName),
                  // Lethality
                  if (ZoneUtils.lethalityLabel(entry.clusterMode).isNotEmpty)
                    _detailRow('Letalidad',
                        ZoneUtils.lethalityLabel(entry.clusterMode)),
                  // History breadcrumb
                  if (entry.clusterHistoryString1.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Text('Ruta',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.grey[500])),
                    const SizedBox(height: 4),
                    _buildBreadcrumbWidget(entry),
                  ],
                  // Timestamp
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _detailRow('Entrada', _formatFullTimestamp(entry.enteredAt)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbWidget(MapHistoryEntry entry) {
    final parts = <String>[];
    if (entry.clusterHistoryString3.isNotEmpty) {
      parts.add(entry.clusterHistoryString3);
    }
    if (entry.clusterHistoryString2.isNotEmpty) {
      parts.add(entry.clusterHistoryString2);
    }
    if (entry.clusterHistoryString1.isNotEmpty) {
      parts.add(entry.clusterHistoryString1);
    }

    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Icon(Icons.chevron_right, size: 14, color: Colors.grey[600]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(parts[i],
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ],
      ],
    );
  }

  String _formatFullTimestamp(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
    } catch (_) {
      return isoTimestamp;
    }
  }
}

class _ChipData {
  final String label;
  final Color color;
  final IconData? icon;
  const _ChipData({required this.label, required this.color, this.icon});
}
