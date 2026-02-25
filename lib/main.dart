import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/connection_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/damage_meter_provider.dart';
import 'providers/dungeon_provider.dart';
import 'providers/trade_provider.dart';
import 'providers/gathering_provider.dart';
import 'providers/party_provider.dart';
import 'providers/firebase_party_provider.dart';
import 'providers/guild_provider.dart';
import 'providers/logging_provider.dart';
import 'providers/map_history_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/connection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/party_join_screen.dart';
import 'theme/app_theme.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[main] Firebase.initializeApp failed: $e');
  }

  try {
    await AdService.instance.init();
  } catch (e) {
    debugPrint('[main] AdService.init failed: $e');
  }

  runApp(const AlbionTrackerApp());
}

class AlbionTrackerApp extends StatelessWidget {
  const AlbionTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => DamageMeterProvider()),
        ChangeNotifierProvider(create: (_) => DungeonProvider()),
        ChangeNotifierProvider(create: (_) => TradeProvider()),
        ChangeNotifierProvider(create: (_) => GatheringProvider()),
        ChangeNotifierProvider(create: (_) => PartyProvider()),
        ChangeNotifierProvider(create: (_) => FirebasePartyProvider()),
        ChangeNotifierProvider(create: (_) => GuildProvider()),
        ChangeNotifierProvider(create: (_) => LoggingProvider()),
        ChangeNotifierProvider(create: (_) => MapHistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Albion Tracker Mobile',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: const Locale('es'),
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/connect': (context) => const ConnectionScreen(),
              '/home': (context) => const HomeScreen(),
              '/party-join': (context) => const PartyJoinScreen(),
              '/party-guest': (context) => const PartyGuestScreen(),
            },
          );
        },
      ),
    );
  }
}
