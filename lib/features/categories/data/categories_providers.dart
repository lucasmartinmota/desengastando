import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/database_provider.dart';
import 'package:desengastando/features/categories/data/categories_dao.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;

// Providers declarados à mão (sem riverpod_generator): o gerador não
// resolve tipos criados pelo Drift (ex.: TransactionCategory) na mesma
// passada do build_runner.

final categoriesDaoProvider = Provider<CategoriesDao>(
  (ref) => ref.watch(appDatabaseProvider).categoriesDao,
);

/// Categorias não arquivadas de um tipo, na ordem definida.
final StreamProviderFamily<List<TransactionCategory>, TransactionType>
activeCategoriesProvider = StreamProvider.autoDispose
    .family<List<TransactionCategory>, TransactionType>(
      (ref, type) =>
          ref.watch(categoriesDaoProvider).watchCategories(type: type),
    );

/// Todas as categorias de um tipo, incluindo as arquivadas (para a tela de
/// gerenciamento e para validar nomes repetidos).
final StreamProviderFamily<List<TransactionCategory>, TransactionType>
allCategoriesProvider = StreamProvider.autoDispose
    .family<List<TransactionCategory>, TransactionType>(
      (ref, type) => ref
          .watch(categoriesDaoProvider)
          .watchCategories(type: type, includeArchived: true),
    );
