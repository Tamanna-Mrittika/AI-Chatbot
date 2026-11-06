import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'widgets/sign_in_form.dart';

/// Landing screen shown while signed out.
///
/// The layout is a centred, width-constrained column so it reads well on a
/// phone and does not stretch across a desktop window.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Logo(theme: theme),
                  const SizedBox(height: 28),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Streamed replies from free AI models. '
                    'Pick a name to get started — everything stays on this '
                    'device.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SignInForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 88,
        width: 88,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 42,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
