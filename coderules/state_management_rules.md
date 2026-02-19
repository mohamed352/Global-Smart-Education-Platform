# State Management Rules

## 1. Technology Stack

- **State Management:** `flutter_bloc` (Cubit preferred) + `freezed` (Unions)
- **DI:** `get_it` + `injectable` (Auto-generated dependency injection)

## 2. Immutability Rules (STRICT)

### Pure Immutability
- The Cubit/Bloc class **MUST NOT** contain mutable fields
- All state changes must go through `emit()` with new state objects
- Use `freezed` for immutable state classes

## 3. Granular Updates (STRICT)

### Widget Rebuild Rules
1. **BlocSelector:** Use for specific value changes
2. **BlocBuilder:** Wrap **ONLY** the specific widget (Leaf Node) that uses dynamic variables from the state. **Do not** rebuild static widgets
3. **BlocListener:** MANDATORY for side effects

### Examples
```dart
// GOOD - BlocSelector for specific value
BlocSelector<MyCubit, MyState, String>(
  selector: (state) => state.userName,
  builder: (context, userName) {
    return Text(userName);
  },
)

// GOOD - BlocBuilder for dynamic widget only
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    return Column(
      children: [
        const StaticHeader(), // Static widget outside
        DynamicContent(data: state.data), // Dynamic widget inside
      ],
    );
  },
)

// GOOD - BlocListener for side effects
BlocListener<MyCubit, MyState>(
  listener: (context, state) {
    if (state.showSuccessDialog) {
      context.showSuccessDialog();
    }
  },
  child: MyWidget(),
)
```

## 4. Skeletonizer Loading Pattern (STRICT)

### Mock Data Requirements
1. **Mock Data in State:** NEVER define mock data in UI files. Create a `Mocks` class in `data/mocks/`
2. **Loading State:** The `loading` state MUST include mock data parameter: `loading(List<Model> mock)`
3. **Cubit:** Emit loading with mocks: `emit(State.loading(Mocks.items))`

### UI Pattern (Skeletonizer)
```dart
final isLoading = state.maybeWhen(
  loading: (_) => true,
  initial: () => true,
  orElse: () => false,
);

final items = state.maybeWhen(
  loaded: (items) => items,
  loading: (mock) => mock,
  orElse: () => Mocks.items,
);

return Skeletonizer(
  enabled: isLoading,
  enableSwitchAnimation: true,
  child: ItemList(items: items, isLoading: isLoading),
);
```

## 5. Separation of Concerns (Data vs UI) - STRICT

### Data Cubits
- Handle **ONLY** API calls, repository interactions, and business data processing
- Examples: fetching data, submitting forms, business logic
- Use `LogTags.bloc` for logging

### UI Cubits
- Handle form validation, visibility toggles, and transient UI state
- Examples: `showHardRejectOverlay`, form field validation, UI toggles
- Use `LogTags.bloc` for logging

### FORBIDDEN Patterns
- **Bad:** A single Cubit handling `submitInspection()` (API) AND `showHardReject()` (UI Toggle)
- **Good:** Split into `InspectionActionCubit` (API) and `InspectionFormCubit` (UI)

## 6. Logging Requirements for State Management

### Mandatory Logging
- **Cubit/Bloc:** Log significant state changes, API calls, and errors
- Use `LogTags.bloc` tag for all state management operations

### Log Levels
- `log.d()` - Debug: State transitions, data flow details
- `log.i()` - Info: Significant state changes, user actions
- `log.w()` - Warning: Validation failures, edge cases
- `log.e()` - Error: State management failures with error object

### Example
```dart
class MyCubit extends Cubit<MyState> {
  MyCubit(this._repository) : super(const MyState.initial());

  Future<void> loadData() async {
    log.d('Loading data...', tag: LogTags.bloc);
    emit(const MyState.loading());
    
    try {
      final result = await _repository.getData();
      result.fold(
        (failure) {
          log.e('Failed to load data', error: failure, tag: LogTags.bloc);
          emit(MyState.error(failure.message));
        },
        (data) {
          log.i('Data loaded successfully', tag: LogTags.bloc);
          emit(MyState.loaded(data));
        },
      );
    } catch (e, s) {
      log.e('Unexpected error loading data', error: e, stackTrace: s, tag: LogTags.bloc);
      emit(const MyState.error('Unexpected error'));
    }
  }
}
```

## 7. Dependency Injection (STRICT)

### Auto-Injection Requirements
- **Auto-Injection:** Use `injectable` for all dependency injection
- **Manual registration in `get_it` is FORBIDDEN**

### Example
```dart
@LazySingleton()
class MyCubit extends Cubit<MyState> {
  MyCubit(this._repository) : super(const MyState.initial());
  final MyRepository _repository;
}
```

## 8. State Design Patterns

### Freezed Union State Pattern
```dart
@freezed
class MyState with _$MyState {
  const factory MyState.initial() = _Initial;
  const factory MyState.loading(List<Item> mock) = _Loading;
  const factory MyState.loaded(List<Item> items) = _Loaded;
  const factory MyState.error(String message) = _Error;
}
```

### State Update Patterns
- Always create new state objects using `copyWith` or factory constructors
- Never mutate state directly
- Use `maybeWhen`, `when`, `map`, or `maybeMap` for state handling

## 9. Error Handling Patterns

### Error State Management
```dart
try {
  final result = await _repository.getData();
  result.fold(
    (failure) => emit(MyState.error(failure.message)),
    (data) => emit(MyState.loaded(data)),
  );
} on DioException catch (e) {
  emit(MyState.error(ApiException.fromDioException(e).message));
} catch (e) {
  emit(MyState.error('Unexpected error occurred'));
}
```

### Error Recovery
- Always provide a way to recover from error states
- Include retry mechanisms where appropriate
- Show user-friendly error messages using `TextManager`

## 10. Performance Rules

### State Object Creation
- Use `const` constructors where possible
- Avoid creating unnecessary objects in `build` methods
- Use `equatable` for value equality in states

### Emission Rules
- Don't emit the same state multiple times
- Batch multiple state updates when possible
- Use `debounceTime` for rapid-fire events (like text input)