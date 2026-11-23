import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presensi_smkn1_beringin/core/services/theme_service.dart';

void main() {
  test('ThemeService defaults to ThemeMode.light matching Web portal', () async {
    SharedPreferences.setMockInitialValues({});
    await ThemeService.init();
    expect(ThemeService.mode.value, ThemeMode.light);

    await ThemeService.set(ThemeMode.dark);
    expect(ThemeService.mode.value, ThemeMode.dark);

    await ThemeService.init();
    expect(ThemeService.mode.value, ThemeMode.dark);
  });
}
