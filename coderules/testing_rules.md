# Testing Requirements & Patterns

## 1. Testing Stack

- **Framework:** `flutter_test` + `bloc_test` + `mocktail`
- **Mocking:** Use `mocktail` (no code generation required)
- **Test Location:** `test/` directory mirroring `lib/` structure

## 2. Required Tests for Every Feature

| Layer        | Test Type    | Required Coverage |
| ------------ | ------------ | ----------------- |
| Use Cases    | Unit Tests   | 100% (if present) |
| Repositories | Unit Tests   | 90%+              |
| Cubits/Blocs | Cubit Tests  | 100% (all states) |
| Entities     | Unit Tests   | Edge cases        |
| Widgets      | Widget Tests | Key interactions  |

## 3. Test File Structure

```
test/
├── mocks/
│   ├── mock_repositories.dart    # Mock classes for repositories
│   └── mock_use_cases.dart       # Mock classes for use cases
├── helpers/
│   └── test_helpers.dart         # PumpApp extension, TestFixtures
├── core/                         # Core layer tests
│   └── error/
│       └── api_exception_test.dart
└── features/
    └── [feature_name]/
        ├── data/repositories/
        │   └── [repo]_impl_test.dart
        ├── domain/usecases/
        │   └── [usecase]_test.dart
        └── presentation/cubit/
            └── [cubit]_test.dart
```

## 4. Test Patterns to Follow

### Use Case Test (using mocktail)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MyUseCase useCase;
  late MockRepository mockRepository;

  setUp(() {
    mockRepository = MockRepository();
    useCase = MyUseCase(repository: mockRepository);
  });

  test('should return data when repository succeeds', () async {
    // Arrange
    when(() => mockRepository.getData(any()))
        .thenAnswer((_) async => ApiResult.success(testData));

    // Act
    final result = await useCase(params);

    // Assert
    expect(result, isA<Success<Data>>());
    verify(() => mockRepository.getData(params)).called(1);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    when(() => mockRepository.getData(any()))
        .thenAnswer((_) async => const ApiResult.failure('Error'));

    // Act
    final result = await useCase(params);

    // Assert
    expect(result, isA<Failure<Data>>());
    verify(() => mockRepository.getData(params)).called(1);
  });
}
```

### Cubit Test (using bloc_test)

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MyCubit cubit;
  late MockUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockUseCase();
    cubit = MyCubit(useCase: mockUseCase);
  });

  tearDown(() => cubit.close());

  blocTest<MyCubit, MyState>(
    'emits [loading, success] when action succeeds',
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => ApiResult.success(data));
      return cubit;
    },
    act: (cubit) => cubit.doAction(),
    expect: () => [
      const MyState.loading(),
      const MyState.success(data),
    ],
  );

  blocTest<MyCubit, MyState>(
    'emits [loading, error] when action fails',
    build: () {
      when(() => mockUseCase(any()))
          .thenAnswer((_) async => const ApiResult.failure('Error'));
      return cubit;
    },
    act: (cubit) => cubit.doAction(),
    expect: () => [
      const MyState.loading(),
      const MyState.error('Error'),
    ],
  );
}
```

### Repository Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MyRepositoryImpl repository;
  late MockServiceClient mockServiceClient;

  setUp(() {
    mockServiceClient = MockServiceClient();
    repository = MyRepositoryImpl(mockServiceClient);
  });

  test('should return success when service call succeeds', () async {
    // Arrange
    when(() => mockServiceClient.getData(any()))
        .thenAnswer((_) async => mockModel);

    // Act
    final result = await repository.getData();

    // Assert
    expect(result, isA<Success<Entity>>());
    verify(() => mockServiceClient.getData(any())).called(1);
  });

  test('should return failure when DioException occurs', () async {
    // Arrange
    when(() => mockServiceClient.getData(any()))
        .thenThrow(DioException(...));

    // Act
    final result = await repository.getData();

    // Assert
    expect(result, isA<Failure<Entity>>());
    verify(() => mockServiceClient.getData(any())).called(1);
  });
}
```

### Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

void main() {
  late MockMyCubit mockCubit;

  setUp(() {
    mockCubit = MockMyCubit();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<MyCubit>.value(
        value: mockCubit,
        child: const MyPage(),
      ),
    );
  }

  testWidgets('shows loading state', (tester) async {
    // Arrange
    whenListen(mockCubit, Stream.value(const MyState.loading()), initialState: const MyState.initial());

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows data when loaded', (tester) async {
    // Arrange
    whenListen(mockCubit, Stream.value(const MyState.loaded(data)), initialState: const MyState.initial());

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Assert
    expect(find.text('Sample data'), findsOneWidget);
  });
}
```

## 5. Mock Setup

### Mock Classes Definition
```dart
// test/mocks/mock_repositories.dart
class MockRepository extends Mock implements MyRepository {}

class MockServiceClient extends Mock implements MyServiceClient {}

// test/mocks/mock_use_cases.dart
class MockUseCase extends Mock implements MyUseCase {}
```

### Test Helpers
```dart
// test/helpers/test_helpers.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget widget) {
    return pumpWidget(
      MaterialApp(
        home: widget,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
      ),
    );
  }
}

class TestFixtures {
  static const testData = Data(id: 1, name: 'Test');
  static const mockModel = Model(id: 1, name: 'Test');
}
```

## 6. Code Generation Workflow (Updated with Tests)

When implementing a new feature, generate code in this order:

1. **Configuration:** Define new keys in `EndPoints`
2. **Domain Layer:** Define `Entity` (Freezed) & `Repository Interface`
3. **Data Layer:** `Retrofit Client`, `DTO`, `Repository Impl`
4. **Presentation (Logic):** Define `Cubit` with `Freezed Union State`
5. **Presentation (UI):** Assemble Page using `BlocSelector` / `BlocListener`
6. **Logging Check:** Add appropriate `log.d/i/w/e` calls with correct tags
7. **TESTS (MANDATORY):**
   - Create mock classes in `test/mocks/`
   - Write use case tests
   - Write repository tests
   - Write cubit tests with `bloc_test`
   - Run `flutter test` to verify all pass

## 7. Running Tests

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter expanded

# Run specific test file
flutter test test/features/auth/domain/usecases/login_usecase_test.dart

# Run with coverage
flutter test --coverage

# Run specific test group
flutter test --name "should return success"
```

## 8. Test Requirements Checklist

Before marking a feature as complete, verify:

- [ ] All use cases have unit tests
- [ ] All repository implementations have tests
- [ ] All cubits have state transition tests
- [ ] All edge cases are covered
- [ ] `flutter test` passes with 0 failures
- [ ] No skipped tests without justification

## 9. Integration Test Guidelines

### When to Write Integration Tests
- Critical user flows (login, checkout, etc.)
- Complex multi-screen interactions
- Performance-critical paths
- Native feature integrations (camera, GPS, etc.)

### Integration Test Structure
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('complete login flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');

      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Welcome!'), findsOneWidget);
    });
  });
}
```

## 10. Best Practices

### Test Organization
- Group related tests using `group()`
- Use descriptive test names that explain the scenario
- Follow Arrange-Act-Assert pattern consistently

### Mock Management
- Reset mocks between tests using `setUp()` and `tearDown()`
- Use `verify()` to ensure expected interactions occurred
- Use `any()` for non-critical parameters

### Test Data
- Use test fixtures for consistent test data
- Keep test data simple and focused on the test scenario
- Avoid production data in tests

### Performance
- Keep tests fast and focused
- Use `tester.pump()` for UI updates instead of `pumpAndSettle()` when possible
- Avoid unnecessary widget rebuilds in tests