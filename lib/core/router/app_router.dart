import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/products/product_list_screen.dart';
import '../../features/products/add_product_screen.dart';
import '../../features/products/edit_product_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/customers/customer_list_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/invoices/create_invoice_screen.dart';
import '../../features/ai_voice/ai_voice_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/insights/ai_insights_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/settings/terms_screen.dart';
import '../../features/business_setup/business_setup_screen.dart';
import '../../features/business_setup/business_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

final GlobalKey<NavigatorState> _rootNavigator = GlobalKey<NavigatorState>();

GoRoute _route(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage(
      key: state.pageKey,
      child: builder(state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    ),
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigator,
  initialLocation: '/',
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final isAuth = container.read(isAuthenticatedProvider);
    final location = state.uri.toString();

    final isAuthRoute =
        location == '/login' ||
        location == '/register' ||
        location == '/forgot-password' ||
        location == '/' ||
        location == '/onboarding';
    final isOnboardingRoute = location == '/' || location == '/onboarding';

    if (!isAuth && !isAuthRoute) return '/login';
    if (isAuth && isOnboardingRoute) return '/dashboard';

    return null;
  },
  routes: [
    // Note: these are intentionally NOT `const`-instantiated. A `const`
    // widget here would be canonicalized by Dart into one shared instance,
    // and Flutter's element diffing then treats every rebuild as "identical"
    // and skips calling build() again — which silently freezes the screen
    // (e.g. dashboard colors) at whatever ambient state (like dark mode)
    // was active the first time it mounted.
    _route('/', (_) => SplashScreen()),
    _route('/onboarding', (_) => OnboardingScreen()),
    _route('/login', (_) => LoginScreen()),
    _route('/register', (_) => RegisterScreen()),
    _route('/forgot-password', (_) => ForgotPasswordScreen()),
    _route('/business-setup', (_) => BusinessSetupScreen()),
    _route('/business-detail', (_) => BusinessDetailScreen()),
    _route('/dashboard', (_) => DashboardScreen()),
    _route('/products', (_) => ProductListScreen()),
    _route('/products/add', (_) => AddProductScreen()),
    _route(
      '/products/:id',
      (state) {
        final id = state.pathParameters['id']!;
        // Check if this is the edit route
        return ProductDetailScreen(productId: id);
      },
    ),
    _route(
      '/products/edit/:id',
      (state) {
        final id = state.pathParameters['id']!;
        // We need to find the product from the provider
        // This is handled by the EditProductScreen itself
        return _EditProductWrapper(productId: id);
      },
    ),
    _route('/customers', (_) => CustomerListScreen()),
    _route(
      '/customers/:id',
      (state) => CustomerDetailScreen(customerId: state.pathParameters['id']!),
    ),
    _route('/invoices/create', (_) => CreateInvoiceScreen()),
    _route('/ai-voice', (_) => AiVoiceScreen()),
    _route('/reports', (_) => ReportsScreen()),
    _route('/insights', (_) => AiInsightsScreen()),
    _route('/subscription', (_) => SubscriptionScreen()),
    _route('/settings', (_) => SettingsScreen()),
    _route('/settings/privacy-policy', (_) => PrivacyPolicyScreen()),
    _route('/settings/terms', (_) => TermsScreen()),
  ],
);

/// Wrapper that resolves a product ID to a Product object for editing.
class _EditProductWrapper extends ConsumerWidget {
  final String productId;
  const _EditProductWrapper({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListNotifierProvider);
    return productsAsync.when(
      data: (products) {
        final product = products.where((p) => p.id == productId).firstOrNull;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Product')),
            body: const Center(child: Text('Product not found')),
          );
        }
        return EditProductScreen(product: product);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
