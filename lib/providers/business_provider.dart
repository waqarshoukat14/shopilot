import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/business.dart';
import '../data/services/api_service.dart';
import '../data/services/storage_service.dart';
import 'auth_provider.dart';

/// Provides a StorageService instance for logo uploads.
final storageServiceProvider = Provider<StorageService>((_) => StorageService());

/// Notifier that manages the current user's Business state — API only, no
/// local cache/fallback.
class BusinessNotifier extends StateNotifier<AsyncValue<Business?>> {
  final ApiService _api;
  final String? _userId;
  final String? _token;

  BusinessNotifier({
    required ApiService api,
    String? userId,
    String? token,
  })  : _api = api,
        _userId = userId,
        _token = token,
        super(const AsyncValue.loading()) {
    _load();
  }

  bool get _hasApiToken {
    final token = _token;
    return token != null && token.isNotEmpty && !token.startsWith('session:');
  }

  Future<void> _load() async {
    if (_userId == null || !_hasApiToken) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final json = await _api.getBusiness(_token!);
      state = AsyncValue.data(Business.fromMap(json));
    } catch (e, st) {
      debugPrint('BusinessNotifier._load: API getBusiness failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save({
    required String name,
    required String type,
    required String currency,
    String? address,
    String? phoneNumber,
    String? logoUrl,
    String? email,
    String? city,
    String? country,
    String? description,
  }) async {
    if (_userId == null) throw Exception('User not logged in');
    if (!_hasApiToken) throw Exception('You must be signed in to save the business profile.');
    state = const AsyncValue.loading();

    try {
      await _api.createBusiness(
        token: _token!,
        name: name,
        type: type,
        currency: currency,
        address: address,
        phoneNumber: phoneNumber,
        logoUrl: logoUrl,
        city: city,
        country: country,
      );
      state = AsyncValue.data(Business(
        id: _userId,
        name: name,
        type: type,
        currency: currency,
        address: address,
        phoneNumber: phoneNumber,
        logoUrl: logoUrl,
        email: email,
        city: city,
        country: country,
        description: description,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Partial update via PUT /api/business.
  Future<void> updateField(String field, dynamic value) async {
    if (_userId == null) throw Exception('User not logged in');
    if (!_hasApiToken) throw Exception('You must be signed in to update the business profile.');

    await _api.updateBusiness(token: _token!, fields: {field: value});

    final current = state.valueOrNull;
    if (current == null) return;
    switch (field) {
      case 'name':
        state = AsyncValue.data(current.copyWith(name: value as String));
        break;
      case 'business_type':
      case 'type':
        state = AsyncValue.data(current.copyWith(type: value as String));
        break;
      case 'currency':
        state = AsyncValue.data(current.copyWith(currency: value as String));
        break;
      case 'address':
        state = AsyncValue.data(current.copyWith(address: value as String?));
        break;
      case 'phone':
      case 'phone_number':
        state = AsyncValue.data(current.copyWith(phoneNumber: value as String?));
        break;
      case 'logo_url':
        state = AsyncValue.data(current.copyWith(logoUrl: value as String?));
        break;
      case 'email':
        state = AsyncValue.data(current.copyWith(email: value as String?));
        break;
      case 'city':
        state = AsyncValue.data(current.copyWith(city: value as String?));
        break;
      case 'country':
        state = AsyncValue.data(current.copyWith(country: value as String?));
        break;
      case 'description':
        state = AsyncValue.data(current.copyWith(description: value as String?));
        break;
    }
  }

  void refresh() => _load();
}

final businessProvider =
    StateNotifierProvider<BusinessNotifier, AsyncValue<Business?>>((ref) {
  final api = ApiService();
  final userId = ref.watch(currentUserIdProvider);
  final apiToken = ref.watch(apiTokenProvider);
  final token = (apiToken != null && apiToken.isNotEmpty) ? apiToken : null;

  return BusinessNotifier(api: api, userId: userId, token: token);
});
