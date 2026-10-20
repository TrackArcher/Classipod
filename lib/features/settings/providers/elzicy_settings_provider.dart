import 'package:classipod/features/settings/repository/elzicy_settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final elzicyConfiguredProvider = FutureProvider<bool>((ref) async {
  return ref.read(elzicySettingsRepositoryProvider).isConfigured();
});

final elzicyBaseUrlProvider = FutureProvider<String?>((ref) async {
  return ref.read(elzicySettingsRepositoryProvider).baseUrl();
});
