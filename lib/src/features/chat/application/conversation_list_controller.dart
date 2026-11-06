import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../domain/chat_message.dart';
import '../domain/conversation.dart';
import 'chat_providers.dart';

/// Single source of truth for every conversation.
///
/// Both the list screen and the thread screen read from here, so a token
/// arriving mid-stream updates the thread *and* the list preview from one
/// state change.
class ConversationListController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    ref.keepAlive();
    return ref.watch(conversationStoreProvider).loadAll();
  }

  List<Conversation> get _current => state.value ?? const [];

  /// Creates, persists and returns a new empty conversation.
  Future<Conversation> create() async {
    final conversation = Conversation.empty(ref.read(uuidProvider).v4());
    state = AsyncData([conversation, ..._current]);
    await ref.read(conversationStoreProvider).save(conversation);
    return conversation;
  }

  /// Looks up a conversation by id, or `null` if it was deleted.
  Conversation? byId(String id) {
    for (final conversation in _current) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  /// Replaces [next] in the list and re-sorts by recency.
  ///
  /// Set [persist] to `false` for high-frequency updates (streamed tokens) and
  /// flush once at the end of the stream instead.
  Future<void> upsert(Conversation next, {bool persist = true}) async {
    final updated = [
      next,
      for (final conversation in _current)
        if (conversation.id != next.id) conversation,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    state = AsyncData(updated);
    if (persist) await ref.read(conversationStoreProvider).save(next);
  }

  /// Applies [transform] to the conversation with [id], if it still exists.
  Future<void> mutate(
    String id,
    Conversation Function(Conversation conversation) transform, {
    bool persist = true,
  }) async {
    final current = byId(id);
    if (current == null) return;
    await upsert(transform(current), persist: persist);
  }

  /// Appends [message] to conversation [id] and bumps its `updatedAt`.
  Future<void> appendMessage(
    String id,
    ChatMessage message, {
    bool persist = true,
  }) {
    return mutate(
      id,
      (conversation) => conversation.copyWith(
        messages: [...conversation.messages, message],
        updatedAt: DateTime.now(),
      ),
      persist: persist,
    );
  }

  /// Replaces the message with [message.id] inside conversation [id].
  Future<void> replaceMessage(
    String id,
    ChatMessage message, {
    bool persist = true,
  }) {
    return mutate(
      id,
      (conversation) => conversation.copyWith(
        messages: [
          for (final existing in conversation.messages)
            if (existing.id == message.id) message else existing,
        ],
        updatedAt: DateTime.now(),
      ),
      persist: persist,
    );
  }

  /// Removes the message with [messageId], used when retrying a failed turn.
  Future<void> removeMessage(String id, String messageId) {
    return mutate(
      id,
      (conversation) => conversation.copyWith(
        messages: [
          for (final message in conversation.messages)
            if (message.id != messageId) message,
        ],
      ),
    );
  }

  Future<void> rename(String id, String title) =>
      mutate(id, (conversation) => conversation.copyWith(title: title.trim()));

  Future<void> delete(String id) async {
    state = AsyncData([
      for (final conversation in _current)
        if (conversation.id != id) conversation,
    ]);
    await ref.read(conversationStoreProvider).delete(id);
  }

  /// Wipes all local history, used when signing out.
  Future<void> clear() async {
    state = const AsyncData([]);
    await ref.read(conversationStoreProvider).clear();
  }

  /// Forces the current in-memory conversation to disk.
  Future<void> flush(String id) async {
    final conversation = byId(id);
    if (conversation != null) {
      await ref.read(conversationStoreProvider).save(conversation);
    }
  }
}

final conversationListControllerProvider =
    AsyncNotifierProvider<ConversationListController, List<Conversation>>(
      ConversationListController.new,
    );

/// Watches one conversation without rebuilding on unrelated list changes.
final conversationProvider = Provider.family<Conversation?, String>((
  ref,
  String id,
) {
  final conversations =
      ref.watch(conversationListControllerProvider).value ?? const [];
  for (final conversation in conversations) {
    if (conversation.id == id) return conversation;
  }
  return null;
});
