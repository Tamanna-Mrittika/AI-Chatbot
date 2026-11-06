import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/chat/presentation/conversations_screen.dart';

/// Chooses the root screen based on the session.
///
/// Because this is driven by provider state rather than navigation, signing out
/// from anywhere in the app returns to the sign-in screen with an empty stack —
/// no authenticated route can survive underneath it.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: isSignedIn
          ? const ConversationsScreen(key: ValueKey('conversations'))
          : const SignInScreen(key: ValueKey('sign-in')),
    );
  }
}
