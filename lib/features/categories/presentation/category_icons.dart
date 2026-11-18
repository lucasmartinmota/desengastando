import 'package:desengastando/data/database/app_database.dart';
import 'package:flutter/material.dart';

/// Ícones disponíveis para categorias, indexados pela chave salva no banco.
///
/// Guardamos a chave (e não o code point) para não quebrar o tree-shaking
/// de ícones no build de release.
abstract final class CategoryIcons {
  /// Ordem usada no seletor de ícones (agrupados por tema).
  static const Map<String, IconData> all = {
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
    'local_bar': Icons.local_bar_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'sell': Icons.sell_rounded,
    'checkroom': Icons.checkroom_rounded,
    'directions_car': Icons.directions_car_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'flight': Icons.flight_rounded,
    'home': Icons.home_rounded,
    'bolt': Icons.bolt_rounded,
    'water_drop': Icons.water_drop_rounded,
    'wifi': Icons.wifi_rounded,
    'phone_iphone': Icons.phone_iphone_rounded,
    'build': Icons.build_rounded,
    'favorite': Icons.favorite_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'medication': Icons.medication_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'child_care': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'celebration': Icons.celebration_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'movie': Icons.movie_rounded,
    'music_note': Icons.music_note_rounded,
    'beach_access': Icons.beach_access_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'content_cut': Icons.content_cut_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'credit_card': Icons.credit_card_rounded,
    'account_balance': Icons.account_balance_rounded,
    'savings': Icons.savings_rounded,
    'payments': Icons.payments_rounded,
    'attach_money': Icons.attach_money_rounded,
    'work': Icons.work_rounded,
    'trending_up': Icons.trending_up_rounded,
    'more_horiz': Icons.more_horiz_rounded,
  };

  static IconData of(String key) => all[key] ?? Icons.category_rounded;
}

/// Cores disponíveis para categorias (ARGB), com bom contraste nos dois
/// temas quando usadas sobre o próprio tom a 16%.
abstract final class CategoryColors {
  static const palette = <(int, String)>[
    (0xFFF25F5C, 'Coral'),
    (0xFFE76F98, 'Rosa'),
    (0xFF9B5DE5, 'Roxo'),
    (0xFF7B6CF6, 'Violeta'),
    (0xFF4C9BE8, 'Azul'),
    (0xFF3D5A80, 'Azul-marinho'),
    (0xFF2EC4B6, 'Menta'),
    (0xFF0E8A7E, 'Verde-água'),
    (0xFF0F766E, 'Verde-petróleo'),
    (0xFF43AA8B, 'Verde'),
    (0xFFF2C14E, 'Amarelo'),
    (0xFFF4A261, 'Laranja'),
    (0xFFA9714B, 'Marrom'),
    (0xFF8D99AE, 'Cinza'),
  ];
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
