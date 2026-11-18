import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/tables.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Stream<List<TransactionCategory>> watchCategories({
    TransactionType? type,
    bool includeArchived = false,
  }) {
    final query = select(categories);
    if (type != null) query.where((c) => c.type.equalsValue(type));
    if (!includeArchived) query.where((c) => c.archived.equals(false));
    query.orderBy([
      (c) => OrderingTerm.asc(c.sortOrder),
      (c) => OrderingTerm.asc(c.name),
    ]);
    return query.watch();
  }

  Future<TransactionCategory> getCategory(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingle();

  Future<int> addCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  /// Cria uma categoria no fim da lista do seu tipo.
  Future<int> createCategory({
    required String name,
    required String iconKey,
    required int color,
    required TransactionType type,
  }) => transaction(() async {
    final maxOrder = categories.sortOrder.max();
    final row =
        await (selectOnly(categories)
              ..addColumns([maxOrder])
              ..where(categories.type.equalsValue(type)))
            .getSingle();
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        iconKey: iconKey,
        color: color,
        type: type,
        sortOrder: Value((row.read(maxOrder) ?? -1) + 1),
      ),
    );
  });

  /// Grava a nova ordem: a posição de cada id em [orderedIds] vira o
  /// `sortOrder` dele.
  Future<void> reorder(List<int> orderedIds) => batch((b) {
    for (final (index, id) in orderedIds.indexed) {
      b.update(
        categories,
        CategoriesCompanion(sortOrder: Value(index)),
        where: (c) => c.id.equals(id),
      );
    }
  });

  Future<bool> updateCategory(TransactionCategory category) =>
      update(categories).replace(category);

  /// Categorias não são apagadas (preserva o histórico); são arquivadas.
  Future<void> setArchived(int id, {required bool archived}) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(archived: Value(archived)),
      );
}
