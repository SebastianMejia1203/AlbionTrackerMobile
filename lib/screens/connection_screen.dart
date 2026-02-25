import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/connection_provider.dart';
import '../services/ad_service.dart';
import '../widgets/ad_widgets.dart';

// ─── Model ──────────────────────────────────────────────────────────────────

class _DiscoveredServer {
  final String name;
  final String host;
  final int port;
  _DiscoveredServer({required this.name, required this.host, required this.port});
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  // Mode
  bool _isManual = false;

  // Manual fields
  final _ipController = TextEditingController(text: '192.168.0.1');
  final _portController = TextEditingController(text: '7777');

  // Discovery state
  bool _isScanning = false;
  final List<_DiscoveredServer> _discovered = [];

  // Shared state
  bool _isConnecting = false;
  String? _errorMessage;

  // Pulse animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    AdService.instance.preloadInterstitial();
    _loadSavedConnection();
  }

  Future<void> _loadSavedConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('server_host');
    final port = prefs.getInt('server_port');
    if (host != null && host.isNotEmpty) _ipController.text = host;
    if (port != null) _portController.text = port.toString();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  // ─── Discovery ────────────────────────────────────────────────────────────

  Future<void> _startDiscovery() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _discovered.clear();
      _errorMessage = null;
    });

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.readEventsEnabled = true;

      final payload = utf8.encode('ALBION_SAT_DISCOVER');
      socket.send(payload, InternetAddress('255.255.255.255'), 7778);

      final completer = Completer<void>();

      final timer = Timer(const Duration(seconds: 3), () {
        try {
          socket.close();
        } catch (_) {}
        if (!completer.isCompleted) completer.complete();
      });

      socket.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final dg = socket.receive();
            if (dg != null) {
              try {
                final map =
                    jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
                final server = _DiscoveredServer(
                  name: map['name'] as String? ?? 'SAT Mobile Server',
                  host: map['host'] as String? ?? dg.address.address,
                  port: map['port'] as int? ?? 7777,
                );
                if (!_discovered.any(
                    (s) => s.host == server.host && s.port == server.port)) {
                  if (mounted) setState(() => _discovered.add(server));
                }
              } catch (_) {}
            }
          } else if (event == RawSocketEvent.closed) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );

      await completer.future;
      timer.cancel();
      try {
        socket.close();
      } catch (_) {}
    } catch (_) {
      // UDP not available — suggestion to use manual
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        if (_discovered.isEmpty) {
          _errorMessage =
              'No se encontró ningún servidor.\nPrueba el modo Manual o asegúrate de que el servidor móvil esté activo en el PC.';
        }
      });
    }
  }

  // ─── Connect ──────────────────────────────────────────────────────────────

  Future<void> _connectTo(String ip, int port) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<ConnectionProvider>();
      await provider.connect(ip, port);

      if (mounted && provider.isConnected) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('server_host', ip);
        await prefs.setInt('server_port', port);
        await AdService.instance.showInterstitial();
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = provider.error.isNotEmpty
              ? provider.error
              : 'No se pudo conectar';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _connectManual() async {
    final ip = _ipController.text.trim();
    final portStr = _portController.text.trim();
    if (ip.isEmpty || portStr.isEmpty) {
      setState(() => _errorMessage = 'Introduce IP y puerto');
      return;
    }
    final port = int.tryParse(portStr);
    if (port == null) {
      setState(() => _errorMessage = 'Puerto inválido');
      return;
    }
    await _connectTo(ip, port);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(theme),
                const SizedBox(height: 32),
                _buildModeToggle(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isManual
                      ? _buildManualPanel(theme)
                      : _buildDiscoverPanel(theme),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) _buildError(),
                const SizedBox(height: 28),

                // ── Divider: Join Party ────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[700])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('O',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                  ),
                  Expanded(child: Divider(color: Colors.grey[700])),
                ]),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed('/party-join'),
                    icon: const Icon(Icons.share_location, size: 20),
                    label: const Text('Unirse a Party',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sin SAT. Introduce el código que te dio el host.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
                const BannerAdWidget(adSize: AdSize.mediumRectangle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2),
          ),
          child: Icon(Icons.analytics_outlined,
              size: 44, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        const Text('Albion Tracker',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Mobile Companion',
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildModeToggle() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          label: Text('Detectar automático'),
          icon: Icon(Icons.wifi_find, size: 18),
        ),
        ButtonSegment(
          value: true,
          label: Text('Manual'),
          icon: Icon(Icons.edit, size: 18),
        ),
      ],
      selected: {_isManual},
      onSelectionChanged: (s) => setState(() {
        _isManual = s.first;
        _errorMessage = null;
      }),
    );
  }

  // ── Discovery panel ───────────────────────────────────────────────────────

  Widget _buildDiscoverPanel(ThemeData theme) {
    return Column(
      key: const ValueKey('discover'),
      children: [
        Text(
          'La app buscará el servidor SAT en tu red WiFi automáticamente.',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        if (!_isScanning && _discovered.isEmpty && _errorMessage == null)
          _buildScanButton(theme),

        if (_isScanning) _buildScanningIndicator(theme),

        if (_discovered.isNotEmpty) ...[
          _buildDiscoveredList(theme),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _isConnecting ? null : _startDiscovery,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Buscar de nuevo'),
          ),
        ],

        if (!_isScanning && _discovered.isEmpty && _errorMessage != null)
          TextButton.icon(
            onPressed: _startDiscovery,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Intentar de nuevo'),
          ),
      ],
    );
  }

  Widget _buildScanButton(ThemeData theme) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Icon(Icons.wifi_find,
                size: 72, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _startDiscovery,
            icon: const Icon(Icons.search),
            label: const Text('Buscar servidores',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator(ThemeData theme) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Icon(Icons.wifi_find,
                size: 72, color: theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Buscando servidores SAT...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
        const SizedBox(height: 4),
        Text('Escaneando la red (3 s)',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildDiscoveredList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_discovered.length} servidor${_discovered.length == 1 ? '' : 'es'} '
          'encontrado${_discovered.length == 1 ? '' : 's'}',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 10),
        ...List.generate(_discovered.length, (i) {
          final s = _discovered[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.computer,
                    color: theme.colorScheme.primary, size: 22),
              ),
              title: Text(s.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('${s.host}:${s.port}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              trailing: _isConnecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.arrow_forward_ios,
                      size: 16, color: theme.colorScheme.primary),
              onTap:
                  _isConnecting ? null : () => _connectTo(s.host, s.port),
            ),
          );
        }),
      ],
    );
  }

  // ── Manual panel ──────────────────────────────────────────────────────────

  Widget _buildManualPanel(ThemeData theme) {
    return Column(
      key: const ValueKey('manual'),
      children: [
        Text(
          'Introduce la IP que aparece en el adaptador de red de tu router (ej: 192.168.0.x).',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ipController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Dirección IP del PC',
            hintText: '192.168.0.x',
            prefixIcon: const Icon(Icons.computer),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          enabled: !_isConnecting,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _portController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Puerto',
            hintText: '7777',
            prefixIcon: const Icon(Icons.settings_ethernet),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          enabled: !_isConnecting,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isConnecting ? null : _connectManual,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isConnecting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Conectar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
