import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('abre no Resumo e navega entre as abas', (tester) async {
    final db = await pumpApp(tester);

    expect(find.text('Saldo do mês'), findsOneWidget);

    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum lançamento neste mês'), findsOneWidget);

    await tester.tap(find.text('Orçamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Sem orçamentos definidos'), findsOneWidget);

    await disposeApp(tester, db);
  });

  test('temas claro e escuro expõem as cores de finanças', () {
    expect(AppTheme.light().extension<FinanceColors>(), FinanceColors.light);
    expect(AppTheme.dark().extension<FinanceColors>(), FinanceColors.dark);
  });
}
