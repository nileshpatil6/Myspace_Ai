import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PulseRingPainter extends CustomPainter {
  PulseRingPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
  }) : super(repaint: Listenable.merge([animation1, animation2, animation3]));

  final Animation<double> animation1;
  final Animation<double> animation2;
  final Animation<double> animation3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final minRadius = min(size.width, size.height) * 0.18;
    final maxRadius = min(size.width, size.height) * 0.48;

    _drawRing(canvas, center, animation1.value, minRadius, maxRadius, 2.5);
    _drawRing(canvas, center, animation2.value, minRadius, maxRadius, 1.5);
    _drawRing(canvas, center, animation3.value, minRadius, maxRadius, 1.0);
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double progress,
    double minRadius,
    double maxRadius,
    double strokeWidth,
  ) {
    final radius = minRadius + (maxRadius - minRadius) * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, paint);

    // Also draw a filled circle at full opacity center
    if (progress < 0.1) {
      final fillPaint = Paint()
        ..color = AppColors.orange.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, minRadius * 0.8, fillPaint);
    }
  }

  @override
  bool shouldRepaint(PulseRingPainter oldDelegate) => true;
}
