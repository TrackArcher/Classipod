import 'package:classipod/features/music/radio/utils/radio_track_title_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRadioStreamTitle splits artist and title', () {
    final parsed = parseRadioStreamTitle('Daft Punk - One More Time');
    expect(parsed.artist, 'Daft Punk');
    expect(parsed.title, 'One More Time');
  });

  test('parseRadioStreamTitle keeps single segment as title', () {
    final parsed = parseRadioStreamTitle('Live From Berlin');
    expect(parsed.artist, isNull);
    expect(parsed.title, 'Live From Berlin');
  });
}
