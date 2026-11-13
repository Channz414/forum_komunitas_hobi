class Comment {
  final String id, userId, username, content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> m) => Comment(
    id: m['id'],
    userId: m['user_id'],
    username: m['profiles']['username'],
    content: m['content'],
    createdAt: DateTime.parse(m['created_at']).toLocal(),
  );
}
