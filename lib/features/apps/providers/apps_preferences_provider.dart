import 'package:classipod/features/apps/models/apps_preferences.dart';
import 'package:classipod/features/apps/repository/apps_preferences_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appsPreferencesProvider =
    NotifierProvider<AppsPreferencesNotifier, AppsPreferences>(
      AppsPreferencesNotifier.new,
    );

class AppsPreferencesNotifier extends Notifier<AppsPreferences> {
  @override
  AppsPreferences build() {
    return ref.read(appsPreferencesRepositoryProvider).load();
  }

  Future<void> setHidden(String appId, {required bool hidden}) async {
    final nextHidden = Set<String>.from(state.hiddenAppIds);
    if (hidden) {
      nextHidden.add(appId);
    } else {
      nextHidden.remove(appId);
    }
    await _persist(state.copyWith(hiddenAppIds: nextHidden));
  }

  Future<void> setCustomLabel(String appId, String? label) async {
    final nextLabels = Map<String, String>.from(state.customLabels);
    final trimmed = label?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      nextLabels.remove(appId);
    } else {
      nextLabels[appId] = trimmed;
    }
    await _persist(state.copyWith(customLabels: nextLabels));
  }

  Future<void> _persist(AppsPreferences next) async {
    await ref.read(appsPreferencesRepositoryProvider).save(next);
    state = next;
  }
}
