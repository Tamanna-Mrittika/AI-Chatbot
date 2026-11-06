import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/storage/key_value_store.dart';
import '../core/storage/shared_prefs_store.dart';

/// Performs asynchronous start-up work and returns the dependencies the root
/// `ProviderScope` has to inject.
///
/// Doing this before `runApp` means every repository can expose synchronous
/// reads, which removes a whole class of loading states from the UI.
Future<BootstrapResult> bootstrap() async {
  final prefs = await SharedPreferences.getInstance();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // A crash reporter (Crashlytics, Sentry) would be wired in here.
    debugPrint('Uncaught framework error: ${details.exception}');
  };

  return BootstrapResult(store: SharedPrefsStore(prefs));
}

/// Everything `main` needs to build the provider overrides.
class BootstrapResult {
  const BootstrapResult({required this.store});

  final KeyValueStore store;
}
