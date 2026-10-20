import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/extensions/go_router_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/subsonic/internet_radio_station.dart';
import 'package:classipod/core/subsonic/subsonic_controller.dart';
import 'package:classipod/core/widgets/display_list_tile.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/core/widgets/fast_scroll_indicator.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/radio/providers/elzicy_radio_overview_provider.dart';
import 'package:classipod/features/music/radio/providers/internet_radio_provider.dart';
import 'package:classipod/features/music/radio/services/radio_station_cover_cache.dart';
import 'package:classipod/features/music/radio/widgets/add_radio_station_dialog.dart';
import 'package:classipod/features/settings/providers/elzicy_settings_provider.dart';
import 'package:classipod/features/settings/widgets/subsonic_dialog.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> with CustomScreen {
  @override
  String get screenStateKey => routeName;

  @override
  String get routeName => Routes.radio.name;

  @override
  int get extraDisplayItems => 1;

  List<InternetRadioStation> get _stations =>
      ref.watch(internetRadioStationsProvider).value ?? const [];

  @override
  List<InternetRadioStation> get displayItems => _stations;

  bool get _subsonicReady {
    final remote = ref.read(subsonicControllerProvider).value;
    return remote != null && remote.enabled && remote.signedIn;
  }

  bool get _elzicyOverview =>
      ref.watch(elzicyConfiguredProvider).value ?? false;

  String _stationLine(
    InternetRadioStation station,
    Map<String, String> elzicyNowPlaying,
  ) {
    if (!_elzicyOverview) return station.name;
    final raw = elzicyTrackForStation(elzicyNowPlaying, station.name);
    return formatRadioStationOverviewLine(station.name, raw);
  }

  @override
  Future<void> onSelectPressed() => _onItemSelected(selectedDisplayItem);

  @override
  Future<void> onSelectLongPress() async {
    if (selectedDisplayItem == 0) return;
    final station = _stations[selectedDisplayItem - 1];
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.localization.deleteRadioStationTitle),
        content: Text(
          context.localization.deleteRadioStationMessage(station.name),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.localization.cancelText),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.localization.removeRadioStationAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(subsonicControllerProvider.notifier)
        .deleteInternetRadioStation(station.id);
    ref.invalidate(internetRadioStationsProvider);
  }

  Future<void> _onItemSelected(int index) async {
    setState(() => selectedDisplayItem = index);
    if (!_subsonicReady) {
      await showSubsonicDialog(context);
      return;
    }
    if (index == 0) {
      final added = await showAddRadioStationDialog(context);
      if (added && mounted) ref.invalidate(internetRadioStationsProvider);
      return;
    }
    await _playStation(index - 1);
  }

  Future<void> _playStation(int stationIndex) async {
    final stations = _stations;
    if (stationIndex < 0 || stationIndex >= stations.length) return;

    final serverId = ref.read(subsonicControllerProvider).value!.config!.id;
    final subtitle = context.localization.radioLiveLabel;
    final metadataList = await Future.wait(
      stations.map((station) async {
        final localCover = await ensureRadioStationLocalCover(
          station,
          subsonicCoverUrl: (coverArtId) => ref
              .read(subsonicControllerProvider.notifier)
              .coverArtUri(coverArtId)
              ?.toString(),
        );
        return station.toPlaybackMetadata(
          serverId: serverId,
          streamSubtitle: subtitle,
          localCoverPath: localCover,
        );
      }),
    );

    await ref.read(audioPlayerServiceProvider.notifier).playInternetRadio(
          metadataList: metadataList,
          stationIndex: stationIndex,
        );
    if (!mounted) return;
    await context.openUniqueNamed(
      Routes.nowPlaying.name,
      extra: Routes.radio.name,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(internetRadioStationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(internetRadioStationsProvider);
    final remote = ref.watch(subsonicControllerProvider).value;
    final elzicyNowPlaying = _elzicyOverview
        ? (ref.watch(elzicyRadioNowPlayingProvider).value ?? const {})
        : const <String, String>{};

    if (remote != null && remote.enabled && !remote.signedIn) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.radioSubsonicRequired,
              ),
            ),
          ],
        ),
      );
    }

    return stationsAsync.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.radioLoadError,
              ),
            ),
          ],
        ),
      ),
      data: (stations) {
        if (remote == null || !remote.enabled) {
          return CupertinoPageScaffold(
            child: Column(
              children: [
                Expanded(
                  child: EmptyStateWidget(
                    emptyDescription: context.localization.radioSubsonicRequired,
                  ),
                ),
              ],
            ),
          );
        }

        if (stations.isEmpty) {
          return CupertinoPageScaffold(
            child: Column(
              children: [
                Expanded(
                  child: CupertinoScrollbar(
                    controller: scrollController,
                    child: ListView(
                      controller: scrollController,
                      children: [
                        DisplayListTile(
                          text: context.localization.addRadioStationTitle,
                          isSelected: selectedDisplayItem == 0,
                          onTap: () async => _onItemSelected(0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return CupertinoPageScaffold(
          child: Column(
            children: [
              Flexible(
                child: FastScrollIndicator(
                  wheelScrollIndex: wheelScrollIndex,
                  itemCount: stations.length + 1,
                  itemExtent: displayTileHeight,
                  labelAt: (index) => index == 0
                      ? ''
                      : _stationLine(stations[index - 1], elzicyNowPlaying),
                  child: CupertinoScrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: stations.length + 1,
                      prototypeItem: const DisplayListTile(
                        text: '',
                        isSelected: false,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return DisplayListTile(
                            text: context.localization.addRadioStationTitle,
                            isSelected: selectedDisplayItem == 0,
                            onTap: () async => _onItemSelected(0),
                          );
                        }
                        final station = stations[index - 1];
                        return DisplayListTile(
                          key: ValueKey(station.id),
                          text: _stationLine(station, elzicyNowPlaying),
                          isSelected: selectedDisplayItem == index,
                          onTap: () async => _onItemSelected(index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
