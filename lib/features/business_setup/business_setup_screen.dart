import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/country_city_data.dart';
import '../../data/models/registered_user.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCategory = 'General Store';
  String _selectedCurrency = 'PKR';
  String? _logoUrl;
  bool _isLoading = false;
  bool _isUploadingLogo = false;

  final List<CountryData> _countries = getCountriesSorted();
  CountryData _selectedCountry = getCountryByIsoCode('PK') ?? countries.first;
  String? _selectedCity;

  List<String> get _cities => getCitiesForCountry(_selectedCountry.isoCode);

  @override
  void initState() {
    super.initState();
    _loadExistingBusiness();
  }

  void _loadExistingBusiness() {
    final business = ref.read(businessProvider).valueOrNull;
    if (business != null) {
      _nameController.text = business.name;
      _addressController.text = business.address ?? '';
      _phoneController.text = business.phoneNumber ?? '';
      _logoUrl = business.logoUrl;
      if (kBusinessCategories.contains(business.type)) {
        _selectedCategory = business.type;
      }
      if (kCurrencies.contains(business.currency)) {
        _selectedCurrency = business.currency;
      }
      final country = business.country;
      if (country != null) {
        final match = _countries.where((c) => c.name == country).firstOrNull;
        if (match != null) _selectedCountry = match;
      }
      if (business.city != null && _cities.contains(business.city)) {
        _selectedCity = business.city;
      }
    } else {
      // Brand-new account, no business yet — pre-fill from what they
      // already gave us at registration instead of starting blank.
      _prefillFromRegistration();
    }
  }

  Future<void> _prefillFromRegistration() async {
    final user = await RegisteredUser.load();
    if (user == null || !mounted) return;
    setState(() {
      if (_nameController.text.trim().isEmpty && user.fullName.isNotEmpty) {
        _nameController.text = "${user.fullName}'s Shop";
      }
      if (_phoneController.text.trim().isEmpty && user.phone != null) {
        _phoneController.text = user.phone!;
      }
      if (user.country != null) {
        final match = _countries.where((c) => c.name == user.country).firstOrNull;
        if (match != null) _selectedCountry = match;
      }
      if (user.city != null && _cities.contains(user.city)) {
        _selectedCity = user.city;
      }
    });
  }

  void _onCountryChanged(CountryData? country) {
    if (country == null || country.isoCode == _selectedCountry.isoCode) return;
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    setState(() => _isUploadingLogo = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final url = await storage.pickAndUploadImage(
        'business_logos',
        token: ref.read(apiTokenProvider),
      );
      if (url != null && mounted) {
        setState(() => _logoUrl = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(businessProvider.notifier).save(
            name: _nameController.text.trim(),
            type: _selectedCategory,
            currency: _selectedCurrency,
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            logoUrl: _logoUrl,
            city: _selectedCity,
            country: _selectedCountry.name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop profile saved successfully!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingBusiness = ref.watch(businessProvider).valueOrNull;
    final isEditing = existingBusiness != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Shop' : 'Set Up Your Shop'),
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.md),

              // ── Logo ──
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: _logoUrl == null
                              ? AppColors.primaryGradient
                              : null,
                          borderRadius: BorderRadius.circular(28),
                          color: _logoUrl != null ? null : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.network(
                                  _logoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _isUploadingLogo
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.store,
                                        size: 44,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add Logo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),

              // ── Shop Name ──
              Text('Shop Name *', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ahmed General Store',
                  prefixIcon: Icon(Icons.store, color: AppColors.primary),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Shop name is required' : null,
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Business Category ──
              Text('Business Type *', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category, color: AppColors.primary),
                ),
                items: kBusinessCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Phone Number ──
              Text('Phone Number', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'e.g. 0300xxxxxxx',
                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Currency ──
              Text('Currency *', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Icons.monetization_on, color: AppColors.primary),
                ),
                items: kCurrencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCurrency = v);
                },
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Address ──
              Text('Shop Address', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Main Market, Lahore',
                  prefixIcon: Icon(Icons.location_on, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // ── Country ──
              Text('Country *', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              DropdownButtonFormField<CountryData>(
                key: ValueKey('country_${_selectedCountry.isoCode}'),
                initialValue: _selectedCountry,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.public, color: AppColors.primary),
                ),
                items: _countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: _onCountryChanged,
                validator: (v) => v == null ? 'Select your country' : null,
              ),
              const SizedBox(height: AppDimensions.md),

              // ── City ──
              Text('City *', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppDimensions.sm),
              DropdownButtonFormField<String>(
                key: ValueKey('city_${_selectedCountry.isoCode}'),
                initialValue: _selectedCity,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Select city',
                  prefixIcon: Icon(Icons.location_city, color: AppColors.primary),
                ),
                items: _cities
                    .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: (city) => setState(() => _selectedCity = city),
                validator: (v) => v == null || v.isEmpty ? 'Select your city' : null,
              ),
              const SizedBox(height: AppDimensions.xl),

              // ── Continue Button ──
              AppButton(
                label: isEditing ? 'Save Changes' : 'Continue',
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: AppDimensions.lg),
            ],
          ),
        ),
      ),
    );
  }
}
