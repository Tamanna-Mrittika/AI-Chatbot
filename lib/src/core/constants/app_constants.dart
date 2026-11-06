/// Compile-time and run-time constants shared across the whole application.
///
/// Anything that could reasonably differ between builds is exposed as a
/// `String.fromEnvironment` so it can be injected with `--dart-define`.
abstract final class AppConstants {
  /// Human readable product name, shown in the app bar and the about dialog.
  static const String appName = 'Streamed AI Chat';

  /// Sent to OpenRouter as the `HTTP-Referer` attribution header.
  static const String appSiteUrl = 'https://github.com/example/ai-chatbot';

  /// Base URL of the Google Generative Language REST API.
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Base URL of OpenRouter's OpenAI-compatible API.
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  /// Keys baked in at build time via
  /// `flutter run --dart-define=OPENROUTER_API_KEY=...`.
  ///
  /// When empty the user is asked for a key in the settings screen instead.
  static const String buildTimeOpenRouterKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
  );

  static const String buildTimeGeminiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
  );

  /// Model used before the catalogue has been fetched.
  ///
  /// Deliberately *not* `openrouter/free`. That endpoint is a lottery over
  /// every zero-cost model, and the free pool contains a content-safety
  /// classifier and music models. Routing there produced replies like
  /// "User Safety: safe / Response Safety: safe" instead of a conversation.
  static const String defaultOpenRouterModel =
      'dots-studio/dots-3-note-preview:free';

  /// Free models verified to answer as a normal chat assistant.
  ///
  /// Vetted by hand: the free pool also contains classifiers, music models
  /// and reasoning models that leak their chain-of-thought into the reply,
  /// none of which belong in a chat UI.
  static const List<String> fallbackFreeModels = <String>[
    'dots-studio/dots-3-note-preview:free',
    'cohere/north-mini-code:free',
    'nvidia/nemotron-3-ultra-550b-a55b:free',
    'google/gemma-4-31b-it:free',
    'google/gemma-4-26b-a4b-it:free',
  ];

  /// Sent as OpenRouter's `models` fallback list so a busy provider falls
  /// through to the next instead of surfacing a 429.
  ///
  /// OpenRouter caps this array at three entries.
  static const List<String> openRouterFallbackChain = <String>[
    'dots-studio/dots-3-note-preview:free',
    'cohere/north-mini-code:free',
    'nvidia/nemotron-3-ultra-550b-a55b:free',
  ];

  /// Default Gemini model. `gemini-2.5-flash` is the fastest model on Google
  /// AI Studio's free tier, which makes it a sensible default for a chat UI.
  static const String defaultGeminiModel = 'gemini-flash-latest';

  /// Fallback list used before the live Gemini catalogue has been fetched,
  /// or when no key is configured (that endpoint needs authentication).
  ///
  /// These are the `-latest` aliases wherever possible: Google retires pinned
  /// versions for new keys, so an alias keeps working when e.g.
  /// `gemini-2.5-flash` starts 404ing.
  static const List<String> geminiModels = <String>[
    'gemini-flash-latest',
    'gemini-flash-lite-latest',
    'gemini-3-flash-preview',
    'gemini-pro-latest',
  ];

  /// Default persona handed to the model as a system instruction.
  static const String defaultSystemPrompt =
      'You are a helpful, concise assistant inside a mobile chat app. '
      'Prefer short paragraphs and use Markdown-free plain text unless the '
      'user explicitly asks for code, in which case use fenced code blocks.';

  /// How many previous messages are replayed to the model as context.
  ///
  /// Keeping this bounded stops the request payload (and therefore the token
  /// bill and latency) from growing without limit in long conversations.
  static const int historyWindow = 30;

  /// Abort a response stream that produces no new bytes for this long.
  static const Duration streamIdleTimeout = Duration(seconds: 60);
}
