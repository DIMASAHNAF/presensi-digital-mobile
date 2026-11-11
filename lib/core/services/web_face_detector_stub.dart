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
  static Future<bool> init() async => false;

  static Future<WebFaceResult> detect() async => const WebFaceResult(
        isSupported: false,
        detected: false,
        yaw: 0.0,
        smile: 0.0,
      );

  static Future<String> compressImage(
    String b64, {
    int maxDim = 480,
    double quality = 0.75,
  }) async =>
      b64;
}

