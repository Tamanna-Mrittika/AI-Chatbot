import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../domain/app_settings.dart';
import 'settings_migration.dart';

/// Reads and writes [AppSettings].
///
/// Reads are synchronous because the underlying store is opened during
/// bootstrap — the UI never has to render a loading state for preferences.
class SettingsRepository {
  const SettingsRepository(this._store);

  static const String _key = 'app.settings';

  final KeyValueStore _store;

  /// Current settings, or the defaults when nothing has been saved yet.
  AppSettings read() {
    final raw = _store.readString(_key);
    if (raw == null) return const AppSettings();

    try {
      return SettingsMigration.apply(
        AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on Object {
      // Corrupt preferences fall back to defaults instead of bricking start-up.
      return const AppSettings();
    }
  }

  Future<void> write(AppSettings settings) =>
      _store.writeString(_key, jsonEncode(settings.toJson()));
}
