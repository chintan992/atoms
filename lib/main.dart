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
import 'package:atmos/ui/screens/alerts_screen.dart';
import 'package:atmos/ui/theme/glass_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable high refresh rate support
  await _enableHighRefreshRate();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize app configuration
  await AppConfig.initialize();
  
  // Store API key in shared preferences for widget access
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('WEATHER_API_KEY', AppConfig.weatherApiKey); // Will be stored as 'flutter.WEATHER_API_KEY'
debugPrint('Stored API key for widgets: ${AppConfig.weatherApiKey.isNotEmpty ? '${AppConfig.weatherApiKey.substring(0, 8)}...' : 'EMPTY'}');

  // Initialize current location if available
  await _initializeCurrentLocation(prefs);

  // Setup widget method channel
  _setupWidgetMethodChannel();

  // Setup current location channel for Android widget configuration
  _setupCurrentLocationChannel();

  runApp(const AtmosWeatherApp());
}

/// Initialize current location and store in shared preferences for widget access
Future<void> _initializeCurrentLocation(SharedPreferences prefs) async {
  try {
    // Ensure location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
debugPrint('Location services are disabled; cannot initialize current location.');
      return;
    }

    // Ensure permission (request if needed)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
debugPrint('Precise location permission not granted; cannot initialize current location.');
      return;
    }

    // Get a high-accuracy (fine) location fix
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );

    // Store coordinates in shared preferences for Android widget
    await prefs.setString('flutter.current_location_lat', position.latitude.toString());
    await prefs.setString('flutter.current_location_lon', position.longitude.toString());

debugPrint('Stored current location (high accuracy): ${position.latitude}, ${position.longitude} (±${position.accuracy}m)');
  } catch (e) {
debugPrint('Failed to get high-accuracy current location for widget: $e');
    // Don't throw error, just continue without current location
  }
}

/// Setup current location channel for Android widget configuration
void _setupCurrentLocationChannel() {
  const channel = MethodChannel('atmos_widget_channel');

  channel.setMethodCallHandler((MethodCall call) async {
    switch (call.method) {
      case 'getCurrentLocation':
        try {
          final prefs = await SharedPreferences.getInstance();

          // Try to get a fresh high-accuracy location first
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
              try {
                final position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 15),
                );
                // Store for future use
                await prefs.setString('flutter.current_location_lat', position.latitude.toString());
                await prefs.setString('flutter.current_location_lon', position.longitude.toString());
                return '${position.latitude},${position.longitude}';
              } catch (e) {
debugPrint('High-accuracy getCurrentPosition failed: $e');
                // fall back to stored coords
              }
            } else {
debugPrint('Location permission denied for precise location.');
            }
          } else {
debugPrint('Location services are disabled.');
          }

          // Fall back to stored coordinates if available
          final lat = prefs.getString('flutter.current_location_lat');
          final lon = prefs.getString('flutter.current_location_lon');
          if (lat != null && lon != null) {
            return '$lat,$lon';
          }
          return null;
        } catch (e) {
          debugPrint('Error getting current location: $e');
          return null;
        }
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method not implemented',
        );
    }
  });
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
    String location = args['location'] ?? 'Current Location';

    // Handle current location request
    if (location == 'CURRENT_LOCATION') {
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('Location services disabled');

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception('Location permission denied');
        }

        // Get a high-accuracy (fine) fix
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );
        location = '${position.latitude},${position.longitude}';

        // Persist for native widget usage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flutter.current_location_lat', position.latitude.toString());
        await prefs.setString('flutter.current_location_lon', position.longitude.toString());
        debugPrint('Using current high-accuracy location: $location (±${position.accuracy}m)');
      } catch (e) {
        debugPrint('Failed to get high-accuracy current location: $e');
        // Fallback to stored coordinates or a default city
        final prefs = await SharedPreferences.getInstance();
        final lat = prefs.getString('flutter.current_location_lat');
        final lon = prefs.getString('flutter.current_location_lon');
        if (lat != null && lon != null) {
          location = '$lat,$lon';
        } else {
          location = 'New York, NY';
        }
      }
    }

    // Create a weather repository to fetch forecast data
    final weatherRepository = WeatherRepository(WeatherService(), WeatherStorage());

    // Try to fetch enhanced weather data (current + forecast)
    // If that fails, fall back to just current weather
    EnhancedWeatherData? enhancedWeatherData;
    WeatherData? currentWeatherData;

    try {
      enhancedWeatherData = await weatherRepository.getWeatherWithForecast(location, opts: WeatherRequestOptions(days: 1));
    } catch (e) {
      // If forecast API fails, try to get just current weather
      try {
        currentWeatherData = await weatherRepository.getCurrentWeather(location);
      } catch (fallbackError) {
        // If everything fails, return error data
        final errorData = {
          'temperature': '--°',
          'condition': 'No Data',
          'location': args['location'] == 'CURRENT_LOCATION' ? 'Current Location' : location,
          'icon': 'default',
          'lastUpdated': DateTime.now().toString(),
          'highTemp': '--°',
          'lowTemp': '--°',
          'humidity': '--%',
          'windSpeed': '-- km/h',
          'feelsLike': '--°',
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
        'feelsLike': '${weatherDataToUse.current.feelslikeC.toInt()}°',
      };

      return jsonEncode(weatherDataMap);
    } else {
      // Fallback data if no weather available
      final fallbackData = {
        'temperature': '--°',
        'condition': 'No Data',
        'location': args['location'] == 'CURRENT_LOCATION' ? 'Current Location' : location,
        'icon': 'default',
        'lastUpdated': DateTime.now().toString(),
        'highTemp': '--°',
        'lowTemp': '--°',
        'humidity': '--%',
        'windSpeed': '-- km/h',
        'feelsLike': '--°',
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
      'location': errorLocation == 'CURRENT_LOCATION' ? 'Current Location' : errorLocation,
      'icon': 'default',
      'lastUpdated': DateTime.now().toString(),
      'highTemp': '--°',
      'lowTemp': '--°',
      'humidity': '--%',
      'windSpeed': '-- km/h',
      'feelsLike': '--°',
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
          '/alerts': (context) => const AlertsScreen(),
        },
      ),
    );
  }
}
