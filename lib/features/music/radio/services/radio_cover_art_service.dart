import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RadioCoverArtService {
  RadioCoverArtService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static Future<Directory> coverDirectory() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/radio_covers');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> localCoverFile(String stationId) async {
    final dir = await coverDirectory();
    return File('${dir.path}/$stationId');
  }

  static Future<String?> existingLocalCoverPath(String stationId) async {
    final file = await localCoverFile(stationId);
    if (file.existsSync()) return file.path;
    return null;
  }

  Future<String?> ensureLocalCover({
    required String stationId,
    String? coverArt,
    String? subsonicArtUrl,
  }) async {
    final existing = await existingLocalCoverPath(stationId);
    if (existing != null) return existing;
    if (coverArt == null || coverArt.isEmpty) return null;
    await downloadCover(
      stationId: stationId,
      coverArtUrl: coverArt,
      subsonicArtUrl: subsonicArtUrl,
    );
    return existingLocalCoverPath(stationId);
  }

  Future<void> downloadCover({
    required String stationId,
    required String coverArtUrl,
    String? subsonicArtUrl,
  }) async {
    final target = await localCoverFile(stationId);
    final url = _resolveDownloadUrl(coverArtUrl, subsonicArtUrl);
    if (url == null) return;
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) return;
    await target.writeAsBytes(response.bodyBytes, flush: true);
  }

  String? _resolveDownloadUrl(String coverArtUrl, String? subsonicArtUrl) {
    if (coverArtUrl.startsWith('http://') ||
        coverArtUrl.startsWith('https://')) {
      return coverArtUrl;
    }
    return subsonicArtUrl;
  }

  void dispose() => _client.close();
}
