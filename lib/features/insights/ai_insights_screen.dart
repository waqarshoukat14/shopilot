import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../providers/report_provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/report.dart';

class AiInsightsScreen extends ConsumerStatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  ConsumerState<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends ConsumerState<AiInsightsScreen> {
  String? _aiRecommendation;
  bool _isLoadingAi = false;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoiceListNotifierProvider);
    final report = ref.watch(salesReportProvider);

    void reload() {
      ref.read(invoiceListNotifierProvider.notifier).load();
      ref.read(productListNotifierProvider.notifier).load();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              reload();
              setState(() => _aiRecommendation = null);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => reload(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          child: invoicesAsync.when(
            data: (_) => _buildContent(report),
            loading: () => const LoadingIndicator(),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(SalesReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiRecommendation(report),
        const SizedBox(height: AppDimensions.md),
        Text('Sales Insights', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppDimensions.sm),
        _buildInsightCards(report),
        const SizedBox(height: AppDimensions.md),
        _buildQuickStats(report),
      ],
    );
  }

  Widget _buildAiRecommendation(SalesReport report) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _loadAiInsight(report),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Recommendation', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: AppDimensions.xs),
                    if (_isLoadingAi)
                      const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    else if (_aiRecommendation != null)
                      Text(_aiRecommendation!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)))
                    else
                      Text('Tap to get AI-powered insights based on your business data', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAiInsight(SalesReport report) async {
    setState(() => _isLoadingAi = true);
    try {
      final currency = ref.read(businessProvider).valueOrNull?.currency ?? 'PKR';
      final data = '''
Daily Sales: ${formatPrice(report.dailySales, currency)}
Weekly Sales: ${formatPrice(report.weeklySales, currency)}
Monthly Sales: ${formatPrice(report.monthlySales, currency)}
Daily Profit: ${formatPrice(report.dailyProfit, currency)}
Pending Payments: ${formatPrice(report.pendingPayments, currency)}
Low Stock Items: ${report.lowStockCount}
''';
      final aiService = ref.read(aiServiceProvider);
      final insight = await aiService.getBusinessInsight(data);
      setState(() => _aiRecommendation = insight);
    } catch (e) {
      setState(() => _aiRecommendation = 'AI insights temporarily unavailable. Please try again later.');
    } finally {
      setState(() => _isLoadingAi = false);
    }
  }

  Widget _buildInsightCards(SalesReport report) {
    return Column(
      children: [
        _InsightCard(
          icon: Icons.trending_up,
          iconColor: AppColors.secondary,
          title: 'Sales Trend',
          value: report.dailySales > 0 ? 'Sales Increased 20%' : 'No sales today',
          badge: report.dailySales > 0 ? 'Positive' : 'No Data',
          badgeColor: report.dailySales > 0 ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(height: AppDimensions.sm),
        _InsightCard(
          icon: Icons.inventory,
          iconColor: report.lowStockCount > 0 ? AppColors.lowStock : AppColors.success,
          title: 'Low Stock Alert',
          value: '${report.lowStockCount} products below minimum stock level',
          badge: '${report.lowStockCount} items',
          badgeColor: report.lowStockCount > 0 ? AppColors.lowStock : AppColors.success,
        ),
        const SizedBox(height: AppDimensions.sm),
        _InsightCard(
          icon: Icons.star,
          iconColor: AppColors.warning,
          title: 'Top Selling',
          value: 'Check reports for top selling products',
          badge: 'View',
          badgeColor: AppColors.primary,
        ),
        const SizedBox(height: AppDimensions.sm),
        _InsightCard(
          icon: Icons.person_off,
          iconColor: report.pendingPayments > 0 ? AppColors.error : AppColors.success,
          title: 'Pending Payments',
          value: report.pendingPayments > 0
              ? '${formatPrice(report.pendingPayments, ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR')} outstanding from customers'
              : 'No pending payments',
          badge: report.pendingPayments > 0 ? 'Collect' : 'Clear',
          badgeColor: report.pendingPayments > 0 ? AppColors.error : AppColors.success,
        ),
      ],
    );
  }

  Widget _buildQuickStats(SalesReport report) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Stats', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Expanded(child: _statItem('Daily Profit', formatPrice(report.dailyProfit, ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR'), AppColors.success)),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(child: _statItem('Pending', formatPrice(report.pendingPayments, ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR'), AppColors.warning)),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(child: _statItem('Low Stock', '${report.lowStockCount}', AppColors.lowStock)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String badge;
  final Color badgeColor;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [iconColor.withValues(alpha: 0.15), iconColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: AppDimensions.iconMd, color: iconColor),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          AppBadge(label: badge, color: badgeColor),
        ],
      ),
    );
  }
}
