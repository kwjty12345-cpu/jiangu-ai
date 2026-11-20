import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Future<void> openExternalUrlPlatform(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  globalContext.callMethod<JSAny?>(
    'open'.toJS,
    trimmed.toJS,
    '_blank'.toJS,
    'noopener,noreferrer'.toJS,
  );
}