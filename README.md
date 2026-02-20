# Global Smart Education Platform

> **Offline-First Education App** — A production-grade Proof of Concept demonstrating Sync Engine, Local Database (Drift), Firebase Firestore backend, and State Management architecture in Flutter.

[![Release](https://img.shields.io/github/v/release/mohamed352/Global-Smart-Education-Platform)](https://github.com/mohamed352/Global-Smart-Education-Platform/releases/latest)

---

## Overview

This project showcases how to build a **fully offline-first mobile application** where the UI reads and writes exclusively from a local SQLite database (Single Source of Truth), while a background Sync Engine handles bidirectional synchronization with **Firebase Firestore** using **Last-Write-Wins (LWW)** conflict resolution.

### Key Features

- **Single Source of Truth (SSOT)** — All UI reads/writes go through the local Drift (SQLite) database. No direct remote calls from the presentation layer.
- **Firebase Firestore Backend** — Real Cloud Firestore for the `Progress` entity. Collection: `progresses`.
- **Offline Mutations with SyncQueue** — Progress updates are persisted locally and queued for upload. The app works fully offline.
- **Sync Engine** — Automatic sync on connectivity change, with manual trigger support. Three-phase cycle: Upload → Conflict Simulations → Download.
- **Last-Write-Wins Conflict Resolution** — When remote and local data conflict, the record with the strictly newer `updatedAt` timestamp wins. Equal timestamps favor local (tie-break).
- **Retry with Backoff** — Failed uploads increment a retry counter. Items exceeding max retries are excluded from future sync cycles.
- **Reactive UI** — Drift watch streams feed into Flutter Bloc Cubits. The UI reacts in real-time to database changes.
- **Demo Controls** — Two buttons per lesson: **"Update Progress Offline"** and **"Simulate Remote Conflict"** for live LWW demonstration.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Presentation Layer                        │
│  DashboardPage ← BlocSelector ← DashboardCubit               │
│         (reads state, dispatches actions)                      │
├──────────────────────────────────────────────────────────────┤
│                        Domain Layer                           │
│          EducationRepository (SSOT over local DB)             │
│          SyncRepository (routes to Mock + Firebase)           │
├──────────────────────────────────────────────────────────────┤
│                        Data Layer                             │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│  │  AppDatabase │  │ SyncManager  │  │ FirebaseRemoteData   │ │
│  │   (Drift)    │  │  (Engine)    │  │ Source (Firestore)   │ │
│  └─────────────┘  └──────────────┘  └──────────────────────┘ │
│                                      ┌──────────────────────┐ │
│                                      │ RemoteDataSource     │ │
│                                      │ (Mock: Users/Lessons)│ │
│                                      └──────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### Sync Engine Flow

```
performFullSync()
  │
  ├─ 1. Upload Queue      → Push pending items to Firestore
  ├─ 2. Conflict Sims     → Execute queued conflict demos (if any)
  └─ 3. Download Updates   → Fetch from Firestore → Apply LWW
```

### Data Flow

1. **User taps "Update Progress Offline"** → Cubit calls `EducationRepository.updateProgress()`
2. **Repository** (inside a Drift transaction):
   - Upserts progress with `syncStatus: pending`
   - Adds entry to `SyncQueue`
3. **Drift watch streams** fire → Cubit emits new state → UI updates instantly
4. **SyncManager** detects connectivity → calls `performFullSync()`
5. **Upload**: Reads queue → uploads each item to Firestore → marks synced → removes from queue
6. **Conflict Simulations**: Executes any queued demos (writes 100%/+1h to Firestore)
7. **Download**: Fetches all progress from Firestore → applies LWW conflict resolution → upserts locally

### Conflict Resolution (LWW)

```
Local:  { lesson: "Algebra", progress: 10%, updatedAt: T1 }
Remote: { lesson: "Algebra", progress: 100%, updatedAt: T1 + 1h }

T1+1h > T1 → Remote wins → progress becomes 100%
```

```
If remote.updatedAt > local.updatedAt  → Remote wins
If remote.updatedAt <= local.updatedAt → Local wins (tie-break favors local)
```

---

## Demo Scenario (Video Recording)

Follow this exact flow to demonstrate offline-first sync with LWW conflict resolution:

1. **Online** — Open the app. Lessons load from seeded data.
2. **Offline** — Turn on **Airplane Mode**.
3. **Press "Update Progress Offline"** — Progress increases to 10%. Status turns **orange (pending)**. Cloud icon turns **red (offline)**.
4. **Press "Simulate Remote Conflict"** — SnackBar confirms: *"Conflict queued (100%, +1h)"*. This queues a conflict simulation to run during the next sync.
5. **Online** — Turn off Airplane Mode.
6. **Watch the screen** — Cloud icon turns **green**. Progress jumps to **100%** automatically. The Sync Engine uploaded 10%, then applied the conflict (100%, +1h), then downloaded and resolved via LWW — remote wins.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Remote Backend** | [Cloud Firestore](https://firebase.google.com/docs/firestore) |
| **Local Database** | [Drift](https://drift.simonbinder.eu/) (SQLite) |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) (Cubit) |
| **Connectivity** | [connectivity_plus](https://pub.dev/packages/connectivity_plus) |
| **DI** | [get_it](https://pub.dev/packages/get_it) + [injectable](https://pub.dev/packages/injectable) |
| **Immutable State** | [freezed](https://pub.dev/packages/freezed) |
| **Testing** | [mocktail](https://pub.dev/packages/mocktail) + flutter_test |
| **Code Generation** | [build_runner](https://pub.dev/packages/build_runner) |

---

## Project Structure

```
lib/
├── main.dart                          # Entry point: Firebase init, DI, SyncManager, seed
├── firebase_options.dart              # FlutterFire CLI generated config
├── core/
│   ├── constants/sync_constants.dart  # Retry limits, delay, failure %, enums
│   ├── di/
│   │   ├── injection.dart             # GetIt + Injectable setup
│   │   └── firebase_module.dart       # FirebaseFirestore DI module
│   └── logger/app_logger.dart         # Structured logging with tags
└── features/education/
    ├── data/
    │   ├── datasources/
    │   │   ├── local/database.dart                  # Drift schema + queries
    │   │   └── remote/
    │   │       ├── firebase_remote_data_source.dart  # Firestore: upload, fetch, conflict
    │   │       └── remote_data_source.dart           # Mock: Users & Lessons seed data
    │   ├── repositories/
    │   │   ├── education_repository.dart  # SSOT: all reads/writes via local DB
    │   │   └── sync_repository.dart       # Routes Progress→Firebase, Users/Lessons→Mock
    │   └── services/
    │       └── sync_manager.dart      # Sync engine: upload → conflict sims → download
    └── presentation/
        ├── cubit/
        │   ├── dashboard_cubit.dart   # Reactive streams → state emissions
        │   └── dashboard_state.dart   # Freezed immutable state
        └── pages/
            └── dashboard_page.dart    # Material 3 UI with BlocSelectors

test/
├── features/education/
│   ├── data/
│   │   ├── repositories/
│   │   │   ├── education_repository_test.dart      # 13 tests
│   │   │   └── lww_conflict_resolution_test.dart   # 8 tests
│   │   └── services/
│   │       └── sync_manager_test.dart              # 14 tests
│   └── presentation/cubit/
│       └── dashboard_cubit_test.dart               # 11 tests
└── widget_test.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.11.0`
- Dart SDK `>=3.11.0`
- Firebase project configured via `flutterfire configure`

### Setup

```bash
# Clone the repository
git clone https://github.com/mohamed352/Global-Smart-Education-Platform.git
cd Global-Smart-Education-Platform

# Install dependencies
flutter pub get

# Run code generation (Drift, Freezed, Injectable)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Build Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Run Tests

```bash
# Run all 46 tests
flutter test

# Run with verbose output
flutter test --reporter expanded

# Run specific test suite
flutter test test/features/education/data/repositories/lww_conflict_resolution_test.dart
```

### Static Analysis

```bash
flutter analyze   # Expected: "No issues found!"
```

---

## Database Schema

### Entities

| Table | Key Columns | Purpose |
|---|---|---|
| **Users** | `id`, `name`, `email`, `updatedAt`, `syncStatus` | Student profiles |
| **Lessons** | `id`, `title`, `description`, `durationMinutes`, `updatedAt`, `syncStatus` | Course lessons |
| **Progresses** | `id`, `userId`, `lessonId`, `progressPercent`, `updatedAt`, `syncStatus` | Per-user lesson progress |
| **SyncQueueItems** | `id`, `operationType`, `entityId`, `payload`, `retryCount`, `createdAt` | Offline mutation queue |

### Firestore Collection

```
progresses/{progressId}
  ├── id: String
  ├── userId: String
  ├── lessonId: String
  ├── progressPercent: int
  ├── updatedAt: String (ISO 8601)
  └── syncStatus: String
```

### Sync Status Lifecycle

```
[User writes] → pending → [Upload succeeds] → synced
                        → [Upload fails]    → pending (retryCount++)
                        → [Max retries]     → excluded from query
```

---

## Testing Summary

| Suite | Tests | Coverage |
|---|---|---|
| **EducationRepository** | 13 | CRUD, atomic transactions, LWW branches, retry count |
| **SyncManager** | 14 | Upload/download, retry skip, conflict queue, queue mechanism, seed data |
| **DashboardCubit** | 11 | Stream subscriptions, error handling, progress helpers |
| **LWW Conflict Resolution** | 8 | Remote wins, local wins, tie-break, multi-lesson isolation, rapid-fire offline |
| **Total** | **46** | All passing |

---

## Design Decisions

| Decision | Rationale |
|---|---|
| **Firebase Firestore** for Progress | Real cloud backend replacing mock; `set(merge: true)` for partial updates |
| **Mock kept for Users/Lessons** | Static seed data; demonstrates hybrid real + mock data sources |
| **Queued conflict simulations** | Executed between upload and download phases for deterministic LWW demo |
| **Drift transactions** for `updateProgress` | Ensures progress upsert + queue insert are atomic — no partial writes on crash |
| **`@injectable` (Factory)** for `DashboardCubit` | `BlocProvider` manages lifecycle; a singleton Cubit would leak stale subscriptions |
| **`SyncRepository`** dual data sources | Routes Progress→Firebase, Users/Lessons→Mock — clean layer separation |
| **`dispose:` on `SyncManager` singleton** | GetIt can properly clean up connectivity subscriptions and stream controllers |
| **`Map<String, Progress>` for lookups** | O(1) progress queries per lesson card instead of O(n) linear scans |
| **`BlocSelector`** instead of `BlocBuilder` | Each widget slice rebuilds only when its specific data changes |
| **`WHERE retryCount < max`** in sync query | Dead items stay in DB for debugging but don't pollute sync cycles |
| **Nullable guards in `upsertProgressIfNewer`** | Gracefully skips incomplete Firestore documents instead of crashing |
| **LWW tie-break favors local** | Prevents server from overwriting user's latest action when clocks are in sync |
| **INTERNET permission in AndroidManifest** | Required for Firestore in release builds (debug grants it implicitly) |

---

## License

This project is for educational and evaluation purposes.
