import 'package:flutter/material.dart';

import '../screens/profile/user_profile_screen.dart';

class ProfileLink extends StatelessWidget {
  final String userId;
  final String? username;
  final Widget child;
  const ProfileLink({
    super.key,
    required this.userId,
    this.username,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: userId, username: username),
        ),
      ),
      child: child,
    );
  }
}
