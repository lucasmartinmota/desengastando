import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/backup/data/backup_providers.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:desengastando/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Guarda o que seria compartilhado e devolve um conteúdo fixo ao "abrir".
class _FakeFiles extends BackupFiles {
  final shared = <String, String>{};
  String? toPick;

  @override
  Future<void> share({
    required String fileName,
    required String content,
    required String mimeType,
    Rect? origin,
  }) async => shared[fileName] = content;

  @override
  Future<String?> pickText() async => toPick;
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

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Ajustes'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exporta backup e CSV e restaura o backup', (tester) async {
    final files = _FakeFiles();
    final db = await pumpApp(
      tester,
      seed: _seed,
      overrides: [backupFilesProvider.overrideWithValue(files)],
    );
    await _openSettings(tester);

    await tester.tap(find.text('Exportar backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exportar planilha'));
    await tester.pumpAndSettle();
    final backupName = files.shared.keys.firstWhere((k) => k.endsWith('.json'));
    expect(backupName, startsWith('desengastando-backup-'));
    expect(
      files.shared.values.firstWhere((v) => v.contains('Data;Tipo')),
      contains('Feira da semana'),
    );

    // Apaga o lançamento pela tela e restaura o backup.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TransactionTile), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    files.toPick = files.shared[backupName];
    await tester.tap(find.text('Resumo'));
    await tester.pumpAndSettle();
    await _openSettings(tester);
    await tester.tap(find.text('Restaurar backup'));
    await tester.pumpAndSettle();
    expect(find.textContaining('com 1 lançamento'), findsOneWidget);
    await tester.tap(find.text('Substituir dados'));
    await tester.pumpAndSettle();
    expect(find.text('Backup restaurado'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Feira da semana'), findsOneWidget);

    await disposeApp(tester, db);
  });

  testWidgets('arquivo inválido mostra o motivo', (tester) async {
    final files = _FakeFiles()..toPick = '{"app": "outro"}';
    final db = await pumpApp(
      tester,
      overrides: [backupFilesProvider.overrideWithValue(files)],
    );
    await _openSettings(tester);
    await tester.tap(find.text('Restaurar backup'));
    await tester.pumpAndSettle();
    expect(
      find.text('Esse arquivo não é um backup do Desengastando.'),
      findsOneWidget,
    );
    await disposeApp(tester, db);
  });
}
