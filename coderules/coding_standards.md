# Coding Standards & Best Practices

## 1. Code Safety & Linter

### Strict Typing Requirements
- **Must pass** `strict-casts`, `strict-inference`, and `strict-raw-types`
- **No `dynamic`** - Always use explicit types
- **Explicit return types** for all functions

### Linting Compliance
- **Strictly follow** the user's `analysis_options.yaml`
- **All lint rules** must be satisfied
- **No warnings** or errors allowed

## 2. Logging Requirements (MANDATORY)

### Forbidden Patterns
- **FORBIDDEN:** `debugPrint`, `print`, raw `developer.log`

### Required Logging Usage
```dart
import 'package:baseet_app/core/logger/app_logger.dart';
import 'package:baseet_app/core/logger/log_config.dart';

log.d('Debug message', tag: LogTags.cache);      // Debug level
log.i('Info message', tag: LogTags.network);     // Info level
log.w('Warning message', tag: LogTags.error);    // Warning level
log.e('Error message', tag: LogTags.error, error: e, stackTrace: s); // Error level
```

### Log Categories & Tags
- `LogTags.bloc` - Bloc/Cubit events
- `LogTags.cache` - Cache operations
- `LogTags.network` - API/Network operations
- `LogTags.camera` - Camera operations
- `LogTags.scanner` - Barcode scanner
- `LogTags.inspection` - Food inspection
- `LogTags.auth` - Authentication
- `LogTags.error` - Error handling
- `LogTags.navigation` - Navigation events
- `LogTags.app` - General app events

### Log Levels
- `log.d()` - Debug: Detailed technical info (cache access, state details)
- `log.i()` - Info: Significant events (camera ready, barcode detected, photo saved)
- `log.w()` - Warning: Potential issues (camera not ready, network issue)
- `log.e()` - Error: Failures with error object and stackTrace

## 3. Logging Requirements (MANDATORY FOR ALL NEW FEATURES)

### Feature Logging Checklist
Every new feature MUST include appropriate logging:

1. **Cubit/Bloc:** Log significant state changes, API calls, and errors
2. **Repository:** Log API requests/responses at debug level, errors at error level
3. **Services:** Log initialization, operations, and failures
4. **Camera/Scanner/Hardware:** Log hardware events (init, capture, toggle, dispose)

## 4. Type Safety Rules

### Explicit Types (Type Safety)
- **FORBIDDEN:** `var` or `dynamic` (except for JSON parsing)
- **REQUIRED:** Always specify return types for functions and types for variables

### Examples
```dart
// BAD - Implicit types hide bugs
final data = await repo.getData();
var user = response.body;

// GOOD - Explicit types catch errors at compile time
final ApiResult<User> result = await repo.getData();
final User user = response.body;
```

## 5. Asset Management

### Required Usage
- **Use** `ColorManager` and `StringsManager`
- **NEVER** hardcode values

### Constants
- **Colors:** Use `ColorManager.primary`, `ColorManager.error`, etc.
- **Strings:** Use `StringsManager.welcome`, `StringsManager.error`, etc.
- **Dimensions:** Use named constants for spacing, sizing, etc.

## 6. File Organization

### File Size Limits
- **Maximum 150 lines per file**
- **Refactor immediately** if exceeded

### File Naming
- **Snake case** for file names: `user_cubit.dart`, `auth_repository.dart`
- **Consistent naming** across the project

### Directory Structure
- Follow feature-first clean architecture
- Keep related files together
- Separate layers clearly (domain, data, presentation)

## 7. Code Quality Standards

### Function Length
- Keep functions under 50 lines
- Single responsibility principle
- Extract helper methods when needed

### Variable Naming
- **Descriptive names** that explain purpose
- **Camel case** for variables: `userName`, `isLoading`
- **Prefix booleans** with `is`, `has`, `can`, `should`: `isLoading`, `hasError`

### Constants
- **Upper snake case** for constants: `API_BASE_URL`, `MAX_RETRY_COUNT`
- Group related constants in classes

## 8. Documentation Standards

