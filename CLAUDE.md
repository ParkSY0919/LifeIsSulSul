# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LifeIsSulSul is a native iOS application built with SwiftUI targeting iOS 18.0+. The project uses modern Xcode project structure with Swift 6.0 and SwiftUI for UI development.

## Project Structure

```
LifeIsSulSul/
├── LifeIsSulSul/
│   ├── LifeIsSulSul.xcodeproj/     # Xcode project configuration
│   └── LifeIsSulSul/               # Main source directory
│       ├── LifeIsSulSulApp.swift   # App entry point
│       ├── ContentView.swift       # Main content view
│       ├── Assets.xcassets/        # App icons and image resources
│       └── Preview Content/        # SwiftUI preview assets
└── README.md
```

## Development Commands

### Building the Project
```bash
# Build for simulator (from project root)
cd LifeIsSulSul
xcodebuild -project LifeIsSulSul.xcodeproj -scheme LifeIsSulSul -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device
xcodebuild -project LifeIsSulSul.xcodeproj -scheme LifeIsSulSul -destination generic/platform=iOS build
```

### Running the App
```bash
# Open in Xcode for development
open LifeIsSulSul/LifeIsSulSul.xcodeproj

# Run on simulator via command line
cd LifeIsSulSul
xcodebuild -project LifeIsSulSul.xcodeproj -scheme LifeIsSulSul -destination 'platform=iOS Simulator,name=iPhone 15' run
```

### Testing
```bash
# Run tests via command line (from LifeIsSulSul directory)
xcodebuild test -project LifeIsSulSul.xcodeproj -scheme LifeIsSulSul -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Technical Specifications

- **Platform**: iOS 18.0+ (supports iPhone only, portrait orientation)
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI with iOS 18.1 deployment target
- **Architecture**: Standard SwiftUI app structure
- **Bundle ID**: com.psy.LifeIsSulSul
- **Development Team**: A95XXD5WT7

## Key Configuration Details

- Uses automatic code signing
- SwiftUI previews enabled
- App supports portrait orientation only on iPhone
- No Mac Catalyst, Mac Designed for iPhone/iPad, or XR support
- File system synchronized groups for modern Xcode project management
- Asset catalog includes app icons and beverage-themed images (beer, soju, somek)

## Working with the Codebase

- Main app logic is in `LifeIsSulSul/LifeIsSulSul/LifeIsSulSulApp.swift`
- UI components start with `ContentView.swift`
- Assets are managed through `Assets.xcassets`
- The project uses modern Xcode 16.1 features and Swift 6.0 syntax
- All source files are within the nested `LifeIsSulSul/LifeIsSulSul/` directory structure

## Development Notes

- The app appears to be in early development stages with a basic "Hello World" style implementation
- Current content shows "for Test Gemini code review" text, suggesting it's being used for testing purposes
- Images in assets suggest the app may be related to alcoholic beverages (beer, soju, somek)

## Swift 6 Concurrency Compliance

This project has been updated to fully comply with Swift 6 strict concurrency requirements:

### MainActor Isolation
- All ViewModels (`MainViewModel`, `OnboardingViewModel`, `RecordViewModel`) are properly annotated with `@MainActor`
- UI-related operations are guaranteed to run on the main thread
- Timer and async operations use proper MainActor isolation

### Sendable Protocol Compliance
- All data models (`DrinkRecord`, `HourlyRecord`, `DrinkType`, `CurrentHourlyPace`) implement `Sendable`
- Enums (`AppState`, `SortOrder`) are marked as `Sendable`
- Services (`DrinkRecordServiceProtocol`) extend `Sendable`

### Async/Await Usage
- Replaced `DispatchQueue.main.asyncAfter` with `Task.sleep(for:)`
- Timer closures use `[weak self]` and `Task { @MainActor }` for safe cross-actor access
- UIApplication access updated to use `connectedScenes` instead of deprecated `windows`

### Memory Safety
- All Timer references use weak self references to prevent retain cycles
- Task-based async operations properly handle actor isolation
- No data races or cross-actor reference warnings