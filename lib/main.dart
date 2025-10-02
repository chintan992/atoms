import 'package:atmos/core/config/app_config.dart';
import 'package:atmos/providers/settings_provider.dart';
import 'package:atmos/providers/weather_provider.dart';
import 'package:atmos/ui/screens/home_screen.dart';
import 'package:atmos/ui/screens/search_screen.dart';
import 'package:atmos/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize app configuration
  await AppConfig.initialize();

  // Setup widget method channel
  _setupWidgetMethodChannel();

  runApp(const AtmosWeatherApp());
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
    final Map<String, dynamic> args = jsonDecode(call.arguments);
    final String location = args['location'] ?? 'Current Location';

    // Get weather data from the weather provider
    final weatherProvider = WeatherProvider();

    // Fetch current weather for the specified location
    await weatherProvider.loadWeatherData(location: location);

    // Get the current weather data
    final weatherData = weatherProvider.weatherData;

    if (weatherData != null) {
      // Convert weather condition to icon name for Android widget
      final iconName = _getWeatherIconName(weatherData.current.condition.text);

      final temperature = '${weatherData.current.tempF.toInt()}°';

      final weatherDataMap = {
        'temperature': temperature,
        'condition': weatherData.current.condition.text,
        'location': weatherData.location.name,
        'icon': iconName,
        'lastUpdated': DateTime.now().toString(),
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
      };

      return jsonEncode(fallbackData);
    }
  } catch (e) {
    // Return error data instead of throwing exception
    final errorData = {
      'temperature': '--°',
      'condition': 'Error',
      'location': call.arguments['location'] ?? 'Unknown',
      'icon': 'default',
      'lastUpdated': DateTime.now().toString(),
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ).copyWith(
                onSurface: const Color(0xFF000000), // High contrast text
                onSurfaceVariant: const Color(
                  0xFF49454F,
                ), // Better contrast for secondary text
                outline: const Color(
                  0xFF79747E,
                ), // Better contrast for outlines
              ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            foregroundColor: Color(0xFF000000), // Ensure title is high contrast
            backgroundColor: Color(0xFFFFFFFF), // Explicit white background
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(0xFFFFFFFF), // Explicit white background
          ),
          textTheme: ThemeData().textTheme.apply(
            bodyColor: const Color(0xFF000000),
            displayColor: const Color(0xFF000000),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ).copyWith(
                onSurface: const Color(
                  0xFFFFFFFF,
                ), // High contrast text for dark theme
                onSurfaceVariant: const Color(
                  0xFFCAC4D0,
                ), // Better contrast for secondary text in dark theme
                outline: const Color(
                  0xFF938F99,
                ), // Better contrast for outlines in dark theme
              ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            foregroundColor: Color(
              0xFFFFFFFF,
            ), // Ensure title is high contrast in dark theme
            backgroundColor: Color(0xFF1C1B1F), // Explicit dark background
          ),
          cardTheme: CardThemeData(
            elevation: 4,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: const Color(
              0xFF1C1B1F,
            ), // Explicit dark background for cards
          ),
          textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
            bodyColor: const Color(0xFFFFFFFF),
            displayColor: const Color(0xFFFFFFFF),
          ),
        ),
        themeMode: _getThemeMode(AppConfig.themeMode),
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
