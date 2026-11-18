import 'dart:convert';

import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

/// Backup inválido ou de outro app.
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Resumo do que um backup contém (mostrado antes de restaurar).
class BackupContents {
  const BackupContents({
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.recurrences,
    required this.installmentPlans,
    required this.exportedAt,
  });

  final List<TransactionCategory> categories;
  final List<Transaction> transactions;
  final List<Budget> budgets;
  final List<Recurrence> recurrences;
  final List<InstallmentPlan> installmentPlans;
  final DateTime exportedAt;
}

/// Exporta e restaura todos os dados do app.
///
/// O backup é um JSON versionado (`format`) com as três tabelas. Restaurar
/// **substitui** tudo, preservando os ids, para que as referências entre
/// lançamentos, categorias e orçamentos continuem válidas.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const appId = 'desengastando';

  /// 2: inclui `recurrences` (lançamentos fixos).
  /// 3: inclui `installmentPlans` (compras parceladas).
  /// Backups de formatos anteriores continuam sendo aceitos.
  static const format = 3;

  Future<String> exportJson({DateTime? now}) async {
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final budgets = await _db.select(_db.budgets).get();
    final recurrences = await _db.select(_db.recurrences).get();
    final plans = await _db.select(_db.installmentPlans).get();
    final data = {
      'app': appId,
      'format': format,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'categories': [for (final c in categories) c.toJson()],
      'transactions': [for (final t in transactions) t.toJson()],
      'budgets': [for (final b in budgets) b.toJson()],
      'recurrences': [for (final r in recurrences) r.toJson()],
      'installmentPlans': [for (final p in plans) p.toJson()],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Lê e valida um backup, sem gravar nada.
  BackupContents parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const BackupFormatException('O arquivo não é um JSON válido.');
    }
    if (decoded is! Map<String, dynamic> || decoded['app'] != appId) {
      throw const BackupFormatException(
        'Esse arquivo não é um backup do Desengastando.',
      );
    }
    final version = decoded['format'];
    if (version is! int || version > format) {
      throw const BackupFormatException(
        'Backup feito por uma versão mais nova do app. Atualize e tente '
        'de novo.',
      );
    }
    final json = decoded;
    try {
      List<Map<String, dynamic>> list(String key) => [
        for (final item in json[key] as List) item as Map<String, dynamic>,
      ];
      return BackupContents(
        categories: [
          for (final json in list('categories'))
            TransactionCategory.fromJson(json),
        ],
        transactions: [
          for (final json in list('transactions')) Transaction.fromJson(json),
        ],
        budgets: [for (final json in list('budgets')) Budget.fromJson(json)],
        recurrences: version < 2
            ? const []
            : [
                for (final json in list('recurrences'))
                  Recurrence.fromJson(json),
              ],
        installmentPlans: version < 3
            ? const []
            : [
                for (final json in list('installmentPlans'))
                  InstallmentPlan.fromJson(json),
              ],
        exportedAt: DateTime.parse(decoded['exportedAt'] as String),
      );
    } on Object {
      throw const BackupFormatException(
        'O backup está incompleto ou corrompido.',
      );
    }
  }

  /// Substitui todos os dados pelos do backup, numa transação só: se algo
  /// falhar (ex.: referência quebrada), nada é alterado.
  Future<void> restore(BackupContents contents) => _db.transaction(() async {
    await _db.delete(_db.budgets).go();
    await _db.delete(_db.transactions).go();
    await _db.delete(_db.recurrences).go();
    await _db.delete(_db.installmentPlans).go();
    await _db.delete(_db.categories).go();
    await _db.batch((b) {
      b
        ..insertAll(_db.categories, contents.categories)
        ..insertAll(_db.recurrences, contents.recurrences)
        ..insertAll(_db.installmentPlans, contents.installmentPlans)
        ..insertAll(_db.transactions, contents.transactions)
        ..insertAll(_db.budgets, contents.budgets);
    });
  });

  /// Lançamentos em CSV para planilhas (padrão brasileiro: `;` como
  /// separador e vírgula decimal), com BOM para o Excel reconhecer UTF-8.
  Future<String> exportCsv() async {
    final rows =
        await (_db.select(_db.transactions).join([
              innerJoin(
                _db.categories,
                _db.categories.id.equalsExp(_db.transactions.categoryId),
              ),
            ])..orderBy([
              OrderingTerm.asc(_db.transactions.date),
              OrderingTerm.asc(_db.transactions.id),
            ]))
            .get();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final buffer = StringBuffer('\uFEFF')
      ..writeln(
        _csvLine(const [
          'Data',
          'Tipo',
          'Categoria',
          'Descrição',
          'Forma de pagamento',
          'Valor',
        ]),
      );
    for (final row in rows) {
      final t = row.readTable(_db.transactions);
      final c = row.readTable(_db.categories);
      final signed = c.type == TransactionType.expense
          ? -t.amountCents
          : t.amountCents;
      buffer.writeln(
        _csvLine([
          dateFormat.format(t.date),
          c.type.label,
          c.name,
          t.description ?? '',
          t.paymentMethod?.label ?? '',
          // Sem separador de milhar: planilhas leem "-1234,56" como número.
          CurrencyFormatter.formatPlain(signed).replaceAll('.', ''),
        ]),
      );
    }
    return buffer.toString();
  }

  static String _csvLine(List<String> fields) => fields
      .map(
        (f) => f.contains(RegExp(r'[;"\n\r]'))
            ? '"${f.replaceAll('"', '""')}"'
            : f,
      )
      .join(';');
}
