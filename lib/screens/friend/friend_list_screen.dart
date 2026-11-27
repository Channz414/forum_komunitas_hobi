import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/friend_provider.dart';
import '../../widgets/app_card.dart';
import '../../widgets/friend_button.dart';
import '../../widgets/user_avatar.dart';
import '../profile/user_profile_screen.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FriendProvider>();
    final friends = fp.friends;

    return Scaffold(
      appBar: AppBar(title: Text('Teman Saya (${friends.length})')),
      body: RefreshIndicator(
        onRefresh: fp.fetch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (fp.loading && fp.all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text('Belum punya teman', textAlign: TextAlign.center),
                ),
              )
            else
              for (final f in friends)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        userId: f.otherId,
                        username: f.otherUsername,
                      ),
                    ),
                  ),
                  child: AppCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        UserAvatar(
                          name: f.otherUsername,
                          imageUrl: f.otherAvatar,
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.otherUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FriendButton(
                          userId: f.otherId,
                          username: f.otherUsername,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
