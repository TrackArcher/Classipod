import 'dart:async';

import 'package:classipod/core/constants/keys.dart';
import 'package:classipod/core/elzicy/elzicy_client.dart';
import 'package:classipod/core/elzicy/elzicy_service.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/features/music/radio/utils/radio_elzicy_metadata.dart';
import 'package:classipod/features/music/radio/utils/radio_track_title_parser.dart';
import 'package:classipod/features/now_playing/models/now_playing_model.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/settings/providers/elzicy_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final radioMetadataSyncProvider = Provider<void>((ref) {
  final notifier = _RadioMetadataSync(ref);
  ref.onDispose(notifier.dispose);
  ref.listen(nowPlayingDetailsProvider, (_, next) {
    unawaited(notifier.syncNowPlaying(next));
  });
});

class _RadioMetadataSync {
  _RadioMetadataSync(this._ref);

  final Ref _ref;
  ElzicyClient? _elzicy;
  StreamSubscription<Map<String, String>>? _elzicyNowPlayingSubscription;
  StreamSubscription<IcyMetadata?>? _icySubscription;
  String? _lastArtist;
  String? _lastTitle;
  String? _activeStationName;

  Future<void> syncNowPlaying(NowPlayingModel model) async {
    final metadata = model.currentMetadata;
    if (metadata == null || !metadata.isInternetRadio) {
      await _stopElzicy();
      await _stopIcy();
      _activeStationName = null;
      _lastArtist = null;
      _lastTitle = null;
      return;
    }

    final stationName = metadata.albumName ?? metadata.trackName ?? '';
    if (stationName.isEmpty) return;

    if (_activeStationName == null ||
        !radioStationNamesMatch(_activeStationName!, stationName)) {
      _activeStationName = stationName;
      _lastArtist = null;
      _lastTitle = null;
    }

    final elzicyConfigured = await _ref.read(elzicyConfiguredProvider.future);
    if (elzicyConfigured) {
      await _stopIcy();
      await _startElzicy(stationName);
      return;
    }
    await _stopElzicy();
    if (model.isPlaying) {
      _startIcy();
    } else {
      await _stopIcy();
    }
  }

  Future<void> _startElzicy(String stationName) async {
    final client = await _ref.read(elzicyServiceProvider).client();
    if (client == null) return;
    if (!identical(_elzicy, client)) {
      await _stopElzicy();
      _elzicy = client;
      client.addTrackUpdateListener(_onElzicyTrackUpdate);
      _elzicyNowPlayingSubscription = client.nowPlayingStream.listen(
        (_) => _applyLatestForActiveStation(client),
      );
    }
    _applyLatestForActiveStation(client, stationName: stationName);
  }

  void _applyLatestForActiveStation(
    ElzicyClient client, {
    String? stationName,
  }) {
    final station = stationName ?? _activeStationName;
    if (station == null || station.isEmpty) return;
    final current = client.getNowPlayingForStation(station);
    if (current != null && current.isNotEmpty) {
      _applyStreamTitle(station, current);
    }
  }

  Future<void> _stopElzicy() async {
    await _elzicyNowPlayingSubscription?.cancel();
    _elzicyNowPlayingSubscription = null;
    final client = _elzicy;
    if (client == null) return;
    client.removeTrackUpdateListener(_onElzicyTrackUpdate);
    _elzicy = null;
  }

  void _onElzicyTrackUpdate(String stationName, String trackTitle) {
    _applyStreamTitle(stationName, trackTitle);
  }

  void _startIcy() {
    if (_icySubscription != null) return;
    final player = _ref.read(audioPlayerProvider);
    _icySubscription = player.icyMetadataStream.listen((metadata) {
      final title = metadata?.info?.title;
      if (title == null || title.isEmpty) return;
      final stationName = _activeStationName;
      if (stationName == null || stationName.isEmpty) return;
      _applyStreamTitle(stationName, title);
    });
  }

  Future<void> _stopIcy() async {
    await _icySubscription?.cancel();
    _icySubscription = null;
  }

  void _applyStreamTitle(String stationName, String streamTitle) {
    final current = _ref.read(nowPlayingDetailsProvider).currentMetadata;
    if (current == null || !current.isInternetRadio) return;
    final currentStation = current.albumName ?? current.trackName ?? '';
    if (!radioStationNamesMatch(currentStation, stationName)) return;

    final parsed = parseRadioStreamTitle(streamTitle);
    final artist = parsed.artist;
    final title = parsed.title ?? streamTitle.trim();
    if (artist == _lastArtist && title == _lastTitle) return;
    _lastArtist = artist;
    _lastTitle = title;

    final updated = applyRadioStreamTitle(
      metadata: current,
      stationName: currentStation,
      streamTitle: streamTitle,
      liveLabel: _liveLabel(),
    );
    publishRadioMetadataUpdate(_ref, updated);
  }

  String _liveLabel() {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return 'Live';
    return context.localization.radioLiveLabel;
  }

  Future<void> dispose() async {
    await _stopElzicy();
    await _stopIcy();
  }
}
