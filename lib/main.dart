import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/ad_service.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Fix 3: Initialize AdMob
  await AdService().initialize();

  runApp(const SmartDataOrganizerApp());
}

class SmartDataOrganizerApp extends StatelessWidget {
  const SmartDataOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..init()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      // Consumer wraps MaterialApp so themeMode changes rebuild immediately
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Smart Data Organizer',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
