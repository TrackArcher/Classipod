import 'package:classipod/core/subsonic/internet_radio_station.dart';
import 'package:classipod/core/subsonic/subsonic_controller.dart';
import 'package:classipod/features/music/radio/services/radio_station_cover_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final internetRadioStationsProvider =
    FutureProvider<List<InternetRadioStation>>((ref) async {
      final remote = ref.watch(subsonicControllerProvider).value;
      if (remote == null || !remote.enabled || !remote.signedIn) {
        return const [];
      }
      final stations = await ref
          .read(subsonicControllerProvider.notifier)
          .fetchInternetRadioStations();
      await cacheRadioStationCovers(
        stations,
        subsonicCoverUrl: (coverArtId) => ref
            .read(subsonicControllerProvider.notifier)
            .coverArtUri(coverArtId)
            ?.toString(),
      );
      return stations;
    });
