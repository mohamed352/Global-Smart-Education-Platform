# API & Networking Rules

## 1. Technology Stack

- **Networking:** `dio` + `retrofit` (Auto-generated clients)
- **Result Type:** `ApiResult<T>` (Freezed Union: `Success<T>` | `Failure<T>`)
- **Data Models:** `freezed` + `json_annotation`
- **Config:** `EndPoints` (Env-based constants)

## 2. Retrofit Requirements (MANDATORY PATTERNS)

### Core Rules
- **FORBIDDEN:** Manual `Dio` calls in repositories or services
- **REQUIRED:** Use `retrofit` for all API clients with type-safe interfaces

## 3. Retrofit Architecture Pattern

### 1. Service Client Interface (Abstract Class)
```dart
@RestApi()
@LazySingleton()
abstract class AuthServiceClient {
  @factoryMethod
  factory AuthServiceClient(Dio dio) = _AuthServiceClient;

  @POST('{path}')
  Future<AuthModel> login(
    @Path('path') String path,
    @Body() LoginRequest request,
  );

  @POST('{path}')
  Future<AuthModel> signup(
    @Path('path') String path,
    @Body() SignupRequest request,
  );
}
```

### 2. Request Models (Type-Safe)
```dart
abstract class AuthRequest extends Equatable {
  const AuthRequest();
  Map<String, dynamic> toJson();
}

class LoginRequest extends AuthRequest {
  const LoginRequest({required this.email, required this.password});
  final String email;
  final String password;

  @override
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  @override
  List<Object?> get props => [email, password];
}
```

### 3. Repository Implementation
```dart
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._serviceClient);
  final AuthServiceClient _serviceClient;

  @override
  Future<ApiResult<AuthEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _serviceClient.login(
        EnvConstants.loginEndpoint,
        LoginRequest(email: email, password: password),
      );
      return ApiResult.success(result);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDioException(e).message);
    }
  }
}
```

## 4. Retrofit Rules (STRICT)

### ✅ REQUIRED:
- **Dynamic Path Parameters:** Use `@Path('path') String path` for endpoint flexibility
- **Type-Safe Request Bodies:** Use dedicated Request models with `toJson()`
- **Proper Error Handling:** Catch `DioException` and convert to `ApiResult`
- **Dependency Injection:** Use `@LazySingleton()` on service clients
- **Environment-Based Endpoints:** Pass paths from `EnvConstants`

### ❌ FORBIDDEN:
- **Raw Map Bodies:** `@Body() Map<String, dynamic>` - Use typed Request models
- **Hardcoded Endpoints:** `@POST('/auth/login')` - Use `@POST('{path}')`
- **Manual Dio Calls:** Direct `dio.post()` in repositories
- **String-Based Requests:** Raw JSON string construction
- **Missing Error Handling:** Unhandled `DioException`

## 5. Environment Configuration

### EnvConstants Structure
```dart
class EnvConstants {
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String loginEndpoint = String.fromEnvironment('LOGIN_ENDPOINT');
  static const String registerEndpoint = String.fromEnvironment('REGISTER_ENDPOINT');
  static const String forgotPasswordEndpoint = String.fromEnvironment('FORGOT_PASSWORD_ENDPOINT');
}
```

### Repository Endpoint Usage
```dart
final result = await _serviceClient.login(
  EnvConstants.loginEndpoint.isNotEmpty 
    ? EnvConstants.loginEndpoint 
    : '/auth/login', // Fallback
  LoginRequest(email: email, password: password),
);
```

## 6. Request Model Best Practices

### 1. Base Request Class
```dart
abstract class AuthRequest extends Equatable {
  const AuthRequest();
  Map<String, dynamic> toJson();
}
```

### 2. Implementation with Validation
```dart
class LoginRequest extends AuthRequest {
  const LoginRequest({required this.email, required this.password});
  
  final String email;
  final String password;

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [email, password];
}
```

### 3. Social Login Requests
```dart
class GoogleLoginRequest extends AuthRequest {
  const GoogleLoginRequest({required this.idToken});
  final String idToken;

  @override
  Map<String, dynamic> toJson() {
    return {'id_token': idToken};
  }

  @override
  List<Object?> get props => [idToken];
}
```

## 7. Code Generation Requirements

### After any changes to:
- Retrofit service interfaces (`.dart`)
- Request models with `@JsonSerializable()` 
- Environment constants

### Always run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## 8. Response Handling Patterns

### Success Response
```dart
final result = await _serviceClient.login(path, request);
await _saveTokens(result);
return ApiResult.success(result.toEntity());
```

### Error Response
```dart
on DioException catch (e) {
  log.e('Login failed', error: e, stackTrace: s, tag: LogTags.auth);
  return ApiResult.failure(ApiException.fromDioException(e).message);
}
```

### Unexpected Error
```dart
catch (e, s) {
  log.e('Unexpected login error', error: e, stackTrace: s, tag: LogTags.auth);
  return const ApiResult.failure(LocaleKeys.globalErrorSubtitle);
}
```

## 9. Data Architecture Rules

### Data Flow
- **Endpoints:** Use `String.fromEnvironment` in `EndPoints`
- **Data Source:** Return raw API response via `DioConsumer`
- **Repository:** Return `Future<ApiResult<Entity>>`

### Repository Pattern Requirements
- All repositories must return `ApiResult<T>` type
- Use proper error handling with `DioException`
- Convert DTOs to Entities before returning
- Log API requests/responses at debug level, errors at error level

## 10. Logging Requirements for API Layer

### Mandatory Logging
- **Repository:** Log API requests/responses at debug level, errors at error level
- **Service Clients:** Log initialization and configuration
- **Network Operations:** Use `LogTags.network` tag
- **Authentication:** Use `LogTags.auth` tag

### Log Levels
- `log.d()` - Debug: API request/response details
- `log.i()` - Info: Successful API operations
- `log.w()` - Warning: Network issues, retries
- `log.e()` - Error: API failures with error object and stackTrace