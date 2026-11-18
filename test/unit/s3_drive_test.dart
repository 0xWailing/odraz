import 'package:flutter_test/flutter_test.dart';
import 'package:img_syncer/setting_storage_route.dart';
import 'package:img_syncer/state_model.dart';
import 'package:img_syncer/storageform/s3form.dart';

void main() {
  group('S3 drive selection', () {
    test('driveName maps Drive.s3 to "S3"', () {
      expect(driveName[Drive.s3], 'S3');
    });

    test('getDrive("S3") returns Drive.s3', () {
      expect(getDrive('S3'), Drive.s3);
    });

    test('getDrive on an unknown name still falls back to SMB', () {
      expect(getDrive('nonsense'), Drive.smb);
    });
  });

  group('defaultPathStyleFor', () {
    test('is off for AWS endpoints', () {
      expect(defaultPathStyleFor('s3.amazonaws.com'), isFalse);
      expect(defaultPathStyleFor('s3.us-east-1.amazonaws.com'), isFalse);
    });

    test('is on for custom endpoints', () {
      expect(defaultPathStyleFor('s3.us-west-004.backblazeb2.com'), isTrue);
      expect(defaultPathStyleFor('localhost:9000'), isTrue);
      expect(defaultPathStyleFor(''), isTrue);
    });
  });
}
