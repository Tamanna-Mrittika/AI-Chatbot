import 'chat_message.dart';

/// Contract the chat feature depends on, so the controllers never import
/// anything HTTP-related and can be driven by a fake in tests.
abstract interface class ChatRepository {
  /// Streams the assistant's reply as incremental text deltas.
  ///
  /// [history] must be ordered oldest-first and end with the user message that
  /// is being answered. Implementations emit each delta exactly once; the
  /// caller is responsible for concatenating them.
  ///
  /// Throws an `AppException` subclass on failure. Cancelling the returned
  /// stream's subscription aborts the underlying request.
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required String model,
    required String systemPrompt,
  });
}
