class Community {
  final String id, name;
  final String? description;
  int memberCount;
  bool joined;

  Community({
    required this.id,
    required this.name,
    this.description,
    required this.memberCount,
    required this.joined,
  });

  factory Community.fromMap(Map<String, dynamic> m) => Community(
    id: m['id'],
    name: m['name'],
    description: m['description'],
    memberCount: (m['member_count'] as num).toInt(),
    joined: m['joined'] as bool,
  );
}
