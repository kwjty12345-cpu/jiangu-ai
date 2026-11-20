import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MuseumBackground extends StatelessWidget {
  const MuseumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/museum_bg.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/museum_bg.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/museum_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => const CustomPaint(
                    painter: BronzeHuiwenBackgroundPainter(),
                  ),
                ),
              ),
            ),
          ),
          // 压低展厅中央与四角明度，突出前景导游与漆面文字卡片
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 1.05,
                  colors: [
                    withAlphaColor(kBgXuanBlack, 0.32),
                    withAlphaColor(kBgXuanBlack, 0.68),
                    withAlphaColor(kBgXuanBlack, 0.88),
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BronzeHuiwenBackgroundPainter extends CustomPainter {
  const BronzeHuiwenBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.1,
        colors: [kBgSecondary, kBgXuanBlack],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final rng = math.Random(433);
    final patinaPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 55; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final radius = 40.0 + rng.nextDouble() * 140.0;
      patinaPaint.shader = RadialGradient(
        colors: [
          i % 3 == 0
              ? withAlphaColor(kBronzePatina, 0.08)
              : withAlphaColor(kAntiqueGold, 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
      canvas.drawCircle(Offset(cx, cy), radius, patinaPaint);
    }

    final fretPaint = Paint()
      ..color = withAlphaColor(kAntiqueGold, 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const double cellSize = 64.0;
    final int cols = (size.width / cellSize).ceil() + 1;
    final int rows = (size.height / cellSize).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _drawSingleHuiwen(canvas, c * cellSize, r * cellSize, cellSize, fretPaint);
      }
    }
  }

  void _drawSingleHuiwen(
    Canvas canvas,
    double x,
    double y,
    double s,
    Paint paint,
  ) {
    final double p1 = s * 0.14;
    final double p2 = s * 0.30;
    final double p3 = s * 0.44;
    final path = Path()
      ..moveTo(x + p1, y + s - p1)
      ..lineTo(x + p1, y + p1)
      ..lineTo(x + s - p1, y + p1)
      ..lineTo(x + s - p1, y + s - p1)
      ..lineTo(x + p2, y + s - p1)
      ..lineTo(x + p2, y + p2)
      ..lineTo(x + s - p2, y + p2)
      ..lineTo(x + s - p2, y + s - p2)
      ..lineTo(x + p3, y + s - p2)
      ..lineTo(x + p3, y + p3)
      ..lineTo(x + s - p3, y + p3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}