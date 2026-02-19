# Global Smart Education Platform

> **Offline-First Education App** — A production-grade Proof of Concept demonstrating Sync Engine, Local Database, and State Management architecture in Flutter.

---

## Overview

This project showcases how to build a **fully offline-first mobile application** where the UI reads and writes exclusively from a local SQLite database (Single Source of Truth), while a background Sync Engine handles bidirectional synchronization with a remote server using **Last-Write-Wins (LWW)** conflict resolution.

### Key Features

- **Single Source of Truth (SSOT)** — All UI reads/writes go through the local Drift (SQLite) database. No direct remote calls from the presentation layer.
- **Offline Mutations with SyncQueue** — Progress updates are persisted locally and queued for upload. The app works fully offline.
- **Sync Engine** — Automatic sync on connectivity change, with manual trigger support. Uploads pending queue items, downloads remote updates.
- **Last-Write-Wins Conflict Resolution** — When remote and local data conflict, the record with the most recent `updatedAt` timestamp wins. Equal timestamps favor local (tie-break).
- **Retry with Backoff** — Failed uploads increment a retry counter. Items exceeding max retries are excluded from future sync cycles.
- **Reactive UI** — Drift watch streams feed into Flutter Bloc Cubits. The UI reacts in real-time to database changes.
- **Mocked Remote API** — A `RemoteDataSource` simulates network delays (800ms) and random failures (15% probability) for realistic testing.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  DashboardPage ← BlocSelector ← DashboardCubit          │
│         (reads state, dispatches actions)                 │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                        │
│         EducationRepository (SSOT over local DB)         │
│         SyncRepository (encapsulates remote calls)       │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │  AppDatabase │  │ SyncManager  │  │RemoteDataSource│  │
│  │   (Drift)    │  │  (Engine)    │  │   (Mocked)     │  │
│  └─────────────┘  └──────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User taps "+10%"** → Cubit calls `EducationRepository.updateProgress()`
2. **Repository** (inside a Drift transaction):
   - Upserts progress with `syncStatus: pending`
   - Adds entry to `SyncQueue`
3. **Drift watch streams** fire → Cubit emits new state → UI updates instantly
4. **SyncManager** detects connectivity → calls `performFullSync()`
5. **Upload**: Reads queue → uploads each item → marks synced → removes from queue
6. **Download**: Fetches remote data → applies LWW conflict resolution → upserts locally

### Conflict Resolution (LWW)

```
Local:  { lesson: "Algebra", progress: 30%, updatedAt: T1 }
Remote: { lesson: "Algebra", progress: 80%, updatedAt: T2 }

If T2 > T1 → Remote wins  (progress becomes 80%)
If T1 > T2 → Local wins   (progress stays 30%)
If T1 == T2 → Local wins  (tie-break favors local)
```

---

## Tech Stack

| Layer | Technology |
|---|---|
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
├── main.dart                          # Entry point: DI, SyncManager init, seed data
├── core/
│   ├── constants/sync_constants.dart  # Retry limits, delay, failure %, enums
│   ├── di/injection.dart              # GetIt + Injectable setup
│   └── logger/app_logger.dart         # Structured logging with tags
└── features/education/
    ├── data/
    │   ├── datasources/
    │   │   ├── local/database.dart    # Drift schema: Users, Lessons, Progresses, SyncQueue
    │   │   └── remote/remote_data_source.dart  # Mocked API with delays & failures
    │   ├── repositories/
    │   │   ├── education_repository.dart  # SSOT: all reads/writes via local DB
    │   │   └── sync_repository.dart       # Encapsulates RemoteDataSource access
    │   └── services/
    │       └── sync_manager.dart      # Sync engine: upload queue, download, LWW
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
│   │   │   ├── education_repository_test.dart      # 13 tests: CRUD, atomicity, retry
│   │   │   └── lww_conflict_resolution_test.dart   # 8 tests: all LWW scenarios
│   │   └── services/
│   │       └── sync_manager_test.dart              # 11 tests: upload, download, retry
│   └── presentation/cubit/
│       └── dashboard_cubit_test.dart               # 11 tests: streams, errors, helpers
└── widget_test.dart                                # Placeholder
```

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.11.0`
- Dart SDK `>=3.11.0`

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

### Run Tests

```bash
# Run all 44 tests
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
| **SyncManager** | 11 | Upload/download paths, retry skip, seed data, status emissions |
| **DashboardCubit** | 11 | Stream subscriptions, error handling, progress helpers |
| **LWW Conflict Resolution** | 8 | Remote wins, local wins, tie-break, multi-lesson isolation, rapid-fire offline |
| **Total** | **44** | All passing |

---

## Design Decisions

| Decision | Rationale |
|---|---|
| **Drift transactions** for `updateProgress` | Ensures progress upsert + queue insert are atomic — no partial writes on crash |
| **`@injectable` (Factory)** for `DashboardCubit` | `BlocProvider` manages lifecycle; a singleton Cubit would leak stale subscriptions |
| **`SyncRepository`** wrapping `RemoteDataSource` | Presentation/service layers never touch the remote directly — clean layer separation |
| **`dispose:` on `SyncManager` singleton** | GetIt can properly clean up connectivity subscriptions and stream controllers |
| **`Map<String, Progress>` for lookups** | O(1) progress queries per lesson card instead of O(n) linear scans |
| **`BlocSelector`** instead of `BlocBuilder` | Each widget slice rebuilds only when its specific data changes |
| **`WHERE retryCount < max`** in sync query | Dead items stay in DB for debugging but don't pollute sync cycles |
| **LWW tie-break favors local** | Prevents server from overwriting user's latest action when clocks are in sync |

---

## License

This project is for educational and evaluation purposes.
