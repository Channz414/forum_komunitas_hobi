class AppNotification {
  final String id, type, message;
  final String? postId, eventId;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.postId,
    this.eventId,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: m['id'].toString(),
    type: m['type'],
    message: m['message'],
    postId: m['post_id']?.toString(),
    eventId: m['event_id']?.toString(),
    createdAt: DateTime.parse(m['created_at']).toLocal(),
    isRead: m['is_read'] as bool,
  );
}
git add .