class UserLite {
  final String id, username;
  final String? avatarUrl;
  UserLite({required this.id, required this.username, this.avatarUrl});

  factory UserLite.fromMap(Map<String, dynamic> m) => UserLite(
    id: m['id'],
    username: m['username'],
    avatarUrl: m['avatar_url'],
  );
}

class Friendship {
  final String id, otherId, otherUsername, status;
  final String? otherAvatar;
  final bool iAmRequester; // true = saya yang mengirim permintaan

  Friendship({
    required this.id,
    required this.otherId,
    required this.otherUsername,
    required this.status,
    this.otherAvatar,
    required this.iAmRequester,
  });

  bool get isAccepted => status == 'accepted';

  // "other" = lawan dari user yang sedang login
  factory Friendship.fromMap(Map<String, dynamic> m, String myId) {
    final mine = m['requester_id'] == myId;
    final other =
        (mine ? m['addressee'] : m['requester']) as Map<String, dynamic>;
    return Friendship(
      id: m['id'],
      status: m['status'],
      iAmRequester: mine,
      otherId: mine ? m['addressee_id'] : m['requester_id'],
      otherUsername: other['username'],
      otherAvatar: other['avatar_url'],
    );
  }
}
