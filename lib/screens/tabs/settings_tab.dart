import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/connection_provider.dart';
import '../../providers/damage_meter_provider.dart';
import '../../providers/dungeon_provider.dart';
import '../../providers/gathering_provider.dart';
import '../../providers/logging_provider.dart';
import '../../providers/map_history_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trade_provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final conn = context.watch<ConnectionProvider>();
    final status = conn.serverStatus;
    final pi = conn.playerInfo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Connection Info ───
        _buildSection(
          context,
          icon: Icons.wifi,
          title: 'Conexión',
          children: [
            _infoTile(context, 'Estado', conn.isConnected ? 'Conectado' : 'Desconectado',
                valueColor: conn.isConnected ? Colors.green : Colors.red),
            _infoTile(context, 'Servidor', conn.service.serverUrl),
            _infoTile(context, 'Versión', status.serverVersion),
            _infoTile(context, 'Tracking', status.isTrackingActive ? 'Activo' : 'Inactivo',
                valueColor: status.isTrackingActive ? Colors.green : Colors.orange),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout, size: 22, color: Colors.red),
              title: const Text('Desconectar',
                  style: TextStyle(fontSize: 14, color: Colors.red)),
              subtitle: Text('Volver a la pantalla de conexión',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Desconectar'),
                    content: const Text(
                        '¿Seguro que quieres desconectarte del servidor?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Desconectar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('server_host');
                  await prefs.remove('server_port');
                  await conn.disconnect();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/connect', (_) => false);
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Player Info ───
        if (pi.username.isNotEmpty) ...[
          _buildSection(
            context,
            icon: Icons.person,
            title: 'Jugador',
            children: [
              _infoTile(context, 'Nombre', pi.username),
              if (pi.guild.isNotEmpty)
                _infoTile(context, 'Guild', pi.guild),
              if (pi.alliance.isNotEmpty)
                _infoTile(context, 'Alianza', pi.alliance),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ─── Theme ───
        _buildSection(
          context,
          icon: Icons.palette,
          title: 'Apariencia',
          children: [
            SwitchListTile(
              dense: true,
              title: const Text('Modo Oscuro', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                theme.isDark ? 'Tema oscuro activado' : 'Tema claro activado',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              secondary: Icon(
                theme.isDark ? Icons.dark_mode : Icons.light_mode,
                color: theme.isDark ? Colors.amber : Colors.orange,
              ),
              value: theme.isDark,
              onChanged: (_) => theme.toggleTheme(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── WPF Remote Controls ───
        _buildSection(
          context,
          icon: Icons.settings_remote,
          title: 'Control Remoto (PC)',
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.restart_alt, size: 22),
              title: const Text('Reset DPS Meter', style: TextStyle(fontSize: 14)),
              subtitle: Text('Reiniciar el medidor de daño en el PC',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () {
                conn.service.resetDamageMeter();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('DPS Meter reiniciado'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.camera_alt, size: 22),
              title: const Text('Snapshot DPS', style: TextStyle(fontSize: 14)),
              subtitle: Text('Tomar snapshot del medidor de daño',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () {
                conn.service.takeDamageMeterSnapshot();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Snapshot tomado'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.refresh, size: 22),
              title: const Text('Solicitar todos los datos', style: TextStyle(fontSize: 14)),
              subtitle: Text('Forzar actualización completa',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
              onTap: () {
                conn.service.requestAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos solicitados'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Clear local data ───
        _buildSection(
          context,
          icon: Icons.delete_sweep,
          title: 'Borrar Datos Locales',
          children: [
            _buildClearTile(
              context,
              icon: Icons.local_fire_department,
              title: 'Medidor de Daño',
              onTap: () {
                context.read<DamageMeterProvider>().clear();
                conn.service.resetDamageMeter();
                _showClearedSnack(context, 'Medidor de daño');
              },
            ),
            _buildClearTile(
              context,
              icon: Icons.castle,
              title: 'Dungeons',
              onTap: () {
                context.read<DungeonProvider>().clear();
                _showClearedSnack(context, 'Dungeons');
              },
            ),
            _buildClearTile(
              context,
              icon: Icons.store,
              title: 'Comercio',
              onTap: () {
                context.read<TradeProvider>().clear();
                _showClearedSnack(context, 'Comercio');
              },
            ),
            _buildClearTile(
              context,
              icon: Icons.grass,
              title: 'Recolección',
              onTap: () {
                context.read<GatheringProvider>().clear();
                _showClearedSnack(context, 'Recolección');
              },
            ),
            _buildClearTile(
              context,
              icon: Icons.map,
              title: 'Historial de Mapas',
              onTap: () {
                context.read<MapHistoryProvider>().clear();
                _showClearedSnack(context, 'Historial de mapas');
              },
            ),
            _buildClearTile(
              context,
              icon: Icons.list_alt,
              title: 'Notificaciones',
              onTap: () {
                context.read<LoggingProvider>().clear();
                _showClearedSnack(context, 'Notificaciones');
              },
            ),
            _buildClearTile(
              context,
              icon: Icons.delete_forever,
              title: 'Todos los datos',
              iconColor: Colors.red,
              onTap: () {
                context.read<DamageMeterProvider>().clear();
                context.read<DungeonProvider>().clear();
                context.read<TradeProvider>().clear();
                context.read<GatheringProvider>().clear();
                context.read<MapHistoryProvider>().clear();
                context.read<LoggingProvider>().clear();
                conn.service.resetDamageMeter();
                _showClearedSnack(context, 'Todos los datos');
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── About ───
        _buildSection(
          context,
          icon: Icons.info_outline,
          title: 'Información',
          children: [
            _infoTile(context, 'App', 'Albion Tracker Mobile'),
            _infoTile(context, 'Versión', '1.0.0'),
            _infoTile(context, 'Basado en', 'StatisticsAnalysisTool'),
            _infoTile(context, 'Desarrollado por', 'Sebastian Mejia'),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Feedback ───
        _buildSection(
          context,
          icon: Icons.feedback_outlined,
          title: 'Comentarios',
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.bug_report, size: 22, color: Colors.orange),
              title: const Text('Reportar un bug', style: TextStyle(fontSize: 14)),
              subtitle: Text('Enviar reporte al desarrollador',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _sendFeedbackEmail(context, subject: 'Bug Report - Albion Tracker Mobile'),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.lightbulb_outline, size: 22, color: Colors.amber),
              title: const Text('Sugerir mejora', style: TextStyle(fontSize: 14)),
              subtitle: Text('Compartir ideas con el desarrollador',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color)),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _sendFeedbackEmail(context, subject: 'Sugerencia - Albion Tracker Mobile'),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 22, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
      onTap: onTap,
    );
  }

  void _showClearedSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label borrado'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _sendFeedbackEmail(BuildContext context, {required String subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'sebastianmejia1203@gmail.com',
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el cliente de correo')),
      );
    }
  }
}
