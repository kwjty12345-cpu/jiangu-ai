import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class DrumSticks {
  DrumSticks(TickerProvider vsync)
      : left = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 85),
          reverseDuration: const Duration(milliseconds: 135),
        ),
        right = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 85),
          reverseDuration: const Duration(milliseconds: 135),
        );

  final AnimationController left;
  final AnimationController right;

  bool _nextLeft = true;
  double leftAimOffset = 0.0;
  double rightAimOffset = 0.0;

  void strike({bool? leftHand, double normalizedX = 0.0}) {
    final bool useLeft = leftHand ?? _nextLeft;
    _nextLeft = !useLeft;

    if (useLeft) {
      leftAimOffset = (normalizedX * 0.20).clamp(-0.16, 0.22);
      left.forward(from: 0).then((_) {
        if (left.status == AnimationStatus.completed) {
          left.reverse();
        }
      });
    } else {
      rightAimOffset = (normalizedX * 0.20).clamp(-0.22, 0.16);
      right.forward(from: 0).then((_) {
        if (right.status == AnimationStatus.completed) {
          right.reverse();
        }
      });
    }
  }

  void dispose() {
    left.dispose();
    right.dispose();
  }
}

/// 带木质/青铜鼓槌架的鼓棒组件：待机插于架上，敲击时从架上抬起落向鼓面
class DrumstickWithRackView extends StatefulWidget {
  final Animation<double> anim;
  final bool isLeft;
  final double height;
  final double aimOffset;

  const DrumstickWithRackView({
    super.key,
    required this.anim,
    required this.isLeft,
    this.height = 175,
    this.aimOffset = 0.0,
  });

  @override
  State<DrumstickWithRackView> createState() => _DrumstickWithRackViewState();
}

class _DrumstickWithRackViewState extends State<DrumstickWithRackView> {
  String? _stickAsset;
  String? _rackAsset;

  @override
  void initState() {
    super.initState();
    _checkCustomAssets();
  }

  Future<void> _checkCustomAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();
      String? foundStick;
      String? foundRack;

      for (final ext in ['.png', '.webp']) {
        if (foundStick == null && assets.contains('assets/images/drumstick$ext')) {
          foundStick = 'assets/images/drumstick$ext';
        }
        if (foundRack == null &&
            assets.contains('assets/images/drumstick_rack$ext')) {
          foundRack = 'assets/images/drumstick_rack$ext';
        }
      }
      if (mounted && (foundStick != null || foundRack != null)) {
        setState(() {
          _stickAsset = foundStick;
          _rackAsset = foundRack;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 平时斜倚在鼓槌架凹槽上，敲击时抬离架面并向鼓心旋转落下
    final double restAngle = widget.isLeft ? -0.28 : 0.28;
    final double hitAngle = (widget.isLeft ? 0.36 : -0.36) + widget.aimOffset;
    final double liftX = widget.isLeft ? 28.0 : -28.0;
    const double liftY = -22.0;

    final Widget stickVisual = _stickAsset != null
        ? Transform.flip(
            flipX: !widget.isLeft,
            child: Image.asset(
              _stickAsset!,
              height: widget.height,
              fit: BoxFit.contain,
            ),
          )
        : CustomPaint(
            size: Size(widget.height * 0.22, widget.height),
            painter: const _LacquerDrumstickPainter(),
          );

    final Widget rackVisual = _rackAsset != null
        ? Image.asset(
            _rackAsset!,
            width: 56,
            height: 76,
            fit: BoxFit.contain,
          )
        : const CustomPaint(
            size: Size(54, 76),
            painter: _CarvedStickRackPainter(),
          );

    return IgnorePointer(
      child: SizedBox(
        width: 72,
        height: widget.height + 24,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. 底座投影（贴合展厅石台地平线）
            Positioned(
              bottom: 0,
              child: Container(
                width: 58,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(150),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // 2. 鼓棒本体（插于架上，击打时向上向内抬起挥动）
            Positioned(
              bottom: 18,
              child: AnimatedBuilder(
                animation: widget.anim,
                builder: (_, child) {
                  final double t = Curves.easeOut.transform(widget.anim.value);
                  final double angle = lerpDouble(restAngle, hitAngle, t)!;
                  final double dx = lerpDouble(0, liftX, t)!;
                  final double dy = lerpDouble(0, liftY, t)!;
                  return Transform.translate(
                    offset: Offset(dx, dy),
                    child: Transform.rotate(
                      angle: angle,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  );
                },
                child: stickVisual,
              ),
            ),

            // 3. 前景木质青铜鼓槌架（托住鼓棒底部，赋予真实物理着落）
            Positioned(
              bottom: 2,
              child: rackVisual,
            ),
          ],
        ),
      ),
    );
  }
}

/// 雕木镶铜鼓槌架（未放置 drumstick_rack.png 时自动绘制）
class _CarvedStickRackPainter extends CustomPainter {
  const _CarvedStickRackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final woodPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF2B1D16), Color(0xFF473023), Color(0xFF241711)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final goldStroke = Paint()
      ..color = withAlphaColor(kAntiqueGold, 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // 底座两级台座
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.84, w * 0.84, h * 0.14),
      const Radius.circular(2),
    );
    canvas.drawRRect(baseRect, woodPaint);
    canvas.drawRRect(baseRect, goldStroke);

    final subBase = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.74, w * 0.64, h * 0.10),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(subBase, woodPaint);
    canvas.drawRRect(subBase, goldStroke);

