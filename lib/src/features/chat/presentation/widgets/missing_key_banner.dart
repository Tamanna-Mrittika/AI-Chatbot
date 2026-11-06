import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';

/// Persistent strip shown above the thread until an API key is configured.
///
/// Tapping it goes straight to Settings, so the fix is one tap from the point
/// where the user notices the problem.
class MissingKeyBanner extends StatelessWidget {
  const MissingKeyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: InkWell(
        onTap: () => AppRoutes.openSettings(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.key_rounded,
                size: 20,
                color: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add a free API key to start chatting.',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onTertiaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty-thread prompt with starter suggestions.
class EmptyThread extends StatelessWidget {
  const EmptyThread({super.key, required this.suggestions});

  /// The chip row, injected so this widget stays free of feature wiring.
  final Widget suggestions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 84,
                width: 84,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 38,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ask me anything',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Replies stream in as they are generated.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              suggestions,
            ],
          ),
        ),
      ),
    );
  }
}
