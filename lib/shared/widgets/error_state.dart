import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import 'app_button.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.message = 'Something went wrong',
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppDimensions.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withValues(alpha: 0.15),
                    AppColors.error.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, size: 36, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(message, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
            if (details != null) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(details!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.lg),
              AppButton(label: 'Try Again', icon: Icons.refresh, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
