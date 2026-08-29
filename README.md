[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat)](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-SwiftUI-brightgreen.svg?style=flat)](https://developer.apple.com/xcode/swiftui)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/ppraveentr/MobileTheme)

[![Build Status](https://github.com/ppraveentr/MobileTheme/actions/workflows/on-push.yml/badge.svg)](https://github.com/ppraveentr/MobileTheme/actions/workflows/on-push.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=ppraveentr_MobileTheme&metric=alert_status)](https://sonarcloud.io/project/overview?id=ppraveentr_MobileTheme)


# MobileTheme

A way to organize and manage style across the application dynamically (dark and light mode).

### Usage
App styles are defined through a JSON theme file and loaded once at launch.

#### Sample - Theme.json
```json
{
    "schemaVersion": 1,
    "themeId": "example-default",
    "palettes": {
        "light": { "neutral": { "0": "#FFFFFF", "900": "#000000" } },
        "dark": { "neutral": { "0": "#FFFFFF", "900": "#121212" } }
    },
    "semantic": {
        "light": { "textNeutral": "{palette.neutral.900}", "borderSuccess": "#44CC77" },
        "dark": { "textNeutral": "{palette.neutral.0}", "borderSuccess": "#309053" }
    },
    "fonts": {
        "title": { "styleName": "title" }
    },
    "borders": {
        "cardSuccess": { "color": "borderSuccess", "radius": [10, 10, 10, 10], "thickness": 2 }
    },
    "backgrounds": {
        "cardSelected": { "color": "textNeutral", "ignoringSafeArea": false }
    },
    "styles": {
        "Label": {
            "Base": { "font": "title" },
            "Primary": { "font": "title", "background": "cardSelected", "border": "cardSuccess" }
        }
    }
}
```

Load theme into the manager:
```swift
let themeData = try Data(contentsOf: themeURL)
try await ThemesManager.setupApplicationTheme(themeData)
```

Generate module/brand-scoped APIs:
```swift
struct AccountSemanticColors: SemanticColorSet {
    @ColorValue(module: AccountThemeProvider.self, "text.primary")
    var textPrimary: ColorID
}

enum AccountSemanticStyle {
    @StyleValue(module: AccountThemeProvider.self, "Label.Primary")
    static var labelPrimary: StyleSelection<AccountSemanticColors>
}

struct AccountThemeProvider: ThemeModuleProviding {
    static let namespace = "account"
    let themeData: Data
}
```
Namespaced module registration is additive for styles: existing namespaced style IDs are not overridden.

Use generated semantic style APIs:
```swift
Text("Primary")
    .style(ExampleTheme.SemanticStyle.labelPrimary.textNeutral)

Text("Base")
    .style(ExampleTheme.SemanticStyle.labelBase)
```

![MobileTheme-Color-Font](https://user-images.githubusercontent.com/15041699/197370343-8bd27dcc-9f04-4b99-afdd-64b0030c08b9.gif)

### Architecture
- See [ARCHITECTURE.md](ARCHITECTURE.md) for model, resolution pipeline, caching, and module namespacing details.

### TODO (Enterprise Scale)
- Add build-time theme validation (missing refs, cycles, deprecated tokens).
- Generate typed theme APIs per module/brand to avoid monolithic constants.
- Support incremental/lazy loading of module theme payloads.
- Add optional precompiled theme artifacts for faster startup.
- Evolve cache strategy (bounded cache size and scoped invalidation).
- Introduce token governance (versioning, deprecation, migration tooling).
