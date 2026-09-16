class SalesReport {
  final double dailySales;
  final double weeklySales;
  final double monthlySales;
  final double dailyProfit;
  final double weeklyProfit;
  final double monthlyProfit;
  final double pendingPayments;
  final int lowStockCount;

  SalesReport({
    this.dailySales = 0,
    this.weeklySales = 0,
    this.monthlySales = 0,
    this.dailyProfit = 0,
    this.weeklyProfit = 0,
    this.monthlyProfit = 0,
    this.pendingPayments = 0,
    this.lowStockCount = 0,
  });

  factory SalesReport.fromMap(Map<String, dynamic> map) => SalesReport(
    dailySales: (map['dailySales'] as num?)?.toDouble() ?? 0,
    weeklySales: (map['weeklySales'] as num?)?.toDouble() ?? 0,
    monthlySales: (map['monthlySales'] as num?)?.toDouble() ?? 0,
    dailyProfit: (map['dailyProfit'] as num?)?.toDouble() ?? 0,
    weeklyProfit: (map['weeklyProfit'] as num?)?.toDouble() ?? 0,
    monthlyProfit: (map['monthlyProfit'] as num?)?.toDouble() ?? 0,
    pendingPayments: (map['pendingPayments'] as num?)?.toDouble() ?? 0,
    lowStockCount: map['lowStockCount'] as int? ?? 0,
  );
}

/// GET /api/dashboard/summary — computed live server-side, so it can't
/// drift between devices the way the local Firestore-cache-derived
/// [SalesReport] figures can.
class DashboardSummary {
  final double totalRevenue;
  final double totalOutstanding;
  final int lowStockCount;

  DashboardSummary({
    this.totalRevenue = 0,
    this.totalOutstanding = 0,
    this.lowStockCount = 0,
  });

  factory DashboardSummary.fromMap(Map<String, dynamic> map) => DashboardSummary(
    totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0,
    totalOutstanding: (map['totalOutstanding'] as num?)?.toDouble() ?? 0,
    lowStockCount: map['lowStockCount'] as int? ?? 0,
  );
}

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint({required this.label, required this.value});
}
