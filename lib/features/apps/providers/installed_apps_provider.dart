import 'dart:io';

import 'package:classipod/features/apps/models/installed_app.dart';
import 'package:classipod/features/apps/providers/apps_preferences_provider.dart';
import 'package:classipod/features/apps/services/installed_apps_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<List<InstalledApp>> _loadApps(Ref ref, {required bool hiddenOnly}) async {
  if (kIsWeb || !Platform.isAndroid) return const [];
  final prefs = ref.watch(appsPreferencesProvider);
  final apps = await InstalledAppsService.instance.getLaunchableApps();
  final filtered = [
    for (final app in apps)
      if (prefs.isHidden(app.id) == hiddenOnly)
        app.withCustomLabel(prefs.customLabel(app.id)),
  ];
  filtered.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return filtered;
}

final installedAppsProvider = FutureProvider<List<InstalledApp>>((ref) {
  return _loadApps(ref, hiddenOnly: false);
});

final hiddenInstalledAppsProvider = FutureProvider<List<InstalledApp>>((ref) {
  return _loadApps(ref, hiddenOnly: true);
});
