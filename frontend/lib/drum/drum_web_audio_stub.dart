import 'dart:typed_data';

class PlatformWebAudioEngine {
  Future<void> resumeIfSuspended() async {}

  Future<void> loadWavBytes(String key, Uint8List bytes) async {}

  Future<void> play(
    String key, {
    double volume = 1.0,
    double playbackRate = 1.0,
    double pan = 0.0,
  }) async {}
}