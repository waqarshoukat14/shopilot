import 'package:flutter/material.dart';
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneNumberController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final List<CountryData> _countries = getCountriesSorted();
  CountryData _selectedCountry = getCountryByIsoCode('PK') ?? countries.first;
  bool _phoneValid = false;

  bool _isLoading = false;
  bool _isResetting = false;
  bool _isSuccess = false;
  String? _otpSentToNumber;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onCountryChanged(CountryData? country) {
    if (country == null || country.isoCode == _selectedCountry.isoCode) return;
    setState(() {
      _selectedCountry = country;
      _phoneNumberController.clear();
      _phoneValid = false;
    });
  }

  void _onPhoneInputChanged(PhoneNumber number) {
    final iso = number.isoCode;
    if (iso != null && iso.isNotEmpty) {
      final country = getCountryByIsoCode(iso);
      if (country != null && country.isoCode != _selectedCountry.isoCode) {
        setState(() => _selectedCountry = country);
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
    if (!_phoneFormKey.currentState!.validate()) return;
    if (!_phoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number for the selected country.')),
      );
      return;
    }
    final number = _normalizedPhoneNumber(_phoneNumberController.text.trim());
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter phone number with country code, e.g. +1 234 567 8900')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.forgotPassword(number: number);
      if (mounted) {
        setState(() => _otpSentToNumber = number);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final number = _otpSentToNumber;
    if (number == null) return;

    setState(() => _isResetting = true);
    try {
      await _apiService.resetPassword(
        number: number,
        code: _codeController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) setState(() => _isSuccess = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOtpStep = _otpSentToNumber != null;

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
                      isOtpStep ? 'Verify your number' : 'Reset your password',
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
                child: _isSuccess
                    ? _buildSuccessView()
                    : isOtpStep
                        ? _buildResetStep()
                        : _buildPhoneStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Forgot Password', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Enter your registered phone number and we\'ll send you a verification code.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildCountryDropdown(),
          const SizedBox(height: AppDimensions.md),
          _buildPhoneField(),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: 'Send Code',
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
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

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Enter Code & New Password', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'We sent a 6-digit code to $_otpSentToNumber.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          AppTextField(
            label: 'Verification Code',
            hint: 'Enter the code',
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter the code';
              if (v.trim().length < 6) return 'Enter the 6-digit code';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'New Password',
            hint: 'Enter new password',
            controller: _passwordController,
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.md),
          AppTextField(
            label: 'Confirm Password',
            hint: 'Re-enter new password',
            controller: _confirmController,
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: 'Reset Password',
            isLoading: _isResetting,
            onPressed: _resetPassword,
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Didn\'t receive the code? ',
                style: AppTextStyles.bodyMedium,
              ),
              TextButton(
                onPressed: _isResetting ? null : _sendOtp,
                child: Text(
                  'Resend',
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

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: AppDimensions.xl),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        Text(
          'Password Reset!',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.sm),
        Text(
          'Your password has been reset successfully.\nYou can now log in with your new password.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        AppButton(
          label: 'Go to Login',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
