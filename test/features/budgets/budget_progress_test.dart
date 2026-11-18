import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/budgets/domain/budget_progress.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

const _mercado = TransactionCategory(
  id: 1,
  name: 'Mercado',
  iconKey: 'shopping_cart',
  color: 0xFF000000,
  type: TransactionType.expense,
  archived: false,
  sortOrder: 0,
);

BudgetProgress _progress(int spent, {int limit = 10000}) =>
    BudgetProgress(category: _mercado, limitCents: limit, spentCents: spent);

void main() {
  group('status', () {
    test('abaixo de 80% está ok', () {
      expect(_progress(7999).status, BudgetStatus.ok);
    });
    test('de 80% até o limite é alerta', () {
      expect(_progress(8000).status, BudgetStatus.warning);
      expect(_progress(10000).status, BudgetStatus.warning);
    });
    test('acima do limite estourou', () {
      expect(_progress(10001).status, BudgetStatus.over);
      expect(_progress(12500).remainingCents, -2500);
    });
  });

  test('totais somam limites e gastos', () {
    final totals = BudgetTotals.of([
      _progress(3000),
      _progress(500, limit: 2000),
    ]);
    expect(totals.limitCents, 12000);
    expect(totals.remainingCents, 8500);
  });

  group('budgetAlert', () {
    test('avisa ao entrar no alerta', () {
      expect(
        budgetAlert(before: _progress(7000), after: _progress(8500)),
        'Atenção: você já usou 85% do orçamento de Mercado',
      );
    });
    test('avisa ao estourar', () {
      expect(
        budgetAlert(before: _progress(9000), after: _progress(10100)),
        'Orçamento de Mercado estourado neste mês',
      );
    });
    test('não repete o aviso na mesma faixa', () {
      expect(
        budgetAlert(before: _progress(8500), after: _progress(9000)),
        isNull,
      );
      expect(
        budgetAlert(before: _progress(11000), after: _progress(12000)),
        isNull,
      );
    });
    test('sem orçamento, sem aviso', () {
      expect(budgetAlert(before: null, after: null), isNull);
    });
  });
}
