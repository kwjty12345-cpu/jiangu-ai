import 'external_link_opener_stub.dart'
    if (dart.library.js_interop) 'external_link_opener_web.dart';

Future<void> openExternalUrl(String url) => openExternalUrlPlatform(url);