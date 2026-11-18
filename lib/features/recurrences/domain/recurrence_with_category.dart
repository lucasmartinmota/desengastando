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

  /// Data do próximo lançamento, a partir de hoje.
  DateTime nextDate({DateTime? today}) => RecurrenceSchedule.nextDate(
    recurrence.dayOfMonth,
    today ?? DateTime.now(),
  );

  @override
  bool operator ==(Object other) =>
      other is RecurrenceWithCategory &&
      other.recurrence == recurrence &&
      other.category == category;

  @override
  int get hashCode => Object.hash(recurrence, category);
}
