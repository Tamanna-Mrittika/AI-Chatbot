import 'package:ai_chatbot/src/core/providers/core_providers.dart';
import 'package:ai_chatbot/src/features/chat/application/chat_providers.dart';
import 'package:ai_chatbot/src/features/chat/application/chat_session_controller.dart';
import 'package:ai_chatbot/src/features/chat/application/conversation_list_controller.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_key_value_store.dart';

/// Repository stub that replays a scripted reply, optionally ending in an
/// error so failure paths can be exercised without touching the network.
class ScriptedRepository implements ChatRepository {
  ScriptedRepository(this.deltas, {this.error});

  final List<String> deltas;
  final Object? error;

  /// History the controller passed on the most recent call.
  List<ChatMessage>? lastHistory;

  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required String model,
    required String systemPrompt,
  }) async* {
    lastHistory = history;
    for (final delta in deltas) {
      yield delta;
    }
    if (error != null) throw error!;
  }
}

/// Wires a `ProviderContainer` around a scripted repository and an in-memory
/// store, and provides the waiting helpers the streaming tests need.
class ChatSessionHarness {
  ChatSessionHarness(ChatRepository repository) {
    store = FakeKeyValueStore();
    container = ProviderContainer(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        chatRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  }

  late final FakeKeyValueStore store;
  late final ProviderContainer container;

  /// Creates a conversation and returns its id.
  Future<String> seed() async {
    await container.read(conversationListControllerProvider.future);
    final conversation = await container
        .read(conversationListControllerProvider.notifier)
        .create();
    return conversation.id;
  }

  List<ChatMessage> messagesOf(String id) =>
      container.read(conversationProvider(id))!.messages;

  ChatSessionController notifier(String id) =>
      container.read(chatSessionControllerProvider(id).notifier);

  /// `send` returns as soon as the stream is subscribed, so the UI can scroll
  /// immediately. Tests must wait for the turn to actually finish.
  Future<void> settle(String id) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (container.read(chatSessionControllerProvider(id)).isStreaming) {
      if (DateTime.now().isAfter(deadline)) fail('Turn never completed.');
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Sends [text] and waits for the reply to complete.
  Future<void> sendAndSettle(String id, String text) async {
    await notifier(id).send(text);
    await settle(id);
  }

  /// Reopens the same store in a fresh container, simulating an app restart.
  ///
  /// Used to prove that a completed reply was actually persisted, not just
  /// held in memory by the live container.
  static ProviderContainer reopen(FakeKeyValueStore store) {
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Swaps in a different repository, used to make a retry succeed.
  void useRepository(ChatRepository repository) {
    container.updateOverrides([
      keyValueStoreProvider.overrideWithValue(store),
      chatRepositoryProvider.overrideWithValue(repository),
    ]);
  }
}
