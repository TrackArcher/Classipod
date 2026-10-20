import 'dart:async';
import 'dart:convert';

import 'package:classipod/core/elzicy/elzicy_stream_payload.dart';
import 'package:classipod/core/elzicy/elzicy_url.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef ElzicyTrackUpdateCallback = void Function(
  String stationName,
  String trackTitle,
);

class ElzicyClient {
  ElzicyClient({
    required http.Client httpClient,
    required String baseUrl,
    required String token,
  }) : _httpClient = httpClient,
       _baseUrl = normalizeElzicyBaseUrl(baseUrl)!,
       _token = token;

  final http.Client _httpClient;
  final String _baseUrl;
  final String _token;

  final _nowPlayingController = StreamController<Map<String, String>>.broadcast();
  final _historyController =
      StreamController<Map<String, List<String>>>.broadcast();
  final _listeners = <ElzicyTrackUpdateCallback>{};

  Stream<Map<String, String>> get nowPlayingStream =>
      _nowPlayingController.stream;
  Stream<Map<String, List<String>>> get historyStream =>
      _historyController.stream;

  Map<String, String> _nowPlaying = const {};
  Map<String, List<String>> _history = const {};

  Map<String, String> get nowPlaying => Map.unmodifiable(_nowPlaying);
  Map<String, List<String>> get history => Map.unmodifiable(_history);

  int _acquireCount = 0;
  bool _running = false;
  Future<void>? _sseLoop;
  http.Client? _sseClient;

  static const _sseRetryDelay = Duration(seconds: 5);

  Uri get streamHistoryUri => _buildUri('/api/stream-history');

  String? getNowPlayingForStation(String? stationName) {
    if (stationName == null || stationName.isEmpty) return null;
    final trimmed = stationName.trim();
    final direct = _nowPlaying[trimmed];
    if (direct != null && direct.isNotEmpty) return direct;
    final lower = trimmed.toLowerCase();
    for (final entry in _nowPlaying.entries) {
      if (entry.key.trim().toLowerCase() == lower && entry.value.isNotEmpty) {
        return entry.value;
      }
    }
    return null;
  }

  void addTrackUpdateListener(ElzicyTrackUpdateCallback listener) {
    _listeners.add(listener);
  }

  void removeTrackUpdateListener(ElzicyTrackUpdateCallback listener) {
    _listeners.remove(listener);
  }

  void acquire() {
    _acquireCount++;
    if (_acquireCount == 1) {
      unawaited(_start());
    }
  }

  void release() {
    if (_acquireCount == 0) return;
    _acquireCount--;
    if (_acquireCount <= 0) {
      _acquireCount = 0;
      unawaited(_stop());
    }
  }

  Future<void> refreshHistory() => _fetchHistory();

  Future<void> _start() async {
    if (_running) return;
    _running = true;
    await _fetchHistory();
    _sseLoop = _runSseLoop();
  }

  Future<void> _stop() async {
    _running = false;
    _sseClient?.close();
    _sseClient = null;
    await _sseLoop;
    _sseLoop = null;
  }

  Future<void> dispose() async {
    await _stop();
    await _nowPlayingController.close();
    await _historyController.close();
    _httpClient.close();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await _httpClient.get(
        _buildUri('/api/history'),
        headers: _headers(),
      );
      if (response.statusCode != 200) {
        debugPrint('Elzicy history HTTP ${response.statusCode}');
        return;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;
      final history = Map<String, dynamic>.from(decoded).map<String, List<String>>(
        (key, value) {
          if (value is List) {
            return MapEntry(
              key.toString(),
              value.map((entry) => entry.toString()).toList(),
            );
          }
          return MapEntry(key.toString(), const <String>[]);
        },
      );
      _history = history;
      _historyController.add(history);
      _mergeNowPlayingFromHistory();
    } catch (error, stackTrace) {
      debugPrint('Elzicy history failed: $error\n$stackTrace');
    }
  }

  Future<void> _runSseLoop() async {
    while (_running) {
      _sseClient?.close();
      _sseClient = http.Client();
      try {
        final request = http.Request('GET', streamHistoryUri);
        request.headers.addAll(_headers(acceptEventStream: true));
        final response = await _sseClient!.send(request);
        if (response.statusCode != 200) {
          debugPrint('Elzicy SSE HTTP ${response.statusCode}');
          await Future<void>.delayed(_sseRetryDelay);
          continue;
        }
        var eventType = '';
        final dataBuffer = StringBuffer();
        var lineBuffer = '';
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          if (!_running) break;
          lineBuffer += chunk;
          while (lineBuffer.contains('\n')) {
            final index = lineBuffer.indexOf('\n');
            var line = lineBuffer.substring(0, index);
            lineBuffer = lineBuffer.substring(index + 1);
            if (line.endsWith('\r')) {
              line = line.substring(0, line.length - 1);
            }
            if (line.isEmpty) {
              _dispatchSseEvent(eventType, dataBuffer.toString());
              eventType = '';
              dataBuffer.clear();
              continue;
            }
            if (line.startsWith('event:')) {
              eventType = line.substring('event:'.length).trim();
            } else if (line.startsWith('data:')) {
              if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
              dataBuffer.write(line.substring('data:'.length).trim());
            }
          }
        }
      } catch (error, stackTrace) {
        if (_running) {
          debugPrint('Elzicy SSE error: $error\n$stackTrace');
        }
      }
      if (_running) {
        await Future<void>.delayed(_sseRetryDelay);
      }
    }
  }

  void _dispatchSseEvent(String eventType, String data) {
    if (data.isEmpty) return;
    if (eventType.isNotEmpty &&
        eventType != 'track_update' &&
        eventType != 'message') {
      return;
    }
    _handleTrackUpdate(data);
  }

  void _mergeNowPlayingFromHistory() {
    if (_history.isEmpty) return;
    final merged = <String, String>{};
    for (final entry in _history.entries) {
      if (entry.value.isNotEmpty) {
        merged[entry.key] = entry.value.last;
      }
    }
    if (merged.isEmpty) return;
    final previous = _nowPlaying;
    _nowPlaying = {...merged, ..._nowPlaying};
    if (!mapEquals(previous, _nowPlaying)) {
      _nowPlayingController.add(_nowPlaying);
      _notifyListenersOfChanges(previous, _nowPlaying);
    }
  }

  void _handleTrackUpdate(String payload) {
    try {
      final snapshot = parseElzicyStreamPayload(payload);
      if (snapshot == null || snapshot.isEmpty) {
        debugPrint('Elzicy stream payload parse failed');
        return;
      }
      final previous = _nowPlaying;
      _nowPlaying = snapshot;
      _nowPlayingController.add(snapshot);
      _notifyListenersOfChanges(previous, snapshot);
    } catch (error, stackTrace) {
      debugPrint('Elzicy track update failed: $error\n$stackTrace');
    }
  }

  void _notifyListenersOfChanges(
    Map<String, String> previous,
    Map<String, String> next,
  ) {
    for (final entry in next.entries) {
      if (previous[entry.key] == entry.value) continue;
      for (final listener in _listeners) {
        listener(entry.key, entry.value);
      }
    }
  }

  Uri _buildUri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> _headers({bool acceptEventStream = false}) => {
    'X-App-Token': _token,
    'User-Agent': 'Classipod/2.1',
    'Cache-Control': 'no-cache',
    if (acceptEventStream) 'Accept': 'text/event-stream',
  };
}
