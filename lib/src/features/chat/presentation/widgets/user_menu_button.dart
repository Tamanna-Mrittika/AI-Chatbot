import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/conversation_list_controller.dart';

/// App-bar avatar that opens the account menu.
class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<_MenuAction>(
      tooltip: user.displayName,
      offset: const Offset(0, 48),
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AppAvatar.initials(user.initials, size: 36),
            title: Text(user.displayName),
            subtitle: user.email == null ? null : Text(user.email!),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _MenuAction.settings,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        const PopupMenuItem(
          value: _MenuAction.signOut,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Sign out'),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AppAvatar.initials(user.initials, size: 34),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.settings:
        await AppRoutes.openSettings(context);
      case _MenuAction.signOut:
        final shouldClear = await _confirmSignOut(context);
        if (shouldClear == null) return;
        if (shouldClear) {
          await ref.read(conversationListControllerProvider.notifier).clear();
        }
        await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  /// Returns `true` to also wipe local history, `false` to keep it, `null` when
  /// the user cancels.
  Future<bool?> _confirmSignOut(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your chats are stored on this device. You can keep them for the '
          'next sign-in or delete them now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete chats'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep chats'),
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { settings, signOut }
