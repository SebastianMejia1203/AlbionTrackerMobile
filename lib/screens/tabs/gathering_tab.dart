import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/gathering_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_image_widget.dart';
import '../../utils/formatters.dart';
import '../../utils/zone_utils.dart';

// ─── Resource type metadata ───
class _ResInfo {
  final GatheringResourceFilter filter;
  final String label;
  final IconData icon;
  final Color color;
  const _ResInfo(this.filter, this.label, this.icon, this.color);
}

const _kResources = <_ResInfo>[
  _ResInfo(GatheringResourceFilter.all, 'Todo', Icons.select_all, Color(0xFF90A4AE)),
  _ResInfo(GatheringResourceFilter.wood, 'Madera', Icons.park, Color(0xFF66BB6A)),
  _ResInfo(GatheringResourceFilter.hide, 'Cuero', Icons.pets, Color(0xFF8D6E63)),
  _ResInfo(GatheringResourceFilter.ore, 'Mineral', Icons.hardware, Color(0xFF78909C)),
  _ResInfo(GatheringResourceFilter.rock, 'Piedra', Icons.terrain, Color(0xFFBCAAA4)),
  _ResInfo(GatheringResourceFilter.fiber, 'Fibra', Icons.grass, Color(0xFF4DD0E1)),
  _ResInfo(GatheringResourceFilter.fish, 'Pesca', Icons.phishing, Color(0xFF42A5F5)),
];

_ResInfo _infoFor(GatheringResourceFilter f) =>
    _kResources.firstWhere((r) => r.filter == f, orElse: () => _kResources.first);

class GatheringTab extends StatefulWidget {
  const GatheringTab({super.key});

  @override
  State<GatheringTab> createState() => _GatheringTabState();
}

