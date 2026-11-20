import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

class PlatformWebAudioEngine {
  JSObject? _ctx;
  final Map<String, JSObject> _buffers = {};

  void _ensureContext() {
    if (_ctx != null) return;
    final JSAny? ctor =
        globalContext.getProperty<JSAny?>('AudioContext'.toJS) ??
            globalContext.getProperty<JSAny?>('webkitAudioContext'.toJS);
    if (ctor != null && ctor.isA<JSFunction>()) {
      _ctx = (ctor as JSFunction).callAsConstructor<JSObject>();
    }
  }

  Future<void> resumeIfSuspended() async {
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;
    final JSAny? rawState = ctx.getProperty<JSAny?>('state'.toJS);
    if (rawState != null &&
        rawState.isA<JSString>() &&
        (rawState as JSString).toDart == 'suspended') {
      final promise = ctx.callMethod<JSPromise<JSAny?>>('resume'.toJS);
      await promise.toDart;
    }
  }

  Future<void> loadWavBytes(String key, Uint8List bytes) async {
    _ensureContext();
    final ctx = _ctx;
    if (ctx == null) return;

    final copy = Uint8List.fromList(bytes);
    final JSArrayBuffer arrayBuffer = copy.buffer.toJS;
    final promise = ctx.callMethod<JSPromise<JSAny?>>(
      'decodeAudioData'.toJS,
      arrayBuffer,
    );
    final audioBuffer = await promise.toDart;
    if (audioBuffer != null && audioBuffer.isA<JSObject>()) {
      _buffers[key] = audioBuffer as JSObject;
    }
  }

  Future<void> play(
    String key, {
    double volume = 1.0,
    double playbackRate = 1.0,
    double pan = 0.0,
  }) async {
    await resumeIfSuspended();
    final ctx = _ctx;
    final buffer = _buffers[key];
    if (ctx == null || buffer == null) return;

    final source = ctx.callMethod<JSObject>('createBufferSource'.toJS);
    source.setProperty('buffer'.toJS, buffer);

    final rateParam = source.getProperty<JSObject?>('playbackRate'.toJS);
    rateParam?.setProperty('value'.toJS, playbackRate.toJS);

    final gainNode = ctx.callMethod<JSObject>('createGain'.toJS);
    final gainParam = gainNode.getProperty<JSObject?>('gain'.toJS);
    gainParam?.setProperty('value'.toJS, volume.toJS);

    final destination = ctx.getProperty<JSObject>('destination'.toJS);

    if (ctx.hasProperty('createStereoPanner'.toJS).toDart) {
      final panner = ctx.callMethod<JSObject>('createStereoPanner'.toJS);
      final panParam = panner.getProperty<JSObject?>('pan'.toJS);
      panParam?.setProperty('value'.toJS, pan.toJS);

      source.callMethod<JSAny?>('connect'.toJS, gainNode);
      gainNode.callMethod<JSAny?>('connect'.toJS, panner);
      panner.callMethod<JSAny?>('connect'.toJS, destination);
    } else {
      source.callMethod<JSAny?>('connect'.toJS, gainNode);
      gainNode.callMethod<JSAny?>('connect'.toJS, destination);
    }

    source.callMethod<JSAny?>('start'.toJS, 0.toJS);
  }
}