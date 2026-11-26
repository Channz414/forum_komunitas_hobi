import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // di ListView horizontal tinggi anak dipaksa penuh, jadi diberi jarak
      // atas-bawah supaya chip tidak menempel ke tepi
      padding: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center, // teks tepat di tengah
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(24),
            // border selalu ada (transparan kalau tidak dipilih) supaya
            // ukuran chip tidak berubah saat dipilih
            border: Border.all(
              color: selected ? AppColors.chipBorder : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.2,
            ),
            textHeightBehavior: const TextHeightBehavior(
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ),
    );
  }
}
