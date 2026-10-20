import 'package:classipod/core/providers/app_lifecycle_provider.dart';
import 'package:classipod/core/subsonic/subsonic_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subsonic only scans on sign-in or explicit user refresh; cancel if the app
/// goes to the background mid-scan.
final subsonicBackgroundProvider = Provider<void>((ref) {
  ref.listen(appLifecycleStateProvider, (previous, next) {
    if (appLifecycleIsInteractive(next)) return;
    if (previous != null && appLifecycleIsInteractive(previous)) {
      ref.read(subsonicControllerProvider.notifier).cancelActiveRefresh();
    }
  });
});
