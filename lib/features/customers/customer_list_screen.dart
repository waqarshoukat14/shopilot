import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/app_button.dart';
import '../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/business_provider.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/phone_helper.dart';
import '../../l10n/app_localizations.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  static const _countryCode = '+92';

  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    final name = _nameController.text.trim();
    final nationalNumber = _phoneController.text.trim();
    if (name.isEmpty || nationalNumber.isEmpty) return;
    final phone = normalizePhone('$_countryCode$nationalNumber');

    final customer = Customer(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
    );

    try {
      await ref.read(customerListNotifierProvider.notifier).addCustomer(customer);
      _nameController.clear();
      _phoneController.clear();
      setState(() => _showAddForm = false);
    } catch (e) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Could Not Add Customer'),
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickContact() async {
    try {
      final status = await FlutterContacts.permissions.request(PermissionType.read);
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission denied')),
          );
        }
        return;
      }
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
      if (contact == null) return;
      setState(() {
        if (_nameController.text.trim().isEmpty && (contact.displayName ?? '').isNotEmpty) {
          _nameController.text = contact.displayName!;
        }
        if (contact.phones.isNotEmpty) {
          _phoneController.text = nationalDigits(contact.phones.first.number, defaultCountryCode: _countryCode);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open contacts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customersAsync = ref.watch(customerListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.customers)),
      body: customersAsync.when(
        data: (customers) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? customers
              : customers.where((c) =>
                  c.name.toLowerCase().contains(query) ||
                  c.phone.contains(query)).toList();

          return Column(
            children: [
              Container(
                padding: AppDimensions.screenPadding.copyWith(bottom: 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.searchCustomers,
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
              ),
              if (_showAddForm) _buildAddForm(),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(icon: Icons.people_outline, title: l10n.noCustomersFound, subtitle: 'Add your first customer to get started.')
                    : RefreshIndicator(
                        onRefresh: () async => ref.read(customerListNotifierProvider.notifier).load(),
                        child: ListView.builder(
                          padding: AppDimensions.listPadding,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _CustomerCard(customer: filtered[i]),
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
          onPressed: () => setState(() => _showAddForm = !_showAddForm),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(_showAddForm ? Icons.close : Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: AppDimensions.screenPadding,
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Customer name'),
          ),
          const SizedBox(height: AppDimensions.sm),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              prefixText: '$_countryCode ',
              hintText: '3001234567',
              suffixIcon: IconButton(
                icon: const Icon(Icons.contact_phone_outlined, color: AppColors.primary),
                tooltip: 'Pick from contacts',
                onPressed: _pickContact,
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [_NationalNumberFormatter()],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.cancel,
                  isOutlined: true,
                  onPressed: () => setState(() => _showAddForm = false),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: AppButton(label: 'Add Customer', backgroundColor: AppColors.secondary, onPressed: _addCustomer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends ConsumerWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(businessProvider).valueOrNull?.currency ?? 'PKR';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Dismissible(
        key: Key(customer.id),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete Customer'),
              content: Text('Delete "${customer.name}"? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) async {
          try {
            await ref.read(customerListNotifierProvider.notifier).deleteCustomer(customer.id);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting: $e')),
              );
            }
          }
        },
        child: AppCard(
          onTap: () => context.push('/customers/${customer.id}'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: AppTextStyles.titleMedium),
                    Text(customer.phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    if (customer.lastPurchase != null)
                      Text('Last: ${_formatDate(customer.lastPurchase!)}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              if (customer.outstandingAmount > 0)
                Text(
                  formatPrice(customer.outstandingAmount, currency),
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Restricts the phone field to digits only and drops a leading trunk '0',
/// since the field already shows a fixed country-code prefix — typing
/// "0304..." or "+92304..." both collapse to the same national digits.
class _NationalNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
