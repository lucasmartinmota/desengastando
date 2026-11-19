import 'dart:typed_data';

import 'package:desengastando/core/formatters/currency_formatter.dart';
import 'package:desengastando/features/reports/domain/report_data.dart';
import 'package:desengastando/features/transactions/domain/transaction_models.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fontes do relatório. É a Manrope do app, que tem os acentos e o sinal
/// de menos.
class ReportFonts {
  const ReportFonts({
    required this.regular,
    required this.bold,
    required this.extraBold,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font extraBold;

  static Future<ReportFonts> load() async {
    Future<pw.Font> font(String weight) async => pw.Font.ttf(
      await rootBundle.load('assets/fonts/manrope/Manrope-$weight.ttf'),
    );
    return ReportFonts(
      regular: await font('Regular'),
      bold: await font('Bold'),
      extraBold: await font('ExtraBold'),
    );
  }
}

typedef _Style =
    pw.TextStyle Function({double size, PdfColor color, pw.Font? font});

/// Monta o PDF de um [ReportData], nesta ordem: cabeçalho, resumo, totais
/// por categoria e o extrato completo do período.
abstract final class ReportPdf {
  static const _primary = PdfColor.fromInt(0xFF0F766E);
  static const _expense = PdfColor.fromInt(0xFFD64541);
  static const _income = PdfColor.fromInt(0xFF0E8A7E);
  static const _ink = PdfColor.fromInt(0xFF1A2421);
  static const _muted = PdfColor.fromInt(0xFF5F6B67);
  static const _line = PdfColor.fromInt(0xFFDDE4E2);
  static const _tint = PdfColor.fromInt(0xFFF1F5F4);

  static Future<Uint8List> build(ReportData data, ReportFonts fonts) =>
      document(data, fonts).save();

  /// O documento montado, antes de virar bytes.
  static pw.Document document(ReportData data, ReportFonts fonts) {
    final generated = DateFormat(
      "dd/MM/yyyy 'às' HH:mm",
    ).format(data.generatedAt);
    final doc = pw.Document(
      title: 'Desengastando: ${data.period.label}',
      author: 'Desengastando',
      creator: 'Desengastando',
    );

    pw.TextStyle style({
      double size = 9,
      PdfColor color = _ink,
      pw.Font? font,
    }) => pw.TextStyle(
      fontSize: size,
      color: color,
      font: font ?? fonts.regular,
    );

    final muted = style(size: 8, color: _muted);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 28),
          theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
        ),
        // O padrão é 20 páginas, e um ano de lançamentos passa disso fácil.
        maxPages: 1000,
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            children: [
              pw.Text('Desengastando · ${data.period.label}', style: muted),
              pw.Spacer(),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: muted,
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Row(
            children: [
              pw.Text(
                'Desengastando',
                style: style(size: 10, color: _primary, font: fonts.extraBold),
              ),
              pw.Spacer(),
              pw.Text('Gerado em $generated', style: muted),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            data.period.label,
            style: style(size: 22, font: fonts.extraBold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${data.period.dates} · '
            '${_plural(data.transactions.length, 'lançamento')}',
            style: style(color: _muted),
          ),
          pw.SizedBox(height: 16),
          _summary(data, style, fonts),
          if (data.scheduledCount > 0) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Inclui ${_plural(data.scheduledCount, 'lançamento previsto', 'lançamentos previstos')} '
              '(fixos e parcelas com data depois de hoje), '
              'marcados como "Previsto".',
              style: muted,
            ),
          ],
          if (data.isEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              'Nenhum lançamento neste período.',
              style: style(font: fonts.bold),
            ),
          ],
          if (data.expensesByCategory.isNotEmpty)
            ..._categorySection(
              'Despesas por categoria',
              data.expensesByCategory,
              _expense,
              style,
              fonts,
            ),
          if (data.incomeByCategory.isNotEmpty)
            ..._categorySection(
              'Receitas por categoria',
              data.incomeByCategory,
              _income,
              style,
              fonts,
            ),
          if (!data.isEmpty) ...[
            _sectionTitle('Lançamentos', style, fonts),
            _transactionsTable(data, style, fonts),
          ],
        ],
      ),
    );
    return doc;
  }

  static pw.Widget _summary(ReportData data, _Style style, ReportFonts fonts) {
    pw.Widget card(String label, String value, PdfColor color) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const pw.BoxDecoration(
          color: _tint,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: style(size: 8, color: _muted)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: style(size: 14, color: color, font: fonts.extraBold),
            ),
          ],
        ),
      ),
    );

    final balance = data.balanceCents;
    return pw.Row(
      children: [
        card('Receitas', CurrencyFormatter.format(data.incomeCents), _income),
        pw.SizedBox(width: 8),
        card('Despesas', CurrencyFormatter.format(data.expenseCents), _expense),
        pw.SizedBox(width: 8),
        card(
          'Saldo',
          CurrencyFormatter.formatSigned(balance),
          balance < 0 ? _expense : _ink,
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(
    String text,
    _Style style,
    ReportFonts fonts,
  ) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 22, bottom: 6),
    child: pw.Text(text, style: style(size: 12, font: fonts.extraBold)),
  );

  static List<pw.Widget> _categorySection(
    String title,
    List<CategoryShare> shares,
    PdfColor barColor,
    _Style style,
    ReportFonts fonts,
  ) {
    final head = style(size: 7.5, color: _muted, font: fonts.bold);
    final cell = style();
    const barWidth = 90.0;
    // A maior categoria ocupa a barra inteira; as outras, em proporção.
    final largest = shares.first.totalCents;
    return [
      _sectionTitle(title, style, fonts),
      pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(),
          1: pw.FixedColumnWidth(barWidth + 8),
          2: pw.FixedColumnWidth(40),
          3: pw.FixedColumnWidth(36),
          4: pw.FixedColumnWidth(78),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          _row([
            pw.Text('CATEGORIA', style: head),
            pw.SizedBox(),
            _right(pw.Text('LANÇ.', style: head)),
            _right(pw.Text('%', style: head)),
            _right(pw.Text('TOTAL', style: head)),
          ], repeat: true),
          for (final share in shares)
            _row([
              pw.Row(
                children: [
                  pw.Container(
                    width: 7,
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(share.category.color),
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: pw.Text(
                      share.category.name,
                      style: cell,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Container(
                  width: barWidth * (share.totalCents / largest).clamp(0.03, 1),
                  height: 5,
                  decoration: pw.BoxDecoration(
                    color: barColor,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(2),
                    ),
                  ),
                ),
              ),
              _right(pw.Text('${share.count}', style: cell)),
              _right(pw.Text('${(share.ratio * 100).round()}%', style: cell)),
              _right(
                pw.Text(
                  CurrencyFormatter.format(share.totalCents),
                  style: style(font: fonts.bold),
                ),
              ),
            ]),
        ],
      ),
    ];
  }

  static pw.Widget _transactionsTable(
    ReportData data,
    _Style style,
    ReportFonts fonts,
  ) {
    final head = style(size: 7.5, color: _muted, font: fonts.bold);
    final cell = style(size: 8.5);
    final note = style(size: 7.5, color: _muted);
    final day = DateFormat('dd/MM/yy');

    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(46),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FixedColumnWidth(78),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        _row([
          pw.Text('DATA', style: head),
          pw.Text('DESCRIÇÃO', style: head),
          pw.Text('CATEGORIA', style: head),
          pw.Text('PAGAMENTO', style: head),
          _right(pw.Text('VALOR', style: head)),
        ], repeat: true),
        for (final t in data.transactions)
          _row([
            pw.Text(day.format(t.transaction.date), style: cell),
            _description(t, data, cell, note),
            pw.Text(t.category.name, style: cell, maxLines: 2),
            pw.Text(
              t.transaction.paymentMethod?.label ?? '',
              style: cell,
              maxLines: 1,
            ),
            _right(
              pw.Text(
                CurrencyFormatter.formatSigned(t.signedCents),
                style: style(
                  size: 8.5,
                  font: fonts.bold,
                  color: t.category.type == TransactionType.expense
                      ? _expense
                      : _income,
                ),
              ),
            ),
          ]),
      ],
    );
  }

  static pw.Widget _description(
    TransactionWithCategory t,
    ReportData data,
    pw.TextStyle cell,
    pw.TextStyle note,
  ) {
    final description = t.transaction.description;
    final details = [
      if (t.installmentLabel case final label?) 'Parcela $label',
      if (t.isScheduled(today: data.generatedAt)) 'Previsto',
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          description == null || description.isEmpty
              ? t.category.name
              : description,
          style: cell,
          maxLines: 2,
        ),
        if (details.isNotEmpty) pw.Text(details.join(' · '), style: note),
      ],
    );
  }

  static pw.TableRow _row(List<pw.Widget> cells, {bool repeat = false}) =>
      pw.TableRow(
        repeat: repeat,
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
        ),
        children: [
          for (final (i, cell) in cells.indexed)
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(i == 0 ? 0 : 4, 5, 0, 5),
              child: cell,
            ),
        ],
      );

  static pw.Widget _right(pw.Widget child) =>
      pw.Align(alignment: pw.Alignment.centerRight, child: child);

  static String _plural(int n, String word, [String? plural]) =>
      '$n ${n == 1 ? word : plural ?? '${word}s'}';
}
