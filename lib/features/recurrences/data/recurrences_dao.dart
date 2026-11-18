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

  /// Cria uma recorrência pela tela de lançamentos fixos e já lança os
  /// próximos meses.
  ///
  /// Se a data deste mês já passou, [includeCurrentMonth] decide se o
  /// lançamento do mês atual sai também ou se começa só no próximo.
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
    final current = YearMonth.fromDate(today);
    final settled = RecurrenceSchedule.settledThrough(dayOfMonth, today);
    final lastGenerated = includeCurrentMonth || settled != current
        ? current.previous
        : current;
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
  /// próximos meses já ficam lançados no mesmo dia.
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

  /// Apaga os lançamentos futuros (depois de hoje) de [recurrenceId] e
  /// devolve o último mês que continua lançado — o ponto de onde a geração
  /// recomeça.
  Future<YearMonth> _dropFuture(int recurrenceId, DateTime today) async {
    final cutoff = today.dateOnly.add(const Duration(days: 1));
    await (delete(transactions)..where(
          (t) =>
              t.recurrenceId.equals(recurrenceId) &
              t.date.isBiggerOrEqualValue(cutoff),
        ))
        .go();
    final latest = transactions.date.max();
    final row =
        await (selectOnly(transactions)
              ..addColumns([latest])
              ..where(transactions.recurrenceId.equals(recurrenceId)))
            .getSingle();
    final kept = row.read(latest);
    final floor = YearMonth.fromDate(today).previous;
    if (kept == null) return floor;
    final keptMonth = YearMonth.fromDate(kept);
    return keptMonth.compareTo(floor) > 0 ? keptMonth : floor;
  }

  /// Atualiza valor, categoria, dia etc. Os lançamentos que já passaram não
  /// mudam; os futuros são refeitos com os novos dados.
  Future<void> updateRecurrence(Recurrence recurrence, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    await transaction(() async {
      final last = await _dropFuture(recurrence.id, today);
      await update(
        recurrences,
      ).replace(recurrence.copyWith(lastGeneratedMonth: last.key));
    });
    await generateDue(now: today);
  }

  /// Pausar remove os lançamentos futuros (os passados ficam). Ao reativar,
  /// recomeça do próximo vencimento, sem lançar para trás os meses em que
  /// ficou pausada.
  Future<void> setActive(int id, {required bool active, DateTime? now}) async {
    final today = now ?? DateTime.now();
    await transaction(() async {
      final current = await (select(
        recurrences,
      )..where((r) => r.id.equals(id))).getSingle();
      var last = current.lastGeneratedMonth;
      if (!active) {
        last = (await _dropFuture(id, today)).key;
      } else if (!current.active) {
        final settled = RecurrenceSchedule.settledThrough(
          current.dayOfMonth,
          today,
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
    if (active) await generateDue(now: today);
  }

  /// Remove a recorrência e os lançamentos futuros dela; os que já passaram
  /// continuam (desvinculados).
  Future<void> deleteRecurrence(int id, {DateTime? now}) =>
      transaction(() async {
        await _dropFuture(id, now ?? DateTime.now());
        await (delete(recurrences)..where((r) => r.id.equals(id))).go();
      });

  /// Completa os lançamentos de cada recorrência ativa até
  /// [RecurrenceSchedule.horizon]. Chamado ao abrir e ao voltar para o app.
  /// Devolve quantos foram criados.
  Future<int> generateDue({DateTime? now}) => transaction(() async {
    final until = RecurrenceSchedule.horizon(now ?? DateTime.now());
    final active = await (select(
      recurrences,
    )..where((r) => r.active.equals(true))).get();
    var created = 0;
    for (final r in active) {
      final months = RecurrenceSchedule.pendingMonths(
        lastGenerated: YearMonth.fromKey(r.lastGeneratedMonth),
        until: until,
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
