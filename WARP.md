# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Atmos** is a Flutter-based weather application with glassmorphism UI design. It provides current weather conditions, forecasts, and Android home screen widgets using the WeatherAPI.com service.

**App Name**: `atmos` (package name) / "Atmos Weather App" (display name)
**Key Dependencies**: Flutter SDK 3.9.0+, Provider (state management), Dio (HTTP), Geolocator (location)

## Essential Development Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Upgrade dependencies  
flutter pub upgrade

# Check Flutter installation
flutter doctor
```

### Running the App
```bash
# Run on default device
flutter run

# Run on specific device (list devices with: flutter devices)
flutter run -d <device-id>

# Run on web (if supported)
flutter run -d web

# Run in release mode for performance testing
flutter run --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality & Analysis
```bash
# Run static analysis and linting (uses flutter_lints)
flutter analyze

# Format Dart code
dart format lib/

# Check formatting without changes (useful for CI)
dart format --set-exit-if-changed lib/
```

### Building for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (requires macOS and Xcode)
flutter build ios --release

# Web
flutter build web
```

### Environment Setup
1. Copy `Template-env.md` content to `.env` file
2. Get API key from WeatherAPI.com and update `WEATHER_API_KEY` in `.env`
3. The `.env` file is automatically loaded at app startup

## Architecture Overview

### Clean Architecture Pattern
The app follows clean architecture with clear separation of concerns:

**Core Layer** (`lib/core/`)
- `config/app_config.dart`: Centralized configuration management using environment variables
- `network/api_client.dart`: Dio-based HTTP client with interceptors
- `utils/`: Utility classes (performance monitoring, etc.)

**Data Layer** (`lib/data/`)
- `models/`: Weather data models (WeatherData, EnhancedWeatherData, Forecast)
- `services/weather_service.dart`: API communication layer
- `repositories/weather_repository.dart`: Data access abstraction with caching
- `storage/weather_storage.dart`: Local storage using SharedPreferences

**Presentation Layer** (`lib/providers/` & `lib/ui/`)
- `providers/`: Provider-based state management (WeatherProvider, SettingsProvider)
- `ui/screens/`: Main app screens (HomeScreen, SearchScreen, SettingsScreen)
- `ui/widgets/`: Reusable UI components with glassmorphism design
- `ui/theme/glass_theme.dart`: Custom glassmorphism theme implementation

### State Management
- **Provider Pattern**: Using ChangeNotifier for reactive state management
- **WeatherProvider**: Handles weather data loading, error states, location management
- **SettingsProvider**: Manages user preferences and app settings
- **Repository Pattern**: Abstracts data sources with caching and offline support

### Key Features
- **Glassmorphism UI**: Custom theme with transparent, blurred glass-like elements
- **Android Widgets**: Native Android home screen widgets via MethodChannel
- **Location Services**: Automatic current location detection with permissions handling
- **Caching Strategy**: 30-minute cache duration for weather data with fallback support
- **Environment Configuration**: Extensive .env-based configuration system

### Android Widget Integration
- Uses MethodChannel (`com.example.atmos/weather_widget`) for Flutter-Android communication
- Kotlin widget provider in `android/app/src/main/kotlin/`
- Widget data synchronization through SharedPreferences

### Error Handling Strategy
- Graceful fallbacks to cached data when API calls fail
- Comprehensive error states in providers with user-friendly messages
- Location permission handling with clear error messages
- API exception handling with specific error codes

### Performance Considerations
- High refresh rate support enabled
- Glassmorphism effects optimized for smooth animations
- Background weather updates for widgets
- Efficient caching to minimize API calls

## Important Configuration

### API Configuration
- **Service**: WeatherAPI.com
- **Endpoints**: `/current.json`, `/forecast.json`, `/search.json`  
- **Rate Limiting**: Consider API quotas when testing
- **Environment Variables**: All API settings configurable via `.env`

### Build Configurations
- **Analysis Options**: Uses `flutter_lints` for code quality
- **Platforms**: Android, iOS, Web (Linux/macOS/Windows directories present)
- **Min SDK**: Flutter 3.9.0+ (specified in pubspec.yaml)

### Development Notes
- App supports both light and dark themes (glassmorphism variants)
- Location permissions required for current weather
- Widget updates happen in background via WorkManager
- Debug logging can be enabled via `DEBUG_MODE=true` in `.env`

## Testing Strategy
- Widget tests for UI components
- Repository tests for data layer logic  
- Provider tests for state management
- Mock external dependencies (API, storage)
- Focus on error states and edge cases

## File Structure Patterns
- **Barrel Exports**: Not used - prefer explicit imports
- **Naming**: snake_case for files, PascalCase for classes, camelCase for variables
- **Organization**: Feature-based organization within clean architecture layers
- **imports**: Group by Dart/Flutter, external packages, then local imports

## Build/Release Notes
- Uses standard Flutter build process
- Environment variables must be properly configured
- Android widgets require additional Kotlin code compilation
- Release builds remove debug logging automatically