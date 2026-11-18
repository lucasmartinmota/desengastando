import 'package:desengastando/core/date/year_month.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/data/database/tables.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_schedule.dart';
import 'package:desengastando/features/recurrences/domain/recurrence_with_category.dart';
import 'package:desengastando/features/transactions/domain/payment_method.dart';
import 'package:drift/drift.dart';

part 'recurrences_dao.g.dart';

@DriftAccessor(tables: [Recurrences, Categories, Transactions])
class RecurrencesDao extends DatabaseAccessor<AppDatabase>
    with _$RecurrencesDaoMixin {
  RecurrencesDao(super.attachedDatabase);

  /// Todas as recorrências: ativas primeiro, depois pelo dia do mês.
  Stream<List<RecurrenceWithCategory>> watchAll() {
    final query =
        select(recurrences).join([
          innerJoin(
            categories,
            categories.id.equalsExp(recurrences.categoryId),
          ),
        ])..orderBy([
          OrderingTerm.desc(recurrences.active),
          OrderingTerm.asc(recurrences.dayOfMonth),
          OrderingTerm.asc(recurrences.id),
        ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          RecurrenceWithCategory(
            recurrence: row.readTable(recurrences),
            category: row.readTable(categories),
          ),
      ],
    );
  }

  /// Cria uma recorrência pela tela de lançamentos fixos.
  ///
  /// Se a data deste mês já passou, [includeCurrentMonth] decide se o
  /// lançamento do mês atual sai agora ou se começa só no próximo.
  Future<int> createRecurrence({
    required int amountCents,
    required int categoryId,
    required int dayOfMonth,
    required bool includeCurrentMonth,
    String? description,
    PaymentMethod? paymentMethod,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final settled = RecurrenceSchedule.settledThrough(dayOfMonth, today);
    final current = YearMonth.fromDate(today);
    final lastGenerated = includeCurrentMonth && settled == current
        ? current.previous
        : settled;
    final id = await into(recurrences).insert(
      RecurrencesCompanion.insert(
        amountCents: amountCents,
        categoryId: categoryId,
        dayOfMonth: dayOfMonth,
        description: Value(description),
        paymentMethod: Value(paymentMethod),
        lastGeneratedMonth: lastGenerated.key,
      ),
    );
    await generateDue(now: today);
    return id;
  }

  /// Grava um lançamento e o transforma em fixo: ele é o primeiro, e os
  /// próximos saem todo mês no mesmo dia. Se a data for de um mês passado,
  /// os meses seguintes até hoje já são preenchidos.
  Future<int> addRepeating(TransactionsCompanion entry, {DateTime? now}) async {
    final id = await transaction(() async {
      final date = entry.date.value;
      final recurrenceId = await into(recurrences).insert(
        RecurrencesCompanion.insert(
          amountCents: entry.amountCents.value,
          categoryId: entry.categoryId.value,
          dayOfMonth: date.day,
          description: entry.description,
          paymentMethod: entry.paymentMethod,
          lastGeneratedMonth: YearMonth.fromDate(date).key,
        ),
      );
      return into(
        transactions,
      ).insert(entry.copyWith(recurrenceId: Value(recurrenceId)));
    });
    await generateDue(now: now);
    return id;
  }

  /// Atualiza valor, categoria, dia etc. Vale para os próximos meses; os
  /// lançamentos já criados não mudam.
  Future<void> updateRecurrence(Recurrence recurrence) =>
      update(recurrences).replace(recurrence);

  /// Pausar não apaga nada. Ao reativar, recomeça do próximo vencimento,
  /// sem lançar para trás os meses em que ficou pausada.
  Future<void> setActive(int id, {required bool active, DateTime? now}) =>
      transaction(() async {
        final current = await (select(
          recurrences,
        )..where((r) => r.id.equals(id))).getSingle();
        var last = current.lastGeneratedMonth;
        if (active && !current.active) {
          final settled = RecurrenceSchedule.settledThrough(
            current.dayOfMonth,
            now ?? DateTime.now(),
          ).key;
          if (settled > last) last = settled;
        }
        await (update(recurrences)..where((r) => r.id.equals(id))).write(
          RecurrencesCompanion(
            active: Value(active),
            lastGeneratedMonth: Value(last),
          ),
        );
      });

  /// Remove a recorrência; os lançamentos já feitos continuam.
  Future<int> deleteRecurrence(int id) =>
      (delete(recurrences)..where((r) => r.id.equals(id))).go();

  /// Cria os lançamentos que já venceram e ainda não saíram. Chamado ao
  /// abrir o app e ao voltar para ele. Devolve quantos foram criados.
  Future<int> generateDue({DateTime? now}) => transaction(() async {
    final today = now ?? DateTime.now();
    final active = await (select(
      recurrences,
    )..where((r) => r.active.equals(true))).get();
    var created = 0;
    for (final r in active) {
      final months = RecurrenceSchedule.dueMonths(
        lastGenerated: YearMonth.fromKey(r.lastGeneratedMonth),
        dayOfMonth: r.dayOfMonth,
        today: today,
      );
      if (months.isEmpty) continue;
      await batch((b) {
        b.insertAll(transactions, [
          for (final month in months)
            TransactionsCompanion.insert(
              amountCents: r.amountCents,
              date: RecurrenceSchedule.dueDate(month, r.dayOfMonth),
              categoryId: r.categoryId,
              description: Value(r.description),
              paymentMethod: Value(r.paymentMethod),
              recurrenceId: Value(r.id),
            ),
        ]);
      });
      await (update(recurrences)..where((x) => x.id.equals(r.id))).write(
        RecurrencesCompanion(lastGeneratedMonth: Value(months.last.key)),
      );
      created += months.length;
    }
    return created;
  });
}
