import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Shows the current system prompt and opens a dialog to edit it.
class SystemPromptTile extends StatelessWidget {
  const SystemPromptTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.psychology_outlined),
      title: const Text('System prompt'),
      subtitle: Text(
        value.isEmpty ? 'None' : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () => _edit(context),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: value);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('System prompt'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Describe how the assistant should behave…',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext)
                    .pop(AppConstants.defaultSystemPrompt),
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result != null) onChanged(result);
  }
}
