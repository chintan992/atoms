import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_models.dart';

abstract class IWeatherStorage {
  Future<void> saveWeatherData(String key, WeatherData weatherData);
  Future<WeatherData?> getWeatherData(String key);
  Future<void> clearWeatherData(String key);
  Future<void> clearAllWeatherData();
  Future<bool> isWeatherDataExpired(String key, Duration maxAge);
}

class WeatherStorage implements IWeatherStorage {
  static const String _weatherPrefix = 'weather_data_';
  static const String _timestampSuffix = '_timestamp';

  @override
  Future<void> saveWeatherData(String key, WeatherData weatherData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save weather data
    final weatherJson = jsonEncode(weatherData.toJson());
    await prefs.setString(_getWeatherKey(key), weatherJson);

    // Save timestamp
    await prefs.setInt(_getTimestampKey(key), DateTime.now().millisecondsSinceEpoch);
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
    await prefs.remove(_getTimestampKey(key));
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

    final timestamp = prefs.getInt(_getTimestampKey(key));
    if (timestamp == null) {
      return true; // No timestamp means expired
    }

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final age = now.difference(cacheTime);

    return age > maxAge;
  }

  String _getWeatherKey(String key) => '$_weatherPrefix$key';
  String _getTimestampKey(String key) => '$_weatherPrefix$key$_timestampSuffix';
}