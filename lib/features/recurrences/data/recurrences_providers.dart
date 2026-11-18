import 'package:desengastando/data/database/database_provider.dart';
import 'package:desengastando/features/recurrences/data/recurrences_dao.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_with_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// À mão, como os demais providers que expõem tipos do Drift.

final recurrencesDaoProvider = Provider<RecurrencesDao>(
  (ref) => ref.watch(appDatabaseProvider).recurrencesDao,
);

final StreamProvider<List<RecurrenceWithCategory>> recurrencesProvider =
    StreamProvider.autoDispose<List<RecurrenceWithCategory>>(
      (ref) => ref.watch(recurrencesDaoProvider).watchAll(),
    );
