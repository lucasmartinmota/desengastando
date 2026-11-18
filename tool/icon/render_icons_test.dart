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
const _size = 1024.0;

const _billFront = Color(0xFFE3F6EF);
const _billMid = Color(0xFFC4EBDD);
const _billBack = Color(0xFFA3DDC9);
const _billInk = Color(0xFF0B5E57);
const _band = Color(0xFFF2C14E);
const _bandShade = Color(0xFFD9A93A);

/// Maço de notas: três cédulas empilhadas e levemente inclinadas, presas por
/// uma cinta amarela com o "D". [scale] encolhe a arte para as áreas
/// seguras (ícone adaptativo e tela de abertura).
void _drawArt(Canvas canvas, double scale) {
  final w = _size * 0.62 * scale;
  final h = _size * 0.34 * scale;
  final radius = Radius.circular(h * 0.12);

  canvas
    ..save()
    ..translate(_size / 2, _size / 2 + h * 0.08)
    ..rotate(-8 * math.pi / 180);

  // Cédulas de trás aparecem por cima, deslocadas.
  for (final (i, color) in [_billBack, _billMid].indexed) {
    final dy = -h * (0.26 - i * 0.13);
    final dx = w * (0.035 - i * 0.0175);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(dx, dy), width: w, height: h),
        radius,
      ),
      Paint()..color = color,
    );
  }

  // Cédula da frente
  final front = Rect.fromCenter(center: Offset.zero, width: w, height: h);
  final ink = Paint()
    ..color = _billInk.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * 0.035;
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(front, radius),
      Paint()..color = _billFront,
    )
    // Moldura interna
    ..drawRRect(
      RRect.fromRectAndRadius(
        front.deflate(h * 0.1),
        Radius.circular(h * 0.06),
      ),
      ink,
    );
  // Círculos dos cantos (como o valor impresso nas notas)
  for (final x in [-1.0, 1.0]) {
    canvas.drawCircle(
      Offset(x * w * 0.34, 0),
      h * 0.13,
      Paint()..color = _billInk.withValues(alpha: 0.28),
    );
  }

  // Cinta no meio, mais alta que as notas para "abraçar" o maço.
  final bandW = w * 0.3;
  final band = Rect.fromCenter(
    center: Offset(0, -h * 0.12),
    width: bandW,
    height: h * 1.42,
  );
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(
        band.shift(Offset(0, h * 0.03)),
        Radius.circular(h * 0.05),
      ),
      Paint()..color = _bandShade,
    )
    ..drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(h * 0.05)),
      Paint()..color = _band,
    );

  // "D" na cinta
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: TextAlign.center,
            fontFamily: 'IconFont',
          ),
        )
        ..pushStyle(
          ui.TextStyle(color: _billInk, fontSize: h * 0.78, height: 1),
        )
        ..addText('D');
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: bandW));
  canvas
    ..drawParagraph(
      paragraph,
      Offset(-bandW / 2, band.center.dy - paragraph.height / 2),
    )
    ..restore();
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