class _GatheringTabState extends State<GatheringTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<ConnectionProvider>().service;
      svc.requestGathering();
      svc.requestGatheringStatus();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── MAP SECTION BUILDER ───
  List<_MapSection> _buildMapSections(List<GatheredData> items) {
    final mapGroups = <String, List<GatheredData>>{};
    for (final item in items) {
      final mapKey = item.clusterIndex.isNotEmpty ? item.clusterIndex : 'unknown';
      mapGroups.putIfAbsent(mapKey, () => []).add(item);
    }

    final sections = <_MapSection>[];
    for (final entry in mapGroups.entries) {
      final mapItems = entry.value;
      final first = mapItems.first;
      final mapName = first.mapDisplayName.isNotEmpty
          ? first.mapDisplayName
          : (first.clusterIndex.isNotEmpty && first.clusterIndex != 'unknown'
              ? first.clusterIndex
              : (first.mapType.isNotEmpty && first.mapType != 'Unknown'
                  ? first.mapType
                  : 'Sin Información'));

      final resourceMap = <String, _GatheringGroup>{};
      for (final item in mapItems) {
        if (resourceMap.containsKey(item.uniqueName)) {
          resourceMap[item.uniqueName]!.addItem(item);
        } else {
          resourceMap[item.uniqueName] = _GatheringGroup(item);
        }
      }

      sections.add(_MapSection(
        mapKey: entry.key,
        mapName: mapName,
        clusterMode: first.clusterMode,
        groups: resourceMap.values.toList(),
        allItems: mapItems,
      ));
    }
    return sections;
  }

  // ══════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GatheringProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Column(
      children: [
        // ── TRACKING TOGGLE ──
        _buildTrackingToggle(provider, cs, isDark),

        // ── TABS: Dashboard | Detalle ──
        Container(
          color: cs.surface,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
            indicatorColor: cs.primary,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard, size: 18), text: 'Dashboard'),
              Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Detalle'),
            ],
          ),
        ),

        // ── TAB VIEWS ──
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              // TAB 1: Dashboard
              _buildDashboardTab(provider, isDark, cs),
              // TAB 2: Detail
              _buildDetailTab(provider, isDark, cs),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  //  TRACKING TOGGLE
  // ══════════════════════════════════════════════════════
  Widget _buildTrackingToggle(GatheringProvider prov, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.12))),
      ),
      child: Row(
        children: [
          Icon(
            prov.isTrackingActive ? Icons.sensors : Icons.sensors_off,
            size: 18,
            color: prov.isTrackingActive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prov.isTrackingActive ? 'Tracking activo' : 'Tracking desactivado',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: prov.isTrackingActive
                    ? (isDark ? Colors.green[300] : Colors.green[700])
                    : Colors.grey,
              ),
            ),
          ),
          Switch.adaptive(
            value: prov.isTrackingActive,
            activeTrackColor: Colors.green,
            onChanged: (val) {
              context.read<ConnectionProvider>().service.setGatheringActive(val);
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 1 — DASHBOARD
  // ══════════════════════════════════════════════════════
  Widget _buildDashboardTab(GatheringProvider prov, bool isDark, ColorScheme cs) {
    final stats = prov.stats;

    if (prov.allItems.isEmpty) {
      return const EmptyState(
        icon: Icons.park_outlined,
        message: 'Sin datos de recolección',
        submessage: 'Los datos aparecerán cuando recolectes recursos',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── TOTALS ROW ──
        Row(
          children: [
            _totalCard('Recursos', '${stats.totalResources}', Icons.inventory_2, Colors.teal, isDark),
            const SizedBox(width: 8),
            _totalCard('Procesos', '${stats.totalMiningProcesses}', Icons.repeat, Colors.orange, isDark),
            const SizedBox(width: 8),
            _totalCard('Plata', Formatters.silver(stats.totalGainedSilver.toDouble()),
                Icons.monetization_on, const Color(0xFFBDBDBD), isDark),
          ],
        ),
        const SizedBox(height: 16),

        // ── PER-RESOURCE GRID ──
        Text('Desglose por recurso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: [
            _resourceDashCard('Madera', stats.woodCount, stats.gainedSilverByWood, Icons.park, const Color(0xFF66BB6A), isDark),
            _resourceDashCard('Cuero', stats.hideCount, stats.gainedSilverByHide, Icons.pets, const Color(0xFF8D6E63), isDark),
            _resourceDashCard('Mineral', stats.oreCount, stats.gainedSilverByOre, Icons.hardware, const Color(0xFF78909C), isDark),
            _resourceDashCard('Piedra', stats.rockCount, stats.gainedSilverByRock, Icons.terrain, const Color(0xFFBCAAA4), isDark),
            _resourceDashCard('Fibra', stats.fiberCount, stats.gainedSilverByFiber, Icons.grass, const Color(0xFF4DD0E1), isDark),
            _resourceDashCard('Pesca', stats.fishCount, stats.gainedSilverByFish, Icons.phishing, const Color(0xFF42A5F5), isDark),
          ],
        ),

        const SizedBox(height: 16),

        // ── PIE-LIKE RESOURCE DISTRIBUTION BAR ──
        Text('Distribución', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        _buildDistributionBar(stats, isDark),
      ],
    );
  }

  Widget _totalCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _resourceDashCard(String label, int count, int silver, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                Text('x$count', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 11, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        Formatters.silver(silver.toDouble()),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(GatheringStatsData stats, bool isDark) {
    final total = stats.totalResources;
    if (total == 0) return const SizedBox.shrink();

    final segments = <_Segment>[
      _Segment('Madera', stats.woodCount, const Color(0xFF66BB6A)),
      _Segment('Cuero', stats.hideCount, const Color(0xFF8D6E63)),
      _Segment('Mineral', stats.oreCount, const Color(0xFF78909C)),
      _Segment('Piedra', stats.rockCount, const Color(0xFFBCAAA4)),
      _Segment('Fibra', stats.fiberCount, const Color(0xFF4DD0E1)),
      _Segment('Pesca', stats.fishCount, const Color(0xFF42A5F5)),
    ];
    // Remove zero
    segments.removeWhere((s) => s.count == 0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 16,
            child: Row(
              children: segments.map((s) {
                final pct = s.count / total;
                return Expanded(
                  flex: (pct * 1000).round().clamp(1, 1000),
                  child: Container(color: s.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: segments.map((s) {
            final pct = (s.count / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('${s.label} $pct%', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[700])),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  //  TAB 2 — DETAIL (Filters + Map Sections)
  // ══════════════════════════════════════════════════════
  Widget _buildDetailTab(GatheringProvider prov, bool isDark, ColorScheme cs) {
    final filtered = prov.filteredItems;
    final hasFilters = prov.resourceFilter != GatheringResourceFilter.all
        || prov.mapFilter.isNotEmpty
        || prov.dateFrom != null
        || prov.dateTo != null;

    return Column(
      children: [
        // ── FILTER BAR ──
        _buildFilterBar(prov, isDark, cs),

        // ── ACTIVE FILTERS CHIPS ──
        if (hasFilters)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: cs.primary.withValues(alpha: 0.06),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _activeFilterLabel(prov),
                    style: TextStyle(fontSize: 11, color: cs.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => prov.clearFilters(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text('Limpiar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
                  ),
                ),
              ],
            ),
          ),

        // ── RESULTS COUNT ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} registro${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),

        // ── MAP SECTIONS ──
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  message: 'Sin resultados',
                  submessage: 'Intenta ajustar los filtros',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: _buildMapSections(filtered).length,
                  itemBuilder: (context, index) {
                    final sections = _buildMapSections(filtered);
                    return _buildMapSection(sections[index], isDark, prov);
                  },
                ),
        ),
      ],
    );
  }

  String _activeFilterLabel(GatheringProvider prov) {
    final parts = <String>[];
    if (prov.resourceFilter != GatheringResourceFilter.all) {
      parts.add(_infoFor(prov.resourceFilter).label);
    }
    if (prov.mapFilter.isNotEmpty) parts.add(prov.mapFilter);
    if (prov.dateFrom != null || prov.dateTo != null) {
      final from = prov.dateFrom != null ? '${prov.dateFrom!.day}/${prov.dateFrom!.month}' : '...';
      final to = prov.dateTo != null ? '${prov.dateTo!.day}/${prov.dateTo!.month}' : '...';
      parts.add('$from – $to');
    }
    return parts.join(' · ');
  }

  // ── FILTER BAR ──
  Widget _buildFilterBar(GatheringProvider prov, bool isDark, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          // RESOURCE TYPE CHIPS
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _kResources.map((r) {
                final selected = prov.resourceFilter == r.filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(r.icon, size: 14, color: selected ? Colors.white : r.color),
                        const SizedBox(width: 4),
                        Text(r.label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[800]))),
                      ],
                    ),
                    selected: selected,
                    selectedColor: r.color,
                    backgroundColor: r.color.withValues(alpha: 0.08),
                    side: BorderSide(color: selected ? r.color : r.color.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => prov.setResourceFilter(r.filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          // MAP DROPDOWN + DATE RANGE
          Row(
            children: [
              // Map dropdown
              Expanded(
                child: _mapDropdown(prov, isDark, cs),
              ),
              const SizedBox(width: 8),
              // Date range button
              _dateRangeButton(prov, isDark, cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapDropdown(GatheringProvider prov, bool isDark, ColorScheme cs) {
    final maps = prov.availableMaps;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        color: cs.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: prov.mapFilter.isEmpty ? null : prov.mapFilter,
          isExpanded: true,
          isDense: true,
          hint: Row(
            children: [
              Icon(Icons.map, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('Todos los mapas', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text('Todos los mapas', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
            ...maps.map((m) => DropdownMenuItem<String>(
              value: m,
              child: Text(m, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: (val) => prov.setMapFilter(val ?? ''),
        ),
      ),
    );
  }

  Widget _dateRangeButton(GatheringProvider prov, bool isDark, ColorScheme cs) {
    final hasDate = prov.dateFrom != null || prov.dateTo != null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: (prov.dateFrom != null && prov.dateTo != null)
              ? DateTimeRange(start: prov.dateFrom!, end: prov.dateTo!)
              : null,
        );
        if (range != null) {
          prov.setDateRange(range.start, range.end);
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasDate ? cs.primary : cs.outline.withValues(alpha: 0.2)),
          color: hasDate ? cs.primary.withValues(alpha: 0.1) : cs.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 14, color: hasDate ? cs.primary : Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              hasDate
                  ? '${prov.dateFrom!.day}/${prov.dateFrom!.month} – ${prov.dateTo!.day}/${prov.dateTo!.month}'
                  : 'Fecha',
              style: TextStyle(fontSize: 12, color: hasDate ? cs.primary : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  MAP SECTION (clickable → detail sheet)
  // ══════════════════════════════════════════════════════
  Widget _buildMapSection(_MapSection section, bool isDark, GatheringProvider prov) {
    final zoneColor = ZoneUtils.clusterModeColor(section.clusterMode, isDark: isDark);
    final zoneLabel = section.clusterMode.isNotEmpty
        ? ZoneUtils.clusterModeLabel(section.clusterMode)
        : '';

    int totalResources = 0;
    int totalFame = 0;
    for (final g in section.groups) {
      totalResources += g.totalAmount;
      totalFame += g.totalFame;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // ── MAP HEADER (tappable) ──
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showMapDetailSheet(context, section, isDark),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: zoneColor, width: 4)),
            ),
            child: Row(
              children: [
                Icon(Icons.explore, size: 16, color: zoneColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.mapName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      if (zoneLabel.isNotEmpty)
                        Text(zoneLabel, style: TextStyle(fontSize: 11, color: zoneColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('x$totalResources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                    if (totalFame > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00)),
                          const SizedBox(width: 2),
                          Text(Formatters.fame(totalFame.toDouble()), style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00))),
                        ],
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        // ── RESOURCES (swipe to delete) ──
        ...section.groups.map((group) => _buildResourceRow(group, isDark, prov)),
      ],
    );
  }

  Widget _buildResourceRow(_GatheringGroup group, bool isDark, GatheringProvider prov) {
    final item = group.representative;

    return Dismissible(
      key: ValueKey(group.guids.join(',')),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_sweep, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar registros'),
            content: Text('¿Eliminar ${group.count} registro${group.count > 1 ? 's' : ''} de "${item.itemName.isNotEmpty ? item.itemName : item.uniqueName}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        final guids = group.guids;
        context.read<ConnectionProvider>().service.removeGatheringEntries(guids);
        prov.removeItemsLocally(guids);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              ItemImageWidget(uniqueName: item.uniqueName, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName.isNotEmpty ? item.itemName : item.uniqueName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('x${group.totalAmount}', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700], fontWeight: FontWeight.w500)),
                        if (group.count > 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('(${group.count} veces)', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                          ),
                        const Spacer(),
                        if (group.totalFame > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00)),
                              const SizedBox(width: 2),
                              Text(Formatters.fame(group.totalFame.toDouble()), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00))),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (group.latestTimestamp.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(Formatters.time(group.latestTimestamp), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  MAP DETAIL BOTTOM SHEET
  // ══════════════════════════════════════════════════════
  void _showMapDetailSheet(BuildContext context, _MapSection section, bool isDark) {
    final zoneColor = ZoneUtils.clusterModeColor(section.clusterMode, isDark: isDark);
    final zoneLabel = section.clusterMode.isNotEmpty ? ZoneUtils.clusterModeLabel(section.clusterMode) : '';

    int totalResources = 0;
    int totalFame = 0;
    int totalSilver = 0;
    for (final g in section.groups) {
      totalResources += g.totalAmount;
      totalFame += g.totalFame;
      totalSilver += g.totalMarketValue;
    }

    // Per-resource breakdown in this map (totalSilver used below)
    final byType = <String, _TypeSummary>{};
    for (final item in section.allItems) {
      final type = _classifyResource(item);
      byType.putIfAbsent(type, () => _TypeSummary(type));
      byType[type]!.count += item.gainedTotalAmount;
      byType[type]!.fame += item.gainedFame;
      byType[type]!.silver += item.totalMarketValue;
    }
    final typeSummaries = byType.values.toList()..sort((a, b) => b.count.compareTo(a.count));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scroll) {
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),

                // Map header
                Row(
                  children: [
                    Icon(Icons.explore, color: zoneColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(section.mapName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                          if (zoneLabel.isNotEmpty)
                            Text(zoneLabel, style: TextStyle(fontSize: 12, color: zoneColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Totals row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _sheetStat('Recursos', '$totalResources', Colors.teal),
                    _sheetStat('Fama', Formatters.fame(totalFame.toDouble()), isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00)),
                    _sheetStat('Plata', Formatters.silver(totalSilver.toDouble()), const Color(0xFFBDBDBD)),
                  ],
                ),

                const SizedBox(height: 16),
                Text('Desglose por tipo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),

                // Resource breakdown
                ...typeSummaries.map((ts) {
                  final info = _typeInfo(ts.type);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(info.icon, size: 18, color: info.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(info.label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87))),
                        Text('x${ts.count}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 70,
                          child: Text(
                            Formatters.silver(ts.silver.toDouble()),
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Divider(height: 20),

                // Individual items
                Text('Recursos recolectados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 8),
                ...section.groups.map((g) {
                  final item = g.representative;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        ItemImageWidget(uniqueName: item.uniqueName, size: 32),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.itemName.isNotEmpty ? item.itemName : item.uniqueName,
                              style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                        Text('x${g.totalAmount}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(width: 10),
                        if (g.totalFame > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00)),
                              Text(Formatters.fame(g.totalFame.toDouble()), style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFFFD700) : const Color(0xFFC49B00))),
                            ],
                          ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  // ── Classify a GatheredData into a resource type string (delegate to provider) ──
  static String _classifyResource(GatheredData item) => GatheringProvider.classifyResource(item);

  static _ResInfo _typeInfo(String type) {
    switch (type) {
      case 'wood': return _kResources[1];
      case 'hide': return _kResources[2];
      case 'ore': return _kResources[3];
      case 'rock': return _kResources[4];
      case 'fiber': return _kResources[5];
      case 'fish': return _kResources[6];
      default: return const _ResInfo(GatheringResourceFilter.all, 'Otro', Icons.help_outline, Color(0xFF90A4AE));
    }
  }
}

// ═══════════ DATA CLASSES ═══════════

class _MapSection {
  final String mapKey;
  final String mapName;
  final String clusterMode;
  final List<_GatheringGroup> groups;
  final List<GatheredData> allItems;

  _MapSection({
    required this.mapKey,
    required this.mapName,
    required this.clusterMode,
    required this.groups,
    required this.allItems,
  });
}

class _GatheringGroup {
  final GatheredData representative;
  final List<String> guids = [];
  int count = 1;
  int totalAmount;
  int totalFame;
  int totalMarketValue;
  String latestTimestamp;

  _GatheringGroup(this.representative)
      : totalAmount = representative.gainedTotalAmount,
        totalFame = representative.gainedFame,
        totalMarketValue = representative.totalMarketValue,
        latestTimestamp = representative.timestampUtc {
    if (representative.guid.isNotEmpty) guids.add(representative.guid);
  }

  void addItem(GatheredData item) {
    count++;
    totalAmount += item.gainedTotalAmount;
    totalFame += item.gainedFame;
    totalMarketValue += item.totalMarketValue;
    if (item.guid.isNotEmpty) guids.add(item.guid);
    if (item.timestampUtc.compareTo(latestTimestamp) > 0) {
      latestTimestamp = item.timestampUtc;
    }
  }
}

class _Segment {
  final String label;
  final int count;
  final Color color;
  _Segment(this.label, this.count, this.color);
}

class _TypeSummary {
  final String type;
  int count = 0;
  int fame = 0;
  int silver = 0;
  _TypeSummary(this.type);
}
