/// The upstream inference services the app can talk to.
///
/// Both are reached through the same [ChatRepository] contract, so adding a
/// third provider means writing one data-layer class and one enum entry — no
/// controller or widget changes.
enum AiProvider {
  /// OpenRouter: OpenAI-compatible gateway with a catalogue of `:free` models.
  openRouter(
    id: 'openrouter',
    label: 'OpenRouter',
    keyUrl: 'https://openrouter.ai/keys',
    keyHint: 'Starts with sk-or-v1-',
  ),

  /// Google AI Studio's Gemini API (free tier, rate limited).
  gemini(
    id: 'gemini',
    label: 'Google Gemini',
    keyUrl: 'https://aistudio.google.com/apikey',
    keyHint: 'Starts with AIza',
  );

  const AiProvider({
    required this.id,
    required this.label,
    required this.keyUrl,
    required this.keyHint,
  });

  /// Stable identifier used as a persistence key — never rename it.
  final String id;

  /// Display name shown in Settings.
  final String label;

  /// Where the user can create an API key.
  final String keyUrl;

  /// Short format hint shown under the key field.
  final String keyHint;

  static AiProvider fromId(String? value) => AiProvider.values.firstWhere(
    (provider) => provider.id == value,
    orElse: () => AiProvider.openRouter,
  );
}
