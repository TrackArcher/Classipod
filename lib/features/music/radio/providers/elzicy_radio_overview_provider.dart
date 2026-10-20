import 'package:classipod/core/elzicy/elzicy_bootstrap_provider.dart';
import 'package:classipod/core/elzicy/elzicy_service.dart';
import 'package:classipod/features/settings/providers/elzicy_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:classipod/features/music/radio/utils/radio_elzicy_metadata.dart'
    show
        elzicyTrackForStation,
        formatElzicyStationSubtitle,
        formatRadioStationOverviewLine;

/// Live Elzicy track titles keyed by station name (Navidrome radio name).
final elzicyRadioNowPlayingProvider =
    StreamProvider.autoDispose<Map<String, String>>((ref) async* {
      ref.watch(elzicyBootstrapProvider);
      final configured = await ref.watch(elzicyConfiguredProvider.future);
      if (!configured) {
        yield const {};
        return;
      }
      final client = await ref.read(elzicyServiceProvider).client();
      if (client == null) {
        yield const {};
        return;
      }
      yield Map<String, String>.from(client.nowPlaying);
      yield* client.nowPlayingStream;
    });
