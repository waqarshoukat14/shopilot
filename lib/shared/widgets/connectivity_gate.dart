import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/report_provider.dart';
import 'app_button.dart';

/// Wraps the whole app. Since every screen depends on the API now (no local
/// fallback), a dropped connection means nothing would work anyway — so
/// instead of leaving broken-looking empty/error states scattered across
/// screens, this blocks with one clear full-screen message. The moment
/// connectivity comes back (automatically, or via the Try Again button), it
/// refreshes the app's core data so the user sees current state right away.
class ConnectivityGate extends ConsumerStatefulWidget {
  final Widget child;
  const ConnectivityGate({super.key, required this.child});

  @override
  ConsumerState<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends ConsumerState<ConnectivityGate> {
  bool _isOnline = true;
  bool _isChecking = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _check();
    _subscription = Connectivity().onConnectivityChanged.listen((_) => _check());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _check({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() => _isChecking = true);
    bool online;
    try {
      final result = await InternetAddress.lookup('google.com');
      online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    final wasOffline = !_isOnline;
    setState(() {
      _isOnline = online;
      _isChecking = false;
    });
    if (online && wasOffline) _refreshData();
  }

  /// Reloads the app's main data sources so a stale/empty state left over
  /// from the outage doesn't linger once the connection is back.
  void _refreshData() {
    ref.read(productListNotifierProvider.notifier).load();
    ref.read(customerListNotifierProvider.notifier).load();
    ref.read(invoiceListNotifierProvider.notifier).load();
    ref.read(businessProvider.notifier).refresh();
    ref.invalidate(dashboardSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    // An overlay (not a replacement) so the screen underneath — e.g. a
    // half-filled form — keeps its state through a brief connectivity blip
    // instead of being unmounted and losing whatever was in progress.
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned.fill(
            child: _NoInternetScreen(
              isChecking: _isChecking,
              onRetry: () => _check(showSpinner: true),
            ),
          ),
      ],
    );
  }
}

class _NoInternetScreen extends StatelessWidget {
  final bool isChecking;
  final VoidCallback onRetry;
  const _NoInternetScreen({required this.isChecking, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppDimensions.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.softGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.primary),
                ),
                const SizedBox(height: AppDimensions.lg),
                Text('No Internet Connection', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppDimensions.sm),
                Text(
                  'Shopilot needs an internet connection to load your shop data. Please check your connection and try again.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.xl),
                AppButton(
                  label: 'Try Again',
                  icon: Icons.refresh,
                  isLoading: isChecking,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
