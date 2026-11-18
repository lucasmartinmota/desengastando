import 'package:desengastando/app/router.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:desengastando/features/recurrences/presentation/recurrence_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesengastandoApp extends ConsumerWidget {
  const DesengastandoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Desengastando',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => RecurrenceSync(child: child!),
    );
  }
}
