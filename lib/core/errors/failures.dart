import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'שגיאת רשת. בדוק את החיבור שלך.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'שגיאת שרת. נסה שוב מאוחר יותר.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'נדרשת הרשאה.']);
}

class RoomFailure extends Failure {
  const RoomFailure(super.message);
}

class RoomNotFoundFailure extends Failure {
  const RoomNotFoundFailure() : super('החדר לא נמצא.');
}

class RoomLockedFailure extends Failure {
  const RoomLockedFailure() : super('החדר נעול.');
}

class RoomFullFailure extends Failure {
  const RoomFullFailure() : super('החדר מלא.');
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('אין לך הרשאה לבצע פעולה זו.');
}

class WebRTCFailure extends Failure {
  const WebRTCFailure([super.message = 'שגיאה בחיבור הקול.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'שגיאת מטמון.']);
}
