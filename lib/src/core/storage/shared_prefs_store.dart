import 'package:shared_preferences/shared_preferences.dart';

import '../errors/app_exception.dart';
import 'key_value_store.dart';

/// [KeyValueStore] backed by `SharedPreferences`.
///
/// The plugin is opened once during bootstrap and the synchronous
/// [SharedPreferences] handle is injected here, so reads never need to be
/// awaited from the UI layer.
class SharedPrefsStore implements KeyValueStore {
  const SharedPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? readString(String key) => _prefs.getString(key);

  @override
  Future<void> writeString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (error) {
      throw StorageException(cause: error);
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs.remove(key);
    } catch (error) {
      throw StorageException(cause: error);
    }
  }

  @override
  Set<String> keys() => _prefs.getKeys();
}
