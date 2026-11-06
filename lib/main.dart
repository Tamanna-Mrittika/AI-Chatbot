import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/app.dart';
import 'src/app/app_bootstrap.dart';
import 'src/core/providers/core_providers.dart';

/// Entry point.
///
/// All asynchronous start-up work (opening local storage, restoring the
/// signed-in user, reading persisted settings) happens in [bootstrap] so that
/// the widget tree itself never has to deal with an "uninitialised" state.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final result = await bootstrap();

  runApp(
    ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(result.store)],
      child: const AiChatbotApp(),
    ),
  );
}
