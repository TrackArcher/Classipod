import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/widgets/display_list_tile.dart';
import 'package:classipod/core/widgets/input_text_bar.dart';
import 'package:classipod/features/apps/models/installed_app.dart';
import 'package:classipod/features/custom_screen_elements/custom_input_text_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _RenameStep { editName, confirm, cancel }

class AppRenameScreen extends ConsumerStatefulWidget {
  const AppRenameScreen({super.key, required this.app});

  final InstalledApp app;

  @override
  ConsumerState createState() => _AppRenameScreenState();
}

class _AppRenameScreenState extends ConsumerState<AppRenameScreen>
    with CustomInputTextScreen {
  @override
  String get routeName => Routes.appsRename.name;

  @override
  List<_RenameStep> get displayItems => _RenameStep.values;

  @override
  void initState() {
    inputText = widget.app.label;
    inputTextBarController.initialText = widget.app.label;
    super.initState();
  }

  @override
  Future<void> onSelectAction() async {
    await _onAction(selectedDisplayItem);
  }

  Future<void> _onAction(int index) async {
    setState(() => selectedDisplayItem = index);
    switch (displayItems[index]) {
      case _RenameStep.editName:
        reopenInputTextBar();
        break;
      case _RenameStep.confirm:
        context.pop(inputText.trim());
        break;
      case _RenameStep.cancel:
        context.pop();
        break;
    }
  }

  String _titleFor(_RenameStep step) {
    switch (step) {
      case _RenameStep.editName:
        return context.localization.appRenameEditAction;
      case _RenameStep.confirm:
        return context.localization.buttonConfirmText;
      case _RenameStep.cancel:
        return context.localization.cancelText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Flexible(
                child: CupertinoScrollbar(
                  controller: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: displayItems.length,
                    prototypeItem: const DisplayListTile(
                      text: '',
                      isSelected: false,
                    ),
                    itemBuilder: (context, index) => DisplayListTile(
                      isSelected: selectedDisplayItem == index,
                      text: _titleFor(displayItems[index]),
                      onTap: () async => _onAction(index),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isInputTextBarActive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: InputTextBar(
                inputTextBarController: inputTextBarController,
                onSearchTextChanged: (value) {
                  setState(() => inputText = value);
                },
              ),
            ),
        ],
      ),
    );
  }
}
