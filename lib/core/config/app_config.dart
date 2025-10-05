import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum TemperatureUnit { celsius, fahrenheit }
enum AppThemeMode { system, light, dark }
enum LogLevel { debug, info, warning, error }

class AppConfig {
  // API Configuration
  static String get weatherApiKey {
    return dotenv.env['WEATHER_API_KEY'] ?? '';
  }

  static String get weatherApiBaseUrl {
    return dotenv.env['WEATHER_API_BASE_URL'] ?? 'https://api.weatherapi.com/v1';
  }

  // App Information
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'Atmos Weather App';
  }

  static String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  static int get appBuildNumber {
    return int.tryParse(dotenv.env['APP_BUILD_NUMBER'] ?? '1') ?? 1;
  }

  // Default Settings
  static TemperatureUnit get defaultTemperatureUnit {
    final unit = dotenv.env['DEFAULT_TEMPERATURE_UNIT'] ?? 'celsius';
    return unit.toLowerCase() == 'fahrenheit'
        ? TemperatureUnit.fahrenheit
        : TemperatureUnit.celsius;
  }

  static int get defaultUpdateIntervalMinutes {
    return int.tryParse(dotenv.env['DEFAULT_UPDATE_INTERVAL_MINUTES'] ?? '30') ?? 30;
  }

  static String get defaultLocation {
    return dotenv.env['DEFAULT_LOCATION'] ?? 'Current Location';
  }

  static double get defaultLocationLat {
    return double.tryParse(dotenv.env['DEFAULT_LOCATION_LAT'] ?? '40.7128') ?? 40.7128;
  }

  static double get defaultLocationLon {
    return double.tryParse(dotenv.env['DEFAULT_LOCATION_LON'] ?? '-74.0060') ?? -74.0060;
  }

  // Weather Update Settings
  static int get weatherCacheDurationMinutes {
    return int.tryParse(dotenv.env['WEATHER_CACHE_DURATION_MINUTES'] ?? '15') ?? 15;
  }

  static int get weatherRequestTimeoutSeconds {
    return int.tryParse(dotenv.env['WEATHER_REQUEST_TIMEOUT_SECONDS'] ?? '10') ?? 10;
  }

  static int get maxForecastDays {
    return int.tryParse(dotenv.env['MAX_FORECAST_DAYS'] ?? '3') ?? 3;
  }

  // Widget Settings
  static int get widgetUpdateIntervalMinutes {
    return int.tryParse(dotenv.env['WIDGET_UPDATE_INTERVAL_MINUTES'] ?? '60') ?? 60;
  }

  static String get widgetDefaultSize {
    return dotenv.env['WIDGET_DEFAULT_SIZE'] ?? '4x2';
  }

  static bool get widgetShowLocation {
    return dotenv.env['WIDGET_SHOW_LOCATION']?.toLowerCase() != 'false';
  }

  static bool get widgetShowCondition {
    return dotenv.env['WIDGET_SHOW_CONDITION']?.toLowerCase() != 'false';
  }

  // UI Settings
  static AppThemeMode get themeMode {
    final mode = dotenv.env['THEME_MODE'] ?? 'system';
    switch (mode.toLowerCase()) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  static int get animationDurationMs {
    return int.tryParse(dotenv.env['ANIMATION_DURATION_MS'] ?? '300') ?? 300;
  }

  static int get chartAnimationDurationMs {
    return int.tryParse(dotenv.env['CHART_ANIMATION_DURATION_MS'] ?? '800') ?? 800;
  }

  // Debug Settings
  static bool get debugMode {
    return dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  }

  static LogLevel get logLevel {
    final level = dotenv.env['LOG_LEVEL'] ?? 'info';
    switch (level.toLowerCase()) {
      case 'debug':
        return LogLevel.debug;
      case 'warning':
        return LogLevel.warning;
      case 'error':
        return LogLevel.error;
      default:
        return LogLevel.info;
    }
  }

  // Validation
  static bool get isValidConfiguration {
    return weatherApiKey.isNotEmpty &&
           weatherApiBaseUrl.isNotEmpty &&
           appName.isNotEmpty;
  }

  // Error Messages
  static String get configurationErrorMessage {
    if (weatherApiKey.isEmpty) {
      return 'WeatherAPI.com API key is missing. Please configure WEATHER_API_KEY in .env file.';
    }
    if (weatherApiBaseUrl.isEmpty) {
      return 'WeatherAPI.com base URL is missing. Please configure WEATHER_API_BASE_URL in .env file.';
    }
    return 'Configuration is valid.';
  }

  static Future<void> initialize() async {
    try {
      if (debugMode) {
        _logConfiguration();
      }

      if (!isValidConfiguration) {
        throw Exception(configurationErrorMessage);
      }
    } catch (e) {
      if (debugMode) {
        debugPrint('AppConfig initialization error: $e');
      }
      rethrow;
    }
  }

  static void _logConfiguration() {
    if (debugMode) {
      debugPrint('=== Atmos App Configuration ===');
      debugPrint('App Name: $appName');
      debugPrint('Version: $appVersion');
      debugPrint('API Key: ${weatherApiKey.substring(0, 8)}...');
      debugPrint('API Base URL: $weatherApiBaseUrl');
      debugPrint('Default Temperature Unit: $defaultTemperatureUnit');
      debugPrint('Default Update Interval: $defaultUpdateIntervalMinutes minutes');
      debugPrint('Debug Mode: $debugMode');
      debugPrint('Log Level: $logLevel');
      debugPrint('===============================');
    }
  }
}