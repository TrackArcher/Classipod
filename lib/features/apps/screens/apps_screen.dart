import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/display_list_tile.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/core/widgets/fast_scroll_indicator.dart';
import 'package:classipod/features/apps/models/apps_options_args.dart';
import 'package:classipod/features/apps/models/installed_app.dart';
import 'package:classipod/features/apps/providers/apps_preferences_provider.dart';
import 'package:classipod/features/apps/providers/installed_apps_provider.dart';
import 'package:classipod/features/apps/services/installed_apps_service.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key});

  @override
  ConsumerState createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> with CustomScreen {
  @override
  String get screenStateKey => routeName;

  @override
  String get routeName => Routes.apps.name;

  @override
  List<InstalledApp> get displayItems =>
      ref.watch(installedAppsProvider).value ?? const [];

  int get _hiddenCount => ref.watch(appsPreferencesProvider).hiddenAppIds.length;

  @override
  int get extraDisplayItems => _hiddenCount > 0 ? 1 : 0;

  bool _isHiddenAppsRow(int index, int appCount) =>
      extraDisplayItems > 0 && index == appCount;

  @override
  Future<void> onSelectPressed() async {
    final apps = displayItems;
    if (_isHiddenAppsRow(selectedDisplayItem, apps.length)) {
      await context.pushNamed(Routes.hiddenApps.name);
      return;
    }
    await _launchApp(selectedDisplayItem);
  }

  @override
  void onSelectLongPress() {
    final apps = displayItems;
    if (_isHiddenAppsRow(selectedDisplayItem, apps.length)) return;
    _openOptions(selectedDisplayItem);
  }

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
      Routes.appsMoreOptions.name,
      extra: AppsOptionsArgs(app: apps[index]),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(installedAppsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appsPreferencesProvider);
    final appsAsync = ref.watch(installedAppsProvider);

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
        if (apps.isEmpty && _hiddenCount == 0) {
          return CupertinoPageScaffold(
            child: Column(
              children: [
                Expanded(
                  child: EmptyStateWidget(
                    emptyDescription: context.localization.noAppsFound,
                  ),
                ),
              ],
            ),
          );
        }

        final itemCount = apps.length + extraDisplayItems;

        return CupertinoPageScaffold(
          child: Column(
            children: [
              Flexible(
                child: FastScrollIndicator(
                  wheelScrollIndex: wheelScrollIndex,
                  itemCount: itemCount,
                  itemExtent: displayTileHeight,
                  labelAt: (index) {
                    if (_isHiddenAppsRow(index, apps.length)) {
                      return context.localization.hiddenAppsMenuEntry(
                        _hiddenCount,
                      );
                    }
                    return apps[index].label;
                  },
                  child: CupertinoScrollbar(
                    controller: scrollController,
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: itemCount,
                      prototypeItem: const DisplayListTile(
                        text: '',
                        isSelected: false,
                      ),
                      itemBuilder: (context, index) {
                        if (_isHiddenAppsRow(index, apps.length)) {
                          return DisplayListTile(
                            text: context.localization.hiddenAppsMenuEntry(
                              _hiddenCount,
                            ),
                            isSelected: selectedDisplayItem == index,
                            onTap: () async {
                              setState(() => selectedDisplayItem = index);
                              await context.pushNamed(Routes.hiddenApps.name);
                            },
                          );
                        }
                        final app = apps[index];
                        return DisplayListTile(
                          key: ValueKey(app.id),
                          text: app.label,
                          isSelected: selectedDisplayItem == index,
                          onTap: () async => _launchApp(index),
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
