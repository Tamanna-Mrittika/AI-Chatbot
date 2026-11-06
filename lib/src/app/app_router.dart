import 'package:flutter/material.dart';

import '../features/chat/presentation/chat_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Named routes for the screens that are pushed onto the navigator.
///
/// The root screen is chosen reactively by `AuthGate` rather than by a route,
/// so signing out cannot leave an authenticated screen on the stack.
abstract final class AppRoutes {
  static const String chat = '/chat';
  static const String settings = '/settings';

  /// Builds the route table, translating arguments into typed screen inputs.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      chat => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) =>
            ChatScreen(conversationId: settings.arguments! as String),
      ),
      AppRoutes.settings => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SettingsScreen(),
      ),
      _ => null,
    };
  }

  /// Pushes the thread screen for [conversationId].
  static Future<void> openChat(BuildContext context, String conversationId) =>
      Navigator.of(context).pushNamed(chat, arguments: conversationId);

  static Future<void> openSettings(BuildContext context) =>
      Navigator.of(context).pushNamed(settings);
}
