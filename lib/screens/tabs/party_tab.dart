import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../models/firebase_party_models.dart';
import '../../providers/party_provider.dart';
import '../../providers/firebase_party_provider.dart';
import '../../providers/connection_provider.dart';
import '../../providers/damage_meter_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/ad_widgets.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/item_image_widget.dart';
import '../../utils/formatters.dart';

class PartyTab extends StatefulWidget {
  const PartyTab({super.key});

  @override
  State<PartyTab> createState() => _PartyTabState();
}

class _PartyTabState extends State<PartyTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().service.requestParty();

      // Wire up the host data callback
      final fbParty = context.read<FirebasePartyProvider>();
      final dps = context.read<DamageMeterProvider>();
      final dash = context.read<DashboardProvider>();
      final conn = context.read<ConnectionProvider>();

      fbParty.onGetMembers = () {
        final hostName = conn.playerInfo.username;
        // Snapshot actual en Firebase (para preservar fama/plata ya reportadas)
        final currentSnap = fbParty.snapshot;
        // Construir lista desde fragmentos del DPS meter
        final members = dps.fragments.map((f) {
          final isHostPlayer = f.name == hostName;
          // Recuperar fama/plata existente para no-host (la que el guest reportó)
          final existing = currentSnap?.members.firstWhere(
            (m) => m.name == f.name,
            orElse: () => FbPartyMember(
                name: f.name, damage: 0, dps: 0, fame: 0, silver: 0,
                lastUpdated: 0),
          );
          return FbPartyMember(
            name: f.name,
            damage: f.damage.toDouble(),
            dps: f.dps,
            fame: isHostPlayer
                ? dash.data.totalGainedFameInSession
                : (existing?.fame ?? 0),
            silver: isHostPlayer
                ? dash.data.totalGainedSilverInSession
                : (existing?.silver ?? 0),
            weapon: f.causerMainHand?.uniqueName ?? '',
            lastUpdated: DateTime.now().millisecondsSinceEpoch,
          );
        }).toList();
        // El host siempre aparece, aunque aún no tenga datos de combate
        if (hostName.isNotEmpty &&
            !members.any((m) => m.name == hostName)) {
          members.insert(
            0,
            FbPartyMember(
              name: hostName,
              damage: 0,
              dps: 0,
              fame: dash.data.totalGainedFameInSession,
              silver: dash.data.totalGainedSilverInSession,
              weapon: '',
              lastUpdated: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
        return members;
      };
    });
  }

  // ─── Firebase Party Share UI ─────────────────────────────────────────────

  Widget _buildShareSection(ThemeData theme, bool isDark) {
    final fb = context.watch<FirebasePartyProvider>();

    if (!fb.isActive) {
      return _buildStartCard(theme, isDark);
    }
    return _buildActiveHostCard(fb, theme, isDark);
  }

  Widget _buildStartCard(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.share_location,
                color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Compartir Party en tiempo real',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Comparte DPS, fama y plata sin SAT',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _showCreatePartyDialog(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Crear Party'),
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
                          final ok = await fb.createParty(
                            hostName: hostName,
                            maxMembers: maxMembers,
                            pushInterval: pushIntervalSeconds, // ← editar aquí para cambiar frecuencia
                          );
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(fb.error ?? 'Error desconocido')),
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

  Widget _buildActiveHostCard(
      FirebasePartyProvider fb, ThemeData theme, bool isDark) {
    final snap = fb.snapshot;
    final memberCount = snap?.memberCount ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.green[900]!.withValues(alpha: 0.2) : Colors.green[50],
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.green.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('Party Compartida Activa',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green)),
                const Spacer(),
                Text('$memberCount/${fb.maxMembers} online',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),

          // Code display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fb.code ?? '',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: theme.colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copiar código',
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: fb.code ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Código copiado'),
                          duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
          ),

          // Live members from Firebase
          if (snap != null && snap.members.isNotEmpty)
            _buildFbMembersList(snap, theme, isDark),

          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              children: [
                // Push interval selector
                Text('Push: ',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 5, label: Text('5s')),
                    ButtonSegment(value: 10, label: Text('10s')),
                    ButtonSegment(value: 30, label: Text('30s')),
                  ],
                  selected: {fb.pushIntervalSeconds},
                  onSelectionChanged: (s) =>
                      fb.updateHostConfig(pushInterval: s.first),
                  style: SegmentedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('Nuevo código',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    final fb = context.read<FirebasePartyProvider>();
                    await fb.regenerateCode();
                  },
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Cerrar Party'),
                        content: const Text(
                            '¿Cerrar la party compartida? Los miembros serán desconectados.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar')),
                          TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Cerrar')),
                        ],
                      ),
                    );
                    if (confirm == true && mounted) {
                      await context.read<FirebasePartyProvider>().closeParty();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      textStyle: const TextStyle(fontSize: 11)),
                  child: const Text('Cerrar Party'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFbMembersList(
      FbPartySnapshot snap, ThemeData theme, bool isDark) {
    final sorted = snap.sortedByDamage;
    // Fama/plata del host como stat general
    final hostMember = snap.members.where((m) => m.name == snap.meta.hostName).firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila de fama/plata del host (stat general)
          if (hostMember != null && (hostMember.fame > 0 || hostMember.silver > 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Image.asset('assets/icons/fame.png', width: 12, height: 12),
                  const SizedBox(width: 3),
                  Text(Formatters.fame(hostMember.fame),
                      style: TextStyle(fontSize: 11, color: Colors.amber[300])),
                  const SizedBox(width: 12),
                  Image.asset('assets/icons/silver.png', width: 12, height: 12),
                  const SizedBox(width: 3),
                  Text(Formatters.silver(hostMember.silver),
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ),
          // Lista de miembros
          ...sorted.map((m) {
            final pct = snap.totalDamage > 0 ? m.damage / snap.totalDamage : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  // Weapon icon
                  if (m.weapon.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: ItemImageWidget(uniqueName: m.weapon, size: 20),
                    )
                  else
                    const SizedBox(width: 25),
                  SizedBox(
                    width: 72,
                    child: Text(m.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 14,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary
                                .withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 52,
                    child: Text(Formatters.compact(m.damage.toInt()),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PartyProvider>();
    final data = provider.data;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // ── Firebase Party Sharing section ───────────────────────────────
        _buildShareSection(theme, isDark),

        // ── AdMob banner (solo Android/iOS, 320×50, sin interrumpir flujo) ─
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: BannerAdWidget(),
        ),

        // ── SAT Party (divider only if share section is active) ──────────
        if (context.watch<FirebasePartyProvider>().isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              Expanded(child: Divider(color: Colors.grey[700])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Party SAT',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey[500])),
              ),
              Expanded(child: Divider(color: Colors.grey[700])),
            ]),
          ),

        if (data == null || provider.players.isEmpty)
          const Expanded(
            child: EmptyState(
              icon: Icons.group_outlined,
              message: 'Sin datos de party',
              submessage:
                  'Los datos aparecerán cuando estés en un grupo',
            ),
          )
        else ...[
          // Party header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline
                      .withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.group, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Party',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${data.players.length} miembros',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Members list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: provider.players.length,
              itemBuilder: (context, index) =>
                  _buildMemberCard(provider.players[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberCard(PartyPlayerData player) {
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
              // Main weapon
              if (player.equipment.mainHand != null)
                ItemImageWidget(
                  uniqueName: player.equipment.mainHand!.uniqueName,
                  size: 44,
                )
              else
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    player.username.isNotEmpty ? player.username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 10),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        if (player.averageItemPower > 0)
                          Text(
                            Formatters.ipLabel(player.averageItemPower),
                            style: TextStyle(
                              fontSize: 11,
                              color: _ipColor(player.averageItemPower),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // IP condition indicator
              if (player.itemPowerCondition.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ipColor(player.averageItemPower).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    player.itemPowerCondition,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _ipColor(player.averageItemPower),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _ipColor(double ip) {
    if (ip >= 1400) return Colors.red;
    if (ip >= 1200) return Colors.orange;
    if (ip >= 1000) return Colors.yellow;
    if (ip >= 800) return Colors.green;
    return Colors.grey;
  }

  void _showPlayerDetail(PartyPlayerData player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final eq = player.equipment;
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
                player.username,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Equipment
              if (eq.allSlots.any((s) => s != null)) ...[
                const SectionHeader(title: 'Equipamiento', icon: Icons.shield),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _equipSlot(eq.mainHand, 'Main'),
                      _equipSlot(eq.offHand, 'Off'),
                      _equipSlot(eq.head, 'Head'),
                      _equipSlot(eq.chest, 'Armor'),
                      _equipSlot(eq.shoes, 'Shoes'),
                      _equipSlot(eq.cape, 'Cape'),
                      _equipSlot(eq.mount, 'Mount'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Item Power',
                      value: player.averageItemPower.toStringAsFixed(0),
                      icon: Icons.bolt,
                      valueColor: _ipColor(player.averageItemPower),
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

  Widget _equipSlot(ItemData? item, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ItemImageWidget(uniqueName: item?.uniqueName ?? '', size: 44),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
