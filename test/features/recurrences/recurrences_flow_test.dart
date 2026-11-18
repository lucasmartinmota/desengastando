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
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('modeSelector')),
        matching: find.text('Fixo'),
      ),
    );
    expect(
      find.textContaining('Lançado todo dia ${DateTime.now().day}'),
      findsOneWidget,
    );
    await _tapVisible(tester, find.text('Adicionar'));

    expect(find.widgetWithText(TransactionTile, 'Salário'), findsOneWidget);
    expect(find.byIcon(Icons.event_repeat_rounded), findsWidgets);

    // Já aparece nos meses à frente, marcado como previsto.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
    }
    expect(find.widgetWithText(TransactionTile, 'Salário'), findsOneWidget);
    expect(find.textContaining('Previsto'), findsOneWidget);
    await tester.tap(find.byType(TextButton).first); // volta ao mês atual
    await tester.pumpAndSettle();

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

  testWidgets('compra parcelada cria uma parcela por mês', (tester) async {
    // Tamanho de um celular (Galaxy S25: 1080 x 2340, densidade 2,625):
    // pega overflow das linhas novas do formulário.
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final db = await pumpApp(tester);
    await _openTransactions(tester);

    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amountField')), '120000');
    await _tapVisible(tester, find.widgetWithText(ChoiceChip, 'Compras'));
    await _tapVisible(
      tester,
      find.descendant(
        of: find.byKey(const Key('modeSelector')),
        matching: find.text('Parcelado'),
      ),
    );
    await _tapVisible(tester, find.byKey(const Key('installmentCountField')));
    await tester.tap(find.text('10x').last);
    await tester.pumpAndSettle();
    expect(find.textContaining(r'10x de R$'), findsOneWidget);
    await _tapVisible(tester, find.text('Adicionar'));

    expect(find.textContaining('Parcela 1/10'), findsOneWidget);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Parcela 2/10'), findsOneWidget);

    // Excluir esta e as próximas
    await tester.tap(find.byType(TransactionTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir parcela 2 de 10?'), findsOneWidget);
    await tester.tap(find.text('Esta e as próximas'));
    await tester.pumpAndSettle();
    expect(find.text('9 parcelas excluídas'), findsOneWidget);
    expect(find.byType(TransactionTile), findsNothing);

    await disposeApp(tester, db);
  });
}
