# Engineering Principles & Architecture

## 1. Core Architecture

### Technology Stack
- **Architecture:** Feature-First Clean Architecture
- **State Management:** `flutter_bloc` (Cubit preferred) + `freezed` (Unions)
- **Networking:** `dio` + `retrofit` (Auto-generated clients)
- **Result Type:** `ApiResult<T>` (Freezed Union: `Success<T>` | `Failure<T>`)
- **Data Models:** `freezed` + `json_annotation`
- **DI:** `get_it` + `injectable` (Auto-generated dependency injection)

## 2. Clean Architecture Principles

### Layer Separation
- **Domain Layer:** Business rules, entities, use cases
- **Data Layer:** Repository implementations, data sources, DTOs
- **Presentation Layer:** UI components, cubits, state management

### Dependency Direction
```
Presentation → Domain ← Data
```
- Inner layers don't know about outer layers
- Use dependency inversion with interfaces
- Test each layer in isolation

## 3. Engineering Principles (The "Why")

### A. Composition Over Inheritance (STRICT)

#### Rules
- **FORBIDDEN:** Creating `BaseActivity`, `BasePage`, or abstract Widgets to share UI logic
- **REQUIRED:** Use **Composition**. Wrap pages in a reusable wrapper widget or use **Mixins** for shared behavior (e.g., `LogMixin`)

#### Examples
```dart
// BAD - Inheritance creates tight coupling
abstract class BasePage extends StatelessWidget {
  Widget buildBody(BuildContext context);
  @override
  Widget build(BuildContext context) => Scaffold(body: buildBody(context));
}
class HomePage extends BasePage { ... }

// GOOD - Composition is flexible
class ScaffoldWrapper extends StatelessWidget {
  final Widget child;
  // ...
}
class HomePage extends StatelessWidget {
  Widget build(context) => ScaffoldWrapper(child: ...);
}
```

### B. Cohesion Over Constraints

#### File Size Guidance
- **Rule:** The "150 lines" limit is a **guideline**, not a law
- **Exception:** If splitting a file breaks the **Logical Cohesion** (reading flow) of a widget, keep it in one file (up to 250 lines)
- **Principle:** A 200-line file that does _one thing_ completely is better than three 70-line files that are tightly coupled

### C. The "Proxy" Rule (KISS)

#### Use Case Guidelines
- **Use Cases:** ONLY create a Domain `UseCase` if there is **Business Logic** (transformation, calculation, combination of multiple repos)
- **Pass-Through:** If a feature is a simple database read/write, the Cubit MAY call the `Repository` directly
- **FORBIDDEN:** Creating "Pass-Through" Use Cases that do nothing but call one function

#### Examples
```dart
// BAD - Pass-through use case adds no value
class GetUserUseCase {
  Future<User> call(String id) => _repo.getUser(id); // Just proxying!
}

// GOOD - Cubit calls repo directly for simple CRUD
class UserCubit extends Cubit<UserState> {
  Future<void> loadUser(String id) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _userRepo.getUser(id); // Direct call is fine
    // ...
  }
}
```

### D. Explicit Types (Type Safety)

#### Type Safety Rules
- **FORBIDDEN:** `var` or `dynamic` (except for JSON parsing)
- **REQUIRED:** Always specify return types for functions and types for variables

#### Examples
```dart
// BAD - Implicit types hide bugs
final data = await repo.getData();
var user = response.body;

// GOOD - Explicit types catch errors at compile time
final ApiResult<User> result = await repo.getData();
final User user = response.body;
```

### E. Value Objects (Avoid Primitive Obsession)

#### Value Object Guidelines
- **RISK:** Passing `String` for email, phone, userId everywhere
- **RECOMMENDED:** Use Value Objects for domain-specific types that have validation rules

#### Examples
```dart
// Instead of passing String email everywhere:
class Email {
  final String value;
  Email(this.value) {
    if (!_isValid(value)) throw InvalidEmailException();
  }
  static bool _isValid(String v) => RegExp(r'...').hasMatch(v);
}
```

### F. YAGNI (You Ain't Gonna Need It)

#### Abstraction Guidelines
- **Principle:** Don't build abstractions for hypothetical future requirements
- **Rule:** Only abstract when you have **3+ concrete implementations** or a clear extensibility need
- **FORBIDDEN:** Creating generic `BaseRepository<T>` for a single entity

## 4. Feature-First Architecture

### Feature Structure
```
lib/features/
├── auth/
│   ├── data/
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   └── presentation/
│       ├── cubit/
│       ├── pages/
│       └── widgets/
```

### Benefits
- **Clear ownership** of each feature
- **Easy navigation** through related code
- **Independent testing** of features
- **Scalable structure** as features grow

## 5. Code Generation Workflow

### Development Chain of Thought
When asked to implement a feature, think and generate in this order:

0. **Context Loading (CRITICAL):** Before writing code, you MUST absorb the 'Soul' of the project by reading relevant documentation
   - **UI/Animation?** Read relevant design/engineering docs
   - **Backend/Data?** Read relevant backend docs
   - **New Feature?** Read product specs

1. **Configuration:** Define new keys in `EndPoints`
2. **Domain Layer:** Define `Entity` (Freezed) & `Repository Interface`
3. **Data Layer:** `Retrofit Client`, `DTO`, `Repository Impl`
4. **Presentation (Logic):** Define `Cubit` with `Freezed Union State`
5. **Presentation (UI):**
   - **Refactor Check:** Do I need a formatter? Use `extension`
   - **Sizing Check:** Use `context.height`
   - **Theme Check:** Use `context.isDark`
   - Assemble Page using `BlocSelector` / `BlocListener`
6. **Logging Check:** Add appropriate `log.d/i/w/e` calls with correct tags
7. **TESTS (MANDATORY):** Write comprehensive tests for all layers

## 6. Domain-Driven Design Principles

### Bounded Contexts
- Each feature represents a bounded context
- Clear boundaries between different domains
- Anti-corruption layers between contexts

### Ubiquitous Language
- Use domain terminology throughout the codebase
- Consistent naming between domain and implementation
- Business concepts reflected in code structure

### Aggregates and Entities
- Clear aggregate roots for data consistency
- Value objects for domain concepts
- Proper invariants enforced at the domain level

## 7. Dependency Injection Architecture

### Auto-Generation Rules
- **Auto-Injection:** Use `injectable` for all dependency injection
- **Manual registration in `get_it` is FORBIDDEN**
- **Annotations:** Use `@LazySingleton`, `@Singleton`, `@Factory`

### Scoping Rules
- **Singleton:** Services, repositories, and shared resources
- **LazySingleton:** Heavy objects that should be created on demand
- **Factory:** Objects that need new instances each time

## 8. Error Handling Architecture

### Result Pattern
```dart
@freezed
class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult.success(T data) = Success<T>;
  const factory ApiResult.failure(String message) = Failure<T>;
}
```

### Error Propagation
- **Use Results** instead of exceptions for business logic
- **Exceptions** only for truly exceptional circumstances
- **Consistent error messages** through localization

## 9. Performance Architecture

### Rendering Performance
- **Widget decomposition** for granular rebuilds
- **Const constructors** for immutable widgets
- **Efficient list rendering** with proper keys

### Memory Management
- **Proper disposal** of streams and controllers
- **Image caching** strategies
- **Lazy loading** for expensive operations

## 10. Scalability Principles

### Modular Architecture
- **Feature modules** that can be developed independently
- **Clear interfaces** between modules
- **Minimal coupling** between different features

### Extensibility Patterns
- **Open/Closed Principle** - open for extension, closed for modification
- **Strategy Pattern** for pluggable algorithms
- **Observer Pattern** for reactive systems

## 11. Maintainability Guidelines

### Code Organization
- **Single Responsibility Principle** for classes and methods
- **Don't Repeat Yourself** (DRY) with proper abstractions
- **You Ain't Gonna Need It** (YAGNI) - avoid over-engineering

### Documentation Standards
- **Self-documenting code** with clear naming
- **Architectural decision records** for major choices
- **Comprehensive README** for each feature module

## 12. Testing Architecture

### Test Pyramid
- **Unit Tests:** Fast, isolated tests for business logic
- **Integration Tests:** Test interactions between layers
- **UI Tests:** Critical user journey validation

### Test Organization
- **Mirror production structure** in test directory
- **Test utilities** for common setup and teardown
- **Mock strategies** for external dependencies