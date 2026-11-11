import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

class WebFaceResult {
  final bool isSupported;
  final bool detected;
  final double yaw;
  final double smile;

  const WebFaceResult({
    required this.isSupported,
    required this.detected,
    required this.yaw,
    required this.smile,
  });
}

class WebFaceDetector {
  static Future<bool> init() async {
    try {
      if (!web.window.has('faceEnrollEngine')) {
        return false;
      }
      final engine = web.window.getProperty<JSObject?>('faceEnrollEngine'.toJS);
      if (engine != null) {
        final initMethod = engine.getProperty<JSFunction?>('init'.toJS);
        if (initMethod != null) {
          final JSPromise resPromise = engine.callMethod('init'.toJS);
          await resPromise.toDart;
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  static Future<WebFaceResult> detect() async {
    try {
      if (!web.window.has('faceEnrollEngine')) {
        return const WebFaceResult(
          isSupported: false,
          detected: false,
          yaw: 0.0,
          smile: 0.0,
        );
      }
      final engine = web.window.getProperty<JSObject?>('faceEnrollEngine'.toJS);
      if (engine != null) {
        final JSPromise detectPromise = engine.callMethod('detect'.toJS);
        final JSAny? anyResult = await detectPromise.toDart;
        if (anyResult != null) {
          final JSObject result = anyResult as JSObject;
          final detected =
              result.getProperty<JSBoolean?>('detected'.toJS)?.toDart ?? false;
          final yaw =
              (result.getProperty<JSNumber?>('yaw'.toJS)?.toDartDouble ?? 0.0);
          final smile =
              (result.getProperty<JSNumber?>('smile'.toJS)?.toDartDouble ??
                  0.0);
          return WebFaceResult(
            isSupported: true,
            detected: detected,
            yaw: yaw,
            smile: smile,
          );
        }
      }
    } catch (_) {}

    return const WebFaceResult(
      isSupported: false,
      detected: false,
      yaw: 0.0,
      smile: 0.0,
    );
  }

  static Future<String> compressImage(
    String b64, {
    int maxDim = 480,
    double quality = 0.75,
  }) async {
    try {
      if (web.window.has('compressImageB64')) {
        final JSPromise compressPromise = web.window.callMethod(
          'compressImageB64'.toJS,
          b64.toJS,
          maxDim.toJS,
          quality.toJS,
        );
        final JSAny? res = await compressPromise.toDart;
        if (res != null) {
          return (res as JSString).toDart;
        }
      }
    } catch (_) {}
    return b64;
  }
}
