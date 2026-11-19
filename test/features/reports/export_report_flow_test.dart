import 'dart:ui';

import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/backup/data/backup_providers.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../helpers/pump_app.dart';

/// Guarda os arquivos que seriam compartilhados.
class _FakeFiles extends BackupFiles {
  final shared = <String, List<int>>{};

  @override
  Future<void> shareBytes({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    Rect? origin,
  }) async {
    expect(mimeType, 'application/pdf');
    shared[fileName] = bytes;
  }
}

Future<void> _seed(AppDatabase db) async {
  final mercado =
      (await db.categoriesDao
              .watchCategories(type: TransactionType.expense)
              .first)
          .firstWhere((c) => c.name == 'Mercado');
  await db.transactionsDao.addTransaction(
    TransactionsCompanion.insert(
      amountCents: 4590,
      date: DateTime.now(),
      categoryId: mercado.id,
      description: const Value('Feira da semana'),
    ),
  );
}

/// Toca em "Gerar PDF" e espera a geração, que lê fontes e banco de
/// verdade (fora do relógio falso dos testes).
Future<void> _generate(WidgetTester tester) async {
  await tester.tap(find.text('Gerar PDF'));
  await tester.pump();
  await tester.runAsync(() async {
    for (var i = 0; i < 100 && find.text('Gerando...').evaluate().isNotEmpty;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exporta o mês em foco pelo Resumo', (tester) async {
    final files = _FakeFiles();
    final db = await pumpApp(
      tester,
      seed: _seed,
      overrides: [backupFilesProvider.overrideWithValue(files)],
    );

    await tester.tap(find.byTooltip('Exportar PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Exportar PDF'), findsWidgets);

    await _generate(tester);

    final month = YearMonth.now().toString();
    final bytes = files.shared['desengastando-relatorio-$month.pdf'];
    expect(bytes, isNotNull);
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
    expect(find.text('Gerar PDF'), findsNothing, reason: 'a folha fecha');

    await disposeApp(tester, db);
  });

  testWidgets('avisa quando o período não tem lançamentos', (tester) async {
    final files = _FakeFiles();
    final db = await pumpApp(
      tester,
      seed: _seed,
      overrides: [backupFilesProvider.overrideWithValue(files)],
    );

    await tester.tap(find.byTooltip('Exportar PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mês anterior').last);
    await tester.pumpAndSettle();

    await _generate(tester);

    expect(find.text('Nenhum lançamento nesse período.'), findsOneWidget);
    expect(files.shared, isEmpty);
    expect(find.text('Gerar PDF'), findsOneWidget, reason: 'continua aberta');

    await disposeApp(tester, db);
  });

  testWidgets('pelos Ajustes, com período livre', (tester) async {
    final files = _FakeFiles();
    final db = await pumpApp(
      tester,
      seed: _seed,
      overrides: [backupFilesProvider.overrideWithValue(files)],
    );

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Exportar relatório em PDF'),
      100,
    );
    await tester.tap(find.text('Exportar relatório em PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Período'));
    await tester.pumpAndSettle();

    final now = YearMonth.now();
    final format = DateFormat('dd/MM/yyyy');
    final dates =
        '${format.format(now.start)} a '
        '${format.format(DateTime(now.year, now.month, now.daysInMonth))}';
    expect(find.text(dates), findsOneWidget);

    await _generate(tester);
    expect(files.shared.keys.single, 'desengastando-relatorio-$now.pdf');

    await disposeApp(tester, db);
  });
}
