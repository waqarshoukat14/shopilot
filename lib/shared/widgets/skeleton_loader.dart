import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final int itemCount;
  final SkeletonType type;

  const SkeletonLoader({super.key, this.itemCount = 4, this.type = SkeletonType.card});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppDimensions.listPadding,
      itemCount: itemCount,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: _buildItem(),
      ),
    );
  }

  Widget _buildItem() {
    switch (type) {
      case SkeletonType.card:
        return _cardShimmer();
      case SkeletonType.productCard:
        return _productCardShimmer();
      case SkeletonType.statsGrid:
        return _statsGridShimmer();
    }
  }

  Widget _cardShimmer() {
    return Container(
      height: 80,
      padding: AppDimensions.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _shimmerBox(48, 48, 8),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerBox(double.infinity, 14, 4),
                const SizedBox(height: AppDimensions.sm),
                _shimmerBox(120, 12, 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCardShimmer() {
    return Container(
      height: 100,
      padding: AppDimensions.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _shimmerBox(56, 56, 8),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerBox(180, 16, 4),
                const SizedBox(height: AppDimensions.sm),
                _shimmerBox(80, 12, 4),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _shimmerBox(50, 12, 4),
              const SizedBox(height: AppDimensions.sm),
              _shimmerBox(60, 20, 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsGridShimmer() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shimmerCard(80)),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: _shimmerCard(80)),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            Expanded(child: _shimmerCard(80)),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: _shimmerCard(80)),
          ],
        ),
      ],
    );
  }

  Widget _shimmerCard(double height) {
    return Container(
      height: height,
      padding: AppDimensions.cardPadding,
      decoration: BoxDecoration(
        gradient: AppColors.softGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(60, 10, 4),
          const Spacer(),
          _shimmerBox(80, 20, 4),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

enum SkeletonType { card, productCard, statsGrid }
