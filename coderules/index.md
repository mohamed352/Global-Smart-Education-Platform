# Code Rules - ProfitFlow

This directory contains all coding standards, rules, and architectural guidelines for the ProfitFlow project. These rules are **non-negotiable** and must be followed strictly to maintain code quality, consistency, and scalability.

## 📁 Rule Categories

### 🎨 [UI Rules](./ui_rules.md)
UI architecture, design patterns, localization, RTL support, and performance guidelines.

### 🌐 [API Rules](./api_rules.md)
Networking standards, Retrofit patterns, request/response handling, and environment configuration.

### 🔄 [State Management Rules](./state_management_rules.md)
BLoC/Cubit patterns, immutability, state design, and logging requirements for state management.

### 🧪 [Testing Rules](./testing_rules.md)
Testing requirements, patterns, mock strategies, and coverage standards for all layers.

### 📝 [Coding Standards](./coding_standards.md)
General coding practices, type safety, logging requirements, and code quality standards.

### 🏗️ [Architecture Principles](./architecture_principles.md)
Engineering principles, design patterns, and architectural decision guidelines.

## 🚀 Quick Start

### For New Features
Follow this workflow when implementing new features:

1. **Read Architecture Principles** - Understand the "why" behind our patterns
2. **Read API Rules** - If your feature involves network operations
3. **Read State Management Rules** - For cubit/bloc implementation
4. **Read UI Rules** - For UI components and pages
5. **Read Testing Rules** - To ensure proper test coverage
6. **Read Coding Standards** - For general code quality

### For Code Reviews
Use this checklist:

- [ ] All rules in [Coding Standards](./coding_standards.md) followed
- [ ] Proper logging with `AppLogger` and correct tags
- [ ] Type safety with explicit types (no `var`/`dynamic`)
- [ ] UI follows [UI Rules](./ui_rules.md) including RTL support
- [ ] State management follows [State Management Rules](./state_management_rules.md)
- [ ] API calls follow [API Rules](./api_rules.md)
- [ ] Tests cover requirements in [Testing Rules](./testing_rules.md)
- [ ] Architecture aligns with [Architecture Principles](./architecture_principles.md)

## 🎯 Core Principles

### 1. Zero Technical Debt
We refuse to accumulate technical debt. All code must meet these standards before merging.

### 2. Type Safety
Strict typing is mandatory. No `dynamic` types except for JSON parsing.

### 3. Immutability
State must be immutable. Use `freezed` for all state classes.

### 4. Performance First
Consider performance implications in every decision - from widget composition to network calls.

### 5. Test Coverage
Every feature must have comprehensive test coverage as specified in the testing rules.

## 🔧 Technology Stack

| Category | Technology | Purpose |
|---------|-------------|---------|
| **Architecture** | Feature-First Clean Architecture | Scalable, maintainable structure |
| **State Management** | flutter_bloc + freezed | Immutable state with unions |
| **Networking** | dio + retrofit | Type-safe auto-generated clients |
| **Dependency Injection** | get_it + injectable | Auto-generated DI |
| **Testing** | flutter_test + bloc_test + mocktail | Comprehensive test coverage |
| **Logging** | Custom AppLogger | Centralized, tagged logging |

## 📋 Mandatory Requirements

### Logging
Every new feature MUST include appropriate logging:
- Use `AppLogger` (NEVER `print` or `debugPrint`)
- Use correct `LogTags` for categorization
- Log state changes, API calls, errors, and significant events

### Testing
- 100% coverage for use cases and cubits
- 90%+ coverage for repositories
- Widget tests for key interactions
- All tests must pass before merging

### Code Generation
Run `dart run build_runner build --delete-conflicting-outputs` after:
- Changing Retrofit interfaces
- Modifying `@JsonSerializable` models
- Updating environment constants

## 🚨 Strict Rules (Break These → Build Fails)

### Forbidden Patterns
- ❌ `print()`, `debugPrint()`, raw logging
- ❌ `dynamic` types (except JSON parsing)
- ❌ Manual `Dio` calls in repositories
- ❌ Hardcoded strings (use `TextManager`)
- ❌ `EdgeInsets.only(left/right)` - use `EdgeInsetsDirectional`
- ❌ Manual DI registration - use `injectable`

### Required Patterns
- ✅ `AppLogger` with correct `LogTags`
- ✅ Explicit types for all variables and returns
- ✅ Retrofit with type-safe interfaces
- ✅ `TextManager` with `LocaleKeys`
- ✅ `EdgeInsetsDirectional` for asymmetric padding
- ✅ `@injectable` annotations for DI

## 📚 Resources

### Official Documentation
- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Library](https://bloclibrary.dev/)
- [Retrofit Documentation](https://pub.dev/packages/retrofit)
- [Freezed Documentation](https://pub.dev/packages/freezed)

### Project-Specific
- [Original AI Rules](../AI_RULES.md) - Complete rules document
- [Project README](../README.md) - Project setup and overview

---

**Remember:** These rules exist to maintain code quality, enable scalability, and ensure consistency across the entire codebase. They are not suggestions - they are requirements.