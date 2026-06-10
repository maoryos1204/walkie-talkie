import 'package:equatable/equatable.dart';

class QueueEntry extends Equatable {
  final String id;
  final String userId;
  final String displayName;
  final String? photoURL;
  final int priority;
  final DateTime joinedAt;
  final int position;

  const QueueEntry({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoURL,
    this.priority = 0,
    required this.joinedAt,
    required this.position,
  });

  bool get isAdminPriority => priority > 0;

  @override
  List<Object?> get props => [id, userId, priority, joinedAt, position];
}
