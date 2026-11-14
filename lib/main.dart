import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/telemetry_service.dart';
import 'core/services/scan_queue_service.dart';
import 'core/services/theme_service.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // B10. Crash/analytics: handler global, dijalankan lebih dulu.
  TelemetryService.install();

  // Initialize Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  // Initialize Local Storage
  await StorageService.init();

  // C12. Tema tersimpan (light/dark/system).
  await ThemeService.init();

  runApp(const PresensiApp());

  // Catat pembukaan aplikasi (analytics ringan, tak memblokir UI).
  TelemetryService.event('app_start');

  // B7. Kirim antrian presensi offline secara berkala (Android/iOS saja).
  ScanQueueService.startAutoSync();
  ScanQueueService.syncPending();
}

class PresensiApp extends StatelessWidget {
  const PresensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (context, themeMode, _) => MaterialApp(
      title: 'Presensi SMKN 1 Beringin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        // C12. Selaraskan token AppColors dengan brightness aktif.
        AppColors.configure(Theme.of(context).brightness);
        return child ?? const SizedBox.shrink();
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
      ),
    );
  }
}
