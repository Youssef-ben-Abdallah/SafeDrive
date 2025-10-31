import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/detection_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/about_screen.dart';
import 'screens/detection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SafeDriveApp());
}

class SafeDriveApp extends StatelessWidget {
  const SafeDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DetectionProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;

          return MaterialApp(
            title: 'SafeDrive',
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blueGrey,
                brightness: Brightness.dark,
              ),
            ),
            initialRoute: SplashScreen.routeName,
            routes: {
              SplashScreen.routeName: (_) => const SplashScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
              DetectionScreen.routeName: (_) => const DetectionScreen(),
              ReportScreen.routeName: (_) => const ReportScreen(),
              SettingsScreen.routeName: (_) => const SettingsScreen(),
              AboutScreen.routeName: (_) => const AboutScreen(),
            },
          );
        },
      ),
    );
  }
}
