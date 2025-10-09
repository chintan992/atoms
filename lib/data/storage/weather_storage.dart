import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_models.dart';

abstract class IWeatherStorage {
  Future<void> saveWeatherData(String key, WeatherData weatherData);
  Future<WeatherData?> getWeatherData(String key);
  Future<void> saveForecastData(String key, Map<String, dynamic> enhancedWeatherJson);
  Future<Map<String, dynamic>?> getForecastData(String key);
  Future<void> clearWeatherData(String key);
  Future<void> clearForecastData(String key);
  Future<void> clearAllWeatherData();
  Future<bool> isWeatherDataExpired(String key, Duration maxAge);
  Future<bool> isForecastDataExpired(String key, Duration maxAge);
}

class WeatherStorage implements IWeatherStorage {
  static const String _weatherPrefix = 'weather_data_';
  static const String _forecastPrefix = 'forecast_data_';
  static const String _timestampSuffix = '_timestamp';

  @override
  Future<void> saveWeatherData(String key, WeatherData weatherData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save weather data
    final weatherJson = jsonEncode(weatherData.toJson());
    await prefs.setString(_getWeatherKey(key), weatherJson);

// Save timestamp
    await prefs.setInt(_getTimestampKey(_getWeatherKey(key)), DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<WeatherData?> getWeatherData(String key) async {
    final prefs = await SharedPreferences.getInstance();

    final weatherJson = prefs.getString(_getWeatherKey(key));
    if (weatherJson == null) {
      return null;
    }

    try {
      final weatherMap = jsonDecode(weatherJson) as Map<String, dynamic>;
      return WeatherData.fromJson(weatherMap);
    } catch (e) {
      // If we can't decode the cached data, remove it
      await clearWeatherData(key);
      return null;
    }
  }

  @override
  Future<void> clearWeatherData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getWeatherKey(key));
    await prefs.remove(_getTimestampKey(_getWeatherKey(key)));
  }

  @override
  Future<void> saveForecastData(String key, Map<String, dynamic> enhancedWeatherJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_getForecastKey(key), jsonEncode(enhancedWeatherJson));
    await prefs.setInt(_getTimestampKey(_getForecastKey(key)), DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<Map<String, dynamic>?> getForecastData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_getForecastKey(key));
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      await clearForecastData(key);
      return null;
    }
  }

  @override
  Future<void> clearForecastData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getForecastKey(key));
    await prefs.remove(_getTimestampKey(_getForecastKey(key)));
  }

  @override
  Future<void> clearAllWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_weatherPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  @override
  Future<bool> isWeatherDataExpired(String key, Duration maxAge) async {
    final prefs = await SharedPreferences.getInstance();

    final timestamp = prefs.getInt(_getTimestampKey(_getWeatherKey(key)));
    if (timestamp == null) {
      return true; // No timestamp means expired
    }

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final age = now.difference(cacheTime);

    return age > maxAge;
  }

  @override
  Future<bool> isForecastDataExpired(String key, Duration maxAge) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_getTimestampKey(_getForecastKey(key)));
    if (timestamp == null) return true;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > maxAge;
  }

  String _getWeatherKey(String key) => '$_weatherPrefix$key';
  String _getForecastKey(String key) => '$_forecastPrefix$key';
  String _getTimestampKey(String key) => '$key$_timestampSuffix';
}
