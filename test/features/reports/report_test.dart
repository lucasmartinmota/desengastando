import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/reports/data/report_pdf.dart';
import 'package:desengastando/features/reports/data/report_service.dart';
import 'package:desengastando/features/reports/domain/report_period.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportPeriod', () {
    test('mês fechado: fim exclusivo, rótulo e nome de arquivo', () {
      final p = ReportPeriod.month(const YearMonth(2026, 2));
      expect(p.start, DateTime(2026, 2));
      expect(p.end, DateTime(2026, 3));
      expect(p.lastDay, DateTime(2026, 2, 28));
      expect(p.label, 'Fevereiro de 2026');
      expect(p.dates, '01/02/2026 a 28/02/2026');
      expect(p.fileSuffix, '2026-02');
    });

    test('intervalo inclui o último dia e ignora a hora', () {
      final p = ReportPeriod.range(
        DateTime(2026, 11, 10, 15),
        DateTime(2026, 12, 5, 9),
      );
      expect(p.start, DateTime(2026, 11, 10));
      expect(p.end, DateTime(2026, 12, 6));
      expect(p.month, isNull);
      expect(p.label, '10/11/2026 a 05/12/2026');
      expect(p.fileSuffix, '2026-11-10_a_2026-12-05');
    });

    test('intervalo invertido é corrigido e um mês inteiro vira o mês', () {
      final p = ReportPeriod.range(DateTime(2026, 11, 30), DateTime(2026, 11));
      expect(p.month, const YearMonth(2026, 11));
      expect(p, ReportPeriod.month(const YearMonth(2026, 11)));
    });
  });

  group('ReportService', () {
    late AppDatabase db;
    late ReportService service;
    late TransactionCategory mercado;
    late TransactionCategory transporte;
    late TransactionCategory salario;

    Future<void> add(
      TransactionCategory c,
      int cents,
      DateTime date, {
      String? description,
    }) => db.transactionsDao.addTransaction(
      TransactionsCompanion.insert(
        amountCents: cents,
        date: date,
        categoryId: c.id,
        description: Value(description),
        paymentMethod: const Value(PaymentMethod.pix),
      ),
    );

    setUp(() async {
      db = createTestDatabase();
      service = ReportService(db.transactionsDao);
      final expenses = await db.categoriesDao
          .watchCategories(type: TransactionType.expense)
          .first;
      mercado = expenses.firstWhere((c) => c.name == 'Mercado');
      transporte = expenses.firstWhere((c) => c.name == 'Transporte');
      salario =
          (await db.categoriesDao
                  .watchCategories(type: TransactionType.income)
                  .first)
              .firstWhere((c) => c.name == 'Salário');
    });

    tearDown(() => db.close());

    test('pega só o período, em ordem cronológica, e soma por tipo', () async {
      await add(mercado, 10000, DateTime(2026, 10, 31, 23)); // fora
      await add(salario, 500000, DateTime(2026, 11, 5));
      await add(mercado, 30000, DateTime(2026, 11, 20));
      await add(transporte, 10000, DateTime(2026, 11, 3));
      await add(mercado, 20000, DateTime(2026, 11, 30, 22));
      await add(mercado, 99900, DateTime(2026, 12)); // fora

      final data = await service.load(
        ReportPeriod.month(const YearMonth(2026, 11)),
        now: DateTime(2026, 11, 18),
      );

      expect(
        [for (final t in data.transactions) t.transaction.date.day],
        [3, 5, 20, 30],
      );
      expect(data.incomeCents, 500000);
      expect(data.expenseCents, 60000);
      expect(data.balanceCents, 440000);
      expect(data.scheduledCount, 2, reason: 'dias 20 e 30 vêm depois do 18');

      final byCategory = data.expensesByCategory;
      expect(
        [for (final s in byCategory) s.category.name],
        ['Mercado', 'Transporte'],
      );
      expect(byCategory.first.totalCents, 50000);
      expect(byCategory.first.count, 2);
      expect(byCategory.first.ratio, closeTo(50000 / 60000, 1e-9));
      expect(data.incomeByCategory.single.ratio, 1);
    });

    test('período vazio', () async {
      final data = await service.load(
        ReportPeriod.month(const YearMonth(2020, 1)),
      );
      expect(data.isEmpty, isTrue);
      expect(data.expensesByCategory, isEmpty);
      expect(data.balanceCents, 0);
    });

    test('gera um PDF válido, com várias páginas quando há muitos '
        'lançamentos', () async {
      for (var i = 0; i < 150; i++) {
        await add(
          i.isEven ? mercado : transporte,
          1234 + i,
          DateTime(2026, 11, 1 + i % 30),
          description: 'Compra número $i com acentuação',
        );
      }
      await add(salario, 500000, DateTime(2026, 11, 5));
      final data = await service.load(
        ReportPeriod.month(const YearMonth(2026, 11)),
      );

      final doc = ReportPdf.document(data, await ReportFonts.load());
      final bytes = await doc.save();

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(doc.document.pdfPageList.pages.length, greaterThan(3));
    });

    test('a fonte tem todos os caracteres usados no relatório', () async {
      final fonts = await ReportFonts.load();
      final context = pw.Context(document: pw.Document().document);
      const text =
          'R\u00A0'
          r'$ −+1.234,56 · ÁÂÃÀÉÊÍÓÔÕÚÇáâãàéêíóôõúç %"';
      for (final font in [fonts.regular, fonts.bold, fonts.extraBold]) {
        final pdfFont = font.getFont(context);
        for (final rune in text.runes) {
          expect(
            pdfFont.isRuneSupported(rune),
            isTrue,
            reason:
                'falta "${String.fromCharCode(rune)}" '
                '(U+${rune.toRadixString(16).toUpperCase()})',
          );
        }
      }
    });
  });
}
