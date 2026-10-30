class Community {
  final String id, name;
  final String? description;

  Community({required this.id, required this.name, this.description});

  factory Community.fromMap(Map<String, dynamic> m) =>
      Community(id: m['id'], name: m['name'], description: m['description']);
}
