import 'package:desengastando/app/app.dart';
import 'package:desengastando/app/theme/app_colors.dart';
import 'package:desengastando/app/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre no Resumo e navega entre as abas', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DesengastandoApp()));
    await tester.pumpAndSettle();

    expect(find.text('Saldo do mês'), findsOneWidget);

    await tester.tap(find.text('Lançamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum gasto registrado'), findsOneWidget);

    await tester.tap(find.text('Orçamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Sem orçamentos definidos'), findsOneWidget);
  });

  test('temas claro e escuro expõem as cores de finanças', () {
    expect(AppTheme.light().extension<FinanceColors>(), FinanceColors.light);
    expect(AppTheme.dark().extension<FinanceColors>(), FinanceColors.dark);
  });
}
