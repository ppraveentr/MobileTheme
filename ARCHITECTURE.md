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
Generated style APIs expose typed `ThemeStyleID` constants. `View.style(_:)`
accepts either a `ThemeStyleID` or a `StyleToken`, so standard styles and
semantic foreground overrides share the same lookup path:
```swift
enum CoreThemeStyles {
    static let labelBase = ThemeStyleID("Label.Base")
    static let accountLabelPrimary = ThemeStyleID("account.Label.Primary")
}

enum CoreThemeColors {
    static let textNeutral = ColorID("textNeutral")
}
```
Usage:
```swift
.style(CoreThemeStyles.labelBase)
.style(CoreThemeStyles.accountLabelPrimary[CoreThemeColors.textNeutral])
```
The IDs are declared in generated Swift, allowing call sites to refer to a
named typed value instead of spelling the token string. `SemanticStyle` and
the `@StyleValue` / `@ColorValue` wrappers remain available for existing APIs.

### Common building blocks
- `StyleValue<Colors>` / `ColorValue` property wrappers support legacy
  `SemanticStyle` APIs.
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
