import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/subsonic/subsonic_client.dart';
import 'package:classipod/features/music/radio/services/radio_artwork.dart';

class InternetRadioStation {
  const InternetRadioStation({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.homePageUrl,
    this.coverArt,
  });

  final String id;
  final String name;
  final String streamUrl;
  final String? homePageUrl;
  final String? coverArt;

  static List<InternetRadioStation> parseEnvelope(Map<String, dynamic> envelope) {
    final container = envelope['internetRadioStations'];
    if (container == null) return const [];
    if (container is! Map) throw const SubsonicException('response');
    return parseList(container['internetRadioStation']);
  }

  static List<InternetRadioStation> parseList(Object? data) {
    if (data == null) return const [];
    final entries = data is List ? data : [data];
    return [
      for (final entry in entries)
        if (entry is Map) _parseEntry(Map<String, dynamic>.from(entry)),
    ];
  }

  static InternetRadioStation _parseEntry(Map<String, dynamic> data) {
    final id = data['id']?.toString();
    final name = data['name']?.toString();
    final streamUrl = data['streamUrl']?.toString();
    if (id == null ||
        id.isEmpty ||
        name == null ||
        name.isEmpty ||
        streamUrl == null ||
        streamUrl.isEmpty) {
      throw const SubsonicException('response');
    }
    final homePageUrl =
        data['homePageUrl']?.toString() ?? data['homepageUrl']?.toString();
    final coverArt = data['coverArt']?.toString();
    return InternetRadioStation(
      id: id,
      name: name,
      streamUrl: streamUrl,
      homePageUrl: homePageUrl?.isEmpty == true ? null : homePageUrl,
      coverArt: coverArt?.isEmpty == true ? null : coverArt,
    );
  }

  MusicMetadata toPlaybackMetadata({
    required String serverId,
    required String streamSubtitle,
    String? localCoverPath,
  }) {
    final artwork = radioStationArtworkReference(
      station: this,
      serverId: serverId,
      localCoverPath: localCoverPath,
    );
    final remoteArtworkId =
        coverArt != null &&
            coverArt!.isNotEmpty &&
            !coverArt!.startsWith('http')
        ? coverArt
        : null;
    return MusicMetadata(
      serverId: serverId,
      remoteSongId: id,
      remoteArtworkId: remoteArtworkId,
      songId: 'subsonic-radio:$serverId:${Uri.encodeComponent(id)}',
      trackName: name,
      albumName: name,
      trackArtistNames: [streamSubtitle],
      filePath: streamUrl,
      thumbnailPath: artwork,
      trackDuration: 0,
      isOnDevice: false,
      genres: const ['Internet Radio'],
    );
  }
}
