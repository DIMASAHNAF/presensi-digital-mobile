import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_smkn1_beringin/core/models/session_model.dart';

void main() {
  test('network policy blocks only when whitelist active and denied', () {
    expect(const NetworkConfig(active: false, isAllowed: false).blocksScan, isFalse);
    expect(const NetworkConfig(active: true, isAllowed: true).blocksScan, isFalse);
    expect(const NetworkConfig(active: true, isAllowed: false).blocksScan, isTrue);
  });

  test('only open, unattended class session permits morning scan', () {
    expect(canScanMorningAttendance(hasSesi: true, sudahHadir: false, sessionType: 'KELAS'), isTrue);
    expect(canScanMorningAttendance(hasSesi: true, sudahHadir: true, sessionType: 'kelas'), isFalse);
    expect(canScanMorningAttendance(hasSesi: false, sudahHadir: false, sessionType: 'kelas'), isFalse);
    expect(canScanMorningAttendance(hasSesi: true, sudahHadir: false, sessionType: 'mapel'), isFalse);
    expect(canScanMorningAttendance(hasSesi: true, sudahHadir: false, sessionType: null), isFalse);
  });

  test('scan gate keeps server authority when policy is unknown', () {
    expect(scanPolicyBlocks(null, null), isFalse);
    expect(scanPolicyBlocks(true, null), isFalse);
    expect(scanPolicyBlocks(false, null), isTrue);
    expect(
      scanPolicyBlocks(true, const NetworkConfig(active: true, isAllowed: false)),
      isTrue,
    );
    expect(
      scanPolicyBlocks(false, const NetworkConfig(active: false, isAllowed: false)),
      isTrue,
    );
  });
}
