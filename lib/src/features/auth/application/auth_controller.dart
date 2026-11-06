import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  ref.keepAlive();
  return AuthRepository(
    ref.watch(keyValueStoreProvider),
    uuid: ref.watch(uuidProvider),
  );
});

/// Owns the session. `null` means signed out, which the router reacts to by
/// showing the sign-in screen.
class AuthController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    ref.keepAlive();
    return ref.watch(authRepositoryProvider).currentUser();
  }

  /// Signs the user in. Propagates `ValidationException` to the form.
  Future<void> signIn({required String displayName, String? email}) async {
    state = await ref
        .read(authRepositoryProvider)
        .signIn(displayName: displayName, email: email);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }
}

final authControllerProvider = NotifierProvider<AuthController, AppUser?>(
  AuthController.new,
);

/// Convenience selector so widgets can rebuild on sign-in state alone.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider) != null,
);
