import 'package:classipod/core/elzicy/elzicy_bootstrap_provider.dart';
import 'package:classipod/core/elzicy/elzicy_service.dart';
import 'package:classipod/core/elzicy/elzicy_url.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/features/settings/providers/elzicy_settings_provider.dart';
import 'package:classipod/features/settings/repository/elzicy_settings_repository.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showElzicyDialog(BuildContext context) => showCupertinoDialog<void>(
  context: context,
  builder: (_) => const ElzicyDialog(),
);

class ElzicyDialog extends ConsumerStatefulWidget {
  const ElzicyDialog({super.key});

  @override
  ConsumerState createState() => _ElzicyDialogState();
}

class _ElzicyDialogState extends ConsumerState<ElzicyDialog> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _token;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _baseUrl = TextEditingController();
    _token = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repository = ref.read(elzicySettingsRepositoryProvider);
    _baseUrl.text = await repository.baseUrl() ?? defaultElzicyBaseUrl;
    _token.text = await repository.token() ?? '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final repository = ref.read(elzicySettingsRepositoryProvider);
    await repository.setBaseUrl(_baseUrl.text);
    await repository.setToken(_token.text);
    await ref.read(elzicyServiceProvider).reload();
    ref.invalidate(elzicyConfiguredProvider);
    ref.invalidate(elzicyBaseUrlProvider);
    ref.invalidate(elzicyBootstrapProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(context.localization.elzicySettingsTitle),
      content: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            context.localization.elzicySettingsDescription,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _baseUrl,
            placeholder: context.localization.elzicyBaseUrlHint,
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _token,
            placeholder: context.localization.elzicyTokenHint,
            autocorrect: false,
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(context.localization.cancelText),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _busy ? null : _save,
          child: _busy
              ? const CupertinoActivityIndicator()
              : Text(context.localization.saveChangesButton),
        ),
      ],
    );
  }
}
