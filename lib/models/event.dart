class Event {
  final String id, communityId, communityName, createdBy, title;
  final String? description, location;
  final DateTime startsAt;
  int attendeeCount;
  bool joinedByMe;

  Event({
    required this.id,
    required this.communityId,
    required this.communityName,
    required this.createdBy,
    required this.title,
    this.description,
    this.location,
    required this.startsAt,
    required this.attendeeCount,
    required this.joinedByMe,
  });

  bool get isPast => startsAt.isBefore(DateTime.now());

  factory Event.fromMap(Map<String, dynamic> m) => Event(
    id: m['id'].toString(),
    communityId: m['community_id'].toString(),
    communityName: m['community_name'],
    createdBy: m['created_by'],
    title: m['title'],
    description: m['description'],
    location: m['location'],
    startsAt: DateTime.parse(m['starts_at']).toLocal(),
    attendeeCount: (m['attendee_count'] as num).toInt(),
    joinedByMe: m['joined_by_me'] as bool,
  );
}