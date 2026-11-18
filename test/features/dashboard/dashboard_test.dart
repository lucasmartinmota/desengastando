import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/dashboard/presentation/category_ranking.dart';
import 'package:desengastando/features/dashboard/presentation/monthly_expenses_chart.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Este mês: Moradia 75,00 + Mercado 25,00. Mês anterior: Mercado 80,00.
Future<void> _seed(AppDatabase db) async {
  final cats = {
    for (final c
        in await db.categoriesDao
            .watchCategories(type: TransactionType.expense)
            .first)
      c.name: c.id,
  };
  final now = YearMonth.now();
  Future<void> add(String category, int cents, DateTime date) =>
      db.transactionsDao.addTransaction(
        TransactionsCompanion.insert(
          amountCents: cents,
          date: date,
          categoryId: cats[category]!,
        ),
      );

  await add('Moradia', 7500, now.start);
  await add('Mercado', 2500, now.start);
  await add('Mercado', 8000, now.previous.start);
}

void main() {
  testWidgets('mostra ranking, comparação e gráfico do mês', (tester) async {
    final db = await pumpApp(tester, seed: _seed);

    expect(find.byType(CategoryRanking), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    // 100,00 este mês vs 80,00 no anterior = +25%
    expect(find.textContaining('25% a mais de gastos que em'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(MonthlyExpensesChart), 200);
    expect(find.text('Despesas nos últimos 6 meses'), findsOneWidget);

    await disposeApp(tester, db);
  });

  testWidgets('mês vazio mostra o estado vazio', (tester) async {
    final db = await pumpApp(tester);
    expect(find.text('Nada por aqui ainda'), findsOneWidget);
    expect(find.byType(CategoryRanking), findsNothing);
    expect(find.byType(MonthlyExpensesChart), findsNothing);
    await disposeApp(tester, db);
  });
}
