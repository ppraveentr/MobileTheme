[![Platform](http://img.shields.io/badge/platform-ios-blue.svg?style=flat)](https://developer.apple.com/iphone/index.action)
[![Language](http://img.shields.io/badge/language-SwiftUI-brightgreen.svg?style=flat)](https://developer.apple.com/xcode/swiftui)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/ppraveentr/MobileTheme)

[![Build Status](https://github.com/ppraveentr/MobileTheme/actions/workflows/on-push.yml/badge.svg)](https://github.com/ppraveentr/MobileTheme/actions/workflows/on-push.yml)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=ppraveentr_MobileTheme&metric=alert_status)](https://sonarcloud.io/project/overview?id=ppraveentr_MobileTheme)


# MobileTheme

A way to organize and manage style across the application dynamically (dark and light mode).

### Usage
App's styles are defined thorugh a JSON file, which can loaded once app is lanched.

#### Sample - Theme.Json
```json
{
    "version": "1.0",
    "colors": {
        "white": "#FFFFFF",
        "red": "#EE4B2B"
    },
    "fonts": {
        "subHeader": { "weight": "subheadline" }
    },
    "styles": {
        "TextRW": {
            "forgroundColor": {"light": "red", "dark": "white"},
            "font": "subHeader"
        }
    }
}
```

We can load the json file into Manager as:
```swift
   guard let themeModel = try? Data.contentOfFile("Theme.json") else { return }
   try? ThemesManager.setupApplicationTheme(themeModel)
}
```

Use typed style IDs generated from the theme payload:
```swift
    enum ExampleThemeStyles {
        static let textRW = ThemeStyleID("TextRW")
    }

    Toggle("Color Scheme", isOn: $isLightMode)
      .theme(Appearance(.title, dark: .headline))
    Text("Font as 'title' in LightMode and 'headline' in DarkMode")
      .theme(Appearance(.title, dark: .headline))
    Text("'Red' in LightMode and 'White' in DarkMode")
      .style(ExampleThemeStyles.textRW)
}
```

![MobileTheme-Color-Font](https://user-images.githubusercontent.com/15041699/197370343-8bd27dcc-9f04-4b99-afdd-64b0030c08b9.gif)

