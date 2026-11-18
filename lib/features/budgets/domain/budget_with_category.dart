import 'package:desengastando/data/database/app_database.dart';
import 'package:flutter/foundation.dart';

@immutable
class BudgetWithCategory {
  const BudgetWithCategory({required this.budget, required this.category});

  final Budget budget;
  final TransactionCategory category;
}
