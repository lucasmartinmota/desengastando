import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_schedule.dart';
import 'package:flutter/foundation.dart';

@immutable
class RecurrenceWithCategory {
  const RecurrenceWithCategory({
    required this.recurrence,
    required this.category,
  });

  final Recurrence recurrence;
  final TransactionCategory category;

  /// Data do próximo lançamento que será criado.
  DateTime get nextDate => RecurrenceSchedule.nextDate(
    YearMonth.fromKey(recurrence.lastGeneratedMonth),
    recurrence.dayOfMonth,
  );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceWithCategory &&
      other.recurrence == recurrence &&
      other.category == category;

  @override
  int get hashCode => Object.hash(recurrence, category);
}
