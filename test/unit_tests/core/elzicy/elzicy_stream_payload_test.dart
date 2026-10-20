import 'package:classipod/core/elzicy/elzicy_stream_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseElzicyStreamPayload reads Python dict literals from SSE', () {
    const payload =
        "{'Distortion - KINK': 'Architects - Hereafter', "
        '"80\'s - KINK": \'Blue Nile - The Downtown Lights\'}';

    final parsed = parseElzicyStreamPayload(payload);
    expect(parsed, isNotNull);
    expect(parsed!['Distortion - KINK'], 'Architects - Hereafter');
    expect(parsed["80's - KINK"], 'Blue Nile - The Downtown Lights');
  });

  test('parseElzicyStreamPayload still accepts JSON', () {
    const payload = '{"KINK":"Artist - Title"}';
    final parsed = parseElzicyStreamPayload(payload);
    expect(parsed, {'KINK': 'Artist - Title'});
  });
}
