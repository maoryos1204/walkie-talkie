class AppException implements Exception {
  final String message;
  final String? code;
  final Object? original;

  const AppException({
    required this.message,
    this.code,
    this.original,
  });

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code, super.original});
}

class RoomException extends AppException {
  const RoomException({required super.message, super.code, super.original});
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'שגיאת רשת', super.code, super.original});
}

class PermissionException extends AppException {
  const PermissionException({super.message = 'נדרשת הרשאה', super.code, super.original});
}

class WebRTCException extends AppException {
  const WebRTCException({super.message = 'שגיאה בחיבור הקול', super.code, super.original});
}
