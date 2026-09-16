import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_pilot/shared/widgets/app_button.dart';
import 'package:shop_pilot/shared/widgets/app_card.dart';
import 'package:shop_pilot/shared/widgets/app_badge.dart';
import 'package:shop_pilot/shared/widgets/empty_state.dart';
import 'package:shop_pilot/shared/widgets/error_state.dart';
import 'package:shop_pilot/core/theme/app_colors.dart';
import 'package:shop_pilot/core/theme/app_theme.dart';

void main() {
  group('Shared Widgets', () {
    testWidgets('AppButton renders label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppButton(label: 'Test Button', onPressed: () {})),
      ));
      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('AppButton shows loading state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppButton(label: 'Loading', isLoading: true, onPressed: () {})),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppCard renders child', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppCard(child: Text('Card Content'))),
      ));
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('AppBadge renders label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: const AppBadge(label: 'Active')),
      ));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('EmptyState renders title and icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: const EmptyState(icon: Icons.inbox, title: 'Empty', subtitle: 'Nothing here'))),
      );
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('ErrorState renders message and retry button', (tester) async {
      bool retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ErrorState(message: 'Error!', onRetry: () => retried = true)),
      ));
      expect(find.text('Error!'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });

  group('Theme', () {
    testWidgets('AppTheme has correct primary color', (tester) async {
      final theme = AppTheme.light;
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    testWidgets('AppTheme uses Material 3', (tester) async {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
    });
  });
}
