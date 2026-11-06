import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../storage/key_value_store.dart';

/// Injected in `main` via a `ProviderScope` override once `SharedPreferences`
/// has been opened. Reading it without that override is a programming error.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) {
  throw UnimplementedError(
    'keyValueStoreProvider must be overridden in ProviderScope — see '
    'lib/src/app/app_bootstrap.dart',
  );
});

/// A single HTTP client shared by every data source, so connections are pooled
/// across requests. Closed automatically when the root scope is disposed.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  ref.keepAlive();
  return client;
});

/// Id generator, injected so tests can supply deterministic ids.
final uuidProvider = Provider<Uuid>((ref) => const Uuid());
