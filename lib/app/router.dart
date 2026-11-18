import 'package:desengastando/app/app_shell.dart';
import 'package:desengastando/features/backup/presentation/settings_page.dart';
import 'package:desengastando/features/budgets/presentation/budgets_page.dart';
import 'package:desengastando/features/categories/presentation/categories_page.dart';
import 'package:desengastando/features/dashboard/presentation/dashboard_page.dart';
import 'package:desengastando/features/transactions/presentation/transactions_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

abstract final class AppRoutes {
  static const dashboard = '/resumo';
  static const transactions = '/lancamentos';
  static const budgets = '/orcamentos';

  /// Fora das abas: abre por cima da barra de navegação.
  static const categories = '/categorias';
  static const settings = '/ajustes';
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, _) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (_, _) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgets,
                builder: (_, _) => const BudgetsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => const CategoriesPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
