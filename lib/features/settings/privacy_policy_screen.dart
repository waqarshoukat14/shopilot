import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    ('Last Updated', 'August 28, 2026'),
    ('1. Information We Collect',
        'Shopilot collects the information you provide directly, including your name, email address, business details, and the data you add about your customers, products, and invoices. We also collect limited usage information to improve the app.'),
    ('2. How We Use Your Information',
        'We use your information to provide and maintain the Shopilot services, process your data locally where possible, sync your data across devices when signed in, and improve app features. We do not sell your personal data to third parties.'),
    ('3. Data Storage & Security',
        'Your data is stored securely using encrypted Firebase services. We implement industry-standard safeguards to protect your information. You are responsible for keeping your account credentials safe.'),
    ('4. AI Features',
        'Shopilot includes AI-assisted features for voice commands and insights. Prompts and data used to generate AI responses are processed to provide the requested feature and are not used to sell advertising.'),
    ('5. Sharing of Information',
        'We do not share your personal information with third parties except as required to operate the service (such as hosting providers) or as required by law.'),
    ('6. Your Choices',
        'You can access and update your business profile and account information at any time. You may contact us to request deletion of your account and associated data.'),
    ('7. Children\u2019s Privacy',
        'Shopilot is not directed to children under 13, and we do not knowingly collect personal information from children.'),
    ('8. Changes to This Policy',
        'We may update this Privacy Policy from time to time. We will notify you of any material changes by updating the date above.'),
    ('9. Contact Us',
        'If you have questions about this Privacy Policy, please contact us through the app support channels.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shopilot Privacy Policy',
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