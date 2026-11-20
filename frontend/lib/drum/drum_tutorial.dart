import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_strings.dart';
import 'drum_audio_service.dart';

enum Onboarding { askName, ready }

final onboardingProvider = StateProvider<Onboarding>((_) => Onboarding.askName);
final userNameProvider = StateProvider<String>((_) => '');

enum SceneMode { chat, drumTutorial, drum }

final sceneModeProvider = StateProvider<SceneMode>((_) => SceneMode.chat);

enum DrumStep { intro, center, rim, roll, rhythm, free }

enum DrumSpotlightTarget {
  wholeDrum,
  center,
  rim,
  holdCenter,
  rhythmPattern,
  none,
}

class DrumStepInfo {
  final DrumStep step;
  final String title;
  final String defaultGuideText;
  final DrumSpotlightTarget target;
  final int needed;

  const DrumStepInfo({
    required this.step,
    required this.title,
    required this.defaultGuideText,
    required this.target,
    required this.needed,
  });
}

const Map<DrumStep, DrumStepInfo> kDrumStepConfigs = {
  DrumStep.intro: DrumStepInfo(
    step: DrumStep.intro,
    title: AppStrings.stepIntroTitle,
    defaultGuideText: AppStrings.stepCenterGuide,
    target: DrumSpotlightTarget.wholeDrum,
    needed: 1,
  ),
  DrumStep.center: DrumStepInfo(
    step: DrumStep.center,
    title: AppStrings.stepCenterTitle,
    defaultGuideText: AppStrings.stepCenterGuide,
    target: DrumSpotlightTarget.center,
    needed: 3,
  ),
  DrumStep.rim: DrumStepInfo(
    step: DrumStep.rim,
    title: AppStrings.stepRimTitle,
    defaultGuideText: AppStrings.stepRimGuide,
    target: DrumSpotlightTarget.rim,
    needed: 3,
  ),
  DrumStep.roll: DrumStepInfo(
    step: DrumStep.roll,
    title: AppStrings.stepRollTitle,
    defaultGuideText: AppStrings.stepRollGuide,
    target: DrumSpotlightTarget.holdCenter,
    needed: 2000,
  ),
  DrumStep.rhythm: DrumStepInfo(
    step: DrumStep.rhythm,
    title: AppStrings.stepRhythmTitle,
    defaultGuideText: AppStrings.stepRhythmGuide,
    target: DrumSpotlightTarget.rhythmPattern,
    needed: 4,
  ),
  DrumStep.free: DrumStepInfo(
    step: DrumStep.free,
    title: AppStrings.stepFreeTitle,
    defaultGuideText: '',
    target: DrumSpotlightTarget.none,
    needed: 0,
  ),
};

const List<bool> kRhythmPatternIsCenter = [true, true, false, true];

@immutable
class DrumTutorialState {
  final DrumStep step;
  final int progressCount;
  final int holdElapsedMs;
  final String guideSpeech;
  final bool hasCompletedTutorialOnce;
  final int sessionStrikes;
  final int currentCombo;
  final int maxCombo;
  final bool isDemoPlaying;
  final int demoBeatIndex;

  const DrumTutorialState({
    this.step = DrumStep.intro,
    this.progressCount = 0,
    this.holdElapsedMs = 0,
    this.guideSpeech = '',
    this.hasCompletedTutorialOnce = false,
    this.sessionStrikes = 0,
    this.currentCombo = 0,
    this.maxCombo = 0,
    this.isDemoPlaying = false,
    this.demoBeatIndex = -1,
  });

  DrumStepInfo get config => kDrumStepConfigs[step]!;

  String get hitsBadgeLabel {
    switch (step) {
      case DrumStep.center:
      case DrumStep.rim:
        return 'Hits: $progressCount/3';
      case DrumStep.roll:
        final sec = (holdElapsedMs / 1000.0).toStringAsFixed(1);
        return 'Hold: ${sec}s/2.0s';
      case DrumStep.rhythm:
        return 'Beats: $progressCount/4';
      case DrumStep.intro:
      case DrumStep.free:
        return 'Hits: $sessionStrikes';
    }
  }

  int get stepNumber {
    switch (step) {
      case DrumStep.intro:
        return 0;
      case DrumStep.center:
        return 1;
      case DrumStep.rim:
        return 2;
      case DrumStep.roll:
        return 3;
      case DrumStep.rhythm:
        return 4;
      case DrumStep.free:
        return 5;
    }
  }

