import 'package:desengastando/features/budgets/presentation/budget_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const _nbsp = '\u00A0';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _goTo(WidgetTester tester, String tab) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(tab),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('define orçamento, alerta ao lançar e remove', (tester) async {
    final db = await pumpApp(tester);

    // Definir
    await _goTo(tester, 'Orçamentos');
    await tester.tap(find.text('Definir orçamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budgetAmountField')), '50000');
    await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Mercado'));
    await _tapVisible(tester, find.text('Definir limite'));
    expect(find.byType(BudgetTile), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    // Lançar 420,00 em Mercado: passa de 80% e avisa
    await _goTo(tester, 'Lançamentos');
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '42000');
    await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Mercado'));
    await _tapVisible(tester, find.text('Adicionar'));
    expect(
      find.text('Atenção: você já usou 84% do orçamento de Mercado'),
      findsOneWidget,
    );

    await _goTo(tester, 'Orçamentos');
    expect(find.text('84%'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    expect(
      find.text('Restam R\$${_nbsp}80,00'),
      findsOneWidget,
    );

    // Resumo mostra o alerta
    await _goTo(tester, 'Resumo');
    expect(find.text('Orçamentos em alerta'), findsOneWidget);

    // Remover
    await _goTo(tester, 'Orçamentos');
    await tester.tap(find.byType(BudgetTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(find.text('Sem orçamentos definidos'), findsOneWidget);

    await disposeApp(tester, db);
  });
}
