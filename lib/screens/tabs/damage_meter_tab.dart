import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../models/firebase_party_models.dart';
import '../../providers/damage_meter_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/firebase_party_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_image_widget.dart';
import '../../utils/formatters.dart';

class DamageMeterTab extends StatefulWidget {
  const DamageMeterTab({super.key});

  @override
  State<DamageMeterTab> createState() => _DamageMeterTabState();
}

class _DamageMeterTabState extends State<DamageMeterTab> {
  final GlobalKey _repaintKey = GlobalKey();
  String _sortBy = 'damage'; // damage | dps | healing | hps | name

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestDamageMeter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DamageMeterProvider>();
    final data = provider.data;

    if (provider.fragments.isEmpty) {
      return const EmptyState(
        icon: Icons.local_fire_department_outlined,
        message: 'Sin datos de combate',
        submessage: 'Los datos aparecerán cuando entres en combate',
      );
    }

    // Sort fragments client-side
    final sorted = List<DamageMeterFragment>.from(provider.fragments);
    switch (_sortBy) {
      case 'dps':
        sorted.sort((a, b) => b.dps.compareTo(a.dps));
        break;
      case 'healing':
        sorted.sort((a, b) => b.heal.compareTo(a.heal));
        break;
      case 'hps':
        sorted.sort((a, b) => b.hps.compareTo(a.hps));
        break;
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      default: // damage
        sorted.sort((a, b) => b.damage.compareTo(a.damage));
    }

