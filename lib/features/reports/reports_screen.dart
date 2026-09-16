import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../data/models/report.dart';
import '../../providers/report_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invoicesAsync = ref.watch(invoiceListNotifierProvider);
    final report = ref.watch(salesReportProvider);
    final chartData = ref.watch(dailySalesChartProvider);
    final topProducts = ref.watch(topSellingProductsProvider);

    final currency = ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.reports)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(invoiceListNotifierProvider.notifier).load();
          ref.read(productListNotifierProvider.notifier).load();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDimensions.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              invoicesAsync.when(
                data: (_) => _buildSummaryCards(report, l10n, currency),
                loading: () => const LoadingIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(l10n.dailySales, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppDimensions.sm),
              invoicesAsync.when(
                data: (_) => _buildBarChart(chartData, currency),
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, _) => AppCard(child: Text(l10n.noDataYet, style: AppTextStyles.bodyMedium)),
              ),
              const SizedBox(height: AppDimensions.lg),
              Text(l10n.topSellingProducts, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppDimensions.sm),
              invoicesAsync.when(
                data: (_) => topProducts.isEmpty
                    ? AppCard(child: Text(l10n.noDataYet, style: AppTextStyles.bodyMedium))
                    : _buildPieChart(topProducts, currency),
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, _) => AppCard(child: Text(l10n.noDataYet, style: AppTextStyles.bodyMedium)),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(SalesReport report, AppLocalizations l10n, String currency) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              title: l10n.dailySales,
              value: formatPrice(report.dailySales, currency),
              gradient: AppColors.primaryGradient,
            )),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: _StatCard(
              title: l10n.weeklySales,
              value: formatPrice(report.weeklySales, currency),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
            )),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            Expanded(child: _StatCard(
              title: l10n.monthlySales,
              value: formatPrice(report.monthlySales, currency),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              ),
            )),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: _StatCard(
              title: l10n.profit,
              value: formatPrice(report.dailyProfit, currency),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF06B6D4), Color(0xFF22D3EE)],
              ),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChart(List<ChartDataPoint> data, String currency) {
    if (data.isEmpty) {
      return AppCard(child: Text('No sales data yet', style: AppTextStyles.bodyMedium));
    }

    final maxValue = data.fold<double>(0, (max, p) => p.value > max ? p.value : max);

    return AppCard(
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    formatPrice(rod.toY, currency),
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(data[index].label, style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    '${currencySymbol(currency)} ${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: maxValue / 4,
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  gradient: AppColors.primaryGradient,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<ChartDataPoint> data, String currency) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
      AppColors.lowStock,
      AppColors.error,
    ];

    return AppCard(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.asMap().entries.map((entry) {
                  final total = data.fold<double>(0, (s, p) => s + p.value);
                  final percentage = total > 0 ? (entry.value.value / total * 100) : 0;
                  return PieChartSectionData(
                    color: colors[entry.key % colors.length],
                    value: entry.value.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          ...data.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(
                  color: colors[entry.key % colors.length],
                  borderRadius: BorderRadius.circular(2),
                )),
                const SizedBox(width: AppDimensions.sm),
                Expanded(child: Text(entry.value.label, style: AppTextStyles.bodyMedium)),
                Text(formatPrice(entry.value.value, currency), style: AppTextStyles.labelLarge),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Gradient gradient;

  const _StatCard({required this.title, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: AppDimensions.sm),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
