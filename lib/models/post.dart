class Post {
  final String id, userId, username, communityId, communityName, content;
  final String? imageUrl;
  final DateTime createdAt;
  int likeCount;
  final int commentCount;
  bool likedByMe;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.communityId,
    required this.communityName,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory Post.fromMap(Map<String, dynamic> m) => Post(
    id: m['id'],
    userId: m['user_id'],
    username: m['username'],
    communityId: m['community_id'],
    communityName: m['community_name'],
    content: m['content'],
    imageUrl: m['image_url'],
    createdAt: DateTime.parse(m['created_at']).toLocal(),
    likeCount: (m['like_count'] as num).toInt(),
    commentCount: (m['comment_count'] as num).toInt(),
    likedByMe: m['liked_by_me'] as bool,
  );
}
