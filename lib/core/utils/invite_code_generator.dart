import 'dart:math';

abstract class InviteCodeGenerator {
  static const _prefixes = [
    'FAMILY',
    'TRIP',
    'FRIENDS',
    'TEAM',
    'GROUP',
    'SQUAD',
    'CLUB',
    'ROOM',
    'GANG',
    'CREW',
  ];

  static String generate() {
    final random = Random.secure();
    final prefix = _prefixes[random.nextInt(_prefixes.length)];
    final number = random.nextInt(90) + 10; // 10-99
    return '$prefix$number';
  }

  static String generateFromName(String name) {
    final cleaned = name
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z]'), '')
        .substring(0, name.length > 6 ? 6 : name.length);

    final random = Random.secure();
    final number = random.nextInt(90) + 10;

    if (cleaned.length >= 3) {
      return '$cleaned$number';
    }
    return generate();
  }

  static bool isValidFormat(String code) {
    return RegExp(r'^[A-Z]{3,6}[0-9]{2}$').hasMatch(code.toUpperCase());
  }
}
