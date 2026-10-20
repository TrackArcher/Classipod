import 'package:classipod/core/subsonic/internet_radio_station.dart';
import 'package:classipod/core/subsonic/subsonic_client.dart';

class SubsonicRadioApi {
  static Future<List<InternetRadioStation>> list(SubsonicClient client) async {
    final envelope = await client.request('getInternetRadioStations');
    final stations = InternetRadioStation.parseEnvelope(envelope);
    stations.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return stations;
  }

  static Future<void> create(
    SubsonicClient client, {
    required String name,
    required String streamUrl,
    String? homepageUrl,
    String? coverArtUrl,
  }) async {
    await client.request('createInternetRadioStation', {
      'name': name,
      'streamUrl': streamUrl,
      if (homepageUrl != null && homepageUrl.isNotEmpty)
        'homepageUrl': homepageUrl,
      if (coverArtUrl != null && coverArtUrl.isNotEmpty) 'coverArt': coverArtUrl,
    });
  }

  static Future<void> update(
    SubsonicClient client, {
    required String id,
    required String name,
    required String streamUrl,
    String? homepageUrl,
  }) async {
    await client.request('updateInternetRadioStation', {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      if (homepageUrl != null && homepageUrl.isNotEmpty)
        'homepageUrl': homepageUrl,
    });
  }

  static Future<void> delete(SubsonicClient client, String id) async {
    await client.request('deleteInternetRadioStation', {'id': id});
  }
}
