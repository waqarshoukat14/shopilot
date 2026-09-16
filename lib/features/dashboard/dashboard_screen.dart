import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/floating_ai_button.dart';
import '../../providers/report_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final dailyProfit = ref.watch(salesReportProvider).dailyProfit;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: true,
        title: Text(l10n.home, style: AppTextStyles.titleLarge),
        leading: Padding(
          padding: const EdgeInsets.only(left: AppDimensions.sm),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
            onPressed: () {},
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
              tooltip: l10n.settings,
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.read(productListNotifierProvider.notifier).load();
            ref.read(invoiceListNotifierProvider.notifier).load();
            ref.invalidate(businessProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
            AppDimensions.md,
            AppDimensions.md,
            AppDimensions.md,
            104,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats Overview ──
              // Revenue/outstanding/low-stock come from GET /api/dashboard/summary
              // (computed live server-side, so it can't drift between devices);
              // profit has no live server equivalent yet, so it stays sourced
              // from the local report and degrades gracefully to 0 until ready.
              summaryAsync.when(
                data: (summary) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Revenue',
                            value: formatPrice(summary.totalRevenue, _currency(ref)),
                            icon: Icons.trending_up,
                            gradient: AppColors.primaryGradient,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: _StatCard(
                            title: l10n.todayProfit,
                            value: formatPrice(dailyProfit, _currency(ref)),
                            icon: Icons.account_balance,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: l10n.outstanding,
                            value: formatPrice(summary.totalOutstanding, _currency(ref)),
                            icon: Icons.pending,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: _StatCard(
                            title: l10n.lowStock,
                            value: '${summary.lowStockCount}',
                            icon: Icons.inventory,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const LoadingShimmer(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // ── Quick Actions ──
              const SizedBox(height: AppDimensions.lg),
              _SectionHeader(title: l10n.quickActions),
              const SizedBox(height: AppDimensions.sm),
              _buildQuickActionsGrid(context, l10n),

              // ── Business Profile Section ──
              const SizedBox(height: AppDimensions.lg),
              _SectionHeader(
                title: 'Business Profile',
                actionLabel: 'View',
                onAction: () => context.push('/business-detail'),
              ),
              const SizedBox(height: AppDimensions.sm),
              _BusinessProfileRow(),

              // ── Products Section ──
              const SizedBox(height: AppDimensions.lg),
              _SectionHeader(
                title: 'Products',
                actionLabel: 'View All',
                onAction: () => context.push('/products'),
              ),
              const SizedBox(height: AppDimensions.sm),
              _ProductsRow(),

              // ── Low Stock Alerts ──
              const SizedBox(height: AppDimensions.lg),
              _LowStockSection(),

              // ── Recent Sales ──
              const SizedBox(height: AppDimensions.lg),
              _SectionHeader(title: l10n.recentSales),
              const SizedBox(height: AppDimensions.sm),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Text(l10n.noRecentSales, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      floatingActionButton: FloatingAiButton(
        onPressed: () => context.push('/ai-voice'),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, AppLocalizations l10n) {
    final actions = [
      _QuickAction(icon: Icons.receipt_long, label: l10n.createInvoice, onTap: () => context.push('/invoices/create')),
      _QuickAction(icon: Icons.add_box, label: l10n.addProduct, onTap: () => context.push('/products/add')),
      _QuickAction(icon: Icons.inventory_2, label: l10n.products, onTap: () => context.push('/products')),
      _QuickAction(icon: Icons.people, label: l10n.customers, onTap: () => context.push('/customers')),
      _QuickAction(icon: Icons.bar_chart, label: l10n.reports, onTap: () => context.push('/reports')),
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Wrap(
        spacing: AppDimensions.md,
        runSpacing: AppDimensions.md,
        children: actions.map((action) {
          final itemWidth = (MediaQuery.of(context).size.width -
              2 * AppDimensions.md -   // screen padding
              2 * AppDimensions.md -   // card padding
              2 * AppDimensions.md) / 3;
          return SizedBox(
            width: itemWidth,
            child: _QuickActionItem(action: action),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section Header ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;

  const _SectionHeader({required this.title, this.onAction, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(title, style: AppTextStyles.titleLarge),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}

// ── Business Profile Row ──
class _BusinessProfileRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(businessProvider);
    return businessAsync.when(
      data: (business) {
        if (business == null) {
          return AppCard(
            onTap: () => context.push('/business-setup'),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_business, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Set Up Your Shop', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Create your business profile to get started.',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          );
        }
        return AppCard(
          onTap: () => context.push('/business-detail'),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: business.logoUrl != null
                    ? AppImage(
                        url: business.logoUrl,
                        borderRadius: BorderRadius.circular(12),
                      )
                    : const Icon(Icons.store, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${business.type} • ${business.currency}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── Products Row ──
class _ProductsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListNotifierProvider);
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return AppCard(
            onTap: () => context.push('/products/add'),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_box, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add Your First Product', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Start adding products to your inventory.',
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          );
        }
        final totalValue = products.fold<double>(0, (sum, p) => sum + (p.sellingPrice * p.quantity));
        final lowStockCount = products.where((p) => p.isLowStock).length;
        return AppCard(
          onTap: () => context.push('/products'),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${products.length} Products in Inventory',
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Value: ${formatPrice(totalValue, _currency(ref))}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                        if (lowStockCount > 0) ...[
                          const SizedBox(width: AppDimensions.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lowStock.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$lowStockCount low stock',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.lowStock,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.xs),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action ──
class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});
}

class _QuickActionItem extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              gradient: AppColors.softGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(action.icon, size: AppDimensions.iconMd, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            action.label,
            style: AppTextStyles.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String _currency(WidgetRef ref) {
  return ref.read(businessProvider).valueOrNull?.currency ?? 'PKR';
}

// ── Loading Shimmer ──
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: AppCard(child: Container(height: 80, color: AppColors.primarySoft))),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: AppCard(child: Container(height: 80, color: AppColors.primarySoft))),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            Expanded(child: AppCard(child: Container(height: 80, color: AppColors.primarySoft))),
            const SizedBox(width: AppDimensions.sm),
            Expanded(child: AppCard(child: Container(height: 80, color: AppColors.primarySoft))),
          ],
        ),
      ],
    );
  }
}

// ── Low Stock Section ──
class _LowStockSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListNotifierProvider);
    return productsAsync.when(
      data: (products) {
        final lowStock = products.where((p) => p.isLowStock).toList();
        if (lowStock.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Low Stock Alerts',
              onAction: () => context.push('/products'),
              actionLabel: 'View All',
            ),
            const SizedBox(height: AppDimensions.sm),
            ...lowStock.take(5).map((product) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: AppCard(
                onTap: () => context.push('/products/${product.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.lowStock.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory, color: AppColors.lowStock, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Only ${product.quantity}${product.unit != null ? ' ${product.unit}' : ''} left',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.lowStock),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
