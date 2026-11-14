import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/models/user_model.dart';
import 'package:presensi_smkn1_beringin/features/auth/auth_router.dart';

UserModel _user({required bool hasChangedPassword, required bool isFaceEnrolled}) {
  return UserModel(
    id: 1,
    nisn: '1234567890',
    name: 'Test Siswa',
    username: 'testsiswa',
    isFaceEnrolled: isFaceEnrolled,
    hasChangedPassword: hasChangedPassword,
  );
}

void main() {
  group('resolveAuthStep', () {
    test('password belum diganti -> setPassword (prioritas tertinggi)', () {
      final step = resolveAuthStep(
        _user(hasChangedPassword: false, isFaceEnrolled: false),
      );
      expect(step, AuthStep.setPassword);
    });

    test('password sudah, wajah belum -> enrollFace', () {
      final step = resolveAuthStep(
        _user(hasChangedPassword: true, isFaceEnrolled: false),
      );
      expect(step, AuthStep.enrollFace);
    });

    test('password belum walau wajah sudah -> setPassword', () {
      final step = resolveAuthStep(
        _user(hasChangedPassword: false, isFaceEnrolled: true),
      );
      expect(step, AuthStep.setPassword);
    });

    test('keduanya selesai -> dashboard', () {
      final step = resolveAuthStep(
        _user(hasChangedPassword: true, isFaceEnrolled: true),
      );
      expect(step, AuthStep.dashboard);
    });
  });
}
