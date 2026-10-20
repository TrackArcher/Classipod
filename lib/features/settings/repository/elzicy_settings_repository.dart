import 'package:classipod/core/elzicy/elzicy_url.dart';
import 'package:classipod/core/models/shared_preference_keys.dart';
import 'package:classipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final elzicySettingsRepositoryProvider = Provider<ElzicySettingsRepository>((
  ref,
) {
  return ElzicySettingsRepository(
    ref.read(sharedPreferencesWithCacheProvider).requireValue,
    const FlutterSecureStorage(),
  );
});

class ElzicySettingsRepository {
  ElzicySettingsRepository(this._preferences, this._secureStorage);

  final SharedPreferencesWithCache _preferences;
  final FlutterSecureStorage _secureStorage;

  static const _tokenKey = 'elzicy_api_token';

  Future<String?> baseUrl() async {
    return _preferences.getString(SharedPreferencesKeys.elzicyApiBaseUrl.name);
  }

  Future<void> setBaseUrl(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _preferences.remove(SharedPreferencesKeys.elzicyApiBaseUrl.name);
      return;
    }
    final normalized = normalizeElzicyBaseUrl(value) ?? value.trim();
    await _preferences.setString(
      SharedPreferencesKeys.elzicyApiBaseUrl.name,
      normalized,
    );
  }

  Future<String?> token() => _secureStorage.read(key: _tokenKey);

  Future<void> setToken(String? value) async {
    if (value == null || value.trim().isEmpty) {
      await _secureStorage.delete(key: _tokenKey);
      return;
    }
    await _secureStorage.write(key: _tokenKey, value: value.trim());
  }

  Future<bool> isConfigured() async {
    final url = await baseUrl();
    final appToken = await token();
    return url != null &&
        url.isNotEmpty &&
        appToken != null &&
        appToken.isNotEmpty;
  }
}
