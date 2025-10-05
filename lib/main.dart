import 'package:atmos/core/config/app_config.dart';
import 'package:atmos/data/models/forecast_models.dart';
import 'package:atmos/data/models/weather_models.dart';
import 'package:atmos/data/repositories/weather_repository.dart';
import 'package:atmos/data/services/weather_service.dart';
import 'package:atmos/data/storage/weather_storage.dart';
import 'package:atmos/providers/settings_provider.dart';
import 'package:atmos/providers/weather_provider.dart';
import 'package:atmos/ui/screens/home_screen.dart';
import 'package:atmos/ui/screens/search_screen.dart';
import 'package:atmos/ui/screens/settings_screen.dart';
import 'package:atmos/ui/theme/glass_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable high refresh rate support
  await _enableHighRefreshRate();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize app configuration
  await AppConfig.initialize();

  // Setup widget method channel
  _setupWidgetMethodChannel();

  runApp(const AtmosWeatherApp());
}

/// Enable high refresh rate support for smooth animations
Future<void> _enableHighRefreshRate() async {
  try {
    // Enable high refresh rate on supported devices
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Set preferred orientations for better performance
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    // Fallback if high refresh rate is not supported
    debugPrint('High refresh rate not supported: $e');
  }
}

void _setupWidgetMethodChannel() {
  const MethodChannel channel = MethodChannel(
    'com.example.atmos/weather_widget',
  );

  channel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'getWeatherForWidget':
        return _handleGetWeatherForWidget(call);
      default:
        throw PlatformException(
          code: 'Unimplemented',
          message: 'Method ${call.method} not implemented',
        );
    }
  });
}

Future<String> _handleGetWeatherForWidget(MethodCall call) async {
  try {
    final Map<String, dynamic> args = call.arguments is String ? jsonDecode(call.arguments) : call.arguments;
    final String location = args['location'] ?? 'Current Location';

    // Create a weather repository to fetch forecast data
    final weatherRepository = WeatherRepository(WeatherService(), WeatherStorage());

    // Try to fetch enhanced weather data (current + forecast)
    // If that fails, fall back to just current weather
    EnhancedWeatherData? enhancedWeatherData;
    WeatherData? currentWeatherData;

    try {
      enhancedWeatherData = await weatherRepository.getWeatherWithForecast(location, days: 1);
    } catch (e) {
      // If forecast API fails, try to get just current weather
      try {
        currentWeatherData = await weatherRepository.getCurrentWeather(location);
      } catch (fallbackError) {
        // If everything fails, return error data
        final errorData = {
          'temperature': '--°',
          'condition': 'No Data',
          'location': location,
          'icon': 'default',
          'lastUpdated': DateTime.now().toString(),
          'highTemp': '--°',
          'lowTemp': '--°',
          'humidity': '--%',
          'windSpeed': '-- km/h',
        };
        return jsonEncode(errorData);
      }
    }

    // Use enhanced data if available, otherwise use current data
    final weatherDataToUse = enhancedWeatherData ?? 
        (currentWeatherData != null ? 
            EnhancedWeatherData(
              location: currentWeatherData.location,
              current: currentWeatherData.current,
              forecast: null,
            ) : null);

    if (weatherDataToUse != null) {
      // Convert weather condition to icon name for Android widget
      final iconName = _getWeatherIconName(weatherDataToUse.current.condition.text);

      final temperature = '${weatherDataToUse.current.tempF.toInt()}°';

      // Get high/low temperatures - start with fallback values from current weather
      String highTemp = '--°';
      String lowTemp = '--°';

      // Try to get from forecast data if available
      if (weatherDataToUse.forecast?.forecastday.isNotEmpty == true) {
        final forecastDay = weatherDataToUse.forecast!.forecastday[0];
        highTemp = '${forecastDay.maxtempF.toInt()}°';
        lowTemp = '${forecastDay.mintempF.toInt()}°';
      } 
      // If no forecast, check if current weather has min/max temp fields
      else if (weatherDataToUse.current.maxtempF != null && weatherDataToUse.current.mintempF != null) {
        highTemp = '${weatherDataToUse.current.maxtempF!.toInt()}°';
        lowTemp = '${weatherDataToUse.current.mintempF!.toInt()}°';
      }
      // Use current temp as both high and low if no proper values available
      else {
        highTemp = temperature;
        lowTemp = temperature;
      }

      // Use current weather data for humidity and wind speed
      final humidity = '${weatherDataToUse.current.humidity}%';
      final windSpeed = '${weatherDataToUse.current.windKph.toInt()} km/h';

      final weatherDataMap = {
        'temperature': temperature,
        'condition': weatherDataToUse.current.condition.text,
        'location': weatherDataToUse.location.name,
        'icon': iconName,
        'lastUpdated': DateTime.now().toString(),
        'highTemp': highTemp,
        'lowTemp': lowTemp,
        'humidity': humidity,
        'windSpeed': windSpeed,
      };

      return jsonEncode(weatherDataMap);
    } else {
      // Fallback data if no weather available
      final fallbackData = {
        'temperature': '--°',
        'condition': 'No Data',
        'location': location,
        'icon': 'default',
        'lastUpdated': DateTime.now().toString(),
        'highTemp': '--°',
        'lowTemp': '--°',
        'humidity': '--%',
        'windSpeed': '-- km/h',
      };

      return jsonEncode(fallbackData);
    }
  } catch (e) {
    // Return error data instead of throwing exception
    String errorLocation = 'Unknown';
    if (call.arguments is String) {
      try {
        final args = jsonDecode(call.arguments);
        errorLocation = args['location'] ?? 'Unknown';
      } catch (e) {
        errorLocation = 'Unknown';
      }
    } else if (call.arguments is Map<String, dynamic>) {
      errorLocation = call.arguments['location'] ?? 'Unknown';
    }

    final errorData = {
      'temperature': '--°',
      'condition': 'Error',
      'location': errorLocation,
      'icon': 'default',
      'lastUpdated': DateTime.now().toString(),
      'highTemp': '--°',
      'lowTemp': '--°',
      'humidity': '--%',
      'windSpeed': '-- km/h',
    };

    return jsonEncode(errorData);
  }
}

String _getWeatherIconName(String condition) {
  final conditionLower = condition.toLowerCase();

  if (conditionLower.contains('clear') || conditionLower.contains('sunny')) {
    return 'clear-day';
  } else if (conditionLower.contains('cloud')) {
    return 'cloudy';
  } else if (conditionLower.contains('rain')) {
    return 'rain';
  } else if (conditionLower.contains('snow')) {
    return 'snow';
  } else if (conditionLower.contains('thunder')) {
    return 'thunderstorm';
  } else if (conditionLower.contains('partly')) {
    return 'partly-cloudy-day';
  } else {
    return 'default';
  }
}

ThemeMode _getThemeMode(AppThemeMode appThemeMode) {
  switch (appThemeMode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class AtmosWeatherApp extends StatelessWidget {
  const AtmosWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WeatherProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: GlassTheme.lightTheme(),
        darkTheme: GlassTheme.darkTheme(),
        themeMode: _getThemeMode(AppConfig.themeMode),
        // Enable high refresh rate support
        builder: (context, child) {
          return child!;
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/search': (context) => const SearchScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
