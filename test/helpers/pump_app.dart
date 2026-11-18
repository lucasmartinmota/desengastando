import 'package:desengastando/app/app.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/database_provider.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sobe o app inteiro com um banco em memória e devolve o banco.
///
/// [seed] permite inserir dados antes da primeira renderização.
///
/// `closeStreamsSynchronously` evita timers pendentes do Drift ao final
/// de testes de widget.
Future<AppDatabase> pumpApp(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db)? seed,
}) async {
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  // Popular antes de montar o app: sem listeners ainda, o banco pode rodar
  // em tempo real (dentro do FakeAsync as escritas ficariam esperando).
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const DesengastandoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Desmonta o app e fecha o banco; chame no fim de cada teste de widget.
Future<void> disposeApp(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await db.close();
}
