import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/subsonic/subsonic_client.dart';
import 'package:classipod/core/subsonic/subsonic_controller.dart';
import 'package:classipod/features/music/radio/providers/internet_radio_provider.dart';
import 'package:classipod/features/music/radio/services/radio_cover_art_service.dart';
import 'package:classipod/features/settings/widgets/subsonic_dialog.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> showAddRadioStationDialog(BuildContext context) async {
  final added = await showCupertinoDialog<bool>(
    context: context,
    builder: (_) => const _AddRadioStationDialog(),
  );
  return added ?? false;
}

class _AddRadioStationDialog extends ConsumerStatefulWidget {
  const _AddRadioStationDialog();

  @override
  ConsumerState createState() => _AddRadioStationDialogState();
}

class _AddRadioStationDialogState extends ConsumerState<_AddRadioStationDialog> {
  final _name = TextEditingController();
  final _streamUrl = TextEditingController();
  final _homePageUrl = TextEditingController();
  final _coverArtUrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _streamUrl.dispose();
    _homePageUrl.dispose();
    _coverArtUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final streamUrl = _streamUrl.text.trim();
    if (name.isEmpty || streamUrl.isEmpty) {
      setState(
        () => _error = context.localization.radioAddStationFieldsRequired,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final coverArtUrl = _coverArtUrl.text.trim();
    try {
      await ref
          .read(subsonicControllerProvider.notifier)
          .createInternetRadioStation(
            name: name,
            streamUrl: streamUrl,
            homepageUrl: _homePageUrl.text.trim(),
            coverArtUrl: coverArtUrl.isEmpty ? null : coverArtUrl,
          );
      if (coverArtUrl.isNotEmpty) {
        ref.invalidate(internetRadioStationsProvider);
        final stations = await ref.read(internetRadioStationsProvider.future);
        final created = stations.where((station) => station.name == name);
        if (created.isNotEmpty) {
          await RadioCoverArtService().downloadCover(
            stationId: created.first.id,
            coverArtUrl: coverArtUrl,
          );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SubsonicException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = subsonicError(context, error.code);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = context.localization.subsonicServerError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(context.localization.addRadioStationTitle),
      content: Column(
        children: [
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _name,
            placeholder: context.localization.radioStationNameHint,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _streamUrl,
            placeholder: context.localization.radioStreamUrlHint,
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _homePageUrl,
            placeholder: context.localization.radioHomePageUrlHint,
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _coverArtUrl,
            placeholder: context.localization.radioCoverArtUrlHint,
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(context.localization.cancelText),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const CupertinoActivityIndicator()
              : Text(context.localization.addRadioStationAction),
        ),
      ],
    );
  }
}
