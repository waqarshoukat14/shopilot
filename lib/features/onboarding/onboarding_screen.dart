import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> _pages(AppLocalizations l10n) => [
    _OnboardingPage(
      icon: Icons.store,
      title: l10n.manageYourShop,
      description: l10n.manageYourShopDesc,
      gradientColors: [AppColors.primary, AppColors.secondary],
    ),
    _OnboardingPage(
      icon: Icons.mic,
      title: l10n.justSpeak,
      description: l10n.justSpeakDesc,
      gradientColors: [const Color(0xFF2563EB), AppColors.primary],
    ),
    _OnboardingPage(
      icon: Icons.bar_chart,
      title: l10n.growYourBusiness,
      description: l10n.growYourBusinessDesc,
      gradientColors: [AppColors.primary, const Color(0xFF7DD3FC)],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => _buildPage(pages[i]),
              ),
            ),
            _buildBottomSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: AppDimensions.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient icon container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradientColors,
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: page.gradientColors.first.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(page.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: AppDimensions.xl),
          Text(page.title, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.md),
          Text(
            page.description,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(AppLocalizations l10n) {
    return Container(
      padding: AppDimensions.screenPadding,
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 32 : 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: _currentPage == i
                      ? AppColors.primaryGradient
                      : null,
                  color: _currentPage != i ? AppColors.border : null,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          if (_currentPage == 2)
            AppButton(label: l10n.getStarted, onPressed: () => context.go('/login'))
          else
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.skip,
                    isOutlined: true,
                    onPressed: () => context.go('/login'),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: AppButton(
                    label: l10n.next,
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}
