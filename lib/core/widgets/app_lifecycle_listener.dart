import 'package:classipod/core/providers/app_lifecycle_provider.dart';
import 'package:classipod/core/services/memory_trim_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _memoryChannel = MethodChannel('com.adeeteya.classipod/memory');

class ClassipodLifecycleListener extends ConsumerStatefulWidget {
  const ClassipodLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ClassipodLifecycleListener> createState() =>
      _ClassipodLifecycleListenerState();
}

class _ClassipodLifecycleListenerState
    extends ConsumerState<ClassipodLifecycleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _memoryChannel.setMethodCallHandler((call) async {
      if (call.method == 'trimMemory') {
        trimHeavyCaches();
      }
    });
    final initial = WidgetsBinding.instance.lifecycleState;
    if (initial != null) {
      ref.read(appLifecycleStateProvider.notifier).update(initial);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleStateProvider.notifier).update(state);
  }

  @override
  void didHaveMemoryPressure() {
    trimHeavyCaches();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
