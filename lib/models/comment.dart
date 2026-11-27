class Comment {
  final String id, userId, username, content;
  final String? avatarUrl, imageUrl;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    this.avatarUrl,
    this.imageUrl,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> m) => Comment(
    id: m['id'],
    userId: m['user_id'],
    username: m['profiles']['username'],
    avatarUrl: m['profiles']['avatar_url'],
    content: m['content'],
    imageUrl: m['image_url'],
    createdAt: DateTime.parse(m['created_at']).toLocal(),
  );
}
