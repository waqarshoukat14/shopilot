import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_image.dart';
import '../../data/models/invoice.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/services/invoice_pdf_service.dart';
import '../../l10n/app_localizations.dart';

String _currency(WidgetRef ref) {
  return ref.read(businessProvider).valueOrNull?.currency ?? 'PKR';
}

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _pdfService = InvoicePdfService();
  Customer? _selectedCustomer;
  final List<_InvoiceLineItem> _items = [];
  final _discountController = TextEditingController();
  final _taxController = TextEditingController();
  final _paidAmountController = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isGenerating = false;

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _discountPercent => double.tryParse(_discountController.text) ?? 0;
  double get _taxPercent => double.tryParse(_taxController.text) ?? 0;
  double get _discountAmount => _subtotal * _discountPercent / 100;
  double get _taxAmount => (_subtotal - _discountAmount) * _taxPercent / 100;
  double get _total => _subtotal - _discountAmount + _taxAmount;
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0;
  double get _dueAmount => (_total - _paidAmount) < 0 ? 0 : (_total - _paidAmount);

  Future<void> _generateInvoice() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product')));
      return;
    }
    // The API expects each item's productId as an integer — a product that
    // hasn't synced with the server yet (e.g. added while offline) only has
    // a local UUID id, and can't be referenced in a server-side invoice.
    for (final item in _items) {
      if (int.tryParse(item.product.id) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${item.product.name}" hasn\'t synced with the server yet. Try again once it appears in the product list.')),
        );
        return;
      }
    }

    setState(() => _isGenerating = true);
    try {
      final invoice = await ref.read(invoiceListNotifierProvider.notifier).createInvoice(
        customerId: _selectedCustomer?.id,
        items: _items.map((item) => {
          'productId': int.parse(item.product.id),
          'quantity': item.quantity,
          'unitPrice': item.product.sellingPrice,
        }).toList(),
        discount: _discountAmount,
        tax: _taxAmount,
        paidAmount: _paidAmount,
        paymentMethod: _paymentMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice generated successfully!'), backgroundColor: AppColors.success),
        );
        _showInvoiceActions(invoice);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showInvoiceActions(Invoice invoice) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: AppDimensions.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppDimensions.md),
            Text('Invoice #${invoice.invoiceNumber}', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimensions.md),
            AppButton(label: 'Preview PDF', icon: Icons.picture_as_pdf, onPressed: () {
              Navigator.pop(ctx);
              _pdfService.previewPdf(invoice);
            }),
            const SizedBox(height: AppDimensions.sm),
            AppButton(label: 'Share PDF', icon: Icons.share, isOutlined: true, onPressed: () {
              Navigator.pop(ctx);
              _pdfService.sharePdf(invoice);
            }),
            const SizedBox(height: AppDimensions.sm),
            AppButton(label: l10n.home, isOutlined: true, onPressed: () {
              Navigator.pop(ctx);
              context.go('/dashboard');
            }),
            const SizedBox(height: AppDimensions.md),
          ],
        ),
      ),
    );
  }

  void _addProduct(Product product) {
    final existing = _items.indexWhere((item) => item.product.id == product.id);
    showDialog(
      context: context,
      builder: (ctx) {
        int qty = 1;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(product.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Price: ${formatPrice(product.sellingPrice, _currency(ref))}', style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppDimensions.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                      onPressed: qty > 1 ? () => setDialogState(() => qty--) : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$qty',
                        style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: () => setDialogState(() => qty++),
                    ),
                  ],
                ),
                if (existing >= 0) ...[
                  const SizedBox(height: AppDimensions.sm),
                  Text('Already added: ${_items[existing].quantity} in cart', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (existing >= 0) {
                    setState(() => _items[existing] = _InvoiceLineItem(product: product, quantity: _items[existing].quantity + qty));
                  } else {
                    setState(() => _items.add(_InvoiceLineItem(product: product, quantity: qty)));
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existing >= 0 ? 'Update Quantity' : 'Add to Invoice'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customerListNotifierProvider);
    final productsAsync = ref.watch(productListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.invoice),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _items.clear();
                _selectedCustomer = null;
                _discountController.clear();
                _taxController.clear();
                _paidAmountController.clear();
              }),
              child: Text(l10n.cancel, style: const TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomerSection(customersAsync),
            const SizedBox(height: AppDimensions.md),
            _buildProductsSection(productsAsync),
            const SizedBox(height: AppDimensions.md),
            _buildItemsList(),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.md),
              _buildDiscountTaxSection(),
              const SizedBox(height: AppDimensions.md),
              _buildPaidAmountSection(),
              const SizedBox(height: AppDimensions.md),
              _buildPaymentMethod(),
              const SizedBox(height: AppDimensions.md),
              _buildTotalSection(),
              const SizedBox(height: AppDimensions.lg),
              AppButton(label: l10n.generateInvoice, isLoading: _isGenerating, onPressed: _generateInvoice),
            ],
            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection(AsyncValue<List<Customer>> customersAsync) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Customer', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.sm),
          customersAsync.when(
            data: (customers) => DropdownButtonFormField<Customer?>(
              initialValue: _selectedCustomer,
              isExpanded: true,
              decoration: const InputDecoration(hintText: 'Choose a customer...', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
              items: [
                const DropdownMenuItem<Customer?>(
                  value: null,
                  child: Text('Walk-in Customer', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                ...customers.map((c) => DropdownMenuItem<Customer?>(
                  value: c,
                  child: Text(
                    '${c.name} (${c.phone})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
              ],
              onChanged: (c) => setState(() => _selectedCustomer = c),
            ),
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(AsyncValue<List<Product>> productsAsync) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Products', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.sm),
          productsAsync.when(
            data: (products) => Column(
              children:              products.map((p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.softGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? AppImage(
                          url: p.imageUrl,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : const Icon(Icons.inventory_2, size: 20, color: AppColors.primary),
                ),
                title: Text(p.name, style: AppTextStyles.bodyLarge),
                subtitle: Text(formatPrice(p.sellingPrice, _currency(ref)), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                trailing: Text('Stock: ${p.quantity}', style: AppTextStyles.labelSmall),
                onTap: p.quantity > 0 ? () => _addProduct(p) : null,
              )).toList(),
            ),
            loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items (${_items.length})', style: AppTextStyles.titleLarge),
              Text(formatPrice(_subtotal, _currency(ref)), style: AppTextStyles.titleLarge),
            ],
          ),
          Divider(color: AppColors.border),
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name, style: AppTextStyles.bodyLarge),
                      Text('${formatPrice(item.product.sellingPrice, _currency(ref))} x ${item.quantity}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(formatPrice(item.total, _currency(ref)), style: AppTextStyles.labelLarge),
                const SizedBox(width: AppDimensions.sm),
                GestureDetector(
                  onTap: () => setState(() => _items.remove(item)),
                  child: const Icon(Icons.close, size: 20, color: AppColors.error),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDiscountTaxSection() {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discount %', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.sm),
                TextField(
                  controller: _discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tax %', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppDimensions.sm),
                TextField(
                  controller: _taxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidAmountSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Paid Amount', style: AppTextStyles.labelLarge),
          const SizedBox(height: AppDimensions.sm),
          TextField(
            controller: _paidAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: '0.00', prefixText: '${currencySymbol(_currency(ref))} '),
            onChanged: (_) => setState(() {}),
          ),
          if (_dueAmount > 0) ...[
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Remaining as credit: ${formatPrice(_dueAmount, _currency(ref))}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: PaymentMethod.values.map((method) {
              final selected = method == _paymentMethod;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: method == PaymentMethod.values.last ? 0 : AppDimensions.sm),
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = method),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.primaryGradient : null,
                        color: selected ? null : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        _methodLabel(method),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return AppCard(
      child: Column(
        children: [
          _totalRow('Subtotal', _subtotal),
          if (_discountPercent > 0) _totalRow('Discount ($_discountPercent%)', -_discountAmount, color: AppColors.error),
          if (_taxPercent > 0) _totalRow('Tax ($_taxPercent%)', _taxAmount, color: AppColors.warning),
          Divider(color: AppColors.border),
          _totalRow('Total', _total, isBold: true),
          _totalRow('Paid', _paidAmount, color: AppColors.success),
          if (_dueAmount > 0) _totalRow('Due', _dueAmount, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: (isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium).copyWith(fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
          Text(
            formatPrice(amount.abs(), _currency(ref)),
            style: (isBold ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium).copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _methodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
    }
  }
}

class _InvoiceLineItem {
  final Product product;
  int quantity;
  _InvoiceLineItem({required this.product, required this.quantity});
  double get total => product.sellingPrice * quantity;
}
