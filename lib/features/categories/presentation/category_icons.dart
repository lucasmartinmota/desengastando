import 'package:desengastando/data/database/app_database.dart';
import 'package:flutter/material.dart';

/// Ícones disponíveis para categorias, indexados pela chave salva no banco.
///
/// Guardamos a chave (e não o code point) para não quebrar o tree-shaking
/// de ícones no build de release.
abstract final class CategoryIcons {
  static const Map<String, IconData> all = {
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'directions_car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'favorite': Icons.favorite_rounded,
    'school': Icons.school_rounded,
    'celebration': Icons.celebration_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'payments': Icons.payments_rounded,
    'work': Icons.work_rounded,
    'trending_up': Icons.trending_up_rounded,
  };

  static IconData of(String key) => all[key] ?? Icons.category_rounded;
}

/// Círculo com o ícone da categoria na cor dela.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({required this.category, this.radius = 20, super.key});

  final TransactionCategory category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Icon(
        CategoryIcons.of(category.iconKey),
        color: color,
        size: radius,
      ),
    );
  }
}
