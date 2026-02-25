import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/connection_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndConnect());
  }

  Future<void> _checkAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHost = prefs.getString('server_host');
    final savedPort = prefs.getInt('server_port');

    if (savedHost == null || savedHost.isEmpty) {
      // No saved connection → go to connection screen
      if (mounted) Navigator.of(context).pushReplacementNamed('/connect');
      return;
    }

    // Try to auto-connect
    final conn = context.read<ConnectionProvider>();
    final success = await conn.connect(savedHost, savedPort ?? 7777);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/connect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_icon.png',
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shield, size: 80, color: Colors.amber),
            ),
            const SizedBox(height: 24),
            const Text(
              'Albion Tracker Mobile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Conectando...',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