  DrumTutorialState copyWith({
    DrumStep? step,
    int? progressCount,
    int? holdElapsedMs,
    String? guideSpeech,
    bool? hasCompletedTutorialOnce,
    int? sessionStrikes,
    int? currentCombo,
    int? maxCombo,
    bool? isDemoPlaying,
    int? demoBeatIndex,
  }) {
    return DrumTutorialState(
      step: step ?? this.step,
      progressCount: progressCount ?? this.progressCount,
      holdElapsedMs: holdElapsedMs ?? this.holdElapsedMs,
      guideSpeech: guideSpeech ?? this.guideSpeech,
      hasCompletedTutorialOnce:
          hasCompletedTutorialOnce ?? this.hasCompletedTutorialOnce,
      sessionStrikes: sessionStrikes ?? this.sessionStrikes,
      currentCombo: currentCombo ?? this.currentCombo,
      maxCombo: maxCombo ?? this.maxCombo,
      isDemoPlaying: isDemoPlaying ?? this.isDemoPlaying,
      demoBeatIndex: demoBeatIndex ?? this.demoBeatIndex,
    );
  }
}

class DrumTutorialNotifier extends Notifier<DrumTutorialState> {
  int _lastStrikeTimestampMs = 0;

  String get _realUserName => ref.read(userNameProvider).trim();

  @override
  DrumTutorialState build() => const DrumTutorialState();

  void prepareSession({required bool forceTutorial}) {
    _lastStrikeTimestampMs = 0;
    final bool runTutorial = forceTutorial || !state.hasCompletedTutorialOnce;
    final DrumStep startStep = runTutorial ? DrumStep.intro : DrumStep.free;

    state = state.copyWith(
      step: startStep,
      progressCount: 0,
      holdElapsedMs: 0,
      guideSpeech: runTutorial
          ? AppStrings.openingIntro(_realUserName)
          : AppStrings.openingFree(_realUserName),
      sessionStrikes: 0,
      currentCombo: 0,
      maxCombo: 0,
      isDemoPlaying: false,
      demoBeatIndex: -1,
    );
  }

  void startTutorialFromIntro() => _transitionTo(DrumStep.center);
  void restartTutorial() => _transitionTo(DrumStep.center);

  void skipToFreePlay() {
    state = state.copyWith(
      step: DrumStep.free,
      progressCount: 0,
      holdElapsedMs: 0,
      hasCompletedTutorialOnce: true,
      isDemoPlaying: false,
      demoBeatIndex: -1,
      guideSpeech: AppStrings.stepFreeGuide(_realUserName),
    );
  }

  void setDemoState({required bool playing, int beatIndex = -1}) {
    state = state.copyWith(isDemoPlaying: playing, demoBeatIndex: beatIndex);
  }

  void _transitionTo(DrumStep nextStep, {String? prefix}) {
    final info = kDrumStepConfigs[nextStep]!;
    final bool finishedAll = nextStep == DrumStep.free;
    final String body = finishedAll
        ? AppStrings.stepFreeGuide(_realUserName)
        : info.defaultGuideText;

    state = state.copyWith(
      step: nextStep,
      progressCount: 0,
      holdElapsedMs: 0,
      hasCompletedTutorialOnce:
          finishedAll ? true : state.hasCompletedTutorialOnce,
      isDemoPlaying: false,
      demoBeatIndex: -1,
      guideSpeech: prefix != null ? '$prefix $body' : body,
    );
  }

  void registerStrike(DrumHitZone zone) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final bool isComboChain =
        _lastStrikeTimestampMs > 0 && (now - _lastStrikeTimestampMs) <= 1350;
    _lastStrikeTimestampMs = now;

    final int nextStrikes = state.sessionStrikes + 1;
    final int nextCombo = isComboChain ? state.currentCombo + 1 : 1;
    final int nextMaxCombo =
        nextCombo > state.maxCombo ? nextCombo : state.maxCombo;

    state = state.copyWith(
      sessionStrikes: nextStrikes,
      currentCombo: nextCombo,
      maxCombo: nextMaxCombo,
    );

    final bool hitCenter =
        zone == DrumHitZone.centerHeavy || zone == DrumHitZone.centerLight;
    final bool hitRim = zone == DrumHitZone.rim;

