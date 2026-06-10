import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shmuki_talk/features/room/domain/entities/queue_entry.dart';

class QueueEntryModel extends QueueEntry {
  const QueueEntryModel({
    required super.id,
    required super.userId,
    required super.displayName,
    super.photoURL,
    super.priority,
    required super.joinedAt,
    required super.position,
  });

  factory QueueEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueEntryModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      photoURL: data['photoURL'] as String?,
      priority: data['priority'] as int? ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      position: data['position'] as int? ?? 99,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'priority': priority,
        'joinedAt': FieldValue.serverTimestamp(),
        'position': position,
      };
}
