import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/display_list_tile.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/core/widgets/fast_scroll_indicator.dart';
import 'package:classipod/features/apps/models/apps_options_args.dart';
import 'package:classipod/features/apps/models/installed_app.dart';
import 'package:classipod/features/apps/providers/installed_apps_provider.dart';
import 'package:classipod/features/apps/services/installed_apps_service.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HiddenAppsScreen extends ConsumerStatefulWidget {
  const HiddenAppsScreen({super.key});

  @override
  ConsumerState createState() => _HiddenAppsScreenState();
}

class _HiddenAppsScreenState extends ConsumerState<HiddenAppsScreen>
    with CustomScreen {
  @override
  String get screenStateKey => routeName;

  @override
  String get routeName => Routes.hiddenApps.name;

  @override
  List<InstalledApp> get displayItems =>
      ref.watch(hiddenInstalledAppsProvider).value ?? const [];

  @override
  Future<void> onSelectPressed() => _launchApp(selectedDisplayItem);

  @override
  void onSelectLongPress() => _openOptions(selectedDisplayItem);

  Future<void> _launchApp(int index) async {
    final apps = displayItems;
    if (index < 0 || index >= apps.length) return;
    setState(() => selectedDisplayItem = index);
    await InstalledAppsService.instance.launchApp(apps[index]);
  }

  void _openOptions(int index) {
    final apps = displayItems;
    if (index < 0 || index >= apps.length) return;
    setState(() => selectedDisplayItem = index);
    context.goNamed(
      Routes.hiddenAppsMoreOptions.name,
      extra: AppsOptionsArgs(app: apps[index], fromHiddenList: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(hiddenInstalledAppsProvider);

    return appsAsync.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.appsLoadError,
              ),
            ),
          ],
        ),
      ),
      data: (apps) {
        if (apps.isEmpty) {
          return CupertinoPageScaffold(
            child: Column(
              children: [
                Expanded(
                  child: EmptyStateWidget(
                    emptyDescription: context.localization.noHiddenApps,
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
                  itemCount: apps.length,
                  itemExtent: displayTileHeight,
                  labelAt: (index) => apps[index].label,
                  child: CupertinoScrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: apps.length,
                      prototypeItem: const DisplayListTile(
                        text: '',
                        isSelected: false,
                      ),
                      itemBuilder: (context, index) => DisplayListTile(
                        key: ValueKey(apps[index].id),
                        text: apps[index].label,
                        isSelected: selectedDisplayItem == index,
                        onTap: () async => _launchApp(index),
                      ),
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
