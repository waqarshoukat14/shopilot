import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_logo.dart';
import '../../data/services/api_service.dart';
import '../../data/models/country_city_data.dart';
import '../../l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final List<CountryData> _countries = getCountriesSorted();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isVerifyingOtp = false;
  String? _tempToken;
  String _otpSentToNumber = '';

  CountryData _selectedCountry = getCountryByIsoCode('PK') ?? countries.first;
  String? _selectedCity;
  bool _phoneValid = false;

  List<String> get _cities => getCitiesForCountry(_selectedCountry.isoCode);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onCountryChanged(CountryData? country) {
    if (country == null || country.isoCode == _selectedCountry.isoCode) return;
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _phoneNumberController.clear();
      _phoneValid = false;
    });
  }

  void _onPhoneInputChanged(PhoneNumber number) {
    final iso = number.isoCode;
    if (iso != null && iso.isNotEmpty) {
      final country = getCountryByIsoCode(iso);
      if (country != null && country.isoCode != _selectedCountry.isoCode) {
        setState(() {
          _selectedCountry = country;
          _selectedCity = null;
        });
      }
    }
    if (mounted) setState(() {});
  }

  String? _normalizedPhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.isEmpty) return null;
    if (!cleaned.startsWith('+')) {
      cleaned = '${_selectedCountry.dialCode}$cleaned';
    }
    return cleaned;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_phoneValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number for the selected country.'),
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);

    final phoneNumber = _normalizedPhoneNumber(_phoneNumberController.text.trim());
    if (phoneNumber == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter phone number with country code, e.g. +1 234 567 8900'),
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _apiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        country: _selectedCountry.name,
        number: phoneNumber,
        city: _selectedCity ?? '',
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _tempToken = response.tempToken;
          _otpSentToNumber = phoneNumber;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    final tempToken = _tempToken;
    if (tempToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please try again.')),
        );
      }
      return;
    }
    setState(() => _isVerifyingOtp = true);
    try {
      final response = await _apiService.verifyOtp(
        tempToken: tempToken,
        code: _otpController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOtpStep = _tempToken != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gradient header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const AppLogo(size: 80),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appName,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOtpStep ? 'Verify your number' : l10n.createYourAccount,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // Form section
              Padding(
                padding: AppDimensions.screenPadding,
                child: isOtpStep ? _buildOtpStep() : _buildDetailsStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l10n.createAccount, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppDimensions.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: l10n.firstName,
                  hint: 'Enter first name',
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter first name'
                      : null,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: AppTextField(
                  label: l10n.lastName,
                  hint: 'Enter last name',
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter last name'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          _buildCountryDropdown(),
          const SizedBox(height: AppDimensions.md),
          _buildPhoneField(),
          const SizedBox(height: 4),
          Text(
            'The number format will match the selected country. A verification code will be sent to this number.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          _buildCityDropdown(),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: l10n.password,
            hint: 'Enter your password',
            controller: _passwordController,
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your password';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),
          AppButton(
            label: l10n.register,
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.alreadyHaveAccount,
                style: AppTextStyles.bodyMedium,
              ),
              TextButton(
                onPressed: _isLoading ? null : () => context.go('/login'),
                child: Text(
                  l10n.login,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.country, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        DropdownButtonFormField<CountryData>(
          key: ValueKey('country_${_selectedCountry.isoCode}'),
          initialValue: _selectedCountry,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Select country'),
          items: _countries
              .map(
                (c) => DropdownMenuItem<CountryData>(
                  value: c,
                  child: Text(
                    '${c.name} (${c.dialCode})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _onCountryChanged,
          validator: (v) => v == null ? 'Select your country' : null,
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.phoneNumber, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        InternationalPhoneNumberInput(
          key: ValueKey('phone_${_selectedCountry.isoCode}'),
          onInputChanged: _onPhoneInputChanged,
          onInputValidated: (valid) {
            if (_phoneValid != valid) {
              setState(() => _phoneValid = valid);
            }
          },
          countries: [_selectedCountry.isoCode],
          initialValue: PhoneNumber(dialCode: _selectedCountry.dialCode, isoCode: _selectedCountry.isoCode),
          textFieldController: _phoneNumberController,
          formatInput: true,
          autoValidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputDecoration: const InputDecoration(hintText: 'Enter phone number'),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final l10n = AppLocalizations.of(context);
    final cities = _cities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.city, style: AppTextStyles.labelLarge),
        const SizedBox(height: AppDimensions.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Select city'),
          items: cities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                ),
              )
              .toList(),
          onChanged: (city) => setState(() => _selectedCity = city),
          validator: (v) => v == null || v.isEmpty ? 'Select your city' : null,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l10n.enterVerificationCode, style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'We sent a 6-digit code to $_otpSentToNumber.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Verification Code',
            hint: 'Enter the code',
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter the code';
              if (v.trim().length < 6) return 'Enter the 6-digit code';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),
          AppButton(
            label: l10n.verifyAndCreateAccount,
            isLoading: _isVerifyingOtp,
            onPressed: _verifyOtp,
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.didntReceiveCode,
                style: AppTextStyles.bodyMedium,
              ),
              TextButton(
                onPressed: _isVerifyingOtp ? null : _sendOtp,
                child: Text(
                  l10n.resend,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
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
