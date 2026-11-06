import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copy / regenerate row shown under a completed assistant message.
///
/// Hidden while the reply is still streaming: neither action is meaningful
/// against a half-written answer.
class MessageActions extends StatelessWidget {
  const MessageActions({
    super.key,
    required this.text,
    required this.onRegenerate,
    this.canRegenerate = true,
  });

  final String text;
  final VoidCallback onRegenerate;
  final bool canRegenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Action(
          icon: Icons.content_copy_rounded,
          tooltip: 'Copy',
          onPressed: () => _copy(context),
          color: scheme.onSurfaceVariant,
        ),
        if (canRegenerate)
          _Action(
            icon: Icons.refresh_rounded,
            tooltip: 'Regenerate response',
            onPressed: onRegenerate,
            color: scheme.onSurfaceVariant,
          ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 16),
      color: color,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      padding: EdgeInsets.zero,
    );
  }
}
