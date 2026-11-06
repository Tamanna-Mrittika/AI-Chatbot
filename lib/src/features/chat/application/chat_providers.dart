import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/core_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../data/conversation_store.dart';
import '../data/gemini_chat_repository.dart';
import '../data/model_catalog_service.dart';
import '../data/openrouter_chat_repository.dart';
import '../domain/ai_model.dart';
import '../domain/ai_provider.dart';
import '../domain/chat_repository.dart';

final conversationStoreProvider = Provider<ConversationStore>((ref) {
  ref.keepAlive();
  return ConversationStore(ref.watch(keyValueStoreProvider));
});

/// Picks the repository implementation matching the selected provider.
///
/// The API key is read lazily through a closure rather than watched, so
/// editing the key in Settings does not tear down and rebuild this provider
/// (which would cancel an in-flight stream).
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  ref.keepAlive();
  final client = ref.watch(httpClientProvider);
  final provider = ref.watch(
    settingsControllerProvider.select((settings) => settings.provider),
  );

  String readKey() => ref.read(settingsControllerProvider).activeKey;

  return switch (provider) {
    AiProvider.openRouter => OpenRouterChatRepository(
      client: client,
      apiKeyReader: readKey,
    ),
    AiProvider.gemini => GeminiChatRepository(
      client: client,
      apiKeyReader: readKey,
    ),
  };
});

final modelCatalogServiceProvider = Provider<ModelCatalogService>((ref) {
  return ModelCatalogService(
    ref.watch(httpClientProvider),
    // Read, not watch: the catalogue is fetched on demand, and rebuilding
    // this provider on every keystroke in Settings would be wasteful.
    () => ref.read(settingsControllerProvider).geminiKey.isNotEmpty
        ? ref.read(settingsControllerProvider).geminiKey
        : AppConstants.buildTimeGeminiKey,
  );
});

/// Models available for the currently selected provider.
///
/// Auto-disposes: the catalogue is only needed while the model picker is open,
/// and refetching on reopen keeps a newly published free model discoverable.
final availableModelsProvider = FutureProvider<List<AiModel>>((ref) async {
  final provider = ref.watch(
    settingsControllerProvider.select((settings) => settings.provider),
  );
  return ref.watch(modelCatalogServiceProvider).fetch(provider);
});
