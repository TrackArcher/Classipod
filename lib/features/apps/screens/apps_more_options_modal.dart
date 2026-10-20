import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/options_list_tile.dart';
import 'package:classipod/features/apps/models/apps_options_args.dart';
import 'package:classipod/features/apps/providers/apps_preferences_provider.dart';
import 'package:classipod/features/apps/providers/installed_apps_provider.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _AppsMoreOptions {
  rename,
  hide,
  unhide,
  cancel;

  String title(BuildContext context, {required bool fromHiddenList}) {
    switch (this) {
      case rename:
        return context.localization.appRenameAction;
      case hide:
        return context.localization.appHideAction;
      case unhide:
        return context.localization.appUnhideAction;
      case cancel:
        return context.localization.cancelText;
    }
  }
}

class AppsMoreOptionsModal extends ConsumerStatefulWidget {
  const AppsMoreOptionsModal({
    super.key,
    required this.routeName,
    required this.args,
  });

  final String routeName;
  final AppsOptionsArgs args;

  @override
  ConsumerState createState() => _AppsMoreOptionsModalState();
}

class _AppsMoreOptionsModalState extends ConsumerState<AppsMoreOptionsModal>
    with CustomScreen {
  @override
  String get routeName => widget.routeName;

  @override
  List<_AppsMoreOptions> get displayItems => [
    _AppsMoreOptions.rename,
    if (widget.args.fromHiddenList)
      _AppsMoreOptions.unhide
    else
      _AppsMoreOptions.hide,
    _AppsMoreOptions.cancel,
  ];

  @override
  Future<void> onSelectPressed() =>
      _onOptionSelected(displayItems[selectedDisplayItem]);

  Future<void> _onOptionSelected(_AppsMoreOptions option) async {
    setState(() => selectedDisplayItem = displayItems.indexOf(option));
    switch (option) {
      case _AppsMoreOptions.rename:
        final name = await context.pushNamed<String>(
          Routes.appsRename.name,
          extra: widget.args.app,
        );
        if (name != null && name.trim().isNotEmpty && mounted) {
          await ref
              .read(appsPreferencesProvider.notifier)
              .setCustomLabel(widget.args.app.id, name.trim());
          ref.invalidate(installedAppsProvider);
          ref.invalidate(hiddenInstalledAppsProvider);
        }
        if (mounted) context.pop();
        break;
      case _AppsMoreOptions.hide:
        await ref
            .read(appsPreferencesProvider.notifier)
            .setHidden(widget.args.app.id, hidden: true);
        ref.invalidate(installedAppsProvider);
        ref.invalidate(hiddenInstalledAppsProvider);
        if (mounted) context.pop();
        break;
      case _AppsMoreOptions.unhide:
        await ref
            .read(appsPreferencesProvider.notifier)
            .setHidden(widget.args.app.id, hidden: false);
        ref.invalidate(installedAppsProvider);
        ref.invalidate(hiddenInstalledAppsProvider);
        if (mounted) context.pop();
        break;
      case _AppsMoreOptions.cancel:
        if (mounted) context.pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appSurfaceColor,
        border: Border.all(color: context.appOutlineColor),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        controller: scrollController,
        itemCount: displayItems.length,
        prototypeItem: const OptionsListTile(text: '', isSelected: false),
        itemBuilder: (context, index) {
          final option = displayItems[index];
          return OptionsListTile(
            text: option.title(
              context,
              fromHiddenList: widget.args.fromHiddenList,
            ),
            isSelected: index == selectedDisplayItem,
            onTap: () async => _onOptionSelected(option),
          );
        },
      ),
    );
  }
}
