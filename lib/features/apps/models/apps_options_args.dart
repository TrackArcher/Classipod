import 'package:classipod/features/apps/models/installed_app.dart';

class AppsOptionsArgs {
  const AppsOptionsArgs({
    required this.app,
    this.fromHiddenList = false,
  });

  final InstalledApp app;
  final bool fromHiddenList;
}
