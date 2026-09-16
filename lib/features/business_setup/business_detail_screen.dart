import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_image.dart';
import '../../data/models/business.dart';
import '../../data/models/registered_user.dart';
import '../../providers/business_provider.dart';

class BusinessDetailScreen extends ConsumerStatefulWidget {
  const BusinessDetailScreen({super.key});

  @override
  ConsumerState<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends ConsumerState<BusinessDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Always fetch a fresh profile on open rather than reusing whatever the
    // provider last held (e.g. from an earlier session/navigation), so a
    // missing/renamed business can't leak through.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(businessProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Business Profile'),
      ),
      body: businessAsync.when(
        data: (business) {
          if (business == null) {
            return _EmptyBusiness(onSetup: () => context.push('/business-setup'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.read(businessProvider.notifier).refresh(),
            child: _BusinessDetailBody(business: business),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.md),
              Text('Error loading business: $e', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppDimensions.md),
              AppButton(
                label: 'Retry',
                onPressed: () => ref.read(businessProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBusiness extends StatelessWidget {
  final VoidCallback onSetup;
  const _EmptyBusiness({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
              child: const Icon(Icons.store, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.lg),
            Text('No Business Profile Yet', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Finish setting up your shop to get started.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.lg),
            FutureBuilder<RegisteredUser?>(
              future: RegisteredUser.load(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user == null || (user.fullName.isEmpty && user.phone == null)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.lg),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: AppDimensions.sm),
                            Text('From Your Registration', style: AppTextStyles.titleMedium),
                          ],
                        ),
                        const Divider(color: AppColors.divider),
                        if (user.fullName.isNotEmpty)
                          _EmptyStateInfoRow(Icons.badge_outlined, 'Name', user.fullName),
                        if (user.phone != null)
                          _EmptyStateInfoRow(Icons.phone, 'Phone', user.phone!),
                        if (user.city != null || user.country != null)
                          _EmptyStateInfoRow(
                            Icons.location_on_outlined,
                            'Location',
                            [user.city, user.country].where((s) => s != null && s.isNotEmpty).join(', '),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            AppButton(label: 'Set Up Shop', onPressed: onSetup),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EmptyStateInfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.sm),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessDetailBody extends ConsumerWidget {
  final Business business;
  const _BusinessDetailBody({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.read(businessProvider.notifier).refresh(),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppDimensions.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Card ──
          _buildHeaderCard(),
          const SizedBox(height: AppDimensions.md),

          // ── Quick Info ──
          _buildQuickInfoRow(),
          const SizedBox(height: AppDimensions.md),

          // ── Contact ──
          _buildContactSection(),
          const SizedBox(height: AppDimensions.md),

          // ── Location ──
          if (business.address != null ||
              business.city != null ||
              business.country != null)
            _buildLocationSection(),

          // ── Description ──
          if (business.description != null && business.description!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.md),
            _buildDescriptionSection(),
          ],

          // ── Account Info ──
          const SizedBox(height: AppDimensions.md),
          _buildAccountInfoSection(),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    ),
    );
  }

  Widget _buildHeaderCard() {
    return AppCard(
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: business.logoUrl != null ? null : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: business.logoUrl != null
                  ? AppImage(
                      url: business.logoUrl,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : const Icon(Icons.store, size: 40, color: Colors.white),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              business.name,
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.xs),
            AppBadge(label: business.type, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.monetization_on,
            label: 'Currency',
            value: business.currency,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _InfoChip(
            icon: Icons.language,
            label: 'Language',
            value: business.language,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_phone, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text('Contact Information', style: AppTextStyles.titleMedium),
            ],
          ),
          const Divider(color: AppColors.divider),
          if (business.phoneNumber != null && business.phoneNumber!.isNotEmpty)
            _KeyValueRow(Icons.phone, 'Phone', business.phoneNumber!),
          if (business.email != null && business.email!.isNotEmpty)
            _KeyValueRow(Icons.email, 'Email', business.email!),
          if ((business.phoneNumber == null || business.phoneNumber!.isEmpty) &&
              (business.email == null || business.email!.isEmpty))
            Text(
              'No contact information available',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final addressParts = <String>[
      if (business.address != null && business.address!.isNotEmpty) business.address!,
      if (business.city != null && business.city!.isNotEmpty) business.city!,
      if (business.country != null && business.country!.isNotEmpty) business.country!,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text('Location', style: AppTextStyles.titleMedium),
            ],
          ),
          const Divider(color: AppColors.divider),
          Text(addressParts.join(', '), style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppDimensions.sm),
          Wrap(
            spacing: AppDimensions.sm,
            children: [
              if (business.city != null && business.city!.isNotEmpty)
                AppBadge(label: business.city!, color: AppColors.primarySoft),
              if (business.country != null && business.country!.isNotEmpty)
                AppBadge(label: business.country!, color: AppColors.secondaryLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text('Description', style: AppTextStyles.titleMedium),
            ],
          ),
          const Divider(color: AppColors.divider),
          Text(business.description!, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildAccountInfoSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: AppDimensions.sm),
              Text('Account Details', style: AppTextStyles.titleMedium),
            ],
          ),
          const Divider(color: AppColors.divider),
          _KeyValueRow(Icons.calendar_today, 'Created', _formatDate(business.createdAt)),
          if (business.updatedAt != null)
            _KeyValueRow(Icons.update, 'Last Updated', _formatDate(business.updatedAt!)),
          _KeyValueRow(Icons.tag, 'Business ID', '#${business.id}'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _KeyValueRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.sm),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
