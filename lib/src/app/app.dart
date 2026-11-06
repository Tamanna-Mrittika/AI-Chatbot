import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/app_settings.dart';
import 'app_router.dart';
import 'auth_gate.dart';

/// Root widget: wires the theme, the route table and the auth-aware home.
class AiChatbotApp extends ConsumerWidget {
  const AiChatbotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      settingsControllerProvider.select((settings) => settings.themeMode),
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const AuthGate(),
    );
  }
}
