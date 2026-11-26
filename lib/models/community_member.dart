class CommunityMember {
  final String userId, username;
  final String? avatarUrl;
  final bool isOwner;

  CommunityMember({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.isOwner,
  });
}
