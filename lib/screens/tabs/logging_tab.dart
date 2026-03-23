import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/logging_provider.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/formatters.dart';

class LoggingTab extends StatefulWidget {
  const LoggingTab({super.key});

  @override
  State<LoggingTab> createState() => _LoggingTabState();
}

class _LoggingTabState extends State<LoggingTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  LoggingSettingsData _loggingSettings = const LoggingSettingsData();
  StreamSubscription? _settingsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<ConnectionProvider>().service;
      service.requestLogging();
      service.requestLoggingSettings();
      _settingsSub = service.loggingSettingsStream.listen((settings) {
        if (mounted) setState(() => _loggingSettings = settings);
      });
    });
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  static const _filterTypes = <_FilterDef>[
    _FilterDef('kill', 'Kills', Icons.gps_fixed, Colors.red),
    _FilterDef('fame', 'Fama', Icons.star, Color(0xFFFFD700)),
    _FilterDef('silver', 'Plata', Icons.monetization_on, Colors.grey),
    _FilterDef('equipmentloot', 'Equipo', Icons.shield, Colors.amber),
    _FilterDef('consumableloot', 'Consumibles', Icons.local_drink, Colors.teal),
    _FilterDef('simpleloot', 'Materiales', Icons.inventory_2, Colors.brown),
    _FilterDef('unknownloot', 'Otro Loot', Icons.help_outline, Colors.blueGrey),
    _FilterDef('faction', 'Facción', Icons.flag, Colors.indigo),
    _FilterDef('seasonpoints', 'Temporada', Icons.emoji_events, Colors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoggingProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar + filter toggle
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      provider.setSearchQuery(value);
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter toggle
              Material(
                color: _showFilters
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : (isDark ? Colors.grey[900]! : Colors.grey[100]!),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    child: Badge(
                      isLabelVisible: provider.activeFilters.length < 9,
                      label: Text('${provider.activeFilters.length}',
                          style: const TextStyle(fontSize: 9)),
                      child: Icon(
                        Icons.filter_list,
                        size: 20,
                        color: _showFilters
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filters panel
        if (_showFilters) _buildFiltersPanel(provider, theme, isDark),

        // Count indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${provider.count} de ${provider.totalCount}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.read<ConnectionProvider>().service.requestLogging(count: 200);
                },
                child: Text(
                  'Actualizar',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Notifications list
        Expanded(
          child: provider.notifications.isEmpty
              ? const EmptyState(
                  icon: Icons.list_alt_outlined,
                  message: 'Sin notificaciones',
                  submessage: 'Ajusta los filtros o espera actividad',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  itemCount: provider.notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(
                        provider.notifications[index], isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersPanel(
      LoggingProvider provider, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Filtros',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500])),
              const Spacer(),
              GestureDetector(
                onTap: () => provider.setAllFilters(true),
                child: Text('Todos',
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.primary)),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => provider.setAllFilters(false),
                child: Text('Ninguno',
                    style: TextStyle(
                        fontSize: 11, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _filterTypes.map((f) {
              final active = provider.activeFilters.contains(f.key);
              return GestureDetector(
                onTap: () => provider.toggleFilter(f.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: active
                        ? f.color.withValues(alpha: 0.15)
                        : (isDark ? Colors.grey[850] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: active
                          ? f.color.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon,
                          size: 13,
                          color: active ? f.color : Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal,
                          color: active
                              ? f.color
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        // Tracking settings section
          const Divider(height: 16, thickness: 0.5),
          Text('Rastreo',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _trackingToggle('Plata', Icons.monetization_on, Colors.grey[300]!, _loggingSettings.isTrackingSilver,
                  () => _setLoggingSettings(isTrackingSilver: !_loggingSettings.isTrackingSilver), isDark),
              _trackingToggle('Fama', Icons.star, const Color(0xFFFFD700), _loggingSettings.isTrackingFame,
                  () => _setLoggingSettings(isTrackingFame: !_loggingSettings.isTrackingFame), isDark),
              _trackingToggle('Loot de Mobs', Icons.bug_report, Colors.orange, _loggingSettings.isTrackingMobLoot,
                  () => _setLoggingSettings(isTrackingMobLoot: !_loggingSettings.isTrackingMobLoot), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackingToggle(String label, IconData icon, Color color, bool active, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : (isDark ? Colors.grey[850] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? color.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? color : Colors.grey[500]),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: active ? color : (isDark ? Colors.grey[400] : Colors.grey[600]),
            )),
            const SizedBox(width: 4),
            Icon(active ? Icons.toggle_on : Icons.toggle_off, size: 18,
                color: active ? color : Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  void _setLoggingSettings({
    bool? isTrackingSilver,
    bool? isTrackingFame,
    bool? isTrackingMobLoot,
  }) {
    final newSettings = LoggingSettingsData(
      isTrackingSilver: isTrackingSilver ?? _loggingSettings.isTrackingSilver,
      isTrackingFame: isTrackingFame ?? _loggingSettings.isTrackingFame,
      isTrackingMobLoot: isTrackingMobLoot ?? _loggingSettings.isTrackingMobLoot,
    );
    setState(() => _loggingSettings = newSettings);
    context.read<ConnectionProvider>().service.setLoggingSettings(
      isTrackingSilver: newSettings.isTrackingSilver,
      isTrackingFame: newSettings.isTrackingFame,
      isTrackingMobLoot: newSettings.isTrackingMobLoot,
    );
  }

  Widget _buildNotificationCard(LoggingNotification notification, bool isDark) {
    final frag = notification.fragment;
    final hasContent =
        frag.localizedName.isNotEmpty || frag.description.isNotEmpty;
    final typeColor = _typeColor(notification.type);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark
              ? Colors.grey[800]!.withValues(alpha: 0.5)
              : Colors.grey[200]!,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: hasContent ? () => _showNotificationDetail(notification) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type icon (compact)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _typeIconWidget(notification.type, typeColor),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First line: name/description
                    if (frag.localizedName.isNotEmpty)
                      Text(
                        '${frag.localizedName}${frag.quantity > 1 ? ' x${frag.quantity}' : ''}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (frag.description.isNotEmpty)
                      Text(
                        frag.description,
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        _typeLabel(notification.type),
                        style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[300] : Colors.grey[700]),
                      ),

                    const SizedBox(height: 2),

                    // Second line: metadata
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            _typeLabel(notification.type),
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: typeColor),
                          ),
                        ),
                        if (frag.lootedByName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.person, size: 10, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              frag.lootedByName,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (frag.lootedFromName.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_back,
                              size: 10, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              frag.lootedFromName,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (frag.killedBy.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('⚔',
                              style: TextStyle(fontSize: 9, color: Colors.red[400])),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              frag.killedBy,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.red[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (frag.died.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Image.asset('assets/icons/skull_red.png',
                              width: 10, height: 10,
                              errorBuilder: (_, __, ___) => Icon(Icons.dangerous, size: 10, color: Colors.red[300])),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              frag.died,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.red[300]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right side: values and time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Values
                  if (frag.gainedFame > 0)
                    _compactValue(
                        Formatters.fame(frag.gainedFame), Colors.amber[300]!),
                  if (frag.gainedSilver > 0)
                    _compactValue(
                        Formatters.silver(frag.gainedSilver), Colors.grey[400]!),
                  if (frag.estimatedMarketValue > 0)
                    _compactValue(Formatters.silver(frag.estimatedMarketValue),
                        Colors.green[400]!),
                  // Timestamp
                  Text(
                    Formatters.dateTime(notification.dateTime),
                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compactValue(String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        value,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  IconData _typeIconData(String type) {
    final t = type.toLowerCase();
    if (t.contains('kill')) return Icons.gps_fixed;
    if (t.contains('loot') || t.contains('grabbed')) return Icons.inventory_2;
    if (t.contains('fame')) return Icons.star;
    if (t.contains('silver')) return Icons.monetization_on;
    if (t.contains('death')) return Icons.dangerous;
    if (t.contains('chest')) return Icons.lock_open;
    if (t.contains('faction')) return Icons.flag;
    if (t.contains('season')) return Icons.emoji_events;
    return Icons.notifications;
  }

  Widget _typeIconWidget(String type, Color color) {
    final t = type.toLowerCase();
    if (t.contains('kill')) {
      return Text('⚔',
          style: TextStyle(fontSize: 16, color: color));
    }
    if (t.contains('death')) {
      return Image.asset('assets/icons/skull_red.png',
          width: 16, height: 16,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.dangerous, size: 16, color: color));
    }
    return Icon(_typeIconData(type), size: 16, color: color);
  }

  Color _typeColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('kill')) return Colors.red;
    if (t.contains('equipment')) return Colors.amber;
    if (t.contains('consumable')) return Colors.teal;
    if (t.contains('simple')) return Colors.brown;
    if (t.contains('loot') || t.contains('grabbed')) return Colors.amber;
    if (t.contains('fame')) return const Color(0xFFFFD700);
    if (t.contains('silver')) return Colors.grey;
    if (t.contains('death')) return Colors.red[800]!;
    if (t.contains('faction')) return Colors.indigo;
    if (t.contains('season')) return Colors.purple;
    if (t.contains('chest')) return Colors.blue;
    return Colors.grey;
  }

  String _typeLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('kill')) return 'KILL';
    if (t.contains('equipment')) return 'EQUIPO';
    if (t.contains('consumable')) return 'CONSUMIBLE';
    if (t.contains('simple')) return 'MATERIAL';
    if (t.contains('loot') || t.contains('grabbed')) return 'LOOT';
    if (t.contains('fame')) return 'FAMA';
    if (t.contains('silver')) return 'PLATA';
    if (t.contains('death')) return 'MUERTE';
    if (t.contains('faction')) return 'FACCIÓN';
    if (t.contains('season')) return 'TEMPORADA';
    if (t.contains('chest')) return 'COFRE';
    return type.toUpperCase();
  }

  void _showNotificationDetail(LoggingNotification notification) {
    final frag = notification.fragment;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _typeColor(notification.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIconData(notification.type),
                      size: 20,
                      color: _typeColor(notification.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel(notification.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _typeColor(notification.type),
                          ),
                        ),
                        if (frag.localizedName.isNotEmpty)
                          Text(
                            '${frag.localizedName}${frag.quantity > 1 ? ' x${frag.quantity}' : ''}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        if (frag.description.isNotEmpty)
                          Text(
                            frag.description,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.dateTime(notification.dateTime),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Detail rows
              if (frag.gainedFame > 0)
                _detailRow(Icons.star, 'Fama ganada',
                    Formatters.fame(frag.gainedFame), Colors.amber[300]!),
              if (frag.totalPlayerFame > 0)
                _detailRow(Icons.star_border, 'Fama total',
                    Formatters.fame(frag.totalPlayerFame), Colors.amber[200]!),
              if (frag.gainedSilver > 0)
                _detailRow(Icons.monetization_on, 'Plata ganada',
                    Formatters.silver(frag.gainedSilver), Colors.grey[400]!),
              if (frag.totalPlayerSilver > 0)
                _detailRow(Icons.savings, 'Plata total',
                    Formatters.silver(frag.totalPlayerSilver), Colors.grey[300]!),
              if (frag.estimatedMarketValue > 0)
                _detailRow(Icons.store, 'Valor de mercado est.',
                    Formatters.silver(frag.estimatedMarketValue), Colors.green[300]!),
              if (frag.lootedByName.isNotEmpty)
                _detailRow(Icons.person, 'Recogido por',
                    frag.lootedByName, Colors.blue[300]!),
              if (frag.lootedFromName.isNotEmpty)
                _detailRow(Icons.person_outline, 'Obtenido de',
                    frag.lootedFromName, Colors.orange[300]!),
              if (frag.killedBy.isNotEmpty)
                _detailRowW(
                  Text('⚔', style: TextStyle(fontSize: 16, color: Colors.red[300])),
                  'Eliminado por', frag.killedBy, Colors.red[300]!),
              if (frag.died.isNotEmpty)
                _detailRowW(
                  Image.asset('assets/icons/skull_red.png', width: 14, height: 14,
                      errorBuilder: (_, __, ___) => Icon(Icons.dangerous, size: 16, color: Colors.red[400])),
                  'Murió', frag.died, Colors.red[400]!),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return _detailRowW(Icon(icon, size: 16, color: color), label, value, color);
  }

  Widget _detailRowW(Widget iconWidget, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _FilterDef {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _FilterDef(this.key, this.label, this.icon, this.color);
}
