import '../models/weather_models.dart';
import '../services/weather_service.dart';
import '../storage/weather_storage.dart';

abstract class IWeatherRepository {
  Future<WeatherData> getCurrentWeather(String location);
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon);
  Future<WeatherData?> getCachedWeather(String location);
  Future<void> cacheWeather(String location, WeatherData weatherData);
}

class WeatherRepository implements IWeatherRepository {
  final IWeatherService _weatherService;
  final IWeatherStorage _weatherStorage;
  static const Duration _cacheMaxAge = Duration(minutes: 30);

  WeatherRepository(this._weatherService, this._weatherStorage);

  @override
  Future<WeatherData> getCurrentWeather(String location) async {
    try {
      // Try to get cached data first
      final cachedData = await getCachedWeather(location);
      if (cachedData != null) {
        // Check if cached data is still fresh (within last 30 minutes)
        final isExpired = await _weatherStorage.isWeatherDataExpired(location, _cacheMaxAge);
        if (!isExpired) {
          return cachedData;
        }
      }

      // Fetch fresh data from API
      final freshData = await _weatherService.getCurrentWeather(location);

      // Cache the fresh data
      await cacheWeather(location, freshData);

      return freshData;
    } catch (e) {
      // If API fails, try to return cached data
      final cachedData = await getCachedWeather(location);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  @override
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon) async {
    try {
      // For coordinates, we'll create a simple cache key
      final locationKey = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';

      // Try to get cached data first
      final cachedData = await getCachedWeather(locationKey);
      if (cachedData != null) {
        // Check if cached data is still fresh (within last 30 minutes)
        final isExpired = await _weatherStorage.isWeatherDataExpired(locationKey, _cacheMaxAge);
        if (!isExpired) {
          return cachedData;
        }
      }

      // Fetch fresh data from API
      final freshData = await _weatherService.getWeatherByCoordinates(lat, lon);

      // Cache the fresh data
      await cacheWeather(locationKey, freshData);

      return freshData;
    } catch (e) {
      // If API fails, try to return cached data
      final locationKey = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
      final cachedData = await getCachedWeather(locationKey);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  @override
  Future<WeatherData?> getCachedWeather(String location) async {
    return await _weatherStorage.getWeatherData(location);
  }

  @override
  Future<void> cacheWeather(String location, WeatherData weatherData) async {
    await _weatherStorage.saveWeatherData(location, weatherData);
  }
}