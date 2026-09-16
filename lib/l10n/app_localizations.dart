import 'package:flutter/material.dart';
import 'translations/en.dart';
import 'translations/ur.dart';
import 'translations/hi.dart';
import 'translations/ar.dart';
import 'translations/es.dart';
import 'translations/fr.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ur'),
    Locale('hi'),
    Locale('ar'),
    Locale('es'),
    Locale('fr'),
  ];

  Map<String, String> get _translations {
    switch (locale.languageCode) {
      case 'ur':
        return urTranslations;
      case 'hi':
        return hiTranslations;
      case 'ar':
        return arTranslations;
      case 'es':
        return esTranslations;
      case 'fr':
        return frTranslations;
      case 'en':
      default:
        return enTranslations;
    }
  }

  String translate(String key) {
    return _translations[key] ?? key;
  }

  // Convenience getters for commonly used strings
  String get appName => translate('app_name');
  String get settings => translate('settings');
  String get home => translate('home');
  String get account => translate('account');
  String get preferences => translate('preferences');
  String get support => translate('support');
  String get legal => translate('legal');
  String get businessProfile => translate('business_profile');
  String get subscription => translate('subscription');
  String get language => translate('language');
  String get voiceLanguage => translate('voice_language');
  String get notifications => translate('notifications');
  String get darkMode => translate('dark_mode');
  String get backupRestore => translate('backup_restore');
  String get about => translate('about');
  String get privacyPolicy => translate('privacy_policy');
  String get termsConditions => translate('terms_conditions');
  String get logOut => translate('log_out');
  String get logOutConfirm => translate('log_out_confirm');
  String get cancel => translate('cancel');
  String get products => translate('products');
  String get customers => translate('customers');
  String get reports => translate('reports');
  String get searchProducts => translate('search_products');
  String get searchCustomers => translate('search_customers');
  String get createInvoice => translate('create_invoice');
  String get addProduct => translate('add_product');
  String get noProductsFound => translate('no_products_found');
  String get noCustomersFound => translate('no_customers_found');
  String get todaySales => translate('today_sales');
  String get todayProfit => translate('today_profit');
  String get pendingPayments => translate('pending_payments');
  String get lowStock => translate('low_stock');
  String get quickActions => translate('quick_actions');
  String get recentSales => translate('recent_sales');
  String get noRecentSales => translate('no_recent_sales');
  String get dailySales => translate('daily_sales');
  String get weeklySales => translate('weekly_sales');
  String get monthlySales => translate('monthly_sales');
  String get profit => translate('profit');
  String get invoice => translate('invoice');
  String get selectLanguage => translate('select_language');
  String get selectVoiceLanguage => translate('select_voice_language');
  String get shopilotUser => translate('shopilot_user');
  String get newProduct => translate('new_product');
  String get productName => translate('product_name');
  String get category => translate('category');
  String get purchasePrice => translate('purchase_price');
  String get sellingPrice => translate('selling_price');
  String get quantity => translate('quantity');
  String get barcode => translate('barcode');
  String get saveProduct => translate('save_product');
  String get useVoiceInput => translate('use_voice_input');
  String get customerProfile => translate('customer_profile');
  String get outstanding => translate('outstanding');
  String get lastPurchase => translate('last_purchase');
  String get generateInvoice => translate('generate_invoice');
  String get call => translate('call');
  String get whatsApp => translate('whatsapp');
  String get purchaseHistory => translate('purchase_history');
  String get selectCustomer => translate('select_customer');
  String get addProducts => translate('add_products');
  String get discount => translate('discount');
  String get tax => translate('tax');
  String get paymentMethod => translate('payment_method');
  String get subtotal => translate('subtotal');
  String get total => translate('total');
  String get cash => translate('cash');
  String get card => translate('card');
  String get bankTransfer => translate('bank_transfer');
  String get addPhoto => translate('add_photo');
  String get required_ => translate('required');
  String get aiVoice => translate('ai_voice');
  String get tapAndHoldToSpeak => translate('tap_and_hold_to_speak');
  String get listening => translate('listening');
  String get speakNow => translate('speak_now');
  String get processing => translate('processing');
  String get trySaying => translate('try_saying');
  String get dailySalesChart => translate('daily_sales_chart');
  String get topSellingProducts => translate('top_selling_products');
  String get welcomeBack => translate('welcome_back');
  String get signIn => translate('sign_in');
  String get email => translate('email');
  String get password => translate('password');
  String get rememberMe => translate('remember_me');
  String get forgotPassword => translate('forgot_password');
  String get login => translate('login');
  String get continueWithGoogle => translate('continue_with_google');
  String get dontHaveAccount => translate('dont_have_account');
  String get register => translate('register');
  String get createAccount => translate('create_account');
  String get firstName => translate('first_name');
  String get lastName => translate('last_name');
  String get country => translate('country');
  String get phoneNumber => translate('phone_number');
  String get city => translate('city');
  String get alreadyHaveAccount => translate('already_have_account');
  String get enterVerificationCode => translate('enter_verification_code');
  String get verifyAndCreateAccount => translate('verify_and_create_account');
  String get didntReceiveCode => translate('didnt_receive_code');
  String get resend => translate('resend');
  String get createYourAccount => translate('create_your_account');
  String get runYourBusinessWithAI => translate('run_your_business_with_ai');
  String get emptyState => translate('empty_state');
  String get noDataYet => translate('no_data_yet');
  String get off => translate('off');
  String get on => translate('on');
  String get free => translate('free');
  String get manageYourShop => translate('manage_your_shop');
  String get manageYourShopDesc => translate('manage_your_shop_desc');
  String get justSpeak => translate('just_speak');
  String get justSpeakDesc => translate('just_speak_desc');
  String get growYourBusiness => translate('grow_your_business');
  String get growYourBusinessDesc => translate('grow_your_business_desc');
  String get getStarted => translate('get_started');
  String get skip => translate('skip');
  String get next => translate('next');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ur', 'hi', 'ar', 'es', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
