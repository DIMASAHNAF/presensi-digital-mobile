import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/features/splash/force_update_screen.dart';

void main() {
  group('ForceUpdateScreen platform handling', () {
    test('uses school download portal and generic label on iOS', () {
      expect(
        ForceUpdateScreen.resolveUpdateUrl(
          platform: TargetPlatform.iOS,
          isWeb: false,
        ),
        ForceUpdateScreen.defaultIosDownloadUrl,
      );
      expect(
        ForceUpdateScreen.resolveButtonLabel(
          platform: TargetPlatform.iOS,
          isWeb: false,
        ),
        'Unduh Versi Terbaru',
      );
    });

    test('keeps Play Store default on Android and respects explicit storeUrl', () {
      expect(
        ForceUpdateScreen.resolveUpdateUrl(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        ForceUpdateScreen.defaultAndroidStoreUrl,
      );
      expect(
        ForceUpdateScreen.resolveButtonLabel(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        'Buka Play Store',
      );
      expect(
        ForceUpdateScreen.resolveUpdateUrl(
          storeUrl: 'https://example.com/ios',
          platform: TargetPlatform.iOS,
          isWeb: false,
        ),
        'https://example.com/ios',
      );
    });
  });
}