    switch (state.step) {
      case DrumStep.intro:
        _transitionTo(DrumStep.center);
        if (hitCenter) registerStrike(zone);
        break;
      case DrumStep.center:
        if (hitCenter) {
          final next = state.progressCount + 1;
          if (next >= 3) {
            _transitionTo(
              DrumStep.rim,
              prefix: 'Deep and steady—that resonance carries well.',
            );
          } else {
            state = state.copyWith(
              progressCount: next,
              guideSpeech:
                  'Good! Deep cowhide tone ($next/3). Strike the center ${3 - next} more time${3 - next > 1 ? 's' : ''}.',
            );
          }
        } else {
          state = state.copyWith(
            guideSpeech:
                'That landed on the outer rim—aim slightly inward inside the golden ring for the deep center tone.',
          );
        }
        break;
      case DrumStep.rim:
        if (hitRim) {
          final next = state.progressCount + 1;
          if (next >= 3) {
            _transitionTo(
              DrumStep.roll,
              prefix: 'Crisp and clean wooden click.',
            );
          } else {
            state = state.copyWith(
              progressCount: next,
              guideSpeech:
                  'Clear rim tone ($next/3). Tap the outer green ring ${3 - next} more time${3 - next > 1 ? 's' : ''}.',
            );
          }
        } else {
          state = state.copyWith(
            guideSpeech:
                'That struck the center—move outward to the bronze-green ring along the wooden rim.',
          );
        }
        break;
      case DrumStep.roll:
        state = state.copyWith(
          guideSpeech:
              'Keep pressing down without lifting so both drumsticks alternate in a steady roll.',
        );
        break;
      case DrumStep.rhythm:
        if (state.isDemoPlaying) return;
        final int idx = state.progressCount;
        if (idx >= kRhythmPatternIsCenter.length) return;

        final bool expectCenter = kRhythmPatternIsCenter[idx];
        final bool matched =
            (expectCenter && hitCenter) || (!expectCenter && hitRim);

        if (matched) {
          final int nextIdx = idx + 1;
          if (nextIdx >= kRhythmPatternIsCenter.length) {
            _transitionTo(
              DrumStep.free,
              prefix: 'Spot on—your cadence matches the imperial court.',
            );
          } else {
            final String nextCue = kRhythmPatternIsCenter[nextIdx]
                ? AppStrings.beatCenter
                : AppStrings.beatRim;
            state = state.copyWith(
              progressCount: nextIdx,
              guideSpeech: 'Steady ($nextIdx/4). Next beat: $nextCue.',
            );
          }
        } else {
          final String expectedName =
              expectCenter ? AppStrings.beatCenter : AppStrings.beatRim;
          state = state.copyWith(
            progressCount: 0,
            guideSpeech:
                'Beat ${idx + 1} calls for $expectedName. Let us restart from beat 1: Dong, Dong, Da, Dong.',
          );
        }
        break;
      case DrumStep.free:
        _updateFreePlayCommentary(zone, nextCombo);
        break;
    }
  }

  void addRollHoldDuration(int deltaMs) {
    if (state.step != DrumStep.roll) return;
    final int nextHold = (state.holdElapsedMs + deltaMs).clamp(0, 2000);
    if (nextHold >= 2000) {
      _transitionTo(
        DrumStep.rhythm,
        prefix: 'Thunderous ceremonial roll!',
      );
    } else {
      final String sec = (nextHold / 1000.0).toStringAsFixed(1);
      state = state.copyWith(
        holdElapsedMs: nextHold,
        guideSpeech:
            'Hold steady (${sec}s / 2.0s)—hear both drumsticks roll in turn.',
      );
    }
  }

  void resetPartialHold() {
    if (state.step == DrumStep.roll && state.holdElapsedMs < 2000) {
      state = state.copyWith(
        holdElapsedMs: 0,
        guideSpeech:
            'Released slightly early—press and hold continuously for 2 full seconds.',
      );
    }
  }

  void _updateFreePlayCommentary(DrumHitZone zone, int combo) {
    if (combo == 15 || combo == 30) {
      final addr = _realUserName.isNotEmpty ? ', $_realUserName' : '';
      state = state.copyWith(
        guideSpeech:
            '$combo unbroken strikes$addr—such rhythm could command an entire ceremonial hall.',
      );
      return;
    }
    switch (zone) {
      case DrumHitZone.centerHeavy:
        state = state.copyWith(
          guideSpeech:
              'Drum Center (Dong)—deep cowhide resonance echoing across the hall.',
        );
        break;
      case DrumHitZone.centerLight:
        state = state.copyWith(
          guideSpeech:
              'Membrane Tap (Thump)—steady pulse gathering momentum between phrases.',
        );
        break;
      case DrumHitZone.rim:
        state = state.copyWith(
          guideSpeech:
              'Wooden Rim (Da)—crisp lacquered frame marking the measure.',
        );
        break;
      case DrumHitZone.bronzeBase:
        state = state.copyWith(
          guideSpeech:
              'Bronze Dragon Base (Clang)—a faint metallic ring from the lost-wax bronze stand.',
        );
        break;
    }
  }
}

final drumTutorialProvider =
    NotifierProvider<DrumTutorialNotifier, DrumTutorialState>(
  DrumTutorialNotifier.new,
);