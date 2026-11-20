import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'drum_web_audio_stub.dart'
    if (dart.library.js_interop) 'drum_web_audio_web.dart';

enum DrumHitZone {
  centerHeavy, // 鼓心重击（浑厚低音）
  centerLight, // 鼓心轻击（连击/滚奏）
  rim,         // 鼓边（清脆木声）
  bronzeBase,  // 青铜龙座（金石余韵）
}

@immutable
class DrumAudioState {
  final bool isReady;
  final bool isMuted;
  final bool isRolling;
  final int totalHits;
  final DrumHitZone? lastZone;

  const DrumAudioState({
    this.isReady = false,
    this.isMuted = false,
    this.isRolling = false,
    this.totalHits = 0,
    this.lastZone,
  });

  DrumAudioState copyWith({
    bool? isReady,
    bool? isMuted,
    bool? isRolling,
    int? totalHits,
    DrumHitZone? lastZone,
  }) {
    return DrumAudioState(
      isReady: isReady ?? this.isReady,
      isMuted: isMuted ?? this.isMuted,
      isRolling: isRolling ?? this.isRolling,
      totalHits: totalHits ?? this.totalHits,
      lastZone: lastZone ?? this.lastZone,
    );
  }
}

class DrumAudioNotifier extends Notifier<DrumAudioState> {
  final SoLoud _soloud = SoLoud.instance;
  final PlatformWebAudioEngine _webAudio = PlatformWebAudioEngine();
  final math.Random _rng = math.Random();

  AudioSource? _heavySource;
  AudioSource? _lightSource;
  AudioSource? _rimSource;
  AudioSource? _bronzeSource;

  bool _initializing = false;
  bool _leftHandNext = true;
  Timer? _rollTimer;

  @override
  DrumAudioState build() {
    initEngine();
    ref.onDispose(stopRoll);
    return const DrumAudioState();
  }

  /// 初始化低延迟音频引擎并预解码 4 个无压缩 WAV 建鼓采样
  Future<void> initEngine() async {
    if (state.isReady || _initializing) return;
    _initializing = true;

    try {
      if (kIsWeb) {
        final files = {
          'heavy': 'assets/audio/drum_heavy.wav',
          'light': 'assets/audio/drum_light.wav',
          'rim': 'assets/audio/drum_rim.wav',
          'bronze': 'assets/audio/gong_retreat.wav',
        };
        for (final entry in files.entries) {
          final byteData = await rootBundle.load(entry.value);
          await _webAudio.loadWavBytes(
            entry.key,
            byteData.buffer.asUint8List(),
          );
        }
        state = state.copyWith(isReady: true);
        debugPrint('[DrumAudio] Web Audio API initialized & 4 WAVs decoded.');
      } else {
        if (!_soloud.isInitialized) {
          await _soloud.init();
        }
        _heavySource ??= await _soloud.loadAsset('assets/audio/drum_heavy.wav');
        _lightSource ??= await _soloud.loadAsset('assets/audio/drum_light.wav');
        _rimSource ??= await _soloud.loadAsset('assets/audio/drum_rim.wav');
        _bronzeSource ??=
            await _soloud.loadAsset('assets/audio/gong_retreat.wav');
        state = state.copyWith(isReady: true);
        debugPrint('[DrumAudio] Native SoLoud initialized & 4 WAVs loaded.');
      }
    } catch (e) {
      debugPrint('[DrumAudio] Init failed: $e');
    } finally {
      _initializing = false;
    }
  }

  /// 触发一次真实的建鼓敲击（支持音高微抖动 + 左右手声像交替 + 多声道混音叠加）
  Future<void> playHit(
    DrumHitZone zone, {
    double velocity = 1.0,
    VoidCallback? onRollBeat,
  }) async {
    if (!state.isReady) {
      await initEngine();
    }

    final nextHits = state.totalHits + 1;
    state = state.copyWith(totalHits: nextHits, lastZone: zone);

    if (state.isMuted) return;

    String key;
    AudioSource? nativeTarget;
    double baseVol = velocity.clamp(0.35, 1.0);
    double pitchJitter = 0.025;

    switch (zone) {
      case DrumHitZone.centerHeavy:
        key = 'heavy';
        nativeTarget = _heavySource;
        pitchJitter = 0.022;
        break;
      case DrumHitZone.centerLight:
        key = 'light';
        nativeTarget = _lightSource ?? _heavySource;
        pitchJitter = 0.030;
        break;
      case DrumHitZone.rim:
        key = 'rim';
        nativeTarget = _rimSource;
        baseVol *= 0.88;
        pitchJitter = 0.038;
        break;
      case DrumHitZone.bronzeBase:
        key = 'bronze';
        nativeTarget = _bronzeSource;
        baseVol *= 0.45;
        pitchJitter = 0.015;
        break;
    }

    final double pan = _leftHandNext ? -0.14 : 0.14;
    final double handAccent = _leftHandNext ? 1.0 : 0.92;
    _leftHandNext = !_leftHandNext;

    final double speed =
        1.0 + (_rng.nextDouble() * 2.0 - 1.0) * pitchJitter;
    final double finalVol = (baseVol * handAccent).clamp(0.1, 1.0);

    try {
      if (kIsWeb) {
        await _webAudio.play(
          key,
          volume: finalVol,
          playbackRate: speed,
          pan: pan,
        );
      } else if (_soloud.isInitialized && nativeTarget != null) {
        final handle = await _soloud.play(
          nativeTarget,
          volume: finalVol,
          pan: pan,
        );
        _soloud.setRelativePlaySpeed(handle, speed);
      }
    } catch (e) {
      debugPrint('[DrumAudio] Play error: $e');
    }
  }

  /// 长按滚奏（双手轮槌连击）
  void startRoll({
    required DrumHitZone zone,
    VoidCallback? onTickVisual,
  }) {
    stopRoll();
    state = state.copyWith(isRolling: true);

    final DrumHitZone rollZone =
        zone == DrumHitZone.rim ? DrumHitZone.rim : DrumHitZone.centerLight;

    _rollTimer = Timer.periodic(const Duration(milliseconds: 115), (_) {
      playHit(rollZone, velocity: 0.72 + _rng.nextDouble() * 0.22);
      onTickVisual?.call();
    });
  }

  void stopRoll() {
    _rollTimer?.cancel();
    _rollTimer = null;
    if (state.isRolling) {
      state = state.copyWith(isRolling: false);
    }
  }

  void toggleMute() {
    final next = !state.isMuted;
    state = state.copyWith(isMuted: next);
    if (next) stopRoll();
  }

  void resetCounter() {
    stopRoll();
    state = state.copyWith(totalHits: 0);
  }
}

final drumAudioProvider =
    NotifierProvider<DrumAudioNotifier, DrumAudioState>(DrumAudioNotifier.new);