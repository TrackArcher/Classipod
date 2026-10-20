import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLifecycleStateProvider =
    NotifierProvider<AppLifecycleStateNotifier, AppLifecycleState>(
      AppLifecycleStateNotifier.new,
    );

class AppLifecycleStateNotifier extends Notifier<AppLifecycleState> {
  @override
  AppLifecycleState build() =>
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  void update(AppLifecycleState next) {
    if (state == next) return;
    state = next;
  }
}

/// True when the app is visible and interactive (not behind another full-screen app).
bool appLifecycleIsInteractive(AppLifecycleState state) {
  return state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;
}
