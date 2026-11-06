import 'conversation.dart';
import 'message_role.dart';

/// Renders a conversation as plain text for the clipboard.
///
/// Kept in the domain layer, free of Flutter imports, so the exact output
/// format is unit-testable without pumping a widget.
abstract final class ConversationExport {
  /// Formats [conversation] as a readable transcript.
  ///
  /// Speaker labels are prefixed so the copied text still makes sense when
  /// pasted somewhere with no styling, and failed or still-streaming turns are
  /// skipped rather than pasted as blanks.
  static String toPlainText(
    Conversation conversation, {
    String userLabel = 'You',
    String assistantLabel = 'Assistant',
  }) {
    final buffer = StringBuffer()
      ..writeln('# ${conversation.title}')
      ..writeln();

    for (final message in conversation.messages) {
      final text = message.text.trim();
      if (text.isEmpty) continue;
      if (message.status == MessageStatus.failed) continue;

      buffer
        ..writeln('## ${message.isFromUser ? userLabel : assistantLabel}')
        ..writeln()
        ..writeln(text)
        ..writeln();
    }

    return buffer.toString().trimRight();
  }

  /// True when there is anything worth copying.
  static bool hasContent(Conversation conversation) =>
      conversation.messages.any(
        (message) =>
            message.text.trim().isNotEmpty &&
            message.status != MessageStatus.failed,
      );
}
