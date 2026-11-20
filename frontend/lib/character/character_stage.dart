import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import 'character_provider.dart';
import 'character_state.dart';

class CharacterStage extends ConsumerStatefulWidget {
  final double maxHeight;
  final bool softBottomFade;

  const CharacterStage({
    super.key,
    required this.maxHeight,
    this.softBottomFade = true,
  });

  @override
  ConsumerState<CharacterStage> createState() => _CharacterStageState();
}

class _CharacterStageState extends ConsumerState<CharacterStage>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _pokeBounceController;
  Timer? _blinkTimer;
  bool _isBlinking = false;

  final Map<CharacterPose, String> _resolvedAssets = {
    CharacterPose.idle: 'assets/images/guide_idle.png',
    CharacterPose.explaining: 'assets/images/guide_explaining.png',
    CharacterPose.drumming: 'assets/images/guide_drumming.png',
  };
  bool _hasSpeakingOpenAsset = false;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _pokeBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 4400), (_) {
      if (!mounted) return;
      setState(() => _isBlinking = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _isBlinking = false);
      });
    });

    _discoverAndPrecacheAssets();
  }

  Future<void> _discoverAndPrecacheAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();

      String? findAsset(List<String> prefixes) {
        for (final prefix in prefixes) {
          for (final ext in ['.png', '.webp', '.jpg']) {
            final target = 'assets/images/$prefix$ext';
            if (allAssets.contains(target)) return target;
          }
        }
        return null;
      }

      final idlePath =
          findAsset(['guide_idle']) ?? 'assets/images/guide_idle.png';
      final explainingPath = findAsset(['guide_explaining']) ?? idlePath;
      final speakingOpenPath =
          findAsset(['guide_speaking_open', 'guide_talking', 'guide_open']);
      final thinkingPath =
          findAsset(['guide_thinking', 'guide_thoughtful', 'guide_confused']);
      final bowingPath =
          findAsset(['guide_bowing', 'guide_happy', 'guide_smile']);
      final drummingPath =
          findAsset(['guide_drumming', 'guide_drum', 'guide_excited']);

      if (!mounted) return;

      setState(() {
        _resolvedAssets[CharacterPose.idle] = idlePath;
        _resolvedAssets[CharacterPose.explaining] = explainingPath;
        _resolvedAssets[CharacterPose.speakingOpen] =
            speakingOpenPath ?? explainingPath;
        _resolvedAssets[CharacterPose.thinking] =
            thinkingPath ?? explainingPath;
        _resolvedAssets[CharacterPose.bowing] = bowingPath ?? idlePath;
        _resolvedAssets[CharacterPose.drumming] =
            drummingPath ?? explainingPath;
        _hasSpeakingOpenAsset = speakingOpenPath != null;
      });

      for (final path in _resolvedAssets.values.toSet()) {
        if (mounted) {
          precacheImage(AssetImage(path), context);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breathingController.dispose();
    _pokeBounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _pokeBounceController.forward(from: 0);
    ref.read(characterProvider.notifier).pokeCharacter();
  }

  String _pickEffectiveAssetPath(CharacterState charState) {
    if (charState.activity == CharacterActivity.speaking) {
      if (_hasSpeakingOpenAsset && charState.isMouthOpen) {
        return _resolvedAssets[CharacterPose.speakingOpen]!;
      }
      return _resolvedAssets[CharacterPose.explaining]!;
    }
    return _resolvedAssets[charState.pose] ??
        _resolvedAssets[CharacterPose.idle]!;
  }

  @override
  Widget build(BuildContext context) {
    final charState = ref.watch(characterProvider);
    final double spriteHeight = widget.maxHeight.clamp(220.0, 560.0);
    final String activeAssetPath = _pickEffectiveAssetPath(charState);

    Widget spriteImage = Image.asset(
      activeAssetPath,
      height: spriteHeight,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      gaplessPlayback: true,
    );

    if (widget.softBottomFade) {
      spriteImage = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.86, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: spriteImage,
      );
    }

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedBuilder(
            animation:
                Listenable.merge([_breathingController, _pokeBounceController]),
            builder: (context, child) {
              final double breathOffsetY = 3.0 * _breathingController.value;
              final double bounceCurve = Curves.elasticOut.transform(
                _pokeBounceController.isAnimating
                    ? _pokeBounceController.value
                    : 1.0,
              );
              final double pokeScale = _pokeBounceController.isAnimating
                  ? (0.95 + 0.05 * bounceCurve)
                  : 1.0;
              final double blinkScaleY = _isBlinking ? 0.993 : 1.0;

              return Transform.translate(
                offset: Offset(0, breathOffsetY),
                child: Transform.scale(
                  scaleX: pokeScale,
                  scaleY: pokeScale * blinkScaleY,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              );
            },
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: spriteHeight * 0.14,
                  child: Container(
                    width: spriteHeight * 0.78,
                    height: spriteHeight * 0.78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          withAlphaColor(kAntiqueGold, 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                spriteImage,
                if (charState.reactionBubble != null)
                  Positioned(
                    top: spriteHeight * 0.10,
                    right: -12,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Container(
                        key: ValueKey(charState.pokeCount),
                        constraints: const BoxConstraints(maxWidth: 230),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: withAlphaColor(kSurfaceLacquer, 0.96),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: withAlphaColor(kAntiqueGold, 0.75),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          charState.reactionBubble!,
                          style: const TextStyle(
                            color: kXuanPaper,
                            fontSize: 12.5,
                            height: 1.45,
                            fontFamilyFallback: kSerifFontFallback,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}