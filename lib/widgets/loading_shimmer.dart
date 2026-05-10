import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.isDarkMode
          ? const Color(0xFF2D2822)
          : const Color(0xFFE9DED0),
      highlightColor: context.isDarkMode
          ? const Color(0xFF3B342D)
          : const Color(0xFFF8F1E7),
      child: Column(
        children: List.generate(
          count,
          (index) => Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: context.appSurface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ),
    );
  }
}
