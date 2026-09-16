import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_badge.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);

    final plans = [
      _PlanData(
        name: 'Free',
        price: '\$0',
        period: 'forever',
        tier: SubscriptionTier.free,
        features: [
          'Up to 50 products',
          'Basic inventory management',
          'Basic reports',
          'Manual invoice creation',
        ],
        limitations: ['No AI insights', 'No voice commands', 'No PDF export'],
        isRecommended: false,
        color: AppColors.textSecondary,
      ),
      _PlanData(
        name: 'Pro',
        price: '\$9.99',
        period: '/month',
        tier: SubscriptionTier.pro,
        features: [
          'Unlimited products',
          'AI-powered insights',
          'Voice commands',
          'PDF invoice export',
          'Advanced reports & charts',
          'Priority support',
        ],
        limitations: [],
        isRecommended: true,
        color: AppColors.primary,
      ),
      _PlanData(
        name: 'Enterprise',
        price: '\$29.99',
        period: '/month',
        tier: SubscriptionTier.enterprise,
        features: [
          'Everything in Pro',
          'Multi-user access',
          'API access',
          'Custom branding',
          'Dedicated account manager',
          'Early access to new features',
        ],
        limitations: [],
        isRecommended: false,
        color: AppColors.secondary,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Plans')),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your plan', style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppDimensions.sm),
            Text('Upgrade to unlock AI features and more.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.lg),
            ...plans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.md),
              child: _PlanCard(
                plan: plan,
                isCurrent: subState.tier == plan.tier,
                onUpgrade: () {
                  if (plan.tier == SubscriptionTier.pro) {
                    ref.read(subscriptionProvider.notifier).upgradeToPro();
                  } else if (plan.tier == SubscriptionTier.enterprise) {
                    ref.read(subscriptionProvider.notifier).upgradeToEnterprise();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Upgraded to ${plan.name} plan!'),
                      backgroundColor: plan.color,
                    ),
                  );
                },
              ),
            )),
            const SizedBox(height: AppDimensions.md),
            _buildFeatureComparison(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureComparison(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Feature Comparison', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.md),
          _compareRow('Products', '50 max', 'Unlimited', 'Unlimited'),
          _compareRow('AI Insights', '—', '✓', '✓'),
          _compareRow('Voice Commands', '—', '✓', '✓'),
          _compareRow('PDF Export', '—', '✓', '✓'),
          _compareRow('Charts & Reports', 'Basic', 'Advanced', 'Advanced'),
          _compareRow('Multi-user', '—', '—', '✓'),
          _compareRow('API Access', '—', '—', '✓'),
          _compareRow('Support', 'Community', 'Priority', 'Dedicated'),
        ],
      ),
    );
  }

  Widget _compareRow(String feature, String free, String pro, String enterprise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(feature, style: AppTextStyles.bodyMedium)),
          Expanded(child: Text(free, style: AppTextStyles.labelSmall.copyWith(color: free == '✓' ? AppColors.success : AppColors.textSecondary), textAlign: TextAlign.center)),
          Expanded(child: Text(pro, style: AppTextStyles.labelSmall.copyWith(color: pro == '✓' ? AppColors.success : AppColors.textSecondary), textAlign: TextAlign.center)),
          Expanded(child: Text(enterprise, style: AppTextStyles.labelSmall.copyWith(color: enterprise == '✓' ? AppColors.success : AppColors.textSecondary), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _PlanData {
  final String name;
  final String price;
  final String period;
  final SubscriptionTier tier;
  final List<String> features;
  final List<String> limitations;
  final bool isRecommended;
  final Color color;

  _PlanData({
    required this.name,
    required this.price,
    required this.period,
    required this.tier,
    required this.features,
    required this.limitations,
    required this.isRecommended,
    required this.color,
  });
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final bool isCurrent;
  final VoidCallback onUpgrade;

  const _PlanCard({required this.plan, required this.isCurrent, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: isCurrent ? plan.color.withValues(alpha: 0.05) : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isRecommended)
            Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('RECOMMENDED', style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.name, style: AppTextStyles.titleLarge.copyWith(color: plan.color)),
              if (isCurrent) const AppBadge(label: 'Current', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(plan.price, style: AppTextStyles.displayLarge.copyWith(color: plan.color)),
              if (plan.period.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(plan.period, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: AppDimensions.iconSm, color: AppColors.success),
                const SizedBox(width: AppDimensions.sm),
                Expanded(child: Text(f, style: AppTextStyles.bodyMedium)),
              ],
            ),
          )),
          ...plan.limitations.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cancel, size: AppDimensions.iconSm, color: AppColors.textSecondary),
                const SizedBox(width: AppDimensions.sm),
                Expanded(child: Text(l, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary))),
              ],
            ),
          )),
          const SizedBox(height: AppDimensions.md),
          if (!isCurrent)
            AppButton(
              label: 'Upgrade to ${plan.name}',
              backgroundColor: plan.color,
              onPressed: onUpgrade,
            )
          else
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeight,
              child: OutlinedButton(
                onPressed: null,
                child: Text('Current Plan', style: AppTextStyles.labelLarge),
              ),
            ),
        ],
      ),
    );
  }
}
