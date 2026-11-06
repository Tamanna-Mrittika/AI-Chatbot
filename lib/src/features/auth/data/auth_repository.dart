import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/app_user.dart';

/// Local-only authentication.
///
/// [signIn] validates the profile and persists it; there is no password
/// because there is no server to authenticate against. The seam exists so a
/// real identity provider can be dropped in without touching the UI.
class AuthRepository {
  AuthRepository(this._store, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String _key = 'auth.user';

  final KeyValueStore _store;
  final Uuid _uuid;

  /// The persisted session, or `null` when nobody is signed in.
  AppUser? currentUser() {
    final raw = _store.readString(_key);
    if (raw == null) return null;

    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// Creates and persists a session for [displayName].
  ///
  /// Throws [ValidationException] when the name is empty or the optional email
  /// is malformed, so the form can surface a field-level error.
  Future<AppUser> signIn({required String displayName, String? email}) async {
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const ValidationException('Please enter a display name.');
    }
    if (name.length > 40) {
      throw const ValidationException(
        'Display names are capped at 40 characters.',
      );
    }

    final trimmedEmail = email?.trim();
    if (trimmedEmail != null &&
        trimmedEmail.isNotEmpty &&
        !_emailPattern.hasMatch(trimmedEmail)) {
      throw const ValidationException('That email address looks invalid.');
    }

    final user = AppUser(
      id: _uuid.v4(),
      displayName: name,
      email: (trimmedEmail?.isEmpty ?? true) ? null : trimmedEmail,
    );

    await _store.writeString(_key, jsonEncode(user.toJson()));
    return user;
  }

  /// Clears the persisted session.
  Future<void> signOut() => _store.remove(_key);

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
