import 'dart:typed_data';

import 'package:desengastando/features/reports/data/report_pdf.dart';
import 'package:desengastando/features/reports/domain/report_data.dart';
import 'package:desengastando/features/reports/domain/report_period.dart';
import 'package:desengastando/features/transactions/data/transactions_dao.dart';
import 'package:desengastando/features/transactions/data/transactions_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reúne os lançamentos de um período e gera o PDF.
class ReportService {
  ReportService(this._dao);

  final TransactionsDao _dao;
  ReportFonts? _fonts;

  Future<ReportData> load(ReportPeriod period, {DateTime? now}) async =>
      ReportData(
        period: period,
        transactions: await _dao.getInPeriod(period.start, period.end),
        generatedAt: now ?? DateTime.now(),
      );

  Future<Uint8List> buildPdf(ReportData data) async =>
      ReportPdf.build(data, _fonts ??= await ReportFonts.load());
}

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(ref.watch(transactionsDaoProvider)),
);
