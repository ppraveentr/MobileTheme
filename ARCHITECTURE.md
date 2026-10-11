# MobileTheme Architecture

## Goals
- Semantic-first theming API for app components.
- Typed generated style/color access for safer usage and autocomplete.
- Runtime mode support (light/dark) without style duplication.

## Theme Model
- **Palettes**: raw color scales per mode.
- **Semantic tokens**: named aliases resolved from palettes or literals.
- **Background tokens**: reusable semantic background definitions.
- **Border tokens**: reusable semantic border definitions (no light/dark
  duplication; a border resolves to a single semantic color reference).
- **Styles**: nested component style tree flattened to dot-path keys (for example, `Label.Primary`).

## Resolution Pipeline
1. Decode JSON into `ThemeJSONModel`.
2. Resolve palette + semantic aliases per mode into concrete colors.
3. Build `ThemeModel` dictionaries (`colors`, `backgrounds`, `borders`, `fonts`, `styles`).
4. For light mode setup, merge dark colors into `Appearance` values.
5. Rebuild derived style/background/border maps with resolved colors, using a
   `ThemeModel.Lookup` (module-first, falling back to a base model when set).

## Style Application API
Two ways to define generated, typed style access. Both resolve through the
same `View.style(_:)` overloads and `ThemesManager` lookup path, and both are
backed by the same `@StyleValue` / `@ColorValue` property wrappers — the
difference is purely where the generated static member is declared.

### 1. Leading-dot static members on `SemanticStyle` (preferred)
Declare generated members as static members on `SemanticStyle`, constrained
by `where Colors == ...`. This lets call sites use SwiftUI's implicit-member
(leading-dot) syntax without any namespacing type prefix, which keeps call
sites shortest and reads closest to a native SwiftUI modifier:
```swift
extension SemanticStyle where Colors == CoreTheme.SemanticColors {
    @StyleValue("Label.Base")
    static var labelBase: Self

    @StyleValue(module: AccountThemeProvider.self, "Label.Primary")
    static var accountLabelPrimary: Self
}
```
Usage:
```swift
.style(.labelBase)
.style(.labelPrimary.textNeutral)   // chained semantic color override
```
This works because `SemanticStyle.subscript(dynamicMember:)` returns `Self`
(not `StyleSelectionValue`), so a chained implicit-member expression still
type-checks against the generic `style<Colors>(_:)` view modifier overload.

Prefer this pattern for new generated code and new components. Use it unless
a call site specifically benefits from an explicit, fully-qualified name (see
below).

### 2. Enum-namespaced (`@StyleValue` / `@ColorValue`) — alternative
If you don't want to add an `extension SemanticStyle where Colors == ...`
per color set (for example, to avoid widening `SemanticStyle`'s public
static-member surface, or because you want call sites to read with an
explicit, self-documenting name instead of a bare leading dot), declare the
same wrapper inside a plain enum instead:
```swift
enum AppSemanticStyle {
    @StyleValue("Label.Primary")
    static var labelPrimary: SemanticStyle<SemanticColors>
}
```
Usage: `.style(AppSemanticStyle.labelPrimary)`.

Choose this option when a named, fully-qualified reference is preferred over
the shorthand leading-dot form — the underlying wrapper, resolution, and
caching behavior are identical either way.

### Common building blocks
- `StyleValue<Colors>` / `ColorValue` property wrappers back both patterns.
- Module/brand codegen uses `ThemeModuleProviding.namespace` directly in
  wrappers, e.g. `@StyleValue(module: AccountThemeProvider.self, "Label.Primary")`.
- `SemanticStyle.style(_:)` / `.style(module:_:)` static builders construct a
  selection from a raw key; `StyleValue.wrappedValue` calls into these.
- Views apply style via:
  - `.style(StyleToken)`
  - `.style(StyleSelectionValue)`
  - `.style(SemanticStyle<Colors>)`
  - `.style(StyleScope, semanticColor: ColorID?)`
- Border is semantic-only at style level (`UserStyleModel.border` token); no inline `background.border`.

## Concurrency
- `ThemesManager` is a Swift `actor` (not a `@MainActor` class). All public
  entry points (`setupApplicationTheme`, `register`, `style`, `color`, `font`,
  `resolvedStyle`) are `async` and hop through actor isolation.
- `ThemeModifier` resolves styles with `.task(id:)` + `await` rather than
  `DispatchQueue.main.async`, keyed on `(styleID, foregroundColorID)` so a
  style change only re-triggers resolution when the identity actually changes.

## Lookup and Caching
- Base style and color lookups are dictionary-based (`O(1)`).
- `ThemesManager` includes an in-memory cache for resolved style variants:
  - key: `themeVersion + styleID + foregroundColorID`
  - invalidated on theme setup/register updates (`themeVersion` incremented,
    cache cleared).

## Module Composition
- `ThemeModuleProviding` supports feature/module theme payloads (`namespace` +
  `themeData`).
- `ThemesManager.register(_:)` generates the module's `ThemeModel` with the
  current base model as fallback, then merges it into the app theme.
- Namespacing (`namespace.styleName`, `namespace.colorName`, etc.) prevents key
  collisions across modules; `ThemeModuleProviding.namespaced(_:)` is reused
  both for merge qualification and for wrapper-based generated keys.
- Module merge is additive for styles; a duplicate namespaced style ID throws
  `ThemeMergeError.duplicateStyle` (no silent override).
- Module themes can reference base (fallback model) colors, backgrounds,
  borders, fonts, and styles during their own resolution, via
  `ThemeModel.Lookup(primary: moduleModel, fallback: baseModel)`.

## Scalability Notes
- Keep JSON semantic and tokenized to avoid duplicated style declarations.
- Generate typed constants per module/brand to keep APIs manageable.
- Add build-time validation and token governance for large multi-team systems.
