import 'package:flutter/material.dart';

import '../core/theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? imageUrl;
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 22,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials = name.length >= 2 ? name.substring(0, 2) : name;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.teal,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Text(
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
