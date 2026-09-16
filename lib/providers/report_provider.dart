import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/report.dart';
import '../data/models/invoice.dart';
import '../data/repositories/report_repository.dart';
import '../data/services/api_service.dart';
import 'auth_provider.dart';
import 'customer_provider.dart';
import 'product_provider.dart';
import 'invoice_provider.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());

/// Computed from whatever the invoice/product notifiers currently hold —
/// both are already API-sourced, so this stays API-only without a second
/// network round trip.
final salesReportProvider = Provider<SalesReport>((ref) {
  final invoices = ref.watch(invoiceListNotifierProvider).valueOrNull ?? const [];
  final products = ref.watch(productListNotifierProvider).valueOrNull ?? const [];
  return ref.watch(reportRepositoryProvider).getSalesReport(invoices, products);
});

final dailySalesChartProvider = Provider<List<ChartDataPoint>>((ref) {
  final invoices = ref.watch(invoiceListNotifierProvider).valueOrNull ?? const [];
  return ref.watch(reportRepositoryProvider).getDailySalesChart(invoices);
});

final topSellingProductsProvider = Provider<List<ChartDataPoint>>((ref) {
  final invoices = ref.watch(invoiceListNotifierProvider).valueOrNull ?? const [];
  return ref.watch(reportRepositoryProvider).getTopSellingProducts(invoices);
});

/// GET /api/dashboard/summary — computed live server-side on every request,
/// so totalRevenue/totalOutstanding/lowStockCount can't drift between
/// devices. Falls back to a locally-computed equivalent (still built from
/// the other API-sourced notifiers, not local storage) if the call fails.
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final token = ref.watch(apiTokenProvider);
  final hasApiToken = token != null && token.isNotEmpty && !token.startsWith('session:');
  if (hasApiToken) {
    try {
      final json = await ApiService().getDashboardSummary(token: token);
      return DashboardSummary.fromMap(json);
    } catch (e) {
      debugPrint('dashboardSummaryProvider: API getDashboardSummary failed: $e');
    }
  }

  final invoices = ref.watch(invoiceListNotifierProvider).valueOrNull ?? const [];
  final totalRevenue = invoices
      .where((inv) => inv.status == InvoiceStatus.paid)
      .fold<double>(0, (sum, inv) => sum + inv.total);
  final customers = ref.watch(customerListNotifierProvider).valueOrNull ?? const [];
  final totalOutstanding = customers.fold<double>(
    0, (sum, c) => sum + (c.outstandingAmount > 0 ? c.outstandingAmount : 0),
  );
  final products = ref.watch(productListNotifierProvider).valueOrNull ?? const [];
  final lowStockCount = products.where((p) => p.isLowStock).length;

  return DashboardSummary(
    totalRevenue: totalRevenue,
    totalOutstanding: totalOutstanding,
    lowStockCount: lowStockCount,
  );
});
