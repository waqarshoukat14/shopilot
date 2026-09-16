import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/customer.dart';
import '../data/services/api_service.dart';
import 'auth_provider.dart';

/// Customer detail with money totals (totalPurchases, totalPaid,
/// outstandingAmount) via GET /api/customers/{id}. No token → null.
final customerDetailProvider = FutureProvider.family<Customer?, String>((ref, id) async {
  final token = ref.watch(apiTokenProvider);
  final hasApiToken = token != null && token.isNotEmpty && !token.startsWith('session:');
  if (!hasApiToken) return null;
  final json = await ApiService().getCustomerDetail(token: token, customerId: id);
  return Customer.fromMap(json);
});

/// Notifier for customer list + create — API only, no local cache/fallback.
class CustomerListNotifier extends StateNotifier<AsyncValue<List<Customer>>> {
  final ApiService _api;
  final String? _token;

  CustomerListNotifier({
    required ApiService api,
    String? token,
  })  : _api = api,
        _token = token,
        super(const AsyncValue.loading()) {
    load();
  }

  bool get _hasApiToken {
    final token = _token;
    return token != null && token.isNotEmpty && !token.startsWith('session:');
  }

  /// Load customers from the API. No token yet → empty list (not an error).
  Future<void> load() async {
    state = const AsyncValue.loading();
    if (!_hasApiToken) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final response = await _api.getCustomers(token: _token!);
      final customerList = response['items'] as List<dynamic>?
          ?? response['customers'] as List<dynamic>?
          ?? [];
      final customers = customerList
          .map((c) => Customer.fromMap(c as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      debugPrint('CustomerListNotifier.load: API getCustomers failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a customer — POST /api/customers. The backend dedupes by phone,
  /// returning the existing customer instead of creating a duplicate; a
  /// duplicate-phone rejection (e.g. {"detail": "Number is Duplicate"})
  /// propagates so the UI can show it.
  Future<void> addCustomer(Customer customer) async {
    if (!_hasApiToken) throw Exception('You must be signed in to add a customer.');
    await _api.createCustomer(token: _token!, name: customer.name, phone: customer.phone);
    await load();
  }

  Future<void> deleteCustomer(String id) async {
    if (!_hasApiToken) throw Exception('You must be signed in to delete a customer.');
    await _api.deleteCustomer(token: _token!, customerId: id);
    await load();
  }

  /// Record a payment against a customer's outstanding balance (clears
  /// udhaar) via POST /api/customers/{id}/payments, then refreshes the list.
  Future<void> recordPayment(String customerId, double amount, {String? note}) async {
    if (!_hasApiToken) throw Exception('You must be signed in to record a payment.');
    await _api.recordCustomerPayment(
      token: _token!,
      customerId: customerId,
      amount: amount,
      note: note,
    );
    await load();
  }
}

final customerListNotifierProvider =
    StateNotifierProvider<CustomerListNotifier, AsyncValue<List<Customer>>>(
        (ref) {
  final api = ApiService();
  final apiToken = ref.watch(apiTokenProvider);
  return CustomerListNotifier(api: api, token: apiToken);
});
