import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_strings.dart';
import 'character_state.dart';

class CharacterNotifier extends Notifier<CharacterState> {
  Timer? _mouthTimer;
  Timer? _resetTimer;

  @override
  CharacterState build() {
    ref.onDispose(() {
      _mouthTimer?.cancel();
      _resetTimer?.cancel();
    });
    return const CharacterState();
  }

  void _cancelTimers() {
    _mouthTimer?.cancel();
    _resetTimer?.cancel();
  }

  void setThinking() {
    _cancelTimers();
    state = state.copyWith(
      activity: CharacterActivity.thinking,
      pose: CharacterPose.thinking,
      isMouthOpen: false,
      clearBubble: true,
    );
  }

  void startSpeaking({String mood = 'explaining', String intent = ''}) {
    _cancelTimers();

    final bool isWelcomeOrName =
        intent == 'Default Welcome Intent' || intent == 'Get_User_Name';

    state = state.copyWith(
      activity: CharacterActivity.speaking,
      pose: isWelcomeOrName ? CharacterPose.bowing : CharacterPose.explaining,
      isMouthOpen: true,
      clearBubble: true,
    );

    _mouthTimer = Timer.periodic(const Duration(milliseconds: 240), (_) {
      state = state.copyWith(isMouthOpen: !state.isMouthOpen);
    });
  }

  void stopSpeaking({String mood = 'idle', String intent = ''}) {
    _mouthTimer?.cancel();

    final bool isWelcomeOrName =
        intent == 'Default Welcome Intent' || intent == 'Get_User_Name';

    if (mood == 'confused') {
      state = state.copyWith(
        activity: CharacterActivity.idle,
        pose: CharacterPose.thinking,
        isMouthOpen: false,
      );
      return;
    }

    if (isWelcomeOrName) {
      state = state.copyWith(
        activity: CharacterActivity.idle,
        pose: CharacterPose.bowing,
        isMouthOpen: false,
      );
      _resetTimer = Timer(const Duration(milliseconds: 2500), () {
        if (state.activity == CharacterActivity.idle) {
          state = state.copyWith(pose: CharacterPose.idle);
        }
      });
      return;
    }

    state = state.copyWith(
      activity: CharacterActivity.idle,
      pose: CharacterPose.explaining,
      isMouthOpen: false,
    );
    _resetTimer = Timer(const Duration(milliseconds: 600), () {
      if (state.activity == CharacterActivity.idle) {
        state = state.copyWith(pose: CharacterPose.idle);
      }
    });
  }

  void pokeCharacter() {
    if (state.activity == CharacterActivity.thinking ||
        state.activity == CharacterActivity.speaking) {
      return;
    }

    _resetTimer?.cancel();
    final nextPokeCount = state.pokeCount + 1;
    final reactions = AppStrings.pokeReactions;
    final line = reactions[nextPokeCount % reactions.length];
    final nextPose =
        nextPokeCount.isOdd ? CharacterPose.bowing : CharacterPose.thinking;

    state = state.copyWith(
      activity: CharacterActivity.poked,
      pose: nextPose,
      isMouthOpen: false,
      reactionBubble: line,
      pokeCount: nextPokeCount,
    );

    _resetTimer = Timer(const Duration(milliseconds: 2800), () {
      if (state.activity == CharacterActivity.poked) {
        state = state.copyWith(
          activity: CharacterActivity.idle,
          pose: CharacterPose.idle,
          clearBubble: true,
        );
      }
    });
  }

  /// Drum Practice uses the guide_drumming sprite (briefly bows on milestone streaks)
  void setGuidingDrum({bool excitedBow = false}) {
    _cancelTimers();
    state = state.copyWith(
      activity: CharacterActivity.drumming,
      pose: excitedBow ? CharacterPose.bowing : CharacterPose.drumming,
      isMouthOpen: false,
      clearBubble: true,
    );
  }

  void returnToIdle() {
    _cancelTimers();
    state = state.copyWith(
      activity: CharacterActivity.idle,
      pose: CharacterPose.idle,
      isMouthOpen: false,
      clearBubble: true,
    );
  }
}

final characterProvider =
    NotifierProvider<CharacterNotifier, CharacterState>(CharacterNotifier.new);