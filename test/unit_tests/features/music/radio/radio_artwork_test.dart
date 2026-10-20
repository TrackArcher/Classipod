import 'package:classipod/features/music/radio/services/radio_artwork.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('localMediaSessionArtUri', () {
    test('returns file uri for absolute paths', () {
      final uri = localMediaSessionArtUri('/data/user/0/covers/station-1');
      expect(uri, isNotNull);
      expect(uri!.scheme, 'file');
      expect(uri.path, '/data/user/0/covers/station-1');
    });

    test('returns null for remote and subsonic references', () {
      expect(
        localMediaSessionArtUri('https://example.com/cover.jpg'),
        isNull,
      );
      expect(
        localMediaSessionArtUri('subsonic:server:abc'),
        isNull,
      );
    });
  });
}
