// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrences_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurrencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $RecurrencesTable get recurrences => attachedDatabase.recurrences;
  $InstallmentPlansTable get installmentPlans =>
      attachedDatabase.installmentPlans;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  RecurrencesDaoManager get managers => RecurrencesDaoManager(this);
}

class RecurrencesDaoManager {
  final _$RecurrencesDaoMixin _db;
  RecurrencesDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db.attachedDatabase, _db.recurrences);
  $$InstallmentPlansTableTableManager get installmentPlans =>
      $$InstallmentPlansTableTableManager(
        _db.attachedDatabase,
        _db.installmentPlans,
      );
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
