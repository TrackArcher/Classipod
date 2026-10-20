import 'dart:async';

import 'package:classipod/core/navigation/browsing_routes.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/providers/app_lifecycle_provider.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/services/memory_trim_service.dart';
import 'package:classipod/core/services/playback/library_audio_handler.dart';
import 'package:classipod/features/now_playing/models/now_playing_model.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// After pause on a browsing screen, tear down the native player and service.
const playbackPausedIdleDelay = Duration(minutes: 3);

final playbackIdleProvider = Provider<void>((ref) {
  final router = ref.read(routerProvider);
  Timer? idleTimer;

  void cancelIdleTimer() {
    idleTimer?.cancel();
    idleTimer = null;
  }

  Future<void> applyIdlePolicy() async {
    cancelIdleTimer();
    final handler = ref.read(libraryAudioHandlerProvider);
    final playback = ref.read(nowPlayingDetailsProvider);
    final lifecycle = ref.read(appLifecycleStateProvider);

    if (playback.metadataList.isEmpty && !playback.isPlaying) {
      await handler.suspendEngine(clearQueue: true);
      return;
    }

    if (!appLifecycleIsInteractive(lifecycle) &&
        !playback.isPlaying &&
        handler.sourceEngaged) {
      await handler.suspendEngine();
      return;
    }

    if (!_shouldScheduleIdleSuspend(
      router: router,
      playback: playback,
      handler: handler,
      lifecycle: lifecycle,
    )) {
      return;
    }

    idleTimer = Timer(playbackPausedIdleDelay, () async {
      if (!_shouldScheduleIdleSuspend(
        router: router,
        playback: ref.read(nowPlayingDetailsProvider),
        handler: ref.read(libraryAudioHandlerProvider),
        lifecycle: ref.read(appLifecycleStateProvider),
      )) {
        return;
      }
      await ref.read(libraryAudioHandlerProvider).suspendEngine();
    });
  }

  ref.listen(nowPlayingDetailsProvider, (_, _) {
    unawaited(applyIdlePolicy());
  });
  ref.listen(appLifecycleStateProvider, (_, next) {
    unawaited(applyIdlePolicy());
    if (!appLifecycleIsInteractive(next)) {
      trimHeavyCaches();
    }
  });

  void onRouteChange() => unawaited(applyIdlePolicy());
  router.routerDelegate.addListener(onRouteChange);

  ref.onDispose(() {
    cancelIdleTimer();
    router.routerDelegate.removeListener(onRouteChange);
  });

  unawaited(applyIdlePolicy());
});

bool _shouldScheduleIdleSuspend({
  required GoRouter router,
  required NowPlayingModel playback,
  required LibraryAudioHandler handler,
  required AppLifecycleState lifecycle,
}) {
  if (playback.isPlaying || handler.wantsPlayback || handler.recovering) {
    return false;
  }
  if (!appLifecycleIsInteractive(lifecycle)) {
    return false;
  }
  if (!handler.loading && !handler.sourceEngaged) {
    return false;
  }
  final configuration = router.routerDelegate.currentConfiguration;
  if (configuration.isEmpty) return false;
  final routeName = configuration.last.route.name;
  return routeName != null && browsingRouteNames.contains(routeName);
}
