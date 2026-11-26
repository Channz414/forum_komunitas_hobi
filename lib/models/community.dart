class Community {
  final String id, name;
  final String? description, imageUrl, ownerId, ownerUsername;
  int memberCount;
  bool joined;
  final bool isOwner;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.ownerId,
    this.ownerUsername,
    required this.memberCount,
    required this.joined,
    required this.isOwner,
  });

  factory Community.fromMap(Map<String, dynamic> m) => Community(
    id: m['id'],
    name: m['name'],
    description: m['description'],
    imageUrl: m['image_url'],
    ownerId: m['created_by'],
    ownerUsername: m['owner_username'],
    memberCount: (m['member_count'] as num).toInt(),
    joined: m['joined'] as bool,
    isOwner: m['is_owner'] as bool,
  );
}
