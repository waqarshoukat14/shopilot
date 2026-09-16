import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/invoice.dart';
import '../data/models/customer.dart';
import '../data/services/api_service.dart';
import 'auth_provider.dart';
import 'customer_provider.dart';
import 'product_provider.dart';

/// Notifier for invoice list + create — API only, no local cache/fallback.
class InvoiceListNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final ApiService _api;
  final Ref _ref;
  final String? _token;

  InvoiceListNotifier({
    required ApiService api,
    required Ref ref,
    String? token,
  })  : _api = api,
        _ref = ref,
        _token = token,
        super(const AsyncValue.loading()) {
    load();
  }

  bool get _hasApiToken {
    final token = _token;
    return token != null && token.isNotEmpty && !token.startsWith('session:');
  }

  String? _customerNameFor(String? customerId) {
    if (customerId == null) return null;
    final customers = _ref.read(customerListNotifierProvider).valueOrNull ?? const <Customer>[];
    for (final c in customers) {
      if (c.id == customerId) return c.name;
    }
    return null;
  }

  /// Load invoices from the API. No token yet → empty list (not an error).
  Future<void> load() async {
    state = const AsyncValue.loading();
    if (!_hasApiToken) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final response = await _api.getInvoices(token: _token!);
      final invoiceList = response['items'] as List<dynamic>? ?? [];
      final invoices = invoiceList
          .map((i) => Invoice.fromMap(
                i as Map<String, dynamic>,
                resolvedCustomerName: _customerNameFor((i['customerId'] ?? i['customer_id'])?.toString()),
              ))
          .toList();
      state = AsyncValue.data(invoices);
    } catch (e, st) {
      debugPrint('InvoiceListNotifier.load: API getInvoices failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Create an invoice via POST /api/invoices. Stock is decremented
  /// automatically server-side; throws if any item's quantity exceeds
  /// available stock (nothing is written server-side in that case).
  ///
  /// [items] must be `{"productId": int, "quantity": int, "unitPrice": double}`
  /// maps — the caller is responsible for resolving product ids to the
  /// server's integer form.
  Future<Invoice> createInvoice({
    String? customerId,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double tax = 0,
    double paidAmount = 0,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    if (!_hasApiToken) {
      throw Exception('You must be signed in to create an invoice.');
    }
    final response = await _api.createInvoice(
      token: _token!,
      customerId: customerId,
      items: items,
      discount: discount,
      tax: tax,
      paidAmount: paidAmount,
    );
    final invoice = Invoice.fromMap(
      response,
      resolvedCustomerName: _customerNameFor(customerId),
      paymentMethod: paymentMethod,
    );

    // Refresh dependent state: stock changed, and (if attached) the
    // customer's balance changed too.
    _ref.invalidate(productListNotifierProvider);
    if (customerId != null) {
      _ref.invalidate(customerDetailProvider(customerId));
    }
    await load();
    return invoice;
  }
}

final invoiceListNotifierProvider =
    StateNotifierProvider<InvoiceListNotifier, AsyncValue<List<Invoice>>>((ref) {
  final api = ApiService();
  final apiToken = ref.watch(apiTokenProvider);
  return InvoiceListNotifier(api: api, ref: ref, token: apiToken);
});

/// Invoice detail via GET /api/invoices/{id}. No token → null.
final invoiceDetailProvider = FutureProvider.family<Invoice?, String>((ref, id) async {
  final token = ref.watch(apiTokenProvider);
  final hasApiToken = token != null && token.isNotEmpty && !token.startsWith('session:');
  if (!hasApiToken) return null;
  final json = await ApiService().getInvoiceDetail(token: token, invoiceId: id);
  return Invoice.fromMap(json);
});
