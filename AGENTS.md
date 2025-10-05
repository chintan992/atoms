# AGENTS.md - Atmos Weather App

## Build/Lint/Test Commands

### Dependencies & Setup
- `flutter pub get` - Install all dependencies
- `flutter pub upgrade` - Upgrade dependencies to latest versions

### Running the App
- `flutter run` - Run on default device
- `flutter run -d <device-id>` - Run on specific device
- `flutter run -d web` - Run on web

### Testing
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file
- `flutter test --coverage` - Run tests with coverage

### Linting & Analysis
- `flutter analyze` - Run static analysis and linting
- `dart format lib/` - Format Dart code
- `dart format --set-exit-if-changed lib/` - Check formatting (CI)

### Building
- `flutter build apk --release` - Build Android APK
- `flutter build appbundle --release` - Build Android App Bundle
- `flutter build ios --release` - Build iOS app
- `flutter build web` - Build for web

## Code Style Guidelines

### Imports
- Use relative imports for local files: `import '../models/weather_models.dart';`
- Use package imports for external dependencies: `import 'package:flutter/material.dart';`
- Group imports: Dart/Flutter first, then external packages, then local imports
- Sort imports alphabetically within groups

### Naming Conventions
- **Classes**: PascalCase (e.g., `WeatherProvider`, `HomeScreen`)
- **Variables/Functions**: camelCase (e.g., `weatherData`, `loadWeatherData()`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `API_BASE_URL`)
- **Enums**: PascalCase (e.g., `WeatherState`)
- **Files**: snake_case (e.g., `weather_provider.dart`)

### Types & Type Safety
- Use strong typing throughout - avoid `dynamic` except when necessary
- Use nullable types (`?`) appropriately for optional values
- Prefer `final` for immutable variables
- Use `const` for compile-time constants

### Error Handling
- Use try-catch blocks with specific exception types when possible
- Provide meaningful error messages to users
- Log errors appropriately (avoid print in production)
- Graceful fallbacks for API failures

### State Management
- Use Provider pattern for state management
- Separate business logic from UI components
- Use ChangeNotifier for reactive updates
- Keep providers focused on specific domains

### Architecture
- **Data Layer**: Models, repositories, services, storage
- **Presentation Layer**: Providers, screens, widgets
- **Core Layer**: Config, network utilities
- Follow clean architecture principles

### Formatting
- Use Dart's standard formatting (dartfmt)
- 2-space indentation
- Line length: follow flutter_lints recommendations
- Consistent brace placement and spacing

### Testing
- Write widget tests for UI components
- Test error states and edge cases
- Use descriptive test names
- Mock external dependencies

### Security
- Never commit API keys or secrets
- Use environment variables for configuration
- Validate user inputs
- Handle sensitive data appropriately