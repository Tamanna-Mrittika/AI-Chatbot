/// The locally signed-in user.
///
/// Authentication here is deliberately local-only: the app has no backend, so
/// a profile is created on the device and used to scope conversations and to
/// render avatars. Swapping in Firebase Auth or an OAuth flow later means
/// replacing `AuthRepository` — nothing above the data layer changes.
class AppUser {
  const AppUser({required this.id, required this.displayName, this.email});

  final String id;
  final String displayName;
  final String? email;

  /// Up to two uppercase letters for the avatar fallback, e.g. `Ada L` → `AL`.
  String get initials {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'displayName': displayName,
    if (email != null) 'email': email,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    displayName: json['displayName'] as String? ?? 'You',
    email: json['email'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.displayName == displayName &&
          other.email == email;

  @override
  int get hashCode => Object.hash(id, displayName, email);
}
