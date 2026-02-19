# UI Architecture & Design Rules

## 1. Localization & Text Management (STRICT)

### Text Management Rules

- **NEVER** use hardcoded static strings
- **Keys:** Define all keys in `LocaleKeys` (`lib/core/localization/locale_keys.dart`)
- **Static Keys:** `AppText(LocaleKeys.welcomeMsg)` (Type-safe keys)
- **Dynamic Text:** `AppText('${score}%', isTranslated: false)` (For values that do not need translation)
- **Forbidden:** `Text('Hello')` or `Text('Welcome $name')`

## 2. RTL/Directionality Support (STRICT - App supports Arabic/RTL)

### Padding Rules

- **FORBIDDEN:** `EdgeInsets.only(left: X)` or `EdgeInsets.only(right: X)`
- **REQUIRED:** Use `EdgeInsetsDirectional.only(start: X)` or `EdgeInsetsDirectional.only(end: X)`
- **FORBIDDEN:** `Padding(padding: EdgeInsets.only(left/right))`
- **REQUIRED:** Use `EdgeInsetsDirectional` for all asymmetric padding
- **Symmetric Padding:** `EdgeInsets.symmetric(horizontal: X)` is ALLOWED (auto-flips correctly)

### Alignment Rules

- **FORBIDDEN:** `Alignment.centerLeft` or `Alignment.centerRight`
- **REQUIRED:** Use `AlignmentDirectional.centerStart` or `AlignmentDirectional.centerEnd`

### Text Alignment Rules

- **FORBIDDEN:** `TextAlign.left` or `TextAlign.right`
- **REQUIRED:** Use `TextAlign.start` or `TextAlign.end`

### Layout Rules

- **FORBIDDEN:** `Row` children with hardcoded left/right positioning
- **REQUIRED:** Use `MainAxisAlignment.start/end` (auto-flips in RTL)

### Examples

```dart
// BAD - Breaks in RTL
Padding(padding: EdgeInsets.only(left: 16))
Align(alignment: Alignment.centerLeft)

// GOOD - Works in both LTR and RTL
Padding(padding: EdgeInsetsDirectional.only(start: 16))
Align(alignment: AlignmentDirectional.centerStart)
```

## 3. UI Performance & Architecture

### DRY UI Components (MANDATORY)

- **Context:** When multiple screens or widgets share a similar layout or logic (e.g., onboarding steps), do **NOT** duplicate widgets with minor variations
- **REQUIRED:** Create a single reusable widget driven by a configuration model/entity
- **Parameterize differences via a dedicated Model class** to keep the codebase maintainable and clean

### Anti-Patterns

- **Anti-Pattern (Wrappers):** NEVER use redundant `Material` widgets
  - **FORBIDDEN:** `Material(color: Colors.transparent, child: ...)` - Use `Material` only when needed for ink effects or proper Material surface behavior
  - **Exception:** Use `Material` only when you need inkwell ripple effects, elevation, or specific Material surface properties
- **Anti-Pattern (Helpers):** Avoid helper methods (e.g., `_buildHeader()`) for UI components; extract to `StatelessWidget`
- **Exception:** Private, simple helper methods (<10 lines) with zero rebuild logic are acceptable

### Const Performance Optimization (MANDATORY)

- **BorderRadius:** **ALWAYS** use `const` constructors for BorderRadius to prevent unnecessary widget rebuilding
- **FORBIDDEN:** `borderRadius: BorderRadius.circular(12)` (creates new instance each build)
- **REQUIRED:** `borderRadius: const BorderRadius.all(Radius.circular(12))` (const instance)

#### Examples

```dart
// BAD - Creates new BorderRadius instance on every build
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    color: ColorManager.primary,
  ),
)

// GOOD - Uses const BorderRadius, prevents unnecessary rebuilds
Container(
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    color: ColorManager.primary,
  ),
)

// BAD - Redundant Material widget
Material(
  color: Colors.transparent,
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
)

// GOOD - Direct Container without unnecessary Material wrapper
Container(
  decoration: BoxDecoration(
    borderRadius: const BorderRadius.all(Radius.circular(8)),
    color: ColorManager.surface,
  ),
)
```

### File Size Limit

- **Maximum 150 lines per file**
- **Refactor immediately** if exceeded

### Images

- **ALWAYS** use the custom `AppImage` widget

### Layout Performance

- **Prefer** `SizedBox` (spacing), `Padding`, or `DecoratedBox` over `Container` when a lighter widget suffices
- **Use `Container`** when combining decoration, padding, and sizing to reduce nesting depth

## 4. Scroll Widgets (STRICT)

### Usage Guidelines

- **SingleChildScrollView:** ONLY for wrapping a SINGLE child that may overflow (e.g., a Form). NOT for full page scrolling
- **ListView:** Use when the entire Scaffold body is scrollable content
- **CustomScrollView:** Use when page has multiple scrollable sections (e.g., header + list + footer with slivers)

## 5. Glow Effects (MANDATORY)

### Rules

- **NEVER** use `BackdropFilter` or `ImageFiltered` for decorative background glows/orbs
- **REQUIRED:** Use `radial-gradient` fading to transparent. This has 0 blur cost
- **ONLY** use `BackdropFilter` for "Frosted Glass" overlays where content behind _must_ be blurred