### Class Documentation
```dart
/// Manages user authentication state and operations.
/// 
/// This cubit handles login, logout, and token refresh operations.
/// It communicates with the authentication repository and emits states
/// based on the current authentication status.
class AuthCubit extends Cubit<AuthState> {
  /// Creates an [AuthCubit] with the provided [authRepository].
  const AuthCubit(this._authRepository) : super(const AuthState.initial());
  
  final AuthRepository _authRepository;
}
```

### Method Documentation
```dart
/// Attempts to log in a user with the provided credentials.
/// 
/// Parameters:
/// - [email] The user's email address
/// - [password] The user's password
/// 
/// Returns [void] and emits appropriate states based on the result.
/// Emits [AuthState.loading] during the operation.
/// Emits [AuthState.authenticated] on successful login.
/// Emits [AuthState.error] if login fails.
Future<void> login({
  required String email,
  required String password,
}) async {
  // Implementation...
}
```

## 9. Error Handling Standards

### Exception Types
- **Custom exceptions** for domain-specific errors
- **Consistent error messaging** using `TextManager`
- **Proper error logging** with stack traces

### Error Handling Pattern
```dart
try {
  final result = await operation();
  return ApiResult.success(result);
} on DioException catch (e) {
  log.e('Network operation failed', error: e, stackTrace: s, tag: LogTags.network);
  return ApiResult.failure(ApiException.fromDioException(e).message);
} catch (e, s) {
  log.e('Unexpected error', error: e, stackTrace: s, tag: LogTags.error);
  return const ApiResult.failure('An unexpected error occurred');
}
```

## 10. Performance Standards

### Memory Management
- **Dispose resources** properly in streams, controllers, and timers
- **Avoid memory leaks** with proper cleanup
- **Use weak references** where appropriate

### Performance Optimization
- **Lazy loading** for heavy operations
- **Efficient algorithms** and data structures
- **Minimal rebuilds** in UI code

## 11. Security Standards

### Data Protection
- **Never log sensitive information** (passwords, tokens, PII)
- **Use secure storage** for sensitive data
- **Validate all inputs** before processing

### API Security
- **HTTPS only** for network requests
- **Proper authentication** headers
- **Input sanitization** for API calls

## 12. Code Generation Standards

### Build Runner Usage
- **Run after changes** to:
  - Retrofit service interfaces
  - Request models with `@JsonSerializable()`
  - Environment constants
- **Command:** `dart run build_runner build --delete-conflicting-outputs`

### Freezed Usage
- **Immutable classes** with `@freezed`
- **Union types** for state and result objects
- **CopyWith** functionality for updates

## 13. Import Organization

### Import Order
```dart
// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports
import 'package:profitflow/core/utils/logger.dart';
import 'package:profitflow/features/auth/domain/entities/user.dart';
```

### Unused Imports
- **Remove all unused imports**
- **Use automatic import organization** in IDE
- **No wildcard imports** unless absolutely necessary

## 14. Quality Control Examples

### BAD CODE (DO NOT DO THIS)
```dart
// Bad: Inline formatting, verbose MediaQuery, manual theme check, raw print
Widget build(BuildContext context) {
   final h = MediaQuery.of(context).size.height; // BAD
   final isDark = Theme.of(context).brightness == Brightness.dark; // BAD: Repetitive
   debugPrint('Building widget'); // BAD: Use AppLogger
   return Container( // BAD: Container used just for height
     height: h * 0.5,
     child: Text("Hello", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
   );
}
```

### GOOD CODE (DO THIS)
```dart
// Good: Uses Extensions, SizedBox, Context Theme check, and AppLogger
Widget build(BuildContext context) {
   log.d('Building MyWidget', tag: LogTags.app); //? Uses AppLogger
   //? Uses context.height extension + SizedBox for performance
   return SizedBox(
     height: context.height * 0.5,
     child: Text(
       DateTime.now().formatTime(), //? Uses Date Extension
       style: TextStyle(
         //? Uses context.isDark extension
         color: context.isDark ? ColorManager.textHighContrast : ColorManager.text,
       ),
     ),
   );
}
```