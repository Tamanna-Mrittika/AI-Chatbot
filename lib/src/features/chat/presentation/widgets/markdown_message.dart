import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import 'code_block.dart';

/// Renders assistant text as Markdown, the way ChatGPT and Gemini do.
///
/// ## Streaming
///
/// This widget is rebuilt on every batch of tokens with the text received so
/// far, so the answer appears progressively rather than as one block. That
/// means it is routinely handed *incomplete* Markdown — an unterminated code
/// fence, half a bold marker, a table with one row. `GptMarkdown` parses
/// partial input without throwing, and the code-fence builder is told whether
/// the closing fence has arrived via its `closed` flag.
///
/// A block cursor is appended while [isStreaming] is true. It is part of the
/// text rather than a sibling widget so it sits inline at the end of the last
/// line, instead of dropping onto a line of its own.
class MarkdownMessage extends StatelessWidget {
  const MarkdownMessage({
    super.key,
    required this.text,
    this.isStreaming = false,
  });

  final String text;
  final bool isStreaming;

  /// Half-block character used as the streaming caret.
  static const String _caret = '▌';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GptMarkdown(
      isStreaming ? '$text$_caret' : text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        height: 1.5,
      ),
      codeBuilder: (context, name, code, closed) =>
          CodeBlock(language: name, code: code, isClosed: closed),
    );
  }
}
