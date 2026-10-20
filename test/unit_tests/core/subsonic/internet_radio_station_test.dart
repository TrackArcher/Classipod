import 'package:classipod/core/subsonic/internet_radio_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InternetRadioStation', () {
    test('parseEnvelope reads a single station', () {
      final stations = InternetRadioStation.parseEnvelope({
        'internetRadioStations': {
          'internetRadioStation': {
            'id': '1',
            'name': 'Jazz FM',
            'streamUrl': 'https://example.test/stream',
            'homePageUrl': 'https://example.test',
          },
        },
      });
      expect(stations, hasLength(1));
      expect(stations.single.name, 'Jazz FM');
      expect(stations.single.streamUrl, 'https://example.test/stream');
      expect(stations.single.homePageUrl, 'https://example.test');
    });

    test('parseEnvelope reads multiple stations', () {
      final stations = InternetRadioStation.parseEnvelope({
        'internetRadioStations': {
          'internetRadioStation': [
            {
              'id': '1',
              'name': 'A',
              'streamUrl': 'https://a.test/stream',
            },
            {
              'id': '2',
              'name': 'B',
              'streamUrl': 'https://b.test/stream',
            },
          ],
        },
      });
      expect(stations, hasLength(2));
    });

    test('parseEnvelope reads coverArt from the server', () {
      final stations = InternetRadioStation.parseEnvelope({
        'internetRadioStations': {
          'internetRadioStation': {
            'id': '1',
            'name': 'Jazz FM',
            'streamUrl': 'https://example.test/stream',
            'coverArt': 'cover-1',
          },
        },
      });
      expect(stations.single.coverArt, 'cover-1');
    });

    test('toPlaybackMetadata marks live subsonic radio', () {
      const station = InternetRadioStation(
        id: '42',
        name: 'News',
        streamUrl: 'https://news.test/live',
      );
      final metadata = station.toPlaybackMetadata(
        serverId: 'navidrome.local',
        streamSubtitle: 'Live',
      );
      expect(metadata.albumName, 'News');
      expect(metadata.isInternetRadio, isTrue);
      expect(metadata.isLiveStream, isTrue);
      expect(metadata.isSubsonic, isTrue);
      expect(metadata.filePath, 'https://news.test/live');
      expect(metadata.trackName, 'News');
    });
  });
}
