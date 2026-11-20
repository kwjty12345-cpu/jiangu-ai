import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/character_provider.dart';
import '../core/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/lacquer_widgets.dart';
import 'drum_audio_service.dart';
import 'drum_ripple_painter.dart';
import 'drum_sticks.dart';
import 'drum_tutorial.dart';

class DrumStagePanel extends ConsumerStatefulWidget {
  const DrumStagePanel({super.key});

  @override
  ConsumerState<DrumStagePanel> createState() => _DrumStagePanelState();
}

class _DrumStagePanelState extends ConsumerState<DrumStagePanel>
    with TickerProviderStateMixin {
  late final AnimationController _recoilController;
  late final AnimationController _spotlightPulseController;
  late final DrumSticks _drumSticks;
  late final Ticker _rippleTicker;
  final FocusNode _keyboardFocusNode = FocusNode();

  final List<DrumRippleEffect> _ripples = [];
  int _nextRippleId = 0;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;
  double _featherSwayAngle = 0.0;

  Timer? _longPressHoldTimer;
  Timer? _holdProgressTimer;
  Timer? _demoSequenceTimer;

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _recoilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _spotlightPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);

    _drumSticks = DrumSticks(this);

    _rippleTicker = createTicker((_) {
      if (_ripples.isEmpty) return;
      final current = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _nowMs = current;
        _ripples.removeWhere((r) => current - r.createdAtMs > 700);
      });
    })..start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _keyboardFocusNode.requestFocus();
      ref.read(characterProvider.notifier).setGuidingDrum();
      ref.read(drumAudioProvider.notifier).initEngine();
    });
  }

  @override
  void dispose() {
    _longPressHoldTimer?.cancel();
    _holdProgressTimer?.cancel();
    _demoSequenceTimer?.cancel();
    _rippleTicker.dispose();
    _recoilController.dispose();
    _spotlightPulseController.dispose();
    _drumSticks.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _executeStrike({
    required Offset localPos,
    required Size boxSize,
    required DrumHitZone zone,
    bool? explicitLeftHand,
    bool countInTutorial = true,
  }) {
    final double normalizedX =
        ((localPos.dx - boxSize.width * 0.5) / (boxSize.width * 0.45))
            .clamp(-1.0, 1.0);

    _drumSticks.strike(leftHand: explicitLeftHand, normalizedX: normalizedX);
    ref.read(drumAudioProvider.notifier).playHit(zone);

    if (zone == DrumHitZone.centerHeavy) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _recoilController.forward(from: 0);
    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _nowMs = now;
      _featherSwayAngle = normalizedX * 0.02;
      _ripples.add(
        DrumRippleEffect(
          id: _nextRippleId++,
          localPosition: localPos,
          zone: zone,
          createdAtMs: now,
        ),
      );
    });

    if (countInTutorial) {
      ref.read(drumTutorialProvider.notifier).registerStrike(zone);
      final tut = ref.read(drumTutorialProvider);
      if (tut.step == DrumStep.free &&
          tut.currentCombo > 0 &&
          tut.currentCombo % 10 == 0) {
        ref.read(characterProvider.notifier).setGuidingDrum(excitedBow: true);
      } else {
        ref.read(characterProvider.notifier).setGuidingDrum(excitedBow: false);
      }
    }
  }

  DrumHitZone _resolveZoneFromPoint(Offset localPos, Size boxSize) {
    final Offset drumCenter = Offset(boxSize.width * 0.5, boxSize.height * 0.48);
    final double drumRadius = boxSize.width * 0.27;
    final double dist = (localPos - drumCenter).distance;
    final double normalizedDist = dist / drumRadius;

    if (normalizedDist <= 0.48) {
      return DrumHitZone.centerHeavy;
    } else if (normalizedDist <= 0.80) {
      return DrumHitZone.centerLight;
    } else if (normalizedDist <= 1.16) {
      return DrumHitZone.rim;
    } else if (localPos.dy > boxSize.height * 0.68) {
      return DrumHitZone.bronzeBase;
    } else {
      return DrumHitZone.centerLight;
    }
  }

  void _startContinuousRoll(Offset anchorPos, Size boxSize, DrumHitZone zone) {
    _holdProgressTimer?.cancel();
    final DrumHitZone rollZone =
        zone == DrumHitZone.rim ? DrumHitZone.rim : DrumHitZone.centerLight;

    ref.read(drumAudioProvider.notifier).startRoll(
          zone: rollZone,
          onTickVisual: () {
            if (!mounted) return;
            final jitter = Offset(
              anchorPos.dx + (math.Random().nextDouble() * 14 - 7),
              anchorPos.dy + (math.Random().nextDouble() * 10 - 5),
            );
            final double normX =
                ((jitter.dx - boxSize.width * 0.5) / (boxSize.width * 0.45))
                    .clamp(-1.0, 1.0);
            _drumSticks.strike(normalizedX: normX);
            _recoilController.forward(from: 0);
            final now = DateTime.now().millisecondsSinceEpoch;
            setState(() {
              _nowMs = now;
              _ripples.add(
                DrumRippleEffect(
                  id: _nextRippleId++,
                  localPosition: jitter,
                  zone: rollZone,
                  createdAtMs: now,
                ),
              );
            });
          },
        );

    _holdProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      ref.read(drumTutorialProvider.notifier).addRollHoldDuration(100);
    });
  }

  void _handlePointerDown(PointerDownEvent event, Size boxSize) {
    final zone = _resolveZoneFromPoint(event.localPosition, boxSize);
    _executeStrike(localPos: event.localPosition, boxSize: boxSize, zone: zone);

    _longPressHoldTimer?.cancel();
    _holdProgressTimer?.cancel();

    _longPressHoldTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _startContinuousRoll(event.localPosition, boxSize, zone);
    });
  }

  void _handlePointerRelease() {
    _longPressHoldTimer?.cancel();
    _holdProgressTimer?.cancel();
    ref.read(drumAudioProvider.notifier).stopRoll();
    ref.read(drumTutorialProvider.notifier).resetPartialHold();
  }

  void _playRhythmDemo(Size boxSize) {
    _demoSequenceTimer?.cancel();
    final tutNotifier = ref.read(drumTutorialProvider.notifier);
    tutNotifier.setDemoState(playing: true, beatIndex: 0);

    final Offset center = Offset(boxSize.width * 0.5, boxSize.height * 0.48);
    final double radius = boxSize.width * 0.27;
    int stepIdx = 0;

    void triggerDemoBeat(int idx) {
      if (!mounted) return;
      final bool isCenter = kRhythmPatternIsCenter[idx];
      final Offset targetPos =
          isCenter ? center : center.translate(radius * 0.94, 0);
      tutNotifier.setDemoState(playing: true, beatIndex: idx);
      _executeStrike(
        localPos: targetPos,
        boxSize: boxSize,
        zone: isCenter ? DrumHitZone.centerHeavy : DrumHitZone.rim,
        explicitLeftHand: idx.isEven,
        countInTutorial: false,
      );
    }

    triggerDemoBeat(0);
    _demoSequenceTimer = Timer.periodic(const Duration(milliseconds: 440), (t) {
      stepIdx++;
      if (!mounted || stepIdx >= kRhythmPatternIsCenter.length) {
        t.cancel();
        if (mounted) tutNotifier.setDemoState(playing: false, beatIndex: -1);
        return;
      }
      triggerDemoBeat(stepIdx);
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, Size boxSize) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final Offset center = Offset(boxSize.width * 0.5, boxSize.height * 0.48);
    final double radius = boxSize.width * 0.27;

    if (key == LogicalKeyboardKey.keyF) {
      _executeStrike(
        localPos: center.translate(-14, 0),
        boxSize: boxSize,
        zone: DrumHitZone.centerHeavy,
        explicitLeftHand: true,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ) {
      _executeStrike(
        localPos: center.translate(14, 0),
        boxSize: boxSize,
        zone: DrumHitZone.centerHeavy,
        explicitLeftHand: false,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD) {
      _executeStrike(
        localPos: center.translate(-radius * 0.92, 0),
        boxSize: boxSize,
        zone: DrumHitZone.rim,
        explicitLeftHand: true,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyK) {
      _executeStrike(
        localPos: center.translate(radius * 0.92, 0),
        boxSize: boxSize,
        zone: DrumHitZone.rim,
        explicitLeftHand: false,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildCompactMobileAvatar() {
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: kAntiqueGold, width: 1),
      ),
      child: Image.asset(
        'assets/images/guide_drumming.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/guide_drumming.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const Center(
            child: Text(
              AppStrings.sealMonogram,
              style: TextStyle(color: kAntiqueGold, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUniformActionButton({
    required String label,
    required VoidCallback? onTap,
    bool primary = false,
    String? tooltip,
  }) {
    final btn = InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: primary
              ? kCinnabar
              : withAlphaColor(kSurfaceElevated, 0.92),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: primary
                ? withAlphaColor(kAntiqueGold, 0.8)
                : withAlphaColor(kBronzePatina, 0.8),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? kXuanPaper : kTextSecondary,
            fontSize: 12.5,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w500,
            fontFamilyFallback: kSansFontFallback,
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 640;
    final tutState = ref.watch(drumTutorialProvider);

    final double drumBoxSize = isWide
        ? math.min(size.width * 0.36, size.height * 0.42).clamp(250.0, 380.0)
        : math.min(size.width * 0.72, size.height * 0.36).clamp(225.0, 310.0);
    final Size stageBox = Size(drumBoxSize, drumBoxSize);
    final double stickHeight = (drumBoxSize * 0.46).clamp(124.0, 178.0);
    // Closer stick spacing (~1.28x drum width) so drum + sticks + guide read as one cohesive group
    final double stickGroupWidth = drumBoxSize * 1.28;

    final Offset drumCenter = Offset(drumBoxSize * 0.5, drumBoxSize * 0.48);
    final double drumRadius = drumBoxSize * 0.27;

    final bool showHitsBadge =
        tutState.step != DrumStep.intro &&
        (tutState.step != DrumStep.free || tutState.sessionStrikes > 0);

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(node, event, stageBox),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Left Drum + Tightly Flanked Sticks + Centered Hint
          Align(
            alignment: isWide ? Alignment.centerLeft : Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(left: isWide ? 24 : 0),
              child: SizedBox(
                width: stickGroupWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: stickGroupWidth,
                      height: drumBoxSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          Positioned(
                            bottom: 6,
                            child: Container(
                              width: drumBoxSize * 0.62,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(185),
                                    blurRadius: 18,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (e) => _handlePointerDown(e, stageBox),
                            onPointerUp: (_) => _handlePointerRelease(),
                            onPointerCancel: (_) => _handlePointerRelease(),
                            child: AnimatedBuilder(
                              animation: _recoilController,
                              builder: (context, child) {
                                final double t = _recoilController.value;
                                final double recoilScale =
                                    _recoilController.isAnimating
                                        ? (1.0 - 0.02 * math.sin(t * math.pi))
                                        : 1.0;
                                final double sway = _recoilController.isAnimating
                                    ? _featherSwayAngle * math.sin(t * math.pi)
                                    : 0.0;
                                return Transform.rotate(
                                  angle: sway,
                                  alignment: Alignment.bottomCenter,
                                  child: Transform.scale(
                                    scale: recoilScale,
                                    child: child,
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: drumBoxSize,
                                height: drumBoxSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: drumBoxSize * 0.80,
                                      height: drumBoxSize * 0.80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            withAlphaColor(kAntiqueGold, 0.16),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'assets/images/jiangu_drum.png',
                                      width: drumBoxSize,
                                      height: drumBoxSize,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/jiangu_drum.webp',
                                        width: drumBoxSize,
                                        height: drumBoxSize,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    if (tutState.step != DrumStep.free)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: AnimatedBuilder(
                                            animation: _spotlightPulseController,
                                            builder: (_, __) => CustomPaint(
                                              painter: _TutorialSpotlightPainter(
                                                target: tutState.config.target,
                                                pulse: _spotlightPulseController
                                                    .value,
                                                holdProgress:
                                                    tutState.holdElapsedMs /
                                                        2000.0,
                                                drumCenter: drumCenter,
                                                drumRadius: drumRadius,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: CustomPaint(
                                          painter: DrumRipplePainter(
                                            ripples: _ripples,
                                            nowMs: _nowMs,
                                            drumCenter: drumCenter,
                                            drumRadius: drumRadius,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 4,
                            bottom: 8,
                            child: DrumstickWithRackView(
                              anim: _drumSticks.left,
                              isLeft: true,
                              height: stickHeight,
                              aimOffset: _drumSticks.leftAimOffset,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 8,
                            child: DrumstickWithRackView(
                              anim: _drumSticks.right,
                              isLeft: false,
                              height: stickHeight,
                              aimOffset: _drumSticks.rightAimOffset,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tutState.step == DrumStep.center ||
                        tutState.step == DrumStep.rim ||
                        tutState.step == DrumStep.roll)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: withAlphaColor(kSurfaceLacquer, 0.94),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: withAlphaColor(kAntiqueGold, 0.55),
                            ),
                          ),
                          child: Text(
                            _buildGestureHintText(tutState.step),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kXuanPaper,
                              fontSize: 12,
                              fontFamilyFallback: kSansFontFallback,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Clean Grid-Aligned Practice Card (16 / 12 / 8px spacing)
          LacquerPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: [Avatar + Name] | [Stage Title + Inline Progress Dots] | [Unified 36px Actions]
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SealNameplate(
                      leadingAvatar: isWide ? null : _buildCompactMobileAvatar(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            tutState.config.title,
                            style: const TextStyle(
                              color: kAntiqueGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamilyFallback: kSansFontFallback,
                            ),
                          ),
                          if (tutState.step != DrumStep.free)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(4, (i) {
                                final int stepIdx = i + 1;
                                final bool done = tutState.stepNumber > stepIdx;
                                final bool active =
                                    tutState.stepNumber == stepIdx;
                                return Container(
                                  margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                                  width: active ? 14 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: done
                                        ? kBronzePatina
                                        : (active
                                            ? kAntiqueGold
                                            : withAlphaColor(kTextMuted, 0.35)),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Right-aligned unified 36px action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tutState.step == DrumStep.intro)
                          // Intro stage: ONLY Start button (hide Retry & Skip)
                          _buildUniformActionButton(
                            label: AppStrings.start,
                            primary: true,
                            onTap: () => ref
                                .read(drumTutorialProvider.notifier)
                                .startTutorialFromIntro(),
                          )
                        else ...[
                          if (showHitsBadge) ...[
                            CountSealBadge(
                              label: tutState.hitsBadgeLabel,
                              streak: tutState.step == DrumStep.free
                                  ? tutState.currentCombo
                                  : 0,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (tutState.step == DrumStep.rhythm) ...[
                            _buildUniformActionButton(
                              label: tutState.isDemoPlaying
                                  ? AppStrings.listening
                                  : AppStrings.hearPattern,
                              primary: true,
                              onTap: tutState.isDemoPlaying
                                  ? null
                                  : () => _playRhythmDemo(stageBox),
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildUniformActionButton(
                            label: AppStrings.retry,
                            tooltip: AppStrings.replayTutorialTooltip,
                            onTap: () => ref
                                .read(drumTutorialProvider.notifier)
                                .restartTutorial(),
                          ),
                          if (tutState.step != DrumStep.free) ...[
                            const SizedBox(width: 8),
                            _buildUniformActionButton(
                              label: AppStrings.skip,
                              tooltip: AppStrings.skipTutorialTooltip,
                              onTap: () => ref
                                  .read(drumTutorialProvider.notifier)
                                  .skipToFreePlay(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 2: Full-width guide text (never squeezed by buttons)
                Text(
                  tutState.guideSpeech,
                  style: const TextStyle(
                    color: kXuanPaper,
                    fontSize: 16.5,
                    height: 1.6,
                    fontFamilyFallback: kSerifFontFallback,
                  ),
                ),

                if (tutState.step == DrumStep.rhythm) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(4, (i) {
                      final bool isCenter = kRhythmPatternIsCenter[i];
                      final bool completed = i < tutState.progressCount;
                      final bool isDemoHit = tutState.demoBeatIndex == i;
                      final bool isCurrentTarget = !tutState.isDemoPlaying &&
                          i == tutState.progressCount;

                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isDemoHit
                                ? withAlphaColor(kAntiqueGold, 0.36)
                                : (completed
                                    ? withAlphaColor(kBronzePatina, 0.34)
                                    : (isCurrentTarget
                                        ? withAlphaColor(kAntiqueGold, 0.16)
                                        : kSurfaceElevated)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: (isDemoHit || isCurrentTarget)
                                  ? kAntiqueGold
                                  : (completed
                                      ? kBronzePatina
                                      : withAlphaColor(kTextMuted, 0.35)),
                            ),
                          ),
                          child: Text(
                            isCenter
                                ? AppStrings.beatCenter
                                : AppStrings.beatRim,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: kXuanPaper,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamilyFallback: kSansFontFallback,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: withAlphaColor(kAntiqueGold, 0.25), height: 1),
                const SizedBox(height: 8),

                // Row 3: 3-column equal-width clickable/pressable control buttons
                Row(
                  children: [
                    Expanded(
                      child: _ZoneControlButton(
                        color: kAntiqueGold,
                        label: AppStrings.legendCenter,
                        highlighted: tutState.step == DrumStep.center ||
                            (tutState.step == DrumStep.rhythm &&
                                tutState.progressCount < 4 &&
                                kRhythmPatternIsCenter[tutState.progressCount]),
                        onDown: () => _executeStrike(
                          localPos: drumCenter,
                          boxSize: stageBox,
                          zone: DrumHitZone.centerHeavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ZoneControlButton(
                        color: kBronzePatina,
                        label: AppStrings.legendRim,
                        highlighted: tutState.step == DrumStep.rim ||
                            (tutState.step == DrumStep.rhythm &&
                                tutState.progressCount < 4 &&
                                !kRhythmPatternIsCenter[tutState.progressCount]),
                        onDown: () => _executeStrike(
                          localPos: drumCenter.translate(drumRadius * 0.94, 0),
                          boxSize: stageBox,
                          zone: DrumHitZone.rim,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ZoneControlButton(
                        color: kCinnabar,
                        label: AppStrings.legendHold,
                        highlighted: tutState.step == DrumStep.roll,
                        onDown: () {
                          _executeStrike(
                            localPos: drumCenter,
                            boxSize: stageBox,
                            zone: DrumHitZone.centerLight,
                          );
                          _startContinuousRoll(
                            drumCenter,
                            stageBox,
                            DrumHitZone.centerLight,
                          );
                        },
                        onUp: _handlePointerRelease,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildGestureHintText(DrumStep step) {
    switch (step) {
      case DrumStep.center:
        return _isMobilePlatform
            ? AppStrings.hintCenterMobile
            : AppStrings.hintCenterDesktop;
      case DrumStep.rim:
        return _isMobilePlatform
            ? AppStrings.hintRimMobile
            : AppStrings.hintRimDesktop;
      case DrumStep.roll:
        return AppStrings.hintRoll;
      default:
        return '';
    }
  }
}

/// Equal-width clickable/pressable bottom drum control cell
class _ZoneControlButton extends StatefulWidget {
  final Color color;
  final String label;
  final bool highlighted;
  final VoidCallback onDown;
  final VoidCallback? onUp;

  const _ZoneControlButton({
    required this.color,
    required this.label,
    required this.highlighted,
    required this.onDown,
    this.onUp,
  });

  @override
  State<_ZoneControlButton> createState() => _ZoneControlButtonState();
}

class _ZoneControlButtonState extends State<_ZoneControlButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.highlighted || _pressed || _hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _pressed = true);
          widget.onDown();
        },
        onPointerUp: (_) {
          setState(() => _pressed = false);
          widget.onUp?.call();
        },
        onPointerCancel: (_) {
          setState(() => _pressed = false);
          widget.onUp?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _pressed
                ? withAlphaColor(widget.color, 0.34)
                : (active
                    ? withAlphaColor(widget.color, 0.18)
                    : withAlphaColor(kSurfaceElevated, 0.65)),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active
                  ? widget.color
                  : withAlphaColor(kTextMuted, 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? kXuanPaper : kTextSecondary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    fontFamilyFallback: kSansFontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSpotlightPainter extends CustomPainter {
  final DrumSpotlightTarget target;
  final double pulse;
  final double holdProgress;
  final Offset drumCenter;
  final double drumRadius;

  const _TutorialSpotlightPainter({
    required this.target,
    required this.pulse,
    required this.holdProgress,
    required this.drumCenter,
    required this.drumRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (target == DrumSpotlightTarget.none ||
        target == DrumSpotlightTarget.wholeDrum) {
      return;
    }

    if (target == DrumSpotlightTarget.center ||
        target == DrumSpotlightTarget.holdCenter) {
      final double r = drumRadius * (0.44 + 0.04 * pulse);
      canvas.drawCircle(
        drumCenter,
        r,
        Paint()..color = withAlphaColor(kAntiqueGold, 0.14 + 0.08 * pulse),
      );
      canvas.drawCircle(
        drumCenter,
        r,
        Paint()
          ..color = withAlphaColor(kAntiqueGold, 0.78 + 0.22 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );

      if (target == DrumSpotlightTarget.holdCenter && holdProgress > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: drumCenter, radius: drumRadius * 0.56),
          -math.pi / 2,
          2 * math.pi * holdProgress.clamp(0.0, 1.0),
          false,
          Paint()
            ..color = kCinnabar
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 4.5,
        );
      }
    } else if (target == DrumSpotlightTarget.rim) {
      canvas.drawCircle(
        drumCenter,
        drumRadius * (0.96 + 0.03 * pulse),
        Paint()
          ..color = withAlphaColor(kBronzePatina, 0.8 + 0.2 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter oldDelegate) => true;
}