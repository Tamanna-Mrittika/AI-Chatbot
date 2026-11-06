import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom input bar.
///
/// While a reply streams, the send button becomes a stop button so the user is
/// never stuck waiting for a long generation to finish.
class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    required this.onStop,
    required this.isStreaming,
    this.enabled = true,
    this.hintText = 'Message…',
  });

  final ValueChanged<String> onSend;
  final VoidCallback onStop;
  final bool isStreaming;
  final bool enabled;
  final String hintText;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
    // Keep focus so the user can keep typing without tapping the field again.
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Shortcuts(
                shortcuts: const {
                  // Enter sends; Shift+Enter inserts a newline.
                  SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
                },
                child: Actions(
                  actions: {
                    _SendIntent: CallbackAction<_SendIntent>(
                      onInvoke: (_) {
                        _send();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: widget.hintText),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _ActionButton(
              isStreaming: widget.isStreaming,
              enabled: widget.enabled && (_hasText || widget.isStreaming),
              onPressed: widget.isStreaming ? widget.onStop : _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isStreaming,
    required this.enabled,
    required this.onPressed,
  });

  final bool isStreaming;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: enabled ? onPressed : null,
      tooltip: isStreaming ? 'Stop generating' : 'Send',
      iconSize: 22,
      padding: const EdgeInsets.all(14),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          isStreaming ? Icons.stop_rounded : Icons.arrow_upward_rounded,
          key: ValueKey(isStreaming),
        ),
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}
