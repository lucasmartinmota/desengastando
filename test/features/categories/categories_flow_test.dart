import 'package:desengastando/features/categories/presentation/category_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openCategories(WidgetTester tester) async {
  await tester.tap(find.text('Lançamentos'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Categorias'));
  await tester.pumpAndSettle();
}

Finder _tile(String name) => find.widgetWithText(ListTile, name);

/// Rola a lista de categorias (há outros Scrollables montados nas abas).
Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ReorderableListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

void main() {
  testWidgets('cria, edita e arquiva uma categoria', (tester) async {
    final db = await pumpApp(tester);
    await _openCategories(tester);
    expect(find.text('Categorias'), findsOneWidget);

    // Criar
    await tester.tap(find.text('Nova categoria'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('categoryNameField')), 'Pets');
    await _tapVisible(tester, find.byIcon(Icons.pets_rounded));
    await _tapVisible(tester, find.text('Criar categoria'));
    await _scrollTo(tester, _tile('Pets'));
    expect(_tile('Pets'), findsOneWidget);

    // Nome repetido bloqueia o salvar
    await tester.tap(_tile('Pets'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      'mercado',
    );
    await tester.pump();
    expect(find.text('Já existe uma categoria com esse nome'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Salvar alterações');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    // Editar
    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      'Bichos',
    );
    await _tapVisible(tester, save);
    expect(_tile('Bichos'), findsOneWidget);

    // Arquivar
    await tester.tap(_tile('Bichos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Arquivadas'));
    expect(find.text('Arquivadas'), findsOneWidget);
    expect(find.textContaining('arquivada'), findsWidgets);

    // Arquivada não aparece no lançamento
    await tester.tap(find.byType(BackButton));
    await tester.pump(const Duration(seconds: 5)); // aviso de arquivada expira
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Bichos'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Mercado'), findsOneWidget);

    await disposeApp(tester, db);
  });

  testWidgets('cria categoria pelo lançamento e já seleciona', (tester) async {
    final db = await pumpApp(tester);
    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byTooltip('Nova categoria'));
    expect(find.byType(CategoryFormSheet), findsOneWidget);
    await tester.enterText(find.byKey(const Key('categoryNameField')), 'Pets');
    await _tapVisible(tester, find.text('Criar categoria'));

    final chip = find.widgetWithText(ChoiceChip, 'Pets');
    expect(chip, findsOneWidget);
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);

    await disposeApp(tester, db);
  });
}
