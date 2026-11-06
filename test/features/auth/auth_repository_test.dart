import 'package:ai_chatbot/src/core/errors/app_exception.dart';
import 'package:ai_chatbot/src/features/auth/data/auth_repository.dart';
import 'package:ai_chatbot/src/features/auth/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_key_value_store.dart';

void main() {
  late FakeKeyValueStore store;
  late AuthRepository repository;

  setUp(() {
    store = FakeKeyValueStore();
    repository = AuthRepository(store);
  });

  group('signIn', () {
    test('persists the session so it survives a restart', () async {
      await repository.signIn(displayName: 'Ada Lovelace');

      final restored = AuthRepository(store).currentUser();
      expect(restored?.displayName, 'Ada Lovelace');
    });

    test('trims the display name', () async {
      final user = await repository.signIn(displayName: '  Ada  ');
      expect(user.displayName, 'Ada');
    });

    test('rejects a blank name', () {
      expect(
        () => repository.signIn(displayName: '   '),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a malformed email', () {
      expect(
        () => repository.signIn(displayName: 'Ada', email: 'not-an-email'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('treats a blank email as absent', () async {
      final user = await repository.signIn(displayName: 'Ada', email: '  ');
      expect(user.email, isNull);
    });
  });

  test('signOut clears the session', () async {
    await repository.signIn(displayName: 'Ada');
    await repository.signOut();

    expect(repository.currentUser(), isNull);
  });

  test('currentUser returns null for corrupt stored data', () async {
    await store.writeString('auth.user', 'not json');
    expect(AuthRepository(store).currentUser(), isNull);
  });

  group('initials', () {
    test('uses first and last word', () {
      const user = AppUser(id: '1', displayName: 'Ada Byron Lovelace');
      expect(user.initials, 'AL');
    });

    test('uses two letters of a single word', () {
      const user = AppUser(id: '1', displayName: 'ada');
      expect(user.initials, 'AD');
    });

    test('falls back to a placeholder for a blank name', () {
      const user = AppUser(id: '1', displayName: '  ');
      expect(user.initials, '?');
    });
  });
}
