import 'dart:async';

import 'package:classipod/core/elzicy/elzicy_service.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/providers/app_lifecycle_provider.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/settings/providers/elzicy_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Elzicy SSE + history polling while on Radio or playing an internet station.
final elzicyBootstrapProvider = Provider<void>((ref) {
  final router = ref.read(routerProvider);
  Timer? pollTimer;
  var pollGeneration = 0;
  var streamHeld = false;

  Future<void> stopStreaming() async {
    pollGeneration++;
    pollTimer?.cancel();
    pollTimer = null;
    if (!streamHeld) return;
    streamHeld = false;
    final client = await ref.read(elzicyServiceProvider).client();
    client?.release();
  }

  Future<void> startStreaming() async {
    if (!await ref.read(elzicyConfiguredProvider.future)) {
      await stopStreaming();
      return;
    }
    final client = await ref.read(elzicyServiceProvider).client();
    if (client == null) return;
    if (!streamHeld) {
      client.acquire();
      streamHeld = true;
    }
    pollGeneration++;
    final generation = pollGeneration;
    pollTimer?.cancel();
    pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(client.refreshHistory());
    });
    if (generation != pollGeneration) return;
    unawaited(client.refreshHistory());
  }

  bool elzicyWorkNeeded() {
    if (!appLifecycleIsInteractive(ref.read(appLifecycleStateProvider))) {
      return false;
    }
    final playback = ref.read(nowPlayingDetailsProvider);
    if (playback.isPlaying &&
        playback.currentMetadata?.isInternetRadio == true) {
      return true;
    }
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return false;
    return configuration.last.route.name == Routes.radio.name;
  }

  Future<void> syncElzicyBackgroundWork() async {
    if (!elzicyWorkNeeded()) {
      await stopStreaming();
      return;
    }
    await startStreaming();
  }

  ref.listen(appLifecycleStateProvider, (_, _) {
    unawaited(syncElzicyBackgroundWork());
  });
  ref.listen(
    nowPlayingDetailsProvider.select(
      (value) => (
        value.isPlaying,
        value.currentMetadata?.isInternetRadio ?? false,
      ),
    ),
    (_, _) => unawaited(syncElzicyBackgroundWork()),
  );
  ref.listen(elzicyConfiguredProvider, (previous, next) {
    next.whenData((_) => unawaited(syncElzicyBackgroundWork()));
  });

  void onRouteChange() => unawaited(syncElzicyBackgroundWork());
  router.routerDelegate.addListener(onRouteChange);

  ref.onDispose(() {
    router.routerDelegate.removeListener(onRouteChange);
    unawaited(stopStreaming());
  });

  unawaited(syncElzicyBackgroundWork());
});
