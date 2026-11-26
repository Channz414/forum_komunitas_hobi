class Post {
  final String id, userId, username, communityId, communityName;
  final String? imageUrl, avatarUrl, communityOwnerId;
  final DateTime createdAt;
  String content;
  DateTime? editedAt;
  int likeCount;
  int commentCount;
  bool likedByMe;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.communityId,
    required this.communityName,
    required this.content,
    this.imageUrl,
    this.avatarUrl,
    this.communityOwnerId,
    required this.createdAt,
    this.editedAt,
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
    avatarUrl: m['avatar_url'],
    communityOwnerId: m['community_owner_id'],
    createdAt: DateTime.parse(m['created_at']).toLocal(),
    editedAt: m['edited_at'] == null
        ? null
        : DateTime.parse(m['edited_at']).toLocal(),
    likeCount: (m['like_count'] as num).toInt(),
    commentCount: (m['comment_count'] as num).toInt(),
    likedByMe: m['liked_by_me'] as bool,
  );
}
