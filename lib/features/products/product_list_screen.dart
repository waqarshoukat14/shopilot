import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../data/models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    var filtered = products;
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((p) =>
        p.name.toLowerCase().contains(query) ||
        (p.sku != null && p.sku!.toLowerCase().contains(query)) ||
        (p.description != null && p.description!.toLowerCase().contains(query))
      ).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final productsAsync = ref.watch(productListNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.products),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () => ref.read(productListNotifierProvider.notifier).load(),
          ),
        ],
      ),
      body: productsAsync.when(
        data: (products) {
          _categories = ['All', ...products.map((p) => p.category).toSet()];
          final filtered = _filterProducts(products);
          return Column(
            children: [
              _buildSearchBar(),
              _buildCategoryChips(),
              // Product count summary
              if (products.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} of ${products.length} products',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (filtered.isNotEmpty)
                        Text(
                          'Total: ${formatPrice(filtered.fold<double>(0, (sum, p) => sum + (p.sellingPrice * p.quantity)), _currency(ref))}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.sm),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2,
                        title: l10n.noProductsFound,
                        subtitle: l10n.emptyState,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.read(productListNotifierProvider.notifier).load(),
                        child: ListView.builder(
                          padding: AppDimensions.listPadding,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _ProductCard(product: filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.fabGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/products/add'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: AppDimensions.screenPadding.copyWith(bottom: 0),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l10n.searchProducts,
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      padding: AppDimensions.listPadding,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                cat,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _currency(WidgetRef ref) {
  return ref.read(businessProvider).valueOrNull?.currency ?? 'PKR';
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Dismissible(
        key: Key(product.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete Product'),
              content: Text(
                  'Delete "${product.name}"? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          try {
            await ref
                .read(productListNotifierProvider.notifier)
                .deleteProduct(product.id);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting: $e')),
              );
            }
          }
        },
        child: AppCard(
          onTap: () => context.push('/products/${product.id}'),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.softGradient,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? AppImage(
                        url: product.imageUrl,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      )
                    : const Icon(Icons.inventory_2,
                        color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      product.category,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (product.description != null && product.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          product.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(product.sellingPrice, _currency(ref)),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Stock: ${product.quantity}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  if (product.isLowStock)
                    const AppBadge(
                        label: 'Low Stock',
                        color: AppColors.lowStock),
                  if (product.sku != null && product.sku!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        product.sku!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
