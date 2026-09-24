import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/services/api_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, ref),
            const SizedBox(height: AppDimensions.md),
            _SectionLabel('Account'),
            AppCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.business,
                    label: 'Edit Business Profile',
                    onTap: () => context.push('/business-setup'),
                  ),
                  Divider(color: AppColors.divider),
                  _SettingRow(
                    icon: Icons.subscriptions_outlined,
                    label: 'Subscription',
                    trailing: 'Free',
                    onTap: () => context.push('/subscription'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            _SectionLabel('Preferences'),
            AppCard(
              child: Column(
                children: [
                  _buildLanguageRow(context, ref),
                  Divider(color: AppColors.divider),
                  _SettingRow(
                    icon: Icons.record_voice_over,
                    label: 'Voice Language',
                    trailing: 'English',
                    onTap: () => _showLanguagePicker(context, ref, isVoice: true),
                  ),
                  Divider(color: AppColors.divider),
                  _SettingRow(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailing: 'On',
                    onTap: () {},
                  ),
                  Divider(color: AppColors.divider),
                  _buildDarkModeRow(context, ref),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            _SectionLabel('Support'),
            AppCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.backup_outlined,
                    label: 'Backup & Restore',
                    onTap: () {},
                  ),
                  Divider(color: AppColors.divider),
                  _SettingRow(
                    icon: Icons.info_outline,
                    label: 'About',
                    trailing: 'v1.0.0',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            _SectionLabel('Legal'),
            AppCard(
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => context.push('/settings/privacy-policy'),
                  ),
                  Divider(color: AppColors.divider),
                  _SettingRow(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () => context.push('/settings/terms'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            AppCard(
              child: _SettingRow(
                icon: Icons.logout,
                label: 'Log Out',
                color: AppColors.error,
                onTap: () => _confirmLogout(context, ref),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            _SectionLabel('Danger Zone'),
            AppCard(
              child: _SettingRow(
                icon: Icons.delete_forever,
                label: 'Delete Account',
                color: AppColors.error,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: _getDisplayName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'User';
        return Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const AppLogo(size: 56),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Shopilot User', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getDisplayName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('api_user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        // Try various name fields the API might return
        final firstName = userData['first_name'] as String? ?? userData['firstName'] as String?;
        final lastName = userData['last_name'] as String? ?? userData['lastName'] as String?;
        final name = userData['name'] as String?;
        final fullName = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
        if (fullName.isNotEmpty) return fullName;
        if (name != null && name.isNotEmpty) return name;
        // Fallback to email
        final email = userData['email'] as String?;
        if (email != null && email.isNotEmpty) return email;
      }
    } catch (_) {}
    return 'User';
  }

  Widget _buildLanguageRow(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final languageNames = {
      'en': 'English',
      'ur': 'Urdu',
      'hi': 'Hindi',
      'ar': 'Arabic',
      'es': 'Spanish',
      'fr': 'French',
    };
    return _SettingRow(
      icon: Icons.language,
      label: 'Language',
      trailing: languageNames[currentLocale.languageCode] ?? 'English',
      onTap: () => _showLanguagePicker(context, ref),
    );
  }

  Widget _buildDarkModeRow(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        children: [
          Icon(Icons.dark_mode_outlined, size: AppDimensions.iconMd, color: AppColors.primary),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text('Dark Mode', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary)),
          ),
          Switch(
            value: isDark,
            activeThumbColor: AppColors.primary,
            onChanged: (value) => ref.read(themeModeProvider.notifier).setDark(value),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, {bool isVoice = false}) {
    final languages = [
      _LanguageOption('English', 'en'),
      _LanguageOption('Urdu', 'ur'),
      _LanguageOption('Hindi', 'hi'),
      _LanguageOption('Arabic', 'ar'),
      _LanguageOption('Spanish', 'es'),
      _LanguageOption('French', 'fr'),
    ];
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: AppDimensions.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: AppDimensions.md), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Text(isVoice ? 'Select Voice Language' : 'Select Language', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimensions.md),
            ...languages.map((lang) => ListTile(
              title: Text(lang.name),
              trailing: lang.code == currentLocale.languageCode
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                if (!isVoice) {
                  ref.read(localeProvider.notifier).setLocale(Locale(lang.code));
                }
              },
            )),
            const SizedBox(height: AppDimensions.md),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your account, business profile, products, customers, and invoices. This cannot be undone.',
              ),
              const SizedBox(height: AppDimensions.md),
              const Text('Type DELETE to confirm', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppDimensions.sm),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(hintText: 'DELETE'),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (isDeleting || confirmController.text.trim() != 'DELETE')
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final token = ref.read(apiTokenProvider);
                        final hasApiToken = token != null && token.isNotEmpty && !token.startsWith('session:');
                        if (hasApiToken) {
                          await ApiService().deleteAccount(token: token);
                        }
                        await ref.read(apiTokenProvider.notifier).clearToken();
                        ref.read(apiUserEmailProvider.notifier).setEmail(null);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) context.go('/login');
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: isDeleting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(apiTokenProvider.notifier).clearToken();
              ref.read(apiUserEmailProvider.notifier).setEmail(null);
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Shopilot',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2026 Shopilot. All rights reserved.',
      applicationIcon: const AppLogo(size: 48),
    );
  }
}

class _LanguageOption {
  final String name;
  final String code;
  const _LanguageOption(this.name, this.code);
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm, left: 4),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color color;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconMd, color: color),
            const SizedBox(width: AppDimensions.md),
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color))),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: AppDimensions.sm),
                child: Text(trailing!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              ),
            Icon(Icons.chevron_right, size: 20, color: color == AppColors.error ? color : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
