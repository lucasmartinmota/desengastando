// Gera os PNGs do ícone e da tela de abertura a partir de código.
//
//   flutter test tool/icon/render_icons_test.dart
//   dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// Desenhar com dart:ui mantém o ícone reproduzível e editável no
// repositório, sem depender de editor de imagem.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _petrol = Color(0xFF0F766E);
const _petrolLight = Color(0xFF14917F);
const _mint = Color(0xFF2EC4B6);
const _white = Color(0xFFFFFFFF);
const _size = 1024.0;

/// Moeda branca com um "D" e um selo menta com seta para baixo
/// ("gastar menos"). [scale] encolhe a arte para as áreas seguras.
void _drawArt(Canvas canvas, double scale) {
  const center = Offset(_size / 2, _size / 2);
  final r = _size * 0.30 * scale;

  // Moeda
  canvas
    ..drawCircle(center, r, Paint()..color = _white)
    ..drawCircle(
      center,
      r * 0.84,
      Paint()
        ..color = _petrol.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05,
    );

  // "D"
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.center,
            fontFamily: 'IconFont',
          ),
        )
        ..pushStyle(
          ui.TextStyle(color: _petrol, fontSize: r * 1.25, height: 1),
        )
        ..addText('D');
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: r * 2));
  canvas.drawParagraph(
    paragraph,
    Offset(center.dx - r, center.dy - paragraph.height / 2 - r * 0.02),
  );

  // Selo com seta para baixo
  final badgeCenter = center + Offset.fromDirection(math.pi / 4, r * 0.92);
  final badgeR = r * 0.36;
  canvas
    ..drawCircle(badgeCenter, badgeR + r * 0.07, Paint()..color = _petrol)
    ..drawCircle(badgeCenter, badgeR, Paint()..color = _mint);
  final a = badgeR * 0.5;
  final arrow = Path()
    ..moveTo(badgeCenter.dx, badgeCenter.dy - a)
    ..lineTo(badgeCenter.dx, badgeCenter.dy + a * 0.85)
    ..moveTo(badgeCenter.dx - a * 0.7, badgeCenter.dy + a * 0.15)
    ..lineTo(badgeCenter.dx, badgeCenter.dy + a * 0.85)
    ..lineTo(badgeCenter.dx + a * 0.7, badgeCenter.dy + a * 0.15);
  canvas.drawPath(
    arrow,
    Paint()
      ..color = _white
      ..style = PaintingStyle.stroke
      ..strokeWidth = badgeR * 0.22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

void _drawBackground(Canvas canvas) {
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, _size, _size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(_size, _size),
        [_petrolLight, _petrol],
      ),
  );
}

Future<void> _render(String path, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera os PNGs do ícone', () async {
    final font = File('assets/fonts/manrope/Manrope-ExtraBold.ttf');
    await (FontLoader('IconFont')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();

    // Ícone completo (iOS e Android antigo).
    await _render('assets/icon/icon.png', (c) {
      _drawBackground(c);
      _drawArt(c, 1);
    });
    // Frente do ícone adaptativo: o plugin ainda aplica margem de 16%
    // e a máscara circular corta as bordas; 0.95 mantém o selo na área segura.
    await _render('assets/icon/icon_foreground.png', (c) => _drawArt(c, 0.95));
    // Tela de abertura (iOS e Android < 12): disco do ícone + arte, para a
    // moeda branca não sumir no fundo claro.
    await _render('assets/icon/splash.png', (c) {
      c.drawCircle(
        const Offset(_size / 2, _size / 2),
        _size * 0.36,
        Paint()..color = _petrol,
      );
      _drawArt(c, 0.8);
    });
  });
}
