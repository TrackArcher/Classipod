import 'package:classipod/features/apps/models/installed_app.dart';
import 'package:flutter/services.dart';

class InstalledAppsService {
  InstalledAppsService._();

  static const MethodChannel _channel = MethodChannel(
    'com.adeeteya.classipod/installed_apps',
  );

  static final InstalledAppsService instance = InstalledAppsService._();

  Future<List<InstalledApp>> getLaunchableApps() async {
    final result = await _channel.invokeMethod<List<Object?>>(
      'getLaunchableApps',
    );
    if (result == null) return const [];
    return result
        .map((entry) => InstalledApp.fromPlatformMap(entry! as Map))
        .toList();
  }

  Future<void> launchApp(InstalledApp app) async {
    await _channel.invokeMethod<void>('launchApp', {
      'packageName': app.packageName,
      'userSerial': app.userSerial,
    });
  }
}
