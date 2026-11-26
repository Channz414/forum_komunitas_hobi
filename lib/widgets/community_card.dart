import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/community.dart';

String formatNumber(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');

class CommunityCard extends StatelessWidget {
  final Community community;
  final String? actionLabel; // null = komunitas milik sendiri (badge Pemilik)
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  const CommunityCard({
    super.key,
    required this.community,
    this.actionLabel,
    this.onAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final img = community.imageUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 6)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: img != null && img.isNotEmpty
                  ? Image.network(
                      img,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${formatNumber(community.memberCount)} Anggota',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    community.description ?? 'Belum ada deskripsi',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (actionLabel != null)
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.chip,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: AppColors.chipBorder),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            else if (community.isOwner)
              // tombol yang sama dengan Keluar/Gabung, hanya beda warna
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.tealText,
                  side: const BorderSide(color: AppColors.tealText),
                ),
                child: const Text(
                  'Pemilik',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 72,
    height: 72,
    color: const Color(0xFFD9D9D9),
    child: const Icon(Icons.groups, color: Colors.white),
  );
}
