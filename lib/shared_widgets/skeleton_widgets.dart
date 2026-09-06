import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tradingpro/core/theme/app_colors.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray200,
      highlightColor: AppColors.gray100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class CoinCardSkeleton extends StatelessWidget {
  const CoinCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerSkeleton(width: 36, height: 36, borderRadius: 18),
              ShimmerSkeleton(width: 50, height: 20, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 12),
          const ShimmerSkeleton(width: 80, height: 14, borderRadius: 4),
          const SizedBox(height: 6),
          const ShimmerSkeleton(width: 110, height: 22, borderRadius: 6),
        ],
      ),
    );
  }
}

class TransactionItemSkeleton extends StatelessWidget {
  const TransactionItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(
        children: const [
          ShimmerSkeleton(width: 44, height: 44, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerSkeleton(width: 120, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerSkeleton(width: 80, height: 10, borderRadius: 4),
              ],
            ),
          ),
          ShimmerSkeleton(width: 70, height: 18, borderRadius: 6),
        ],
      ),
    );
  }
}

class TransactionListSkeleton extends StatelessWidget {
  final int count;
  const TransactionListSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const TransactionItemSkeleton(),
    );
  }
}
