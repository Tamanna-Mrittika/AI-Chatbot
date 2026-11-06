import 'package:ai_chatbot/src/features/chat/domain/chat_message.dart';
import 'package:ai_chatbot/src/features/chat/domain/message_role.dart';
import 'package:ai_chatbot/src/features/chat/presentation/widgets/markdown_message.dart';
import 'package:ai_chatbot/src/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ai_chatbot/src/features/chat/presentation/widgets/message_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ChatMessage assistant(String text, MessageStatus status) => ChatMessage(
    id: 'a1',
    role: MessageRole.assistant,
    text: text,
    createdAt: DateTime(2026, 3, 1, 10),
    status: status,
  );

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('incremental rendering', () {
    testWidgets('shows a shimmer skeleton before the first token arrives', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant('', MessageStatus.streaming),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MessageSkeleton), findsOneWidget);
      expect(find.byType(MarkdownMessage), findsNothing);
    });

    testWidgets('renders partial text mid-stream, not just the final block', (
      tester,
    ) async {
      // First frame: only the opening words have arrived.
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant('The first', MessageStatus.streaming),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MessageSkeleton), findsNothing);
      final partial = tester.widget<MarkdownMessage>(
        find.byType(MarkdownMessage),
      );
      expect(partial.text, 'The first');
      expect(partial.isStreaming, isTrue);

      // Next frame: more tokens, same bubble, longer text.
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant('The first two lines', MessageStatus.streaming),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MarkdownMessage), findsOneWidget);
      expect(
        tester.widget<MarkdownMessage>(find.byType(MarkdownMessage)).text,
        'The first two lines',
      );
    });

    testWidgets('drops the caret and shows actions once the reply completes', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant('All done.', MessageStatus.sent),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      final rendered = tester.widget<MarkdownMessage>(
        find.byType(MarkdownMessage),
      );
      expect(rendered.isStreaming, isFalse);
      expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('hides the action row while still streaming', (tester) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant('partial', MessageStatus.streaming),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.content_copy_rounded), findsNothing);
    });
  });

  group('markdown', () {
    testWidgets('renders a fenced code block with a copy action', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant(
              'Example:\n\n```dart\nvoid main() {}\n```',
              MessageStatus.sent,
            ),
            onRetry: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('dart'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('renders an unterminated code fence while streaming', (
      tester,
    ) async {
      // Mid-stream the closing fence has not arrived yet; this must not throw.
      await tester.pumpWidget(
        wrap(
          MessageBubble(
            message: assistant(
              'Here:\n\n```python\nprint("hi"',
              MessageStatus.streaming,
            ),
            onRetry: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(MarkdownMessage), findsOneWidget);
    });
  });
}
