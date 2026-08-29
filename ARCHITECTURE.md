# MobileTheme Architecture

## Goals
- Semantic-first theming API for app components.
- Typed generated style/color access for safer usage and autocomplete.
- Runtime mode support (light/dark) without style duplication.

## Theme Model
- **Palettes**: raw color scales per mode.
- **Semantic tokens**: named aliases resolved from palettes or literals.
- **Background tokens**: reusable semantic background definitions.
- **Border tokens**: reusable semantic border definitions.
- **Styles**: nested component style tree flattened to dot-path keys (for example, `Label.Primary`).

## Resolution Pipeline
1. Decode JSON into `ThemeJSONModel`.
2. Resolve palette + semantic aliases per mode into concrete colors.
3. Build `ThemeModel` dictionaries (`colors`, `backgrounds`, `borders`, `fonts`, `styles`).
4. For light mode setup, merge dark colors into `Appearance` values.
5. Rebuild derived style/background/border maps with resolved colors.

## Style Application API
- `StyleValue` and `ColorValue` property wrappers define generated APIs.
- Module/brand codegen uses `ThemeModuleProviding.namespace` directly in wrappers.
  - Example: `@StyleValue(module: AccountThemeProvider.self, "Label.Primary")`
  - Example: `@ColorValue(module: AccountThemeProvider.self, "text.primary")`
- Views apply style via:
  - `.style(StyleToken)`
  - `.style(StyleSelectionValue)`
  - `.style(StyleSelection<SemanticColors>)`
  - `.style(StyleScope, semanticColor: ColorID?)`
- Border is semantic-only at style level (`UserStyleModel.border` token); no inline `background.border`.

## Lookup and Caching
- Base style and color lookups are dictionary-based (`O(1)`).
- `ThemesManager` is a Swift `actor` and includes in-memory cache for resolved style variants:
  - key: `themeVersion + styleID + foregroundColorID`
  - invalidated on theme setup/register updates.

## Module Composition
- `ThemeModuleProviding` supports feature/module theme payloads.
- `ThemesManager.register(_:)` merges module dictionaries into app theme.
- `ThemesManager.queue(_:)` supports deferred module registration.
- `ThemesManager.loadDeferredModule(namespace:)` / `loadAllDeferredModules()` merge queued modules incrementally.
- Namespacing prevents key collisions across modules.
- Module merge is additive for styles; duplicate namespaced style IDs are rejected (no override).

## Scalability Notes
- Keep JSON semantic and tokenized to avoid duplicated style declarations.
- Generate typed constants per module/brand to keep APIs manageable.
- Add build-time validation and token governance for large multi-team systems.
