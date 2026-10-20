import 'package:classipod/core/constants/keys.dart';
import 'package:classipod/core/elzicy/elzicy_service.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/features/music/radio/utils/radio_track_title_parser.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/settings/providers/elzicy_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool radioStationNamesMatch(String a, String b) {
  return a.trim().toLowerCase() == b.trim().toLowerCase();
}

String? elzicyTrackForStation(
  Map<String, String> nowPlaying,
  String stationName,
) {
  final trimmed = stationName.trim();
  final direct = nowPlaying[trimmed];
  if (direct != null && direct.isNotEmpty) return direct;
  for (final entry in nowPlaying.entries) {
    if (radioStationNamesMatch(entry.key, trimmed) &&
        entry.value.isNotEmpty) {
      return entry.value;
    }
  }
  return null;
}

String formatElzicyStationSubtitle(String? rawTrack) {
  if (rawTrack == null || rawTrack.trim().isEmpty) return '';
  final parsed = parseRadioStreamTitle(rawTrack);
  final artist = parsed.artist;
  final title = parsed.title ?? rawTrack.trim();
  if (artist != null && artist.isNotEmpty && title.isNotEmpty) {
    return '$artist — $title';
  }
  return title;
}

/// One-line radio list label: `Station - Artist - Song`.
String formatRadioStationOverviewLine(
  String stationName,
  String? rawTrack,
) {
  final station = stationName.trim();
  if (rawTrack == null || rawTrack.trim().isEmpty) return station;
  final parsed = parseRadioStreamTitle(rawTrack);
  final artist = parsed.artist?.trim();
  final title = (parsed.title ?? rawTrack).trim();
  if (artist != null && artist.isNotEmpty && title.isNotEmpty) {
    return '$station - $artist - $title';
  }
  if (title.isNotEmpty && !radioStationNamesMatch(title, station)) {
    return '$station - $title';
  }
  return station;
}

MusicMetadata applyRadioStreamTitle({
  required MusicMetadata metadata,
  required String stationName,
  required String streamTitle,
  required String liveLabel,
}) {
  final parsed = parseRadioStreamTitle(streamTitle);
  final artist = parsed.artist;
  final title = parsed.title ?? streamTitle.trim();
  return metadata.copyWith(
    albumName: stationName,
    trackName: title.isEmpty ? stationName : title,
    trackArtistNames: artist == null || artist.isEmpty ? [liveLabel] : [artist],
  );
}

String _liveLabel() {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return 'Live';
  return context.localization.radioLiveLabel;
}

void publishRadioMetadataUpdate(Ref ref, MusicMetadata updated) {
  ref.read(nowPlayingDetailsProvider.notifier).patchRadioMetadata(updated);
  ref.read(libraryAudioHandlerProvider).updateCurrentSongMetadata(updated);
}

Future<void> refreshRadioNowPlayingFromElzicy(Ref ref) async {
  final configured = await ref.read(elzicyConfiguredProvider.future);
  if (!configured) return;
  final current = ref.read(nowPlayingDetailsProvider).currentMetadata;
  if (current == null || !current.isInternetRadio) return;
  final stationName = current.albumName ?? current.trackName ?? '';
  if (stationName.isEmpty) return;
  final client = await ref.read(elzicyServiceProvider).client();
  if (client == null) return;
  final raw = elzicyTrackForStation(client.nowPlaying, stationName);
  if (raw == null || raw.isEmpty) return;
  final updated = applyRadioStreamTitle(
    metadata: current,
    stationName: stationName,
    streamTitle: raw,
    liveLabel: _liveLabel(),
  );
  publishRadioMetadataUpdate(ref, updated);
}
