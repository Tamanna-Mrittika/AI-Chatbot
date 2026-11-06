import 'package:ai_chatbot/src/app/app.dart';
import 'package:ai_chatbot/src/core/providers/core_providers.dart';
import 'package:ai_chatbot/src/features/chat/application/chat_providers.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/chat_repository.dart';
import 'package:ai_chatbot/src/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_key_value_store.dart';

/// Replays a fixed reply one delta at a time.
class _StubRepository implements ChatRepository {
  @override
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required String model,
    required String systemPrompt,
  }) async* {
    yield 'Streamed ';
    yield 'answer.';
  }
}

void main() {
  /// Phone-sized surface so the compact (single-pane) layout is exercised.
  void useCompactWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Widget buildApp(FakeKeyValueStore store) => ProviderScope(
    overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      chatRepositoryProvider.overrideWithValue(_StubRepository()),
    ],
    child: const AiChatbotApp(),
  );

  testWidgets('sign in, start a chat, and receive a streamed reply', (
    tester,
  ) async {
    useCompactWindow(tester);
    final store = FakeKeyValueStore();

    // A configured API key, so the composer is enabled.
    final container = ProviderContainer(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
    );
    await container
        .read(settingsControllerProvider.notifier)
        .setApiKey('sk-or-v1-test');
    container.dispose();

    await tester.pumpWidget(buildApp(store));
    await tester.pumpAndSettle();

    // 1. Sign in.
    expect(find.text('Start chatting'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Ada');
    await tester.tap(find.text('Start chatting'));
    await tester.pumpAndSettle();

    // 2. The empty conversation list is shown.
    expect(find.text('No chats yet'), findsOneWidget);

    // 3. Create a chat and open the thread.
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New chat'));
    await tester.pumpAndSettle();
    expect(find.text('Ask me anything'), findsOneWidget);

    // 4. Type a message; the send button enables once there is text.
    await tester.enterText(find.byType(TextField).last, 'Hello');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    // 5. The streamed deltas are assembled into a single reply bubble.
    expect(find.text('Streamed answer.'), findsOneWidget);

    // 6. The thread auto-titles itself after the first message, so "Hello"
    //    appears twice: once in the bubble and once in the app bar.
    expect(find.widgetWithText(AppBar, 'Hello'), findsOneWidget);
    expect(find.text('Hello'), findsNWidgets(2));
  });

  testWidgets('composer is disabled until an API key is configured', (
    tester,
  ) async {
    useCompactWindow(tester);
    final store = FakeKeyValueStore();

    await tester.pumpWidget(buildApp(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ada');
    await tester.tap(find.text('Start chatting'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New chat'));
    await tester.pumpAndSettle();

    expect(find.text('Add a free API key to start chatting.'), findsOneWidget);
    final composer = tester.widget<TextField>(find.byType(TextField).last);
    expect(composer.enabled, isFalse);
  });

  testWidgets('wide windows use the two-pane master/detail layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final store = FakeKeyValueStore();
    await tester.pumpWidget(buildApp(store));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ada');
    await tester.tap(find.text('Start chatting'));
    await tester.pumpAndSettle();

    // The detail pane placeholder proves both panes are mounted at once.
    expect(find.text('Pick a chat'), findsOneWidget);
    expect(find.text('No chats yet'), findsOneWidget);
  });
}
