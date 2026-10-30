import 'package:flutter/material.dart';

import '../core/theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  const UserAvatar({super.key, required this.name, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2 ? name.substring(0, 2) : name;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.teal,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: AppColors.tealText,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
