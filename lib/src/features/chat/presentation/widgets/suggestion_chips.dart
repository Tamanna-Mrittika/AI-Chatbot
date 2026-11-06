import 'package:flutter/material.dart';

/// Starter prompts shown in an empty thread.
///
/// Gives the user a zero-typing way to see streaming in action, which doubles
/// as onboarding for what the assistant can do.
class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  static const List<({String label, String prompt})> _suggestions = [
    (
      label: 'Explain a concept',
      prompt: 'Explain how HTTP streaming works, in simple terms.',
    ),
    (
      label: 'Write some code',
      prompt: 'Write a Dart function that debounces a callback.',
    ),
    (
      label: 'Brainstorm',
      prompt: 'Give me five app ideas that use on-device machine learning.',
    ),
    (
      label: 'Summarise',
      prompt: 'Summarise the pros and cons of the BLoC pattern in Flutter.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final suggestion in _suggestions)
          ActionChip(
            label: Text(suggestion.label),
            onPressed: () => onSelected(suggestion.prompt),
          ),
      ],
    );
  }
}
