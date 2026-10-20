import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/features/app_startup/controllers/splash_controller.dart';
import 'package:classipod/core/elzicy/elzicy_bootstrap_provider.dart';
import 'package:classipod/core/providers/playback_idle_provider.dart';
import 'package:classipod/core/providers/subsonic_background_provider.dart';
import 'package:classipod/core/widgets/app_lifecycle_listener.dart'
    show ClassipodLifecycleListener;
import 'package:classipod/features/music/radio/providers/radio_metadata_sync_provider.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/l10n/generated/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassipodApp extends ConsumerWidget {
  const ClassipodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryInitialized = ref.watch(
      splashControllerProvider.select((value) => value.hasValue),
    );
    if (libraryInitialized) {
      ref.listen(audioPlayerServiceProvider, (_, _) {});
      ref.watch(radioMetadataSyncProvider);
      ref.watch(elzicyBootstrapProvider);
      ref.watch(playbackIdleProvider);
      ref.watch(subsonicBackgroundProvider);
    }
    final languageLocaleCode = ref.watch(
      settingsPreferencesControllerProvider.select(
        (value) => value.languageLocaleCode,
      ),
    );
    final appTheme = ref.watch(
      settingsPreferencesControllerProvider.select((value) => value.appTheme),
    );
    final router = ref.watch(routerProvider);
    return ClassipodLifecycleListener(
      child: CupertinoApp.router(
        onGenerateTitle: (context) => context.localization.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        locale: Locale(languageLocaleCode),
        theme: appTheme.toCupertinoTheme(),
      ),
    );
  }
}