    return RepaintBoundary(
      key: _repaintKey,
      child: Column(
        children: [
          // Summary Header
          _buildSummaryBar(data),

          // Actions Bar
          _buildActionsBar(data),

          // Player list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                return _buildPlayerCard(sorted[index], index, data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(DamageMeterData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _miniStat('Jugadores', '${data.fragments.length}', null),
          _miniStat('DPS Total', Formatters.compact(data.fragments.fold<int>(0, (s, f) => s + f.damage)), Colors.red[300]),
          _miniStat('HPS Total', Formatters.compact(data.fragments.fold<int>(0, (s, f) => s + f.heal)), Colors.green[300]),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color? color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildActionsBar(DamageMeterData data) {
    final service = context.read<ConnectionProvider>().service;
    final resetOnMap = data.isDamageMeterResetByMapChangeActive;
    final fb = context.watch<FirebasePartyProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () {
              // Immediately clear local data so UI resets in one click
              context.read<DamageMeterProvider>().clear();
              context.read<ConnectionProvider>().service.resetDamageMeter();
              // Si hay party activa como host, propagar reset a guests de inmediato
              if (fb.isHost) {
                context.read<FirebasePartyProvider>().pushNow();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Damage meter reseteado'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reset', style: TextStyle(fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: () => _takeScreenshot(),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Snapshot', style: TextStyle(fontSize: 12)),
          ),
          TextButton.icon(
            onPressed: () => _copyToClipboard(),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar', style: TextStyle(fontSize: 12)),
          ),
          // ── Party button ────────────────────────────────────────────────
          fb.isActive
              ? _buildPartyActiveChip(fb)
              : TextButton.icon(
                  onPressed: () => _showCreatePartyDialog(),
                  icon: Icon(Icons.share_location, size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  label: Text('Party',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
          const Spacer(),
          // Toggle reset on map change
          Tooltip(
            message: resetOnMap ? 'Auto-reset al cambiar mapa: ON' : 'Auto-reset al cambiar mapa: OFF',
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => service.setDamageMeterResetOnMapChange(!resetOnMap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 16, color: resetOnMap ? Colors.greenAccent : Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      'Auto-reset',
                      style: TextStyle(
                        fontSize: 11,
                        color: resetOnMap ? Colors.greenAccent : Colors.grey[600],
                        fontWeight: resetOnMap ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (sort) {
              setState(() => _sortBy = sort);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 18, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  _sortByLabel(_sortBy),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'damage', child: Text('Daño')),
              const PopupMenuItem(value: 'dps', child: Text('DPS')),
              const PopupMenuItem(value: 'healing', child: Text('Curación')),
              const PopupMenuItem(value: 'hps', child: Text('HPS')),
              const PopupMenuItem(value: 'name', child: Text('Nombre')),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Party helpers ──────────────────────────────────────────────────────

  Widget _buildPartyActiveChip(FirebasePartyProvider fb) {
    return GestureDetector(
      onTap: () => _showPartyActiveDialog(fb),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
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
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                size: 15, color: Colors.green),
          ],
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
            Container(
                width: 8, height: 8,
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
                  const SnackBar(
                      content: Text('Código copiado'),
                      duration: Duration(seconds: 1)),
                );
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fb.code ?? '',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Theme.of(context).colorScheme.primary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${fb.snapshot?.memberCount ?? 0}/${fb.maxMembers} miembros conectados',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
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
                              SnackBar(
                                  content: Text(
                                      fb.error ?? 'Error desconocido')),
                            );
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

  String _sortByLabel(String sortBy) {
    switch (sortBy) {
      case 'dps': return 'DPS';
      case 'healing': return 'Curación';
      case 'hps': return 'HPS';
      case 'name': return 'Nombre';
      default: return 'Daño';
    }
  }

  Future<void> _takeScreenshot() async {
    try {
      // Also save on server
      context.read<ConnectionProvider>().service.takeDamageMeterSnapshot();

      // Capture the widget as an image
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al capturar pantalla'), duration: Duration(seconds: 2)),
        );
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      // Save to device gallery
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await Gal.putImageBytes(pngBytes, name: 'dps_meter_$timestamp');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Snapshot guardado en la galería'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _copyToClipboard() {
    final provider = context.read<DamageMeterProvider>();
    final fragments = provider.fragments;
    if (fragments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin datos para copiar'), duration: Duration(seconds: 1)),
      );
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('=== Albion DPS Meter ===');
    final totalDamage = fragments.fold<int>(0, (s, f) => s + f.damage);
    final totalHealing = fragments.fold<int>(0, (s, f) => s + f.heal);
    buffer.writeln('Total DMG: ${Formatters.number(totalDamage)} | Total HEAL: ${Formatters.number(totalHealing)}');
    buffer.writeln('');
    for (int i = 0; i < fragments.length; i++) {
      final f = fragments[i];
      final dmgPct = totalDamage > 0 ? (f.damage / totalDamage * 100).toStringAsFixed(1) : '0';
      final healPct = totalHealing > 0 ? (f.heal / totalHealing * 100).toStringAsFixed(1) : '0';
      buffer.writeln('#${i + 1} ${f.name}: DMG ${Formatters.compact(f.damage)} ($dmgPct%) ${Formatters.compact(f.dps)}/s | HEAL ${Formatters.compact(f.heal)} ($healPct%) ${Formatters.compact(f.hps)}/s');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos copiados al portapapeles'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildPlayerCard(DamageMeterFragment player, int index, DamageMeterData data) {
    final totalDamage = data.fragments.fold<int>(0, (s, f) => s + f.damage);
    final totalHealing = data.fragments.fold<int>(0, (s, f) => s + f.heal);
    final damagePercent = totalDamage > 0
        ? (player.damage / totalDamage)
        : 0.0;
    final healingPercent = totalHealing > 0
        ? (player.heal / totalHealing)
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showPlayerDetail(player),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: index < 3
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[500],
                  ),
                ),
              ),

              // Main weapon
              if (player.causerMainHand != null)
                ItemImageWidget(
                  uniqueName: player.causerMainHand!.uniqueName,
                  size: 40,
                ),
              if (player.causerMainHand == null)
                const SizedBox(width: 40, height: 40),

              const SizedBox(width: 10),

              // Name + stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Damage bar
                    _buildStatBar(
                      'DMG',
                      Formatters.compact(player.damage),
                      '${Formatters.compact(player.dps)}/s',
                      damagePercent,
                      Colors.red[400]!,
                    ),
                    const SizedBox(height: 2),
                    // Healing bar
                    _buildStatBar(
                      'HEAL',
                      Formatters.compact(player.heal),
                      '${Formatters.compact(player.hps)}/s',
                      healingPercent,
                      Colors.green[400]!,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBar(
    String label,
    String value,
    String perSecond,
    double percent,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent.clamp(0, 1).toDouble(),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        perSecond,
                        style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 36,
          child: Text(
            '${(percent * 100).toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 9, color: Colors.grey[400]),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showPlayerDetail(DamageMeterFragment player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                player.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 16),

              // Equipment - show main hand if available
              if (player.causerMainHand != null) ...[
                const SectionHeader(title: 'Equipamiento', icon: Icons.shield),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _equipSlot(player.causerMainHand!.uniqueName, 'Main'),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Detailed Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Daño Total',
                      value: Formatters.number(player.damage),
                      valueColor: Colors.red[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'DPS',
                      value: Formatters.decimal(player.dps),
                      valueColor: Colors.red[300],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Curación Total',
                      value: Formatters.number(player.heal),
                      valueColor: Colors.green[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'HPS',
                      value: Formatters.decimal(player.hps),
                      valueColor: Colors.green[300],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _equipSlot(String uniqueName, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ItemImageWidget(
            uniqueName: uniqueName,
            size: 48,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
