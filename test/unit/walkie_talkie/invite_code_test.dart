import 'package:flutter_test/flutter_test.dart';
import 'package:shmuki_talk/core/utils/invite_code_generator.dart';

void main() {
  group('InviteCodeGenerator', () {
    test('generate() should return a code matching prefix + 2 digit format', () {
      final code = InviteCodeGenerator.generate();
      expect(code.length, greaterThanOrEqualTo(5));
      expect(InviteCodeGenerator.isValidFormat(code), true);
    });

    test('generateFromName() with long name should produce valid code', () {
      final code = InviteCodeGenerator.generateFromName('משפחה');
      expect(code.length, greaterThanOrEqualTo(5));
    });

    test('generateFromName() with English name should produce valid code', () {
      final code = InviteCodeGenerator.generateFromName('Family');
      expect(InviteCodeGenerator.isValidFormat(code), true);
    });

    test('isValidFormat() should accept valid codes', () {
      expect(InviteCodeGenerator.isValidFormat('FAMILY7'), false); // 7 = 1 digit
      expect(InviteCodeGenerator.isValidFormat('FAMILY27'), true);
      expect(InviteCodeGenerator.isValidFormat('TRIP55'), true);
      expect(InviteCodeGenerator.isValidFormat('FAM99'), true);
    });

    test('isValidFormat() should reject invalid codes', () {
      expect(InviteCodeGenerator.isValidFormat(''), false);
      expect(InviteCodeGenerator.isValidFormat('12345'), false);
      expect(InviteCodeGenerator.isValidFormat('family27'), false); // lowercase
    });
  });
}
