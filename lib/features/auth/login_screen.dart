import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_logo.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../../data/models/country_city_data.dart';
import '../../core/utils/phone_helper.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _prefsPhoneKey = 'remembered_phone';
  static const _prefsPasswordKey = 'remembered_password';
  static const _prefsRememberKey = 'remember_me';

  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _phoneValid = false;

  final List<CountryData> _countries = getCountriesSorted();
  CountryData _selectedCountry = getCountryByIsoCode('PK') ?? countries.first;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_prefsRememberKey) ?? false;
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember) {
        final remembered = prefs.getString(_prefsPhoneKey) ?? '';
        if (remembered.isNotEmpty) _applyRememberedPhone(remembered);
        _passwordController.text = prefs.getString(_prefsPasswordKey) ?? '';
      }
    });
  }

  /// The remembered number is stored fully normalized (e.g. "+923045454545")
  /// for the API, but the input field only holds the national digits — the
  /// "+92" is shown separately by the country picker. Setting the full
  /// string straight into the field made it display "923045454545" glued
  /// together. Resolve the right country from the stored dial code, then
  /// strip it so only the local number (e.g. "3045454545") lands in the box.
  void _applyRememberedPhone(String remembered) {
    CountryData? match;
    for (final c in _countries) {
      if (remembered.startsWith(c.dialCode)) {
        if (match == null || c.dialCode.length > match.dialCode.length) match = c;
      }
    }
    if (match != null) _selectedCountry = match;
    _phoneNumberController.text = nationalDigits(remembered, defaultCountryCode: _selectedCountry.dialCode);
    _phoneValid = true;
  }

  Future<void> _saveCredentials(String normalizedPhone) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(_prefsPhoneKey, normalizedPhone);
      await prefs.setString(_prefsPasswordKey, _passwordController.text);
    } else {
      await prefs.remove(_prefsPhoneKey);
      await prefs.remove(_prefsPasswordKey);
    }
    await prefs.setBool(_prefsRememberKey, _rememberMe);
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      await _saveCredentials(number);
      final apiService = ApiService();
      final loginResponse = await apiService.login(
        number: number,
        password: _passwordController.text,
      );
      // Save user data so the auth state recognizes the user as logged in.
      final token = loginResponse.token ?? '';
      if (token.isNotEmpty) {
        await ref.read(apiTokenProvider.notifier).setToken(token, email: number);
      } else {
        // API didn't return a token — use the phone number as a session
        // marker so isAuthenticatedProvider recognises the user.
        await ref.read(apiTokenProvider.notifier).setToken('session:$number', email: number);
      }
      ref.read(apiUserEmailProvider.notifier).setEmail(number);
      // Persist the user object for later use (profile, settings, etc.)
      {
        final prefs = await SharedPreferences.getInstance();
        if (loginResponse.user != null) {
          await prefs.setString('api_user_data', jsonEncode(loginResponse.user));
        }
      }
      if (mounted) context.go('/dashboard');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                      l10n.welcomeBack,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(l10n.signIn, style: AppTextStyles.headlineMedium),
                      const SizedBox(height: AppDimensions.md),
                      _buildCountryDropdown(),
                      const SizedBox(height: AppDimensions.md),
                      _buildPhoneField(),
                      const SizedBox(height: AppDimensions.md),
                      AppTextField(
                        label: l10n.password,
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Enter your password';
                          }
                          if (v.length < 6) {
                            return 'Min 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                          ),
                          const SizedBox(width: AppDimensions.xs),
                          Text(l10n.rememberMe, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          child: Text(
                            l10n.forgotPassword,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      AppButton(
                        label: l10n.login,
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.dontHaveAccount,
                            style: AppTextStyles.bodyMedium,
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => context.go('/register'),
                            child: Text(
                              l10n.register,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
}
