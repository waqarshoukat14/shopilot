import '../models/report.dart';
import '../models/invoice.dart';
import '../models/product.dart';

/// Pure computation over already-loaded (API-sourced) invoices/products —
/// no local storage involved. Callers pass in whatever the invoice/product
/// notifiers currently hold.
class ReportRepository {
  SalesReport getSalesReport(List<Invoice> invoices, List<Product> products) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double totalFor(DateTime since) {
      return invoices
          .where((inv) =>
              inv.createdAt.isAfter(since) &&
              inv.status == InvoiceStatus.paid)
          .fold<double>(0, (sum, inv) => sum + inv.total);
    }

    double profitFor(DateTime since) {
      return invoices
          .where((inv) =>
              inv.createdAt.isAfter(since) &&
              inv.status == InvoiceStatus.paid)
          .fold<double>(0, (sum, inv) {
            final cost = inv.items.fold<double>(
              0, (s, item) => s + (item.unitPrice * item.quantity * 0.7),
            );
            return sum + (inv.total - cost);
          });
    }

    final pendingPayments = invoices
        .where((inv) => inv.status != InvoiceStatus.paid)
        .fold<double>(0, (sum, inv) => sum + inv.dueAmount);

    return SalesReport(
      dailySales: totalFor(todayStart),
      weeklySales: totalFor(weekStart),
      monthlySales: totalFor(monthStart),
      dailyProfit: profitFor(todayStart),
      weeklyProfit: profitFor(weekStart),
      monthlyProfit: profitFor(monthStart),
      pendingPayments: pendingPayments,
      lowStockCount: products.where((p) => p.isLowStock).length,
    );
  }

  List<ChartDataPoint> getDailySalesChart(List<Invoice> invoices) {
    final paid = invoices.where((inv) => inv.status == InvoiceStatus.paid);

    final Map<String, double> dayTotals = {};
    for (final inv in paid) {
      final day = '${inv.createdAt.day}/${inv.createdAt.month}';
      dayTotals[day] = (dayTotals[day] ?? 0) + inv.total;
    }

    return dayTotals.entries.map((e) => ChartDataPoint(label: e.key, value: e.value)).toList();
  }

  List<ChartDataPoint> getTopSellingProducts(List<Invoice> invoices) {
    final Map<String, double> productSales = {};

    for (final inv in invoices) {
      for (final item in inv.items) {
        productSales[item.productName] = (productSales[item.productName] ?? 0) + item.subtotal;
      }
    }

    final sorted = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(5).map((e) => ChartDataPoint(label: e.key, value: e.value)).toList();
  }
}
