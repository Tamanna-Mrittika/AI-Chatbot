import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fenced code block, styled after the one in ChatGPT and Gemini.
///
/// A header strip carries the language label and a copy action; the body
/// scrolls horizontally rather than wrapping, so indentation stays readable.
///
/// [isClosed] is false while the closing fence has not streamed in yet. The
/// block still renders — it just omits the copy button, because copying a
/// half-written snippet is rarely what the user wants.
class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.language,
    required this.code,
    this.isClosed = true,
  });

  final String language;
  final String code;
  final bool isClosed;

  static const TextStyle _monospace = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Consolas', 'Menlo', 'Courier New'],
    fontSize: 13,
    height: 1.5,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = language.trim().isEmpty ? 'code' : language.trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(label: label, code: code, isClosed: isClosed),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Text(
              code.trimRight(),
              style: _monospace.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.code,
    required this.isClosed,
  });

  final String label;
  final String code;
  final bool isClosed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (isClosed)
            TextButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: const Text('Copy'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: scheme.onSurfaceVariant,
                textStyle: theme.textTheme.labelSmall,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Code copied')));
  }
}
