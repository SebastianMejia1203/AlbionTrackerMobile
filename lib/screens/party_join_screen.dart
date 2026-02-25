import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../models/firebase_party_models.dart';
import '../providers/firebase_party_provider.dart';
import '../utils/formatters.dart';
import '../widgets/ad_widgets.dart';
import '../widgets/item_image_widget.dart';

class PartyJoinScreen extends StatefulWidget {
  const PartyJoinScreen({super.key});

  @override
  State<PartyJoinScreen> createState() => _PartyJoinScreenState();
}

class _PartyJoinScreenState extends State<PartyJoinScreen> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'El código debe tener 6 caracteres');
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    final fb = context.read<FirebasePartyProvider>();
    final ok = await fb.joinParty(code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed('/party-guest');
    } else {
      setState(() {
        _joining = false;
        _error = fb.error ?? 'No se pudo unirse a la party';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed('/connect'),
        ),
        title: const Text('Unirse a Party'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: Icon(Icons.share_location,
                      size: 38, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 20),
                const Text('Unirse a Party',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Introduce el código que te dio el host del grupo',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Code input
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 28,
                        letterSpacing: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    counterText: '',
                  ),
                  enabled: !_joining,
                  onChanged: (v) {
                    _codeController.value = _codeController.value.copyWith(
                      text: v.toUpperCase(),
                      selection: TextSelection.collapsed(
                          offset: v.toUpperCase().length),
                    );
                  },
                  onSubmitted: (_) => _join(),
                ),
                const SizedBox(height: 20),

                // Error
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Join button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _joining ? null : _join,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _joining
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Unirse',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 32),
                const BannerAdWidget(adSize: AdSize.banner),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Guest live view ─────────────────────────────────────────────────────────

class PartyGuestScreen extends StatefulWidget {
  const PartyGuestScreen({super.key});

  @override
  State<PartyGuestScreen> createState() => _PartyGuestScreenState();
}

class _PartyGuestScreenState extends State<PartyGuestScreen> {
  @override
  Widget build(BuildContext context) {
    final fb = context.watch<FirebasePartyProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // If host closed party (was active before, now it's not), go back
    if (!fb.isActive && !fb.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('El host cerró la party'),
                duration: Duration(seconds: 3)),
          );
          Navigator.of(context).pushReplacementNamed('/connect');
        }
      });
    }

    final snap = fb.snapshot;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('Party: ${fb.code ?? ''}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, size: 18, color: Colors.red),
            label: const Text('Salir',
                style: TextStyle(color: Colors.red, fontSize: 13)),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Salir de la Party'),
                  content: const Text('¿Salir de la party compartida?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    TextButton(
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Salir')),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                context.read<FirebasePartyProvider>().leaveParty();
                Navigator.of(context).pushReplacementNamed('/connect');
              }
            },
          ),
        ],
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(snap, theme, isDark),
    );
  }

  Widget _buildContent(
      FbPartySnapshot snap, ThemeData theme, bool isDark) {
    final sorted = snap.sortedByDamage;
    // Fama y plata vienen del host (son datos de sesión general compartidos)
    final hostMember = snap.members.where((m) => m.name == snap.meta.hostName).firstOrNull;
    final hostFame = hostMember?.fame ?? 0.0;
    final hostSilver = hostMember?.silver ?? 0.0;

    return Column(
      children: [
        // Summary bar — fama/plata del host como stats generales
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: theme.colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumStat('Host', snap.meta.hostName, Colors.blue[300]!),
              _sumStat('Miembros', '${snap.memberCount}',
                  theme.colorScheme.primary),
              _sumStat('⚔ Daño',
                  Formatters.compact(snap.totalDamage.toInt()), Colors.red[400]!),
              _iconStat('assets/icons/fame.png', Formatters.fame(hostFame),
                  'Fama', Colors.amber[300]!),
              _iconStat('assets/icons/silver.png', Formatters.silver(hostSilver),
                  'Plata', Colors.grey[400]!),
            ],
          ),
        ),

        // Members
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) =>
                _buildMemberCard(sorted[i], i, snap, theme, isDark),
          ),
        ),

        const BannerAdWidget(adSize: AdSize.banner),
      ],
    );
  }

  Widget _sumStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  Widget _iconStat(String asset, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(asset, width: 12, height: 12),
            const SizedBox(width: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildMemberCard(FbPartyMember m, int rank,
      FbPartySnapshot snap, ThemeData theme, bool isDark) {
    final pct = snap.totalDamage > 0 ? m.damage / snap.totalDamage : 0.0;
    final rankColors = [
      Colors.amber,
      Colors.grey[400]!,
      Colors.brown[300]!
    ];
    final rankColor =
        rank < 3 ? rankColors[rank] : Colors.grey[600]!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + rank + weapon icon
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text('${rank + 1}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: rankColor)),
                  ),
                ),
                const SizedBox(width: 8),
                // Weapon icon
                if (m.weapon.isNotEmpty) ...[  
                  ItemImageWidget(uniqueName: m.weapon, size: 28),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(m.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                if (m.name == snap.meta.hostName) ...[  
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('HOST',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ),
                ],
                const SizedBox(width: 4),
                Text(Formatters.compact(m.damage.toInt()),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),

            // Damage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    isDark ? Colors.grey[800] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 6),

            // Stats row (DPS + \%)
            Row(
              children: [
                _statChip('DPS', m.dps.toStringAsFixed(0),
                    Colors.orange[300]!),
                const Spacer(),
                Text('${(pct * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
