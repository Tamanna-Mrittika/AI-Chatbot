# Streamed AI Chat

A Flutter chat client that streams replies from free large language models token
by token, built with Riverpod and a feature-first architecture.

Replies arrive over **Server-Sent Events** and render incrementally, the way a
production assistant does — no spinner-then-dump.

## Features

| Area | What is implemented |
| --- | --- |
| Streaming | SSE decoding, token-by-token rendering, blinking caret, stop-generation, idle timeout, cancellation |
| Rendering | Markdown with headings, lists, tables and fenced code blocks (language label + copy), tolerant of half-written Markdown mid-stream |
| Loading | Shimmering skeleton while waiting for the first token, and while the chat list loads |
| Providers | OpenRouter (free-tier models) and Google Gemini, behind one interface |
| Model picker | OpenRouter's catalogue fetched live and filtered to models that cost nothing |
| Auth | Local profile session, gated routing, sign-out with optional history wipe |
| Threads | Create, auto-title, preview, swipe-to-delete, day separators, persisted locally |
| Message actions | Copy, regenerate, per-message retry on failure |
| Errors | Typed exceptions mapped to actionable copy |
| Responsive | Single-pane on phones, master/detail on tablets and desktop, jump-to-latest button |
| Theming | Material 3, seeded colour scheme, light/dark/system |
| Tests | 69 tests: SSE decoder, both API clients, streaming state machine, incremental rendering, domain logic, widget flows |

## Getting an API key

Both providers have a free tier. **OpenRouter is the default** because its
`:free` models need no billing details at all.

1. **OpenRouter** — sign in at <https://openrouter.ai/keys>, create a key
   (`sk-or-v1-…`). Models tagged *(free)* in the picker cost nothing.
2. **Gemini** — create a key at <https://aistudio.google.com/apikey>
   (`AIza…`). The free tier is rate limited per minute.

### Supplying the key

There are two ways, and you do not have to pick one forever — a key typed into
Settings always wins over a build-time key, so you can bake in your own and
still let someone else try the app with theirs.

**1. Bake it in (recommended for development).** Put the key in `env.json`,
which is gitignored:

```json
{
  "OPENROUTER_API_KEY": "sk-or-v1-your-key",
  "GEMINI_API_KEY": ""
}
```

Then run with that file:

```bash
flutter run --dart-define-from-file=env.json
```

The value lands in `AppConstants.buildTimeOpenRouterKey`, which
`AppSettings.activeKey` falls back to. The app starts ready to chat — no
Settings visit, nothing to retype between runs.

Copy `env.example.json` to `env.json` to get started. A single key can also be
passed inline without the file:

```bash
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-your-key
```

**2. Type it into Settings → API key** at runtime, stored on the device.

> **Do not hardcode the key in a `.dart` file.** It would be committed to
> version control, and `env.json` already keeps it out of both git and the
> source tree.
>
> Note that `--dart-define` values *are* embedded in the compiled binary and
> can be extracted from a shipped app. That is an acceptable trade-off for
> development and coursework, but a production build should route requests
> through a small server that holds the key instead.

> **Note on model names:** there is no "Gemini 3.5". The current Gemini models
> are `gemini-2.5-flash` (default here), `gemini-2.5-flash-lite` and
> `gemini-2.5-pro`.

## Running

```bash
flutter pub get
flutter run
```

```bash
flutter test
flutter analyze
```

## Architecture

Feature-first at the top level, layered inside each feature. Dependencies point
inwards only: `presentation → application → domain ← data`.

```
lib/
├── main.dart                       Composition root
└── src/
    ├── app/                        Shell: theme, routes, auth gate, bootstrap
    ├── core/                       Cross-cutting, feature-agnostic
    │   ├── constants/              Endpoints, defaults, --dart-define hooks
    │   ├── errors/                 Sealed AppException hierarchy
    │   ├── network/                SSE decoder (spec-compliant)
    │   ├── providers/              Root DI: storage, http client, uuid
    │   ├── storage/                KeyValueStore interface + prefs impl
    │   ├── theme/                  Material 3 themes, breakpoints
    │   ├── utils/                  Timestamp formatting, token buffering
    │   └── widgets/                Shared presentational widgets
    └── features/
        ├── auth/                   domain · data · application · presentation
        ├── chat/                   domain · data · application · presentation
        └── settings/               domain · data · application · presentation
```

### Key decisions

**One `ChatRepository` interface, two implementations.** `GeminiChatRepository`
and `OpenRouterChatRepository` both expose `Stream<String> streamReply(...)`.
Nothing above the data layer knows which provider is active; adding a third is
one class plus one enum entry.

**Conversations are a single source of truth.** `ConversationListController`
owns every thread. The list screen and the open thread read the same state, so a
token arriving mid-stream updates the bubble *and* the list preview from one
state change.

**Streaming writes are debounced, not persisted per token.** `TokenBuffer`
coalesces deltas into ~50 ms flushes so the widget tree is not rebuilt per
token, and only terminal states are written to disk. A test asserts that a
50-token reply causes fewer than 10 disk writes.

**Terminal state is guaranteed.** `TurnFinaliser` ensures the assistant
placeholder always ends as `sent` or `failed`, whichever way the stream ends —
completion, error, user-initiated stop, or app restart mid-stream.

**Errors are typed, not strings.** A sealed `AppException` hierarchy maps HTTP
status codes and payload shapes onto messages the user can act on ("Rate limit
reached", "Pick a model tagged free"), with retry attached to the failed bubble.

### Testing

| Suite | Covers |
| --- | --- |
| `test/core/sse_transformer_test.dart` | Chunk-split reassembly, multi-line data, comments, `[DONE]` |
| `test/features/chat/*_repository_test.dart` | Wire format, auth headers, status mapping, safety blocks, cancellation |
| `test/features/chat/chat_session_controller_test.dart` | Send, stream, retry, titling, write-amplification, reload |
| `test/features/chat/conversation_test.dart` | Titling rules, previews, JSON round-trip |
| `test/features/auth/auth_repository_test.dart` | Validation, persistence, initials |
| `test/features/chat/chat_flow_widget_test.dart` | Sign-in → chat → streamed reply; disabled state; two-pane layout |

Data sources are tested through a fake `http.Client` that replays real SSE
bytes, so the decoder and status handling are exercised rather than mocked away.

## Known limitations

- **The API key is stored in `SharedPreferences`, which is not encrypted.** For
  production, add a `flutter_secure_storage` implementation of `KeyValueStore`;
  the interface exists for exactly this swap.
- Authentication is local-only — there is no backend, so profiles are not
  verified and history is per-device.
- Code blocks are styled and copyable but not syntax-highlighted — tokens are
  rendered in a single colour.
- Attachments, voice input and multi-turn branching are out of scope.