## 6. UI Logic Separation (GOLDEN RULE)

### Styling Logic Rules

- **FORBIDDEN:** Inline conditional logic for styling (colors, gradients, icons) in widgets
- **REQUIRED:** Extract complex styling logic into dedicated helper classes, enums, or extensions

### Examples

```dart
// BAD
gradient: LinearGradient(
  colors: isCritical
      ? [ColorManager.error, ColorManager.error.withValues(alpha: 0.8)]
      : isWarning
      ? [ColorManager.warning, ColorManager.warning.withValues(alpha: 0.8)]
      : [ColorManager.limeGreen, ColorManager.primary],
)

// GOOD - In a separate helper file:
class ButtonStyle {
  List<Color> get gradientColors => switch (status) {
    Status.critical => [ColorManager.error, ...],
    Status.warning => [ColorManager.warning, ...],
    Status.safe => [ColorManager.limeGreen, ColorManager.primary],
  };
}
// In UI:
gradient: LinearGradient(colors: style.gradientColors)
```

## 7. Required Extensions & Utilities

### Context Extensions (Use These)

```dart
extension ContextValues on BuildContext {
  // Sizing
  double get height => MediaQuery.sizeOf(this).height;
  double get width => MediaQuery.sizeOf(this).width;
  double get shortestSide => MediaQuery.sizeOf(this).shortestSide;
  bool get isTablet => width > 600 && shortestSide > 550;

  // Theme
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Dialogs
  // Use context.loadingDialog(), context.errorDialog()
}
```

### DateTime Extensions (Use These)

```dart
extension FormatDateTimeOnDateTime on DateTime {
  String formatTime(); // Returns "HH:MM"
  String get formatDate; // Returns "DD/MM/YYYY"
  String since(); // Returns "5 minutes ago"
}
```

### Forbidden Patterns

- **Media Queries:** **FORBIDDEN:** `MediaQuery.of(context)...`
  - **REQUIRED:** Use `context.height`, `context.width`
- **Theming:** **FORBIDDEN:** `Theme.of(context).brightness == ...`
  - **REQUIRED:** Use `context.isDark`
- **Formatting:** **FORBIDDEN:** Writing private `_formatDate()` methods
  - **REQUIRED:** Use `date.formatTime()`, `date.formatDate`
- **Dialogs:** **FORBIDDEN:** `showDialog(...)`
  - **REQUIRED:** Use `context.loadingDialog()`, `context.errorDialog()`

## 8. Theming & Colors (STRICT)

### Theme-Aware Colors (MANDATORY)

- **FORBIDDEN:** Using hardcoded `Colors.white`, `Colors.black`, or any `Color(0xFF...)` for text, backgrounds, or UI elements
- **REQUIRED:** Use `context.appColors` for semantic colors that adapt to light/dark mode

### Available Theme Colors (via `context.appColors`)

```dart
// Text Colors
context.appColors.textPrimary     // Main text (headings, important content)
context.appColors.textSecondary   // Subtitles, labels, hints
context.appColors.textMuted       // Disabled, captions, placeholders

// Background Colors
context.appColors.scaffoldBackground     // Main screen background
context.appColors.cardBackground         // Card surfaces
context.appColors.cardBackgroundElevated // Nested/raised cards
context.appColors.surfaceOverlay         // Subtle overlays

// Border Colors
context.appColors.borderSubtle    // Dividers, subtle borders
context.appColors.borderHover     // Interactive element borders
```

### When to Use Theme Colors

| Use Case                    | Color to Use                   |
| --------------------------- | ------------------------------ |
| Page/section titles         | `textPrimary`                  |
| Subtitles, descriptions     | `textSecondary`                |
| Input hints, captions       | `textSecondary` or `textMuted` |
| Card backgrounds            | `cardBackground`               |
| Icon colors (informational) | `textSecondary`                |
| Borders, dividers           | `borderSubtle`                 |

### When Static Colors Are Allowed

- **Primary brand color:** Use `Theme.of(context).primaryColor` or `ColorManager.primary`
- **Semantic status colors:** Use `ColorManager.success`, `ColorManager.danger`, `ColorManager.warning`
- **Glass/frosted effects:** Use `ColorManager.glassSurface`, `ColorManager.glassBorder`
- **Gradients with brand colors:** Use `ColorManager.primaryGradient`

### Examples

```dart
// BAD - Hardcoded colors break in light mode
Text('Hello', style: TextStyle(color: Colors.white))
Container(color: Color(0xFF1a1a1a))
Icon(Icons.star, color: Colors.grey)

// GOOD - Theme-aware colors adapt automatically
Text('Hello', style: TextStyle(color: context.appColors.textPrimary))
Container(color: context.appColors.cardBackground)
Icon(Icons.star, color: context.appColors.textSecondary)
```

### AppColors Extension Location

- Defined in: `lib/core/style/app_colors.dart`
- Import: `import 'package:profitflow/core/style/app_colors.dart';`

## 9. Asset Management

### Assets & Strings

- **Use** `ColorManager` and `StringsManager`
- **NEVER** hardcode values
