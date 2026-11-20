import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../theme/app_theme.dart';

class LacquerPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double opacity;

  const LacquerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.opacity = 0.94,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: withAlphaColor(kSurfaceLacquer, opacity),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _LacquerFramePainter(),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _LacquerFramePainter extends CustomPainter {
  const _LacquerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    final rng = math.Random(108);
    final grainPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 90; i++) {
      final gx = rng.nextDouble() * size.width;
      final gy = rng.nextDouble() * size.height;
      grainPaint.color = i.isEven
          ? withAlphaColor(kXuanPaper, 0.02)
          : withAlphaColor(Colors.black, 0.05);
      canvas.drawRect(Rect.fromLTWH(gx, gy, 1.5, 1.5), grainPaint);
    }

    final borderPaint = Paint()
      ..color = withAlphaColor(kAntiqueGold, 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(0.5), borderPaint);

    // Compact 8px key-fret corners at 4px inset: never overlaps 16px+ content padding
    final cornerPaint = Paint()
      ..color = withAlphaColor(kAntiqueGold, 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    _drawCornerFret(canvas, 4, 4, 1, 1, cornerPaint);
    _drawCornerFret(canvas, size.width - 4, 4, -1, 1, cornerPaint);
    _drawCornerFret(canvas, 4, size.height - 4, 1, -1, cornerPaint);
    _drawCornerFret(canvas, size.width - 4, size.height - 4, -1, -1, cornerPaint);
  }

  void _drawCornerFret(
    Canvas canvas,
    double ox,
    double oy,
    double sx,
    double sy,
    Paint paint,
  ) {
    final path = Path()
      ..moveTo(ox, oy + 8 * sy)
      ..lineTo(ox, oy)
      ..lineTo(ox + 8 * sx, oy)
      ..lineTo(ox + 8 * sx, oy + 3.5 * sy)
      ..lineTo(ox + 3.5 * sx, oy + 3.5 * sy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SealNameplate extends StatelessWidget {
  final Widget? leadingAvatar;

  const SealNameplate({super.key, this.leadingAvatar});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leadingAvatar != null) ...[
          leadingAvatar!,
          const SizedBox(width: 10),
        ] else ...[
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: kCinnabar,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: withAlphaColor(kXuanPaper, 0.72),
                  width: 0.9,
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
              child: const Text(
                AppStrings.sealMonogram,
                style: TextStyle(
                  color: kXuanPaper,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontFamilyFallback: kSerifFontFallback,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.guideName,
              style: TextStyle(
                color: kXuanPaper,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.15,
                fontFamilyFallback: kSerifFontFallback,
              ),
            ),
            Text(
              AppStrings.guideSubtitle,
              style: TextStyle(
                color: kAntiqueGold,
                fontSize: 11.5,
                height: 1.2,
                fontFamilyFallback: kSansFontFallback,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CountSealBadge extends StatelessWidget {
  final String label;
  final int streak;

  const CountSealBadge({
    super.key,
    required this.label,
    this.streak = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (streak >= 3) ...[
          Text(
            'Streak: $streak',
            style: const TextStyle(
              color: kAntiqueGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamilyFallback: kSansFontFallback,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: kCinnabar,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: withAlphaColor(kXuanPaper, 0.45),
              width: 0.9,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kXuanPaper,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamilyFallback: kSansFontFallback,
            ),
          ),
        ),
      ],
    );
  }
}

enum ChineseIconType {
  scroll,
  chronicle,
  drum,
  sound,
  soundMuted,
}

class ChineseLineIcon extends StatelessWidget {
  final ChineseIconType type;
  final double size;
  final Color color;

  const ChineseLineIcon({
    super.key,
    required this.type,
    this.size = 18,
    this.color = kAntiqueGold,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ChineseLineIconPainter(type: type, color: color),
    );
  }
}

class _ChineseLineIconPainter extends CustomPainter {
  final ChineseIconType type;
  final Color color;

  const _ChineseLineIconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    switch (type) {
      case ChineseIconType.scroll:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.72, h * 0.56),
            const Radius.circular(1.5),
          ),
          p,
        );
        canvas.drawLine(Offset(w * 0.14, h * 0.14), Offset(w * 0.14, h * 0.86), p);
        canvas.drawLine(Offset(w * 0.86, h * 0.14), Offset(w * 0.86, h * 0.86), p);
        canvas.drawLine(Offset(w * 0.34, h * 0.38), Offset(w * 0.66, h * 0.38), p);
        canvas.drawLine(Offset(w * 0.34, h * 0.58), Offset(w * 0.58, h * 0.58), p);
        break;
      case ChineseIconType.chronicle:
        for (final x in [0.24, 0.5, 0.76]) {
          canvas.drawLine(Offset(w * x, h * 0.18), Offset(w * x, h * 0.82), p);
        }
        canvas.drawLine(Offset(w * 0.16, h * 0.34), Offset(w * 0.84, h * 0.34), p);
        canvas.drawLine(Offset(w * 0.16, h * 0.66), Offset(w * 0.84, h * 0.66), p);
        break;
      case ChineseIconType.drum:
        canvas.drawLine(Offset(w * 0.5, h * 0.10), Offset(w * 0.5, h * 0.25), p);
        canvas.drawLine(Offset(w * 0.32, h * 0.14), Offset(w * 0.68, h * 0.14), p);
        canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.24, p);
        canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.10, p);
        canvas.drawLine(Offset(w * 0.5, h * 0.72), Offset(w * 0.5, h * 0.86), p);
        canvas.drawLine(Offset(w * 0.26, h * 0.88), Offset(w * 0.74, h * 0.88), p);
        break;
      case ChineseIconType.sound:
        final horn = Path()
          ..moveTo(w * 0.16, h * 0.38)
          ..lineTo(w * 0.34, h * 0.38)
          ..lineTo(w * 0.54, h * 0.22)
          ..lineTo(w * 0.54, h * 0.78)
          ..lineTo(w * 0.34, h * 0.62)
          ..lineTo(w * 0.16, h * 0.62)
          ..close();
        canvas.drawPath(horn, p);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.58, h * 0.5), radius: w * 0.16),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          p,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.58, h * 0.5), radius: w * 0.29),
          -math.pi / 3,
          2 * math.pi / 3,
          false,
          p,
        );
        break;
      case ChineseIconType.soundMuted:
        final horn = Path()
          ..moveTo(w * 0.16, h * 0.38)
          ..lineTo(w * 0.34, h * 0.38)
          ..lineTo(w * 0.54, h * 0.22)
          ..lineTo(w * 0.54, h * 0.78)
          ..lineTo(w * 0.34, h * 0.62)
          ..lineTo(w * 0.16, h * 0.62)
          ..close();
        canvas.drawPath(horn, p);
        canvas.drawLine(Offset(w * 0.68, h * 0.36), Offset(w * 0.88, h * 0.64), p);
        canvas.drawLine(Offset(w * 0.88, h * 0.36), Offset(w * 0.68, h * 0.64), p);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ChineseLineIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

class ScrollUnfurlTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const ScrollUnfurlTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
    );
    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: Tween<double>(begin: 0.90, end: 1.0).animate(curved),
        axis: Axis.vertical,
        axisAlignment: 1.0,
        child: child,
      ),
    );
  }
}