import 'dart:convert';

import 'package:classipod/core/models/shared_preference_keys.dart';
import 'package:classipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:classipod/features/apps/models/apps_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appsPreferencesRepositoryProvider = Provider<AppsPreferencesRepository>((
  ref,
) {
  return AppsPreferencesRepository(
    ref.read(sharedPreferencesWithCacheProvider).requireValue,
  );
});

class AppsPreferencesRepository {
  AppsPreferencesRepository(this._preferences);

  final SharedPreferencesWithCache _preferences;

  AppsPreferences load() {
    final raw = _preferences.getString(
      SharedPreferencesKeys.appsLauncherOverrides.name,
    );
    if (raw == null || raw.isEmpty) return const AppsPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const AppsPreferences();
      return AppsPreferences.fromJson(decoded);
    } catch (_) {
      return const AppsPreferences();
    }
  }

  Future<void> save(AppsPreferences preferences) async {
    await _preferences.setString(
      SharedPreferencesKeys.appsLauncherOverrides.name,
      jsonEncode(preferences.toJson()),
    );
  }
}
