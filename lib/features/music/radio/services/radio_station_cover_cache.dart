import 'package:classipod/core/subsonic/internet_radio_station.dart';
import 'package:classipod/features/music/radio/services/radio_cover_art_service.dart';

typedef SubsonicCoverUrlResolver = String? Function(String coverArtId);

Future<String?> ensureRadioStationLocalCover(
  InternetRadioStation station, {
  SubsonicCoverUrlResolver? subsonicCoverUrl,
}) async {
  final coverArt = station.coverArt;
  if (coverArt == null || coverArt.isEmpty) {
    return RadioCoverArtService.existingLocalCoverPath(station.id);
  }
  final subsonicArtUrl = coverArt.startsWith('http')
      ? null
      : subsonicCoverUrl?.call(coverArt);
  return RadioCoverArtService().ensureLocalCover(
    stationId: station.id,
    coverArt: coverArt,
    subsonicArtUrl: subsonicArtUrl,
  );
}

Future<void> cacheRadioStationCovers(
  List<InternetRadioStation> stations, {
  SubsonicCoverUrlResolver? subsonicCoverUrl,
}) async {
  final service = RadioCoverArtService();
  for (final station in stations) {
    final coverArt = station.coverArt;
    if (coverArt == null || coverArt.isEmpty) continue;
    final subsonicArtUrl = coverArt.startsWith('http')
        ? null
        : subsonicCoverUrl?.call(coverArt);
    await service.ensureLocalCover(
      stationId: station.id,
      coverArt: coverArt,
      subsonicArtUrl: subsonicArtUrl,
    );
  }
  service.dispose();
}
