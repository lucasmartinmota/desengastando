import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';

/// Categorias criadas na primeira abertura do app.
final List<CategoriesCompanion> defaultCategories = [
  ..._build(TransactionType.expense, const [
    ('Alimentação', 'restaurant', 0xFFF25F5C),
    ('Mercado', 'shopping_cart', 0xFFF4A261),
    ('Transporte', 'directions_car', 0xFF4C9BE8),
    ('Moradia', 'home', 0xFF0F766E),
    ('Saúde', 'favorite', 0xFFE76F98),
    ('Educação', 'school', 0xFF7B6CF6),
    ('Lazer', 'celebration', 0xFFF2C14E),
    ('Assinaturas', 'subscriptions', 0xFF9B5DE5),
    ('Compras', 'shopping_bag', 0xFF2EC4B6),
    ('Outros', 'more_horiz', 0xFF8D99AE),
  ]),
  ..._build(TransactionType.income, const [
    ('Salário', 'payments', 0xFF0E8A7E),
    ('Freelance', 'work', 0xFF4C9BE8),
    ('Investimentos', 'trending_up', 0xFF7B6CF6),
    ('Outros', 'more_horiz', 0xFF8D99AE),
  ]),
];

Iterable<CategoriesCompanion> _build(
  TransactionType type,
  List<(String, String, int)> items,
) sync* {
  for (final (index, (name, iconKey, color)) in items.indexed) {
    yield CategoriesCompanion.insert(
      name: name,
      iconKey: iconKey,
      color: color,
      type: type,
      sortOrder: Value(index),
    );
  }
}
