// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/prayer_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await initDependencies();

  runApp(
    const ProviderScope(
      child: PrayerJournalApp(),
    ),
  );
}

class PrayerJournalApp extends StatelessWidget {
  const PrayerJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '기도 일지',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const PrayerListScreen(),
    );
  }
}
