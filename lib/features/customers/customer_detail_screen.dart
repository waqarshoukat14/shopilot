import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../data/models/customer.dart';
import '../../data/models/invoice.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../l10n/app_localizations.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final invoicesAsync = ref.watch(invoiceListNotifierProvider);
    final currency = ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.customerProfile)),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }
          return _buildContent(context, ref, customer, invoicesAsync, currency);
        },
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Customer customer, AsyncValue<List<Invoice>> invoicesAsync, String currency) {
    final l10n = AppLocalizations.of(context);
    final customerInvoices = invoicesAsync.hasValue
        ? invoicesAsync.value!.where((inv) => inv.customerId == customerId).toList()
        : <Invoice>[];

    return SingleChildScrollView(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: [
          _buildProfileCard(customer),
          const SizedBox(height: AppDimensions.md),
          _buildBalanceCard(customer, l10n, currency),
          const SizedBox(height: AppDimensions.md),
          _buildActionButtons(context, ref, customer, l10n, currency),
          const SizedBox(height: AppDimensions.md),
          _buildPurchaseHistory(context, customerInvoices, l10n, currency),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              customer.name[0].toUpperCase(),
              style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.xs),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.phone,
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (customer.email != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.email!,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Customer customer, AppLocalizations l10n, String currency) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _balanceStat('Total Purchases', formatPrice(customer.totalPurchases, currency), AppColors.textPrimary),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _balanceStat('Total Paid', formatPrice(customer.totalPaid, currency), AppColors.success),
              ),
              Container(width: 1, height: 40, color: AppColors.border),
              Expanded(
                child: _balanceStat(
                  l10n.outstanding,
                  formatPrice(customer.outstandingAmount, currency),
                  customer.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          if (customer.lastPurchase != null) ...[
            const Divider(color: AppColors.divider, height: AppDimensions.md),
            Text(
              '${l10n.lastPurchase}: ${customer.lastPurchase!.day}/${customer.lastPurchase!.month}/${customer.lastPurchase!.year}',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _balanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppDimensions.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Customer customer, AppLocalizations l10n, String currency) {
    return AppCard(
      child: Column(
        children: [
          AppButton(
            label: l10n.generateInvoice,
            icon: Icons.receipt_long,
            onPressed: () => context.push('/invoices/create'),
          ),
          if (customer.outstandingAmount > 0) ...[
            const SizedBox(height: AppDimensions.sm),
            AppButton(
              label: 'Record Payment',
              icon: Icons.payments,
              backgroundColor: AppColors.success,
              onPressed: () => _showRecordPaymentDialog(context, ref, customer, currency),
            ),
          ],
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.call,
                  isOutlined: true,
                  icon: Icons.phone,
                  onPressed: () => _launchCall(context, customer.phone),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: AppButton(
                  label: l10n.whatsApp,
                  isOutlined: true,
                  icon: Icons.chat,
                  onPressed: () => _launchWhatsApp(context, customer.phone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchCall(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer')),
      );
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone) async {
    // wa.me expects the number in international form with no leading '+'.
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  void _showRecordPaymentDialog(BuildContext context, WidgetRef ref, Customer customer, String currency) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Record Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding: ${formatPrice(customer.outstandingAmount, currency)}',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.md),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Amount received'),
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(hintText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final amount = double.tryParse(amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount')),
                        );
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      try {
                        await ref.read(customerListNotifierProvider.notifier).recordPayment(
                              customer.id,
                              amount,
                              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                            );
                        ref.invalidate(customerDetailProvider(customer.id));
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistory(BuildContext context, List<Invoice> invoices, AppLocalizations l10n, String currency) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.purchaseHistory, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppDimensions.sm),
          if (invoices.isEmpty)
            Text('No purchases yet', style: AppTextStyles.bodyMedium)
          else
            ...invoices.map((inv) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${inv.invoiceNumber}', style: AppTextStyles.bodyLarge),
                        Text(
                          '${inv.createdAt.day}/${inv.createdAt.month}/${inv.createdAt.year}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      formatPrice(inv.total, currency),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: inv.status == InvoiceStatus.paid ? AppColors.success : AppColors.warning,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
