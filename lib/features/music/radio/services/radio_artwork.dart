import 'package:classipod/core/subsonic/internet_radio_station.dart';

bool isLikelyImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'http' && uri.scheme != 'https') {
    return false;
  }
  final path = uri.path.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.gif') ||
      path.contains('/cover') ||
      path.contains('/art');
}

String? radioStationArtworkReference({
  required InternetRadioStation station,
  required String serverId,
  String? localCoverPath,
}) {
  if (localCoverPath != null && localCoverPath.isNotEmpty) {
    return localCoverPath;
  }
  final coverArt = station.coverArt;
  if (coverArt != null && coverArt.isNotEmpty) {
    if (coverArt.startsWith('http://') || coverArt.startsWith('https://')) {
      return coverArt;
    }
    return Uri(
      scheme: 'subsonic',
      host: serverId,
      pathSegments: [coverArt],
    ).toString();
  }
  final homePage = station.homePageUrl;
  if (isLikelyImageUrl(homePage)) {
    return homePage;
  }
  return null;
}

/// Art URI for [MediaItem] / SystemUI — local files only.
Uri? localMediaSessionArtUri(String? thumbnailPath) {
  if (thumbnailPath == null || thumbnailPath.isEmpty) return null;
  if (thumbnailPath.startsWith('/')) return Uri.file(thumbnailPath);
  final uri = Uri.tryParse(thumbnailPath);
  if (uri == null) return null;
  if (uri.scheme == 'file') return uri;
  return null;
}
