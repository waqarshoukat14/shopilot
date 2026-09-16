import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    ('1. Acceptance of Terms',
        'By accessing or using the Shopilot application, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the app.'),
    ('2. Description of Service',
        'Shopilot is a small business management app that helps you manage products, customers, invoices, reports, and more. Features may include AI-assisted voice commands and insights.'),
    ('3. Account Responsibilities',
        'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must be at least 13 years old to use Shopilot.'),
    ('4. Acceptable Use',
        'You agree not to misuse the app, upload unlawful content, attempt to access other users\u2019 data, or use the service to violate any applicable laws or regulations.'),
    ('5. Data & Content',
        'You retain ownership of the data you enter into Shopilot. You grant us a limited license to store and process this data solely to provide the service to you.'),
    ('6. Intellectual Property',
        'The Shopilot app, including its design, logo, and software, is protected by intellectual property laws. You may not copy, modify, or distribute the app or its components without permission.'),
    ('7. Subscriptions & Payments',
        'Certain features may require a paid subscription. Fees are charged in advance and are non-refundable except where required by law. We may change pricing with prior notice.'),
    ('8. AI Features Disclaimer',
        'AI-generated insights and responses are provided for assistance only and may not always be accurate. You are responsible for verifying important business information before acting on it.'),
    ('9. Limitation of Liability',
        'To the maximum extent permitted by law, Shopilot shall not be liable for any indirect, incidental, or consequential damages arising from your use of the app.'),
    ('10. Termination',
        'You may stop using the app at any time. We may suspend or terminate access to the service if you violate these terms.'),
    ('11. Changes to Terms',
        'We may revise these Terms and Conditions at any time. Continued use of the app after changes become effective constitutes acceptance of the updated terms.'),
    ('12. Contact',
        'For questions about these terms, please contact us through the app support channels.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shopilot Terms & Conditions',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppDimensions.md),
            ..._sections.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.$1,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(s.$2, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
          ],
        ),
      ),
    );
  }
}