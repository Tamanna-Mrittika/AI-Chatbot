/// Minimal persistence contract used by every repository in the app.
///
/// Abstracting `SharedPreferences` behind this interface keeps the data layer
/// testable (see `FakeKeyValueStore` in the tests) and means swapping in an
/// encrypted backend later is a one-class change.
///
/// > **Security note:** [SharedPrefsStore] is *not* encrypted. It is fine for
/// > conversation history, but a production build should store the Gemini API
/// > key in `flutter_secure_storage` (Keychain / Keystore) by providing a
/// > second implementation of this interface.
abstract interface class KeyValueStore {
  /// Reads a string, or `null` when the key was never written.
  String? readString(String key);

  /// Writes [value] under [key].
  Future<void> writeString(String key, String value);

  /// Removes [key]; a no-op when it is absent.
  Future<void> remove(String key);

  /// All keys currently present, used for bulk conversation loading.
  Set<String> keys();
}
