import 'package:flutter/material.dart';

import '../../../chat/domain/ai_provider.dart';

/// Obscured API-key input with a reveal toggle.
///
/// The value is committed on blur / submit rather than on every keystroke, so
/// a half-typed key is never written to disk.
///
/// When the build already carries a key (via `--dart-define`), the field is
/// deliberately left empty — it edits the *stored* key, not the baked-in one —
/// so [usesBuildTimeKey] drives a note saying the app is already configured.
/// Without that note an empty field reads as "nothing is set up", which is the
/// opposite of the truth.
class ApiKeyField extends StatefulWidget {
  const ApiKeyField({
    super.key,
    required this.provider,
    required this.initialValue,
    required this.onChanged,
    this.usesBuildTimeKey = false,
  });

  final AiProvider provider;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool usesBuildTimeKey;

  @override
  State<ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<ApiKeyField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  final _focusNode = FocusNode();
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onChanged(_controller.text.trim());
    });
  }

  @override
  void didUpdateWidget(ApiKeyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching provider swaps which key is being edited.
    if (oldWidget.provider != widget.provider) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.usesBuildTimeKey) _BuiltInKeyNotice(scheme: scheme),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: _obscured,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (value) => widget.onChanged(value.trim()),
          decoration: InputDecoration(
            labelText: widget.usesBuildTimeKey
                ? 'Override with your own key'
                : '${widget.provider.label} API key',
            hintText: widget.provider.keyHint,
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: IconButton(
              tooltip: _obscured ? 'Show key' : 'Hide key',
              onPressed: () => setState(() => _obscured = !_obscured),
              icon: Icon(
                _obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.usesBuildTimeKey
              ? 'Leave this empty to keep using the built-in key.'
              : 'Create a free key at ${widget.provider.keyUrl}. '
                    'It is stored only on this device.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Green strip confirming the app already has a working key.
class _BuiltInKeyNotice extends StatelessWidget {
  const _BuiltInKeyNotice({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A key is already built into this app, so you can start '
              'chatting right away.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
