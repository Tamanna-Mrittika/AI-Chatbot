import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/conversation.dart';

/// Persists conversations locally, one [KeyValueStore] entry per thread.
///
/// Storing threads separately (rather than one big blob) means saving a message
/// only rewrites the conversation it belongs to, which keeps writes cheap while
/// tokens are streaming in.
class ConversationStore {
  const ConversationStore(this._store);

  static const String _prefix = 'conversation.';

  final KeyValueStore _store;

  /// All stored conversations, most recently updated first.
  ///
  /// Entries that fail to decode are skipped and removed rather than throwing:
  /// one corrupt record should not make the whole list screen unusable.
  Future<List<Conversation>> loadAll() async {
    final conversations = <Conversation>[];
    final corruptKeys = <String>[];

    for (final key in _store.keys()) {
      if (!key.startsWith(_prefix)) continue;
      final raw = _store.readString(key);
      if (raw == null) continue;

      try {
        conversations.add(
          Conversation.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } on Object {
        corruptKeys.add(key);
      }
    }

    for (final key in corruptKeys) {
      await _store.remove(key);
    }

    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  /// Writes [conversation], overwriting any previous version.
  Future<void> save(Conversation conversation) async {
    try {
      await _store.writeString(
        '$_prefix${conversation.id}',
        jsonEncode(conversation.toJson()),
      );
    } on StorageException {
      rethrow;
    } on Object catch (error) {
      throw StorageException(cause: error);
    }
  }

  /// Deletes the conversation with [id]; a no-op when it does not exist.
  Future<void> delete(String id) => _store.remove('$_prefix$id');

  /// Removes every stored conversation, used when signing out.
  Future<void> clear() async {
    final keys = _store.keys().where((key) => key.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _store.remove(key);
    }
  }
}
