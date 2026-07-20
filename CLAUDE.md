# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

AlentoAI — a Flutter (Dart) mobile app that runs a fine-tuned Gemma LLM **100% on-device** to coach COPD/DPOC patients toward daily step goals. Privacy is the core constraint: no health data or conversation history leaves the device. All user-facing copy is Portuguese (PT-PT); locale is hard-set to `pt_PT` in `main.dart`.

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run on connected device/emulator (Android is the primary target)
flutter analyze          # static analysis (lints from flutter_lints via analysis_options.yaml)
dart format lib          # format
flutter test             # run tests — see note below
flutter test path/to/x_test.dart --plain-name 'test name'   # single test / single case
flutter clean && flutter pub get   # fix stale build paths after renaming the project dir
```

**No `test/` directory exists yet.** Test infrastructure is not set up, so `flutter test` currently finds nothing. When adding tests for core logic (e.g. `lib/utils/step_goal_calculator.dart`, `lib/services/*`), create the `test/` tree mirroring `lib/`. Pure functions in `lib/utils/` are the cheapest, highest-value place to start.

## Architecture

**Startup flow:** `main()` → `LoadingScreen` → `HomeScreen`. `LoadingScreen` sequentially initializes `PerformanceMetricsService`, then the AI model (downloads the GGUF on first run), then `AppStateManager`, before replacing itself with `HomeScreen`. `HomeScreen` is a 3-tab scaffold: Steps / Places / Chat.

**Two singletons hold the app together:**

- **`AppStateManager`** (`lib/services/app_state_manager.dart`) — the single shared state orchestrator for steps, location, nearby places, chat history, step goal, and the weekly-questionnaire schedule. It owns the child services and exposes broadcast streams (`chatUpdateStream`, `stepGoalStream`) that screens listen to for reactive rebuilds. Persistence is via `SharedPreferences` (step goal, last-questionnaire date) and `ChatHistoryService`. Screens should coordinate UI and delegate all domain logic here or to a service — do not put business logic in widgets.

- **`AILlamaService`** (`lib/services/ai_llama_service.dart`) — wraps `llama_flutter_android`'s `LlamaController`. It is created in `LoadingScreen` and passed **by constructor** down into `HomeScreen` and each tab screen (it is *not* a singleton and *not* inside `AppStateManager`). On `initialize()` it downloads the model GGUF from HuggingFace into the app documents directory, validates/repairs the cached file by byte size, and loads it. Every generation call is wrapped in `PerformanceMetricsService` timing (TTFT, tokens/sec).

**Step detection — the fallback chain (`UnifiedStepService`):** on `initialize()` it tries, in order, **Health Connect → hardware pedometer → accelerometer**, and settles on the first that works, exposing a single `stepCountStream` and an `activeMethod`. Preserve this order and the single-stream façade. Health-history features (7-day average, daily breakdown) only work when the active method is `healthConnect`; guard for that. `setDebugHistoryOverride` injects mock history for debugging.

**AI model config (`lib/models/ai_model.dart`):** models are declared as `AIModelConfig` constants (name, HuggingFace URL, filename, fallback size). Default is `gemma31bGoals`. Add a new model by adding a constant and appending it to `availableModels`. Note: the README's model URL/name is illustrative — the actual default and URLs live here.

**Step-goal logic:** `lib/utils/step_goal_calculator.dart` computes the next weekly goal from the current goal + a 1–10 confidence score. The AI's job (via the questionnaire flow) is the motivational/contextual layer; this deterministic calculator is the source of truth for the number.

**Prompting:** prompts are built for Gemma's chat template (`<start_of_turn>user … <end_of_turn>\n<start_of_turn>model`). `sendMessage` wraps the user message with step/goal/places context; `sendDirectMessage` sends raw and uses greedy decoding (`temperature: 0.0, topK: 1, seed: 0`) for reproducible questionnaire answers. Match these conventions when adding prompts.

## Platform pitfalls (Android)

- Health Connect requires `MainActivity` to extend `FlutterFragmentActivity` — see `android/app/src/main/kotlin/com/example/health_test_app/MainActivity.kt` (note: the package dir is `health_test_app`, an artifact of the original project name).
- Health readings may arrive as wrapped types (e.g. `NumericHealthValue`), not raw `num` — parse defensively.
- Google Places `403`s are almost always config (API key restrictions, billing off, API disabled), not code.
- Location code must explicitly handle all three states: service disabled, permission denied, permission denied-forever.

## Conventions

- Read secrets from `.env` via `flutter_dotenv` (`GOOGLE_PLACES_API_KEY`); `.env` is bundled as a Flutter asset. Never hardcode keys.
- In `StatefulWidget`s, guard post-await UI updates with `if (!mounted) return;` before `setState` (see `LoadingScreen._safeSetState` for the pattern).
- Store every `StreamSubscription` and cancel it in `dispose()` — the app is stream-heavy and leaks/`setState after dispose` are the main failure mode.
- Logging is `debugPrint` with an emoji-prefixed context string; keep that style for consistency with existing traces.

## Working style (from project rules)

- **KISS / DRY / SOLID, readability first.** Prefer the most boring standard implementation. Before writing a new helper, search `lib/services`, `lib/utils`, `lib/widgets` for something to extend rather than duplicate — and state what you found (or that you found nothing) before adding code.
- Functions do one thing; use early-return guard clauses over nested conditionals. Names carry meaning; comments explain *why*, not *what*.
- Briefly state your plan and trade-offs before non-trivial changes; ask 1–3 clarifying questions when the request is ambiguous.
- Keep edits minimal and scoped — no unrelated refactors in the same change. Add/update tests for core logic when you touch it.

## Reference

- `guides/` — thesis-oriented docs: `AI_TESTING_GUIDE.md`, `PERFORMANCE_METRICS_GUIDE.md`, `METRICS_QUICK_START.md`, `FINE_TUNING_IDEAS.md`, `DATASET_MVP_EXAMPLES.md`, `PRESENTATION.md`.
- `tese-requests/` — Bruno API collection for the Google Places endpoints.
