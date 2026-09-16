import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// API token auth (custom backend login)
// ---------------------------------------------------------------------------
const _apiTokenKey = 'api_auth_token';
const _apiUserEmailKey = 'api_user_email';

/// Notifier that manages the API auth token both in memory and on disk.
/// It auto-hydrates from SharedPreferences when first created.
class _ApiTokenNotifier extends StateNotifier<String?> {
  _ApiTokenNotifier() : super(null) {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_apiTokenKey);
  }

  /// Persist the token to disk and update in-memory state.
  Future<void> setToken(String token, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiTokenKey, token);
    if (email != null) await prefs.setString(_apiUserEmailKey, email);
    state = token;
  }

  /// Clear the token from disk and in-memory state.
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiTokenKey);
    await prefs.remove(_apiUserEmailKey);
    state = null;
  }
}

final apiTokenProvider =
    StateNotifierProvider<_ApiTokenNotifier, String?>((ref) {
  return _ApiTokenNotifier();
});

/// The API-authenticated user's email — hydrates from SharedPreferences on
/// startup, and should be set explicitly (via `.notifier.setEmail(...)`)
/// right after a successful login. Used as a stable per-user identifier,
/// since the bearer token itself can differ across logins for the same
/// account.
class _ApiUserEmailNotifier extends StateNotifier<String?> {
  _ApiUserEmailNotifier() : super(null) {
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_apiUserEmailKey);
  }

  void setEmail(String? email) => state = email;
}

final apiUserEmailProvider =
    StateNotifierProvider<_ApiUserEmailNotifier, String?>((ref) {
  return _ApiUserEmailNotifier();
});

/// True when a valid API token is present.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final apiToken = ref.watch(apiTokenProvider);
  return apiToken != null && apiToken.isNotEmpty;
});

/// A stable per-account identifier — the API-auth email, or a hash of the
/// token as a last resort while the email hasn't hydrated yet.
final currentUserIdProvider = Provider<String?>((ref) {
  final apiToken = ref.watch(apiTokenProvider);
  if (apiToken == null || apiToken.isEmpty) return null;
  final email = ref.watch(apiUserEmailProvider);
  return email ?? 'api_${apiToken.hashCode}';
});
