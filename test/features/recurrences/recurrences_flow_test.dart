import 'package:desengastando/features/transactions/presentation/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openTransactions(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Lançamentos'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lançamento com "Repetir todo mês" vira fixo', (tester) async {
    final db = await pumpApp(tester);
    await _openTransactions(tester);

    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '350000');
    await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Salário'));
    await _tapVisible(tester, find.byKey(const Key('repeatMonthlySwitch')));
    expect(
      find.text('Lançado sozinho todo dia ${DateTime.now().day}'),
      findsOneWidget,
    );
    await _tapVisible(tester, find.text('Adicionar'));

    expect(find.widgetWithText(TransactionTile, 'Salário'), findsOneWidget);
    expect(find.byIcon(Icons.event_repeat_rounded), findsWidgets);

    await tester.tap(find.byTooltip('Lançamentos fixos'));
    await tester.pumpAndSettle();
    expect(find.text('Receitas fixas'), findsOneWidget);
    expect(
      find.textContaining('Todo dia ${DateTime.now().day}'),
      findsOneWidget,
    );

    await disposeApp(tester, db);
  });

  testWidgets('cria conta fixa pela tela de fixos e pausa', (tester) async {
    final db = await pumpApp(tester);
    await _openTransactions(tester);
    await tester.tap(find.byTooltip('Lançamentos fixos'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum lançamento fixo'), findsOneWidget);

    await tester.tap(find.text('Novo fixo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recurrenceAmountField')),
      '180000',
    );
    await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Moradia'));
    // O dia padrão é hoje: o deste mês já venceu e sai junto.
    expect(find.textContaining('Lançar também o de'), findsOneWidget);
    await _tapVisible(tester, find.text('Criar'));
    expect(find.text('Contas fixas'), findsOneWidget);

    // O lançamento deste mês já está na lista.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TransactionTile, 'Moradia'), findsOneWidget);

    // Pausar
    await tester.tap(find.byTooltip('Lançamentos fixos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moradia'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Ativo'));
    expect(find.text('Pausado'), findsOneWidget);

    await disposeApp(tester, db);
  });
}
