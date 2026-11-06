import 'package:ai_chatbot/src/core/storage/key_value_store.dart';

/// In-memory [KeyValueStore] for tests.
///
/// [failOnWrite] lets a test simulate a full or read-only disk so the
/// rollback paths in the controllers can be exercised.
class FakeKeyValueStore implements KeyValueStore {
  FakeKeyValueStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  bool failOnWrite = false;

  /// Number of successful writes, used to assert that streaming deltas are not
  /// persisted on every token.
  int writeCount = 0;

  @override
  String? readString(String key) => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    if (failOnWrite) throw Exception('disk full');
    _data[key] = value;
    writeCount++;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Set<String> keys() => _data.keys.toSet();
}
