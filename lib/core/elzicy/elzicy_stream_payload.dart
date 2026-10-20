import 'dart:convert';

/// Parses Elzicy SSE `data:` payloads (JSON or Python dict literals).
Map<String, String>? parseElzicyStreamPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final jsonMap = _tryJsonMap(trimmed);
  if (jsonMap != null) return jsonMap;

  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return _parsePythonDictLiteral(trimmed);
  }
  return null;
}

Map<String, String>? _tryJsonMap(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  } catch (_) {
    return null;
  }
}

Map<String, String>? _parsePythonDictLiteral(String raw) {
  final inner = raw.substring(1, raw.length - 1);
  var index = 0;
  final result = <String, String>{};

  while (index < inner.length) {
    index = _skipWhitespace(inner, index);
    if (index >= inner.length) break;

    final key = _readQuotedString(inner, index);
    if (key == null) return null;
    index = key.nextIndex;
    index = _skipWhitespace(inner, index);
    if (index >= inner.length || inner[index] != ':') return null;
    index++;
    index = _skipWhitespace(inner, index);

    final value = _readQuotedString(inner, index);
    if (value == null) return null;
    index = value.nextIndex;
    result[key.value] = value.value;

    index = _skipWhitespace(inner, index);
    if (index < inner.length && inner[index] == ',') {
      index++;
    }
  }

  return result.isEmpty ? null : result;
}

class _QuotedParseResult {
  const _QuotedParseResult(this.value, this.nextIndex);

  final String value;
  final int nextIndex;
}

int _skipWhitespace(String input, int index) {
  while (index < input.length && _isWhitespace(input.codeUnitAt(index))) {
    index++;
  }
  return index;
}

bool _isWhitespace(int codeUnit) {
  return codeUnit == 0x20 ||
      codeUnit == 0x09 ||
      codeUnit == 0x0a ||
      codeUnit == 0x0d;
}

_QuotedParseResult? _readQuotedString(String input, int start) {
  if (start >= input.length) return null;
  final quote = input[start];
  if (quote != "'" && quote != '"') return null;

  final buffer = StringBuffer();
  var index = start + 1;
  while (index < input.length) {
    final char = input[index];
    if (char == '\\' && index + 1 < input.length) {
      buffer.write(input[index + 1]);
      index += 2;
      continue;
    }
    if (char == quote) {
      return _QuotedParseResult(buffer.toString(), index + 1);
    }
    buffer.write(char);
    index++;
  }
  return null;
}