    // 两侧立柱 + 顶横梁托槽
    canvas.drawRect(Rect.fromLTWH(w * 0.24, h * 0.26, w * 0.12, h * 0.48), woodPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.64, h * 0.26, w * 0.12, h * 0.48), woodPaint);

    // 弧形鼓槌托槽（抱住棒身）
    final cradlePath = Path()
      ..moveTo(w * 0.16, h * 0.24)
      ..quadraticBezierTo(w * 0.50, h * 0.36, w * 0.84, h * 0.24)
      ..lineTo(w * 0.84, h * 0.36)
      ..quadraticBezierTo(w * 0.50, h * 0.46, w * 0.16, h * 0.36)
      ..close();
    canvas.drawPath(cradlePath, woodPaint);
    canvas.drawPath(cradlePath, goldStroke);

    // 底部青铜兽面纹细线点缀
    canvas.drawLine(
      Offset(w * 0.32, h * 0.56),
      Offset(w * 0.68, h * 0.56),
      goldStroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 程序化朱红描金鼓棒
class _LacquerDrumstickPainter extends CustomPainter {
  const _LacquerDrumstickPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width * 0.5;
    final double topY = size.height * 0.06;
    final double bottomY = size.height * 0.94;

    final shaftPath = Path()
      ..moveTo(cx - 3.0, topY + 12)
      ..lineTo(cx + 3.0, topY + 12)
      ..lineTo(cx + 5.4, bottomY - 12)
      ..lineTo(cx - 5.4, bottomY - 12)
      ..close();

    final shaftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF6B2019),
          kCinnabar,
          Color(0xFFC74F43),
          Color(0xFF5D1C16),
        ],
      ).createShader(Rect.fromLTWH(cx - 6, topY, 12, bottomY - topY));
    canvas.drawPath(shaftPath, shaftPaint);

    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        colors: [Color(0xFFEDE0C4), kAntiqueGold, Color(0xFF664E26)],
      ).createShader(Rect.fromCircle(center: Offset(cx, topY + 6), radius: 9));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, topY + 7), width: 13, height: 17),
      headPaint,
    );

    final goldRing = Paint()..color = kAntiqueGold;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, topY + 17), width: 8.5, height: 3.5),
      goldRing,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, bottomY - 18), width: 12, height: 4.5),
      goldRing,
    );
    canvas.drawCircle(Offset(cx, bottomY - 9), 5.8, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}