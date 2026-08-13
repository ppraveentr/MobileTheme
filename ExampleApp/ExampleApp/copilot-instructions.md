# Copilot Instructions: JSON-Driven SwiftUI Theme and Component Styling

## Purpose

Apply these instructions when adding or changing SwiftUI design-system code in this project.

The app uses a JSON-driven styling system. Existing color palettes and font-style definitions are **primitive tokens**. SwiftUI components must use resolved, semantic, typed styles—not raw palette values, JSON paths, or ad hoc view modifiers.

The design system must support:

- Existing visual parity with legacy components
- Multiple brands or palettes
- Light and dark mode
- Optional increased-contrast variants
- Runtime JSON loading with bundled fallback
- Reusable, strongly typed SwiftUI components
- Incremental migration of existing screens

---

## Non-negotiable architecture

Follow this pipeline exactly:

```text
JSON names tokens
→ Decodable payload structs
→ validation + alias resolver
→ concrete resolved Swift types
→ protocol-backed theme/style registry
→ observable theme store
→ SwiftUI environment
→ components render semantic styles
```

### Rules

1. Do not let SwiftUI views or components decode JSON.
2. Do not let components access JSON dictionaries, token-path strings, or palette keys.
3. Do not hardcode `Color`, `Font`, spacing, radius, border, or shadow values in feature views or reusable components.
4. Do not make one large generic component with many Boolean style flags.
5. Do not make components choose `light` or `dark` palettes themselves.
6. Do not derive dark colors by blindly inverting light colors.
7. Resolve all aliases and mode-specific values before styles reach the SwiftUI view hierarchy.
8. Keep the last validated theme active if a remote payload is invalid.

---

## Token layers

Use three layers. Never bypass a layer.

### 1. Primitive tokens

Primitive tokens are raw design values. They are not used directly by SwiftUI components.

Examples:

```text
palette.neutral.0
palette.neutral.950
palette.brand.400
palette.brand.600
font.inter.regular
font.inter.semibold
space.8
space.16
radius.12
```

### 2. Semantic tokens

Semantic tokens describe purpose, not a literal color or font value. They are mode-aware.

Examples:

```text
surface.canvas
surface.raised
surface.selected
text.primary
text.secondary
text.inverse
border.subtle
border.focus
icon.primary
action.primary.background
action.primary.foreground
status.error.foreground
typography.body
typography.button.label
```

### 3. Component tokens

Component tokens describe a specific component part, variant, and state. They normally reference semantic tokens.

Examples:

```text
button.primary.container.default
button.primary.container.pressed
button.primary.label.default
button.primary.label.disabled
textField.default.border.focused
textField.default.border.error
card.summary.surface
card.summary.title
```

---

## JSON conventions

### Theme structure

Use one stable semantic contract. Light and dark modes provide different primitive or semantic mappings, while components retain the same logical style keys.

```json
{
  "schemaVersion": 1,
  "themeId": "default",
  "palettes": {
    "light": {
      "neutral": {
        "0": "#FFFFFF",
        "50": "#F7F7F8",
        "600": "#5F6368",
        "900": "#1C1B1F"
      },
      "brand": {
        "400": "#4A86FF",
        "600": "#0057D9"
      }
    },
    "dark": {
      "neutral": {
        "0": "#FFFFFF",
        "50": "#F4F4F5",
        "300": "#C7C7CC",
        "900": "#1B1B1F",
        "950": "#101114"
      },
      "brand": {
        "400": "#78A5FF",
        "600": "#3D7CF2"
      }
    }
  },
  "semantic": {
    "light": {
      "surface.canvas": "{palette.neutral.0}",
      "surface.raised": "{palette.neutral.50}",
      "text.primary": "{palette.neutral.900}",
      "text.secondary": "{palette.neutral.600}",
      "action.primary.background": "{palette.brand.600}",
      "action.primary.foreground": "{palette.neutral.0}"
    },
    "dark": {
      "surface.canvas": "{palette.neutral.950}",
      "surface.raised": "{palette.neutral.900}",
      "text.primary": "{palette.neutral.50}",
      "text.secondary": "{palette.neutral.300}",
      "action.primary.background": "{palette.brand.400}",
      "action.primary.foreground": "{palette.neutral.950}"
    }
  },
  "components": {
    "button": {
      "primary": {
        "container": {
          "default": "{action.primary.background}",
          "pressed": "{action.primary.backgroundPressed}",
          "disabled": "{surface.disabled}"
        },
        "label": {
          "default": "{action.primary.foreground}",
          "disabled": "{text.disabled}"
        },
        "radius": "{radius.control}",
        "minHeight": "{size.control.md}",
        "horizontalPadding": "{space.control.md}",
        "font": "{typography.button.label}"
      }
    }
  }
}
```

### JSON rules

- Use semantic aliases such as `"{text.primary}"`, not duplicated raw hex values in component definitions.
- Every remote payload must include `schemaVersion`, `themeId`, and an optional payload version or ETag.
- Component types, variants, elements, and states are controlled values.
- Unknown component variants or required missing values must fail validation.
- Optional values may use documented fallback rules.
- Do not allow arbitrary screen-level keys to create unreviewed visual styles.

---

## Dark mode and contrast

### Theme mode selection

Support these preferences:

```swift
enum ThemePreference: String, Codable, Sendable {
    case system
    case light
    case dark
}

enum ThemeMode: String, Codable, Sendable {
    case light
    case dark
}
```

Resolve the active mode in this order:

1. User preference of `.light` or `.dark` wins.
2. A `.system` preference uses SwiftUI `colorScheme`.
3. Select the theme's palette and semantic mappings for the resulting mode.
4. Apply an increased-contrast override last, when supplied.
5. Resolve component tokens after semantic tokens have been resolved.

### Requirements

- A theme must provide intentional light and dark values for all required semantic color roles.
- Do not automatically invert colors to generate dark mode.
- Typography should normally be mode-independent.
- Typography may vary by accessibility requirement only when explicitly designed and documented.
- Preserve Dynamic Type. Map typography tokens to a text style and scaling behavior; do not use fixed font sizes without `relativeTo:`.
- Test color contrast for default, disabled, selected, focused, error, and pressed states in both modes.

---

## Swift types and protocol contracts

Protocols define semantic capability. Payload structs mirror JSON. Resolved structs conform to protocols.

### Do this

```swift
protocol ThemeProviding {
    var colors: any ColorTokensProviding { get }
    var typography: any TypographyTokensProviding { get }
    var buttons: any ButtonStyleRegistryProviding { get }
    var textFields: any TextFieldStyleRegistryProviding { get }
}

protocol ColorTokensProviding {
    var canvas: Color { get }
    var raisedSurface: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var borderSubtle: Color { get }
}

protocol ButtonStyleProviding {
    var container: any ControlStateColorProviding { get }
    var label: any ControlStateColorProviding { get }
    var minimumHeight: CGFloat { get }
    var horizontalPadding: CGFloat { get }
    var cornerRadius: CGFloat { get }
    var font: Font { get }
}

protocol ControlStateColorProviding {
    var normal: Color { get }
    var pressed: Color { get }
    var disabled: Color { get }
}

enum ButtonVariant: String, Codable, Hashable, Sendable {
    case primary
    case secondary
    case destructive
}
```

### Do not do this

```swift
// Do not expose raw JSON dictionaries to SwiftUI components.
let color = payload["button.primary.container.default"]

// Do not require string paths in component APIs.
AppButton(styleKey: "button.primary")

// Do not encode every visual property as an unrelated Boolean.
AppButton(isPrimary: true, isRounded: true, isLarge: true)
```

### Resolved concrete types

```swift
struct ResolvedButtonStyle: ButtonStyleProviding {
    let container: any ControlStateColorProviding
    let label: any ControlStateColorProviding
    let minimumHeight: CGFloat
    let horizontalPadding: CGFloat
    let cornerRadius: CGFloat
    let font: Font
}

struct ResolvedTheme: ThemeProviding {
    let colors: any ColorTokensProviding
    let typography: any TypographyTokensProviding
    let buttons: any ButtonStyleRegistryProviding
    let textFields: any TextFieldStyleRegistryProviding
}
```

Do not make payload structs conform to UI-facing style protocols unless they are already fully validated and resolved.

---

## Resolver requirements

Create a dedicated resolver, separate from the loader and separate from SwiftUI views.

```swift
protocol ThemeResolving {
    func resolve(
        payload: ThemePayload,
        mode: ThemeMode,
        contrast: AccessibilityContrast
    ) throws -> ResolvedTheme
}
```

The resolver must:

1. Verify the supported `schemaVersion`.
2. Select the active light or dark branch.
3. Resolve alias references recursively.
4. Detect alias cycles.
5. Convert raw values to platform values such as `Color`, `Font`, and `CGFloat`.
6. Validate mandatory semantic tokens.
7. Validate mandatory component tokens for every supported variant.
8. Use only documented fallbacks.
9. Return an immutable resolved theme.
10. Never expose unresolved aliases to the UI layer.

Use a diagnostics result for development builds that identifies missing paths, invalid hex values, unsupported variants, and fallback use.

---

## Loader and cache requirements

Use a repository. Do not place loading or cache logic in a SwiftUI view.

```text
ThemeStore
→ ThemeRepository
→ memory cache
→ disk cache
→ bundle source / remote source
→ JSON decoder
→ resolver
```

### Startup behavior

1. Use the in-memory resolved theme when present.
2. Otherwise load the last validated disk payload.
3. Otherwise load a bundled default JSON theme.
4. Render immediately using that validated result.
5. Refresh the remote payload in the background.
6. Replace the current theme only after the new payload validates and resolves successfully.
7. Keep the active last-known-good theme if fetch, parsing, or resolution fails.

### Cache keys

Use a cache key that includes:

```text
themeId + schemaVersion + platform + appMajorVersion
```

When tenant or brand customization exists, include the tenant/brand identifier as well.

### Invalidate cache when

- The JSON schema becomes incompatible
- The active brand or tenant changes
- The payload expires according to TTL or server cache metadata
- The user logs out and themes are tenant-specific
- A feature-flag context that affects tokens changes
- The app deliberately resets styling during development/testing

Cache raw validated JSON payloads. Optionally cache a serialized resolved representation only if it is stable and safe to recreate across app versions. Always revalidate after app upgrades when schema rules may have changed.

---

## Observable environment delivery

The observable store is a delivery mechanism, not the JSON source of truth.

```swift
@Observable
@MainActor
final class ThemeStore {
    private(set) var theme: ResolvedTheme
    private(set) var activeMode: ThemeMode
    private(set) var state: ThemeLoadState = .ready

    private let repository: ThemeLoading
    private let resolver: ThemeResolving

    init(
        theme: ResolvedTheme,
        activeMode: ThemeMode,
        repository: ThemeLoading,
        resolver: ThemeResolving
    ) {
        self.theme = theme
        self.activeMode = activeMode
        self.repository = repository
        self.resolver = resolver
    }

    func load(mode: ThemeMode) async {
        state = .loading
        do {
            let payload = try await repository.loadPayload()
            theme = try resolver.resolve(
                payload: payload,
                mode: mode,
                contrast: .standard
            )
            activeMode = mode
            state = .ready
        } catch {
            state = .usingFallback(error)
        }
    }
}
```

Inject one store at the app composition root:

```swift
RootView()
    .environment(themeStore)
```

Components use the resolved theme:

```swift
struct AppButton: View {
    @Environment(ThemeStore.self) private var themeStore

    let title: String
    let variant: ButtonVariant
    let action: () -> Void
    let isEnabled: Bool

    var body: some View {
        let style = themeStore.theme.buttons[variant]
        let background = isEnabled ? style.container.normal : style.container.disabled
        let foreground = isEnabled ? style.label.normal : style.label.disabled

        Button(action: action) {
            Text(title)
                .font(style.font)
                .foregroundStyle(foreground)
                .frame(minHeight: style.minimumHeight)
                .padding(.horizontal, style.horizontalPadding)
                .frame(maxWidth: .infinity)
                .background(background)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: style.cornerRadius,
                        style: .continuous
                    )
                )
        }
        .disabled(!isEnabled)
    }
}
```

Do not inject raw payloads or generic `[String: Any]` token maps into SwiftUI environment.

---

## Component authoring rules

When creating a component:

1. Identify its semantic and component style contract before writing the view.
2. Use controlled enums for variants and states.
3. Read resolved style protocols from the active theme.
4. Keep interaction state native to SwiftUI, for example `isPressed`, `isEnabled`, focus, and accessibility state.
5. Use the resolved component style to determine how that state looks.
6. Provide preview fixtures for light, dark, and fallback themes.
7. Test the component against the legacy counterpart before migration.

### Example component contract

```swift
enum TextFieldVariant: String, Codable, Hashable, Sendable {
    case standard
    case inline
    case search
}

enum FieldState: Hashable, Sendable {
    case normal
    case focused
    case error
    case disabled
}
```

Use `TextFieldVariant` and `FieldState`; do not use raw token strings such as `"textField.inline.border.error"` in the component API.

---

## Migration rules for the existing app

- Audit each legacy component before replacing it.
- Create a parity matrix with visual properties, states, accessibility behavior, and edge cases.
- Extract observed legacy colors, typography, spacing, radii, borders, and elevation into primitive and semantic tokens.
- Create a SwiftUI component only after required parity states are represented in JSON and the resolver.
- Migrate one screen or feature at a time.
- Keep a migration adapter only when it prevents duplicate styling during transition; delete it after migration is complete.
- Do not modify a legacy component solely to imitate the new SwiftUI API.

### Required parity states

Validate, when applicable:

- Default
- Pressed
- Disabled
- Selected
- Focused
- Error
- Loading
- Empty
- Light mode
- Dark mode
- Increased contrast
- Dynamic Type sizes
- VoiceOver labels and traits

---

## Testing requirements

### Unit tests

Test:

- JSON decoding
- Schema-version compatibility
- Alias resolution
- Alias-cycle detection
- Light and dark token resolution
- Contrast override resolution
- Missing required token failures
- Fallback behavior
- Cache read/write/invalidation
- Theme replacement only after successful validation

### Snapshot or UI tests

Test each supported component variant and state in:

- Light mode
- Dark mode
- Increased contrast when available
- Dynamic Type accessibility sizes
- Enabled and disabled states
- Error and focus states when applicable

### Development diagnostics

In debug builds, log or surface:

- Theme ID and payload version
- Active mode
- Fallback theme usage
- Missing or unused component style keys
- Invalid token references
- Any component variant that resolves through a fallback

---

## Copilot implementation checklist

Before suggesting code, verify:

- [ ] Is the data source JSON payload, not hardcoded styles?
- [ ] Are payload structs separate from resolved runtime types?
- [ ] Is the relevant protocol semantic rather than a mirror of JSON?
- [ ] Are token aliases resolved before rendering?
- [ ] Does the theme support both light and dark mappings?
- [ ] Are component APIs enum-based and free of token strings?
- [ ] Is a last-known-good/bundled fallback retained?
- [ ] Is caching outside SwiftUI views?
- [ ] Does the change preserve Dynamic Type and accessibility?
- [ ] Is there a test or preview for both modes?

---

## Rule of thumb

**JSON names tokens. The resolver builds types. Protocols define usage. The environment publishes resolved styles. Components render semantic contracts.**
