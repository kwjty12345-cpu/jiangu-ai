import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../character/character_provider.dart';
import 'text_sanitizer.dart';

enum TtsSpeedPreset {
  slow('0.85x', 0.42),
  normal('1.0x', 0.50),
  fast('1.2x', 0.60);

  final String label;
  final double nativeRate;
  const TtsSpeedPreset(this.label, this.nativeRate);
}

@immutable
class TtsState {
  final bool autoPlay;
  final bool isMuted;
  final bool isSpeaking;
  final TtsSpeedPreset speed;

  const TtsState({
    this.autoPlay = true,
    this.isMuted = false,
    this.isSpeaking = false,
    this.speed = TtsSpeedPreset.normal,
  });

  TtsState copyWith({
    bool? autoPlay,
    bool? isMuted,
    bool? isSpeaking,
    TtsSpeedPreset? speed,
  }) {
    return TtsState(
      autoPlay: autoPlay ?? this.autoPlay,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      speed: speed ?? this.speed,
    );
  }
}

class TtsNotifier extends Notifier<TtsState> {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  Timer? _safetyTimeoutTimer;
  String _activeMood = 'idle';
  String _activeIntent = '';

  @override
  TtsState build() {
    _initEngine();
    ref.onDispose(() {
      _safetyTimeoutTimer?.cancel();
      _tts.stop();
    });
    return const TtsState();
  }

  Future<void> _initEngine() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.02);
      await _applyRate(state.speed);

      _tts.setStartHandler(() {
        state = state.copyWith(isSpeaking: true);
        ref
            .read(characterProvider.notifier)
            .startSpeaking(mood: _activeMood, intent: _activeIntent);
      });

      _tts.setCompletionHandler(_handleSpeechFinished);
      _tts.setCancelHandler(_handleSpeechFinished);
      _tts.setErrorHandler((_) => _handleSpeechFinished());
    } catch (_) {}
  }

  Future<void> _applyRate(TtsSpeedPreset preset) async {
    try {
      // Web Speech API 的基准语速与移动端不同，自动做平台归一化
      final double platformRate =
          kIsWeb ? (preset.nativeRate * 1.85).clamp(0.5, 1.3) : preset.nativeRate;
      await _tts.setSpeechRate(platformRate);
    } catch (_) {}
  }

  void _handleSpeechFinished() {
    _safetyTimeoutTimer?.cancel();
    if (!state.isSpeaking) return;
    state = state.copyWith(isSpeaking: false);
    ref
        .read(characterProvider.notifier)
        .stopSpeaking(mood: _activeMood, intent: _activeIntent);
  }

  /// 朗读指定文本（force: true 时忽略 autoPlay/isMuted 限制，用于用户手动点重播按钮）
  Future<void> speak(
    String rawText, {
    String mood = 'explaining',
    String intent = '',
    bool force = false,
  }) async {
    if (!force && (!state.autoPlay || state.isMuted)) return;

    final cleaned = TtsTextSanitizer.sanitizeForEnglishTts(rawText);
    if (cleaned.isEmpty) return;

    await _initEngine();
    await stop(resetCharacter: false);

    _activeMood = mood;
    _activeIntent = intent;

    // 立即驱动状态机开口说话（防止部分浏览器首字延迟）
    state = state.copyWith(isSpeaking: true);
    ref
        .read(characterProvider.notifier)
        .startSpeaking(mood: mood, intent: intent);

    // 浏览器 Web Speech 偶发吞掉 completionHandler，按词数设置安全兜底计时器
    final wordCount = cleaned.split(RegExp(r'\s+')).length;
    final estimatedMs = math.max(3000, (wordCount * 520 / (state.speed.nativeRate / 0.5)).round());
    _safetyTimeoutTimer?.cancel();
    _safetyTimeoutTimer = Timer(Duration(milliseconds: estimatedMs), () {
      _handleSpeechFinished();
    });

    try {
      await _tts.speak(cleaned);
    } catch (_) {
      _handleSpeechFinished();
    }
  }

  /// 立即停止当前朗读（切换页面、点击击鼓、重置对话时调用）
  Future<void> stop({bool resetCharacter = true}) async {
    _safetyTimeoutTimer?.cancel();
    try {
      await _tts.stop();
    } catch (_) {}

    if (state.isSpeaking) {
      state = state.copyWith(isSpeaking: false);
      if (resetCharacter) {
        ref
            .read(characterProvider.notifier)
            .stopSpeaking(mood: _activeMood, intent: _activeIntent);
      }
    }
  }

  void toggleMute() {
    final nextMuted = !state.isMuted;
    state = state.copyWith(isMuted: nextMuted);
    if (nextMuted) {
      stop();
    }
  }

  void setAutoPlay(bool enabled) {
    state = state.copyWith(autoPlay: enabled);
    if (!enabled) {
      stop();
    }
  }

  Future<void> setSpeed(TtsSpeedPreset preset) async {
    state = state.copyWith(speed: preset);
    await _applyRate(preset);
  }
}

final ttsProvider = NotifierProvider<TtsNotifier, TtsState>(TtsNotifier.new);