import 'package:flutter/material.dart';

/// Barra de progresso determinada que cresce até [value] ao aparecer e
/// desliza quando o valor muda. Sem animação se o sistema pedir menos
/// movimento.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.value,
    required this.color,
    this.minHeight = 8,
    super.key,
  });

  /// De 0 a 1 (valores fora disso são limitados).
  final double value;
  final Color color;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? target : 0, end: target),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => LinearProgressIndicator(
        value: animated,
        minHeight: minHeight,
        borderRadius: BorderRadius.circular(minHeight / 2),
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}
