import 'package:desengastando/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const _nbsp = ' ';

Finder _tileAmount(String text) => find.descendant(
  of: find.byType(TransactionTile),
  matching: find.text(text),
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _addExpense(
  WidgetTester tester, {
  required String digits,
  required String category,
}) async {
  await tester.tap(find.byTooltip('Novo lançamento'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('amountField')), digits);
  await _tapVisible(tester, find.widgetWithText(ChoiceChip, category));
  await _tapVisible(tester, find.text('Adicionar'));
}

void main() {
  testWidgets('cria, edita, exclui e desfaz um lançamento', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();

    // Criar
    await _addExpense(tester, digits: '1250', category: 'Mercado');
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.widgetWithText(TransactionTile, 'Mercado'), findsOneWidget);
    expect(_tileAmount('−R\$${_nbsp}12,50'), findsOneWidget);

    // Editar
    await tester.tap(find.byType(TransactionTile));
    await tester.pumpAndSettle();
    expect(find.text('Editar lançamento'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('amountField')), '2000');
    await _tapVisible(tester, find.text('Salvar alterações'));
    expect(_tileAmount('−R\$${_nbsp}20,00'), findsOneWidget);

    // Excluir pelo formulário e desfazer
    await tester.tap(find.byType(TransactionTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionTile), findsNothing);
    expect(find.text('Lançamento excluído'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(_tileAmount('−R\$${_nbsp}20,00'), findsOneWidget);

    await disposeApp(tester, db);
  });

  testWidgets('swipe exclui o lançamento', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();

    await _addExpense(tester, digits: '990', category: 'Lazer');
    expect(find.byType(TransactionTile), findsOneWidget);

    await tester.drag(find.byType(TransactionTile), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionTile), findsNothing);
    expect(find.text('Nenhum lançamento neste mês'), findsOneWidget);
    expect(find.text('Lançamento excluído'), findsOneWidget);

    await disposeApp(tester, db);
  });

  testWidgets('resumo reflete as despesas do mês', (tester) async {
    final db = await pumpApp(tester);

    await _addExpense(tester, digits: '5000', category: 'Mercado');

    // Saldo negativo e total de despesas.
    expect(find.text('-R\$${_nbsp}50,00'), findsOneWidget);
    expect(find.text('R\$${_nbsp}50,00'), findsOneWidget);
    expect(find.text('Nada por aqui ainda'), findsNothing);

    await disposeApp(tester, db);
  });
}
