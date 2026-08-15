# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documents

| File | Contents | Read it when |
|---|---|---|
| `CLAUDE.md` (this file) | Project overview, build commands, conventions | Always |
| [`SPEC.md`](SPEC.md) | Feature-by-feature behavioral spec (Korean), reverse-engineered from shipped code | Changing or extending a feature |
| [`PROGRESS.md`](PROGRESS.md) | Current state, unfinished work, known issues, dead code (Korean) | Starting a session, picking up work |
| `Sequential Timer/SequentialTimer_Ads_IAP_TASK.md` | Unimplemented AdMob + StoreKit 2 spec (Korean) | Touching monetization — it mandates a report-and-approve step before any code |

Keep them in sync: behavior changes → `SPEC.md`, status/issue changes → `PROGRESS.md`.

## Project

iOS app (SwiftUI, iOS 26.0 deployment target) that runs a routine of sequential timed steps. Bundle id `com.ner.sequentialtimer`, display name "순차 타이머". Single Xcode target `Sequential Timer`; **no test target and no git repo here**.

Dependencies come from SPM: Firebase (Analytics / Auth / Firestore) 12.8.0.

## Commands

```bash
# Build for simulator (verified working)
xcodebuild -project "Sequential Timer.xcodeproj" -scheme "Sequential Timer" \
  -destination 'generic/platform=iOS Simulator' build

# Build for a concrete simulator (needed to install/run)
xcodebuild -project "Sequential Timer.xcodeproj" -scheme "Sequential Timer" \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project "Sequential Timer.xcodeproj" -scheme "Sequential Timer" clean
xcodebuild -resolvePackageDependencies -project "Sequential Timer.xcodeproj"
```

The first `xcodebuild` invocation of a session resolves the Firebase package graph and prints a lot before any real output — check the tail.

No tests exist. If a test target is added, run it with `-destination 'platform=iOS Simulator,name=<device>' test` and a single test via `-only-testing:<Target>/<Class>/<method>`. `SequentialTimerEngine` and the `Sync/` builders are the pure, easily testable pieces.

The project uses `objectVersion = 77` with `fileSystemSynchronizedGroups`: **adding a `.swift` file anywhere under `Sequential Timer/` automatically puts it in the target** — do not hand-edit `project.pbxproj` to register new files.

## Architecture at a glance

Full behavior is in `SPEC.md`; this is the map plus the invariants that are easy to break.

```
SequentialTimerApp → ContentView → RoutineListView ─┬─ RoutineCreateView   (create/edit)
                                                    ├─ NotificationModeSheet (run config)
                                                    │    └─ TimerRunningView (execution)
                                                    └─ SettingsView
SequentialTimerEngine   pure timeline/progress math (no state)
CoreData/               PersistenceController + CoreDataManager (singleton over viewContext)
Sync/                   upload-only queue → Firestore, behind the RemoteBackend protocol
Theme.swift             ThemeStore → \.themePalette
```

Invariants worth protecting:

- **Elapsed time is derived from wall-clock, never tick-accumulated.** `elapsed = now - startAt - accumulatedPausedSeconds`; the 1s timer only redraws. Backgrounding and suspension self-correct because of this.
- **Two state stores, different jobs.** `SessionState` (UserDefaults, `seqtimer.sessionState.v1`) is the live resumable session; Core Data `Session` is the durable history record. Its hand-written `init(from:)` defaults every field — keep that when adding fields or existing sessions fail to decode.
- **Timer math belongs in `SequentialTimerEngine`**, not in the view.
- **Sync is upload-only.** Firestore is a backup sink, never a source of truth, and every SDK call sits behind `RemoteBackend` + `#if canImport(...)`.
- **Notification identifiers are derived from the session UUID**, which is what makes cancel-and-reschedule on every `scenePhase` change safe.
- **`PersistenceController` destroys and recreates the store if migration fails** — a non-lightweight-migratable model change silently wipes user data.

## Conventions

- Localization is `en` + `ko` `.strings` (`en.lproj`/`ko.lproj`). SwiftUI `Text("some.key")` resolves keys implicitly; interpolated strings use `String(format: String(localized: "key", locale: locale), ...)` with `@Environment(\.locale) private var locale`. **Any new key must be added to both language files.**
- Step ordering everywhere uses the composite `(order, stepId.uuidString)` comparison — match it in new code so list, timeline, sync, and hashing stay consistent.
- User-facing enum raw values like `NotificationSound.default = "기본"` are persisted in `UserDefaults`/`SessionState` — changing a raw value breaks stored preferences. Display text comes from `displayName`, not the raw value.
- Theming: new view code reads `@Environment(\.themePalette) private var theme` for colors, and `AppFont` / `AppSpacing` / `AppRadius` from `DesignSystem.swift` for type and layout. `AppColor` statics there are legacy.
- `DesignSystem.swift` also holds the shared `NotificationMode` / `NotificationSound` / `VibrationPattern` / `NotificationConfiguration` models, despite the file name.
- Core Data entity classes are Xcode-generated (`codeGenerationType="class"`) — there are no source files for `Routine`, `RoutineStep`, `Session`, `SessionStep`, `UploadQueueItem`.
- Inline comments and project docs are frequently Korean; match the surrounding file.
- `GoogleService-Info.plist` is committed in the app folder; `FirebaseApp.configure()` runs in `AppDelegate`.
