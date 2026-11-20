import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'drum_audio_service.dart';

class DrumRippleEffect {
  final int id;
  final Offset localPosition;
  final DrumHitZone zone;
  final int createdAtMs;

  const DrumRippleEffect({
    required this.id,
    required this.localPosition,
    required this.zone,
    required this.createdAtMs,
  });

  String get onomatopoeia {
    switch (zone) {
      case DrumHitZone.centerHeavy:
        return 'Dong';
      case DrumHitZone.centerLight:
        return 'Thump';
      case DrumHitZone.rim:
        return 'Da';
      case DrumHitZone.bronzeBase:
        return 'Clang';
    }
  }

  Color get ringColor {
    switch (zone) {
      case DrumHitZone.centerHeavy:
        return kAntiqueGold;
      case DrumHitZone.centerLight:
        return const Color(0xFFC49E63);
      case DrumHitZone.rim:
        return kBronzePatina;
      case DrumHitZone.bronzeBase:
        return const Color(0xFFD98A7C);
    }
  }
}

class DrumRipplePainter extends CustomPainter {
  final List<DrumRippleEffect> ripples;
  final int nowMs;
  final Offset drumCenter;
  final double drumRadius;

  const DrumRipplePainter({
    required this.ripples,
    required this.nowMs,
    required this.drumCenter,
    required this.drumRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerGuidePaint = Paint()
      ..color = withAlphaColor(kAntiqueGold, 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(drumCenter, drumRadius * 0.46, centerGuidePaint);

    final rimGuidePaint = Paint()
      ..color = withAlphaColor(kBronzePatina, 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(drumCenter, drumRadius, rimGuidePaint);

    const int durationMs = 680;
    for (final effect in ripples) {
      final elapsed = nowMs - effect.createdAtMs;
      if (elapsed < 0 || elapsed > durationMs) continue;

      final double t = (elapsed / durationMs).clamp(0.0, 1.0);
      final double ease = 1.0 - (1.0 - t) * (1.0 - t);
      final double alpha = 1.0 - t;

      final mainPaint = Paint()
        ..color = withAlphaColor(effect.ringColor, alpha * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 * (1.0 - t * 0.6);
      canvas.drawCircle(
        effect.localPosition,
        16.0 + ease * 84.0,
        mainPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: effect.onomatopoeia,
          style: TextStyle(
            color: withAlphaColor(kXuanPaper, alpha),
            fontSize: effect.zone == DrumHitZone.centerHeavy ? 22 : 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            fontFamilyFallback: kSerifFontFallback,
            shadows: [
              Shadow(
                color: withAlphaColor(Colors.black, alpha * 0.85),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        effect.localPosition.dx - textPainter.width / 2,
        effect.localPosition.dy - 22.0 - ease * 54.0 - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant DrumRipplePainter oldDelegate) =>
      ripples.isNotEmpty || oldDelegate.ripples.isNotEmpty;
}