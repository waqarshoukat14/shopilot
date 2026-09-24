import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_image.dart';
import '../../data/models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListNotifierProvider);

    return productsAsync.when(
      data: (products) {
        final product = products.where((p) => p.id == productId).firstOrNull;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(child: Text('Product not found')),
          );
        }
        return _ProductDetailBody(product: product);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  final Product product;
  const _ProductDetailBody({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image ──
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: AppColors.softGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? AppImage(
                        url: product.imageUrl,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      )
                    : const Icon(Icons.inventory_2, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),

            // ── Name & Status ──
            Row(
              children: [
                Flexible(
                  child: Text(
                    product.name,
                    style: AppTextStyles.headlineMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (product.isLowStock) ...[
                  const SizedBox(width: AppDimensions.sm),
                  const AppBadge(label: 'Low Stock', color: AppColors.lowStock),
                ],
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            if (product.sku != null && product.sku!.isNotEmpty)
              Text(
                'SKU: ${product.sku}',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            if (product.description != null && product.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  product.description!,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            const SizedBox(height: AppDimensions.md),

            // ── Price Cards ──
            Row(
              children: [
                Expanded(
                  child: _PriceCard(
                    label: 'Purchase',
                    value: formatPrice(product.purchasePrice, currency),
                    icon: Icons.shopping_cart,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _PriceCard(
                    label: 'Selling',
                    value: formatPrice(product.sellingPrice, currency),
                    icon: Icons.sell,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            _PriceCard(
              label: 'Profit per Unit',
              value: formatPrice(product.profit, currency),
              icon: Icons.trending_up,
              color: product.profit >= 0 ? AppColors.success : AppColors.error,
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Details Card ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.sm),
                      Text('Details', style: AppTextStyles.titleMedium),
                    ],
                  ),
                  Divider(color: AppColors.divider),
                  _KeyValueRow('Category', product.category),
                  _KeyValueRow('Stock', '${product.quantity} ${product.unit ?? ''}'),
                  _KeyValueRow('Low Stock Limit', '${product.lowStockLimit}'),
                  _KeyValueRow(
                    'Added',
                    '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Stock Adjustment ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.sm),
                      Text('Stock Adjustment', style: AppTextStyles.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Remove',
                          isOutlined: true,
                          icon: Icons.remove,
                          onPressed: () => _showStockAdjustmentDialog(context, ref, -1),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: AppButton(
                          label: 'Add',
                          icon: Icons.add,
                          onPressed: () => _showStockAdjustmentDialog(context, ref, 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),

            // ── Action Buttons ──
            AppButton(
              label: 'Edit Product',
              icon: Icons.edit,
              onPressed: () => context.push('/products/edit/${product.id}'),
            ),
            const SizedBox(height: AppDimensions.sm),
            AppButton(
              label: 'Delete Product',
              isOutlined: true,
              icon: Icons.delete,
              onPressed: () => _confirmDelete(context, ref),
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(productListNotifierProvider.notifier)
                    .deleteProduct(product.id);
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStockAdjustmentDialog(BuildContext context, WidgetRef ref, int direction) {
    final controller = TextEditingController();
    final stockType = direction > 0 ? 'add' : 'remove';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(direction > 0 ? 'Add Stock' : 'Remove Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current stock: ${product.quantity}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              if (qty == null || qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid quantity')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ref
                    .read(productListNotifierProvider.notifier)
                    .adjustStock(product.id, qty, type: stockType);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

/// Compact price card with no overflow risk.
class _PriceCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PriceCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Key-value row that wraps instead of overflowing.
class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
