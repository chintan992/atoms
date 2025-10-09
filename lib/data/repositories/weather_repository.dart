import '../models/weather_models.dart';
import '../models/forecast_models.dart';
import '../services/weather_service.dart';
import '../storage/weather_storage.dart';

abstract class IWeatherRepository {
  Future<WeatherData> getCurrentWeather(String location, {WeatherRequestOptions? opts});
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon, {WeatherRequestOptions? opts});
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {WeatherRequestOptions? opts});
  Future<EnhancedWeatherData> getWeatherWithForecastByCoordinates(double lat, double lon, {WeatherRequestOptions? opts});
  Future<WeatherData?> getCachedWeather(String location);
  Future<void> cacheWeather(String location, WeatherData weatherData);
}

class WeatherRepository implements IWeatherRepository {
  final IWeatherService _weatherService;
  final IWeatherStorage _weatherStorage;
  static const Duration _cacheMaxAge = Duration(minutes: 30);
  static const Duration _forecastCacheMaxAge = Duration(minutes: 90);

  WeatherRepository(this._weatherService, this._weatherStorage);

  String _coordsKey(double lat, double lon, {int precision = 2}) =>
      '${lat.toStringAsFixed(precision)},${lon.toStringAsFixed(precision)}';

  String _optionsSuffix(WeatherRequestOptions? opts) {
    if (opts == null) return '';
    final parts = <String>[
      'd${opts.days}',
      if (opts.includeAqi) 'aqi',
      if (opts.includeAlerts) 'alrt',
      if (opts.lang != null) 'lng_${opts.lang}',
    ];
    return parts.isEmpty ? '' : '_${parts.join('_')}';
  }

  @override
  Future<WeatherData> getCurrentWeather(String location, {WeatherRequestOptions? opts}) async {
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
final freshData = await _weatherService.getCurrentWeather(location, opts: opts);

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
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) async {
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
final freshData = await _weatherService.getWeatherByCoordinates(lat, lon, opts: opts);

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

  @override
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {WeatherRequestOptions? opts}) async {
    try {
      // Check forecast cache first
      final cacheKey = 'loc_$location${_optionsSuffix(opts)}';
      final cachedJson = await _weatherStorage.getForecastData(cacheKey);
      if (cachedJson != null) {
        final expired = await _weatherStorage.isForecastDataExpired(cacheKey, _forecastCacheMaxAge);
        if (!expired) {
          return EnhancedWeatherData.fromJson(cachedJson);
        } else {
          // SWR: return stale cache and refresh in background
          () async {
            try {
              final fresh = await _weatherService.getWeatherWithForecast(location, opts: opts);
              await _weatherStorage.saveForecastData(cacheKey, fresh.toJson());
            } catch (_) {}
          }();
          return EnhancedWeatherData.fromJson(cachedJson);
        }
      }

      // Fetch both current weather and forecast
      final fresh = await _weatherService.getWeatherWithForecast(location, opts: opts);

      // Cache
      await _weatherStorage.saveForecastData(cacheKey, fresh.toJson());
      return fresh;
    } catch (e) {
      // Fallback to cache
      final cacheKey = 'loc_$location${_optionsSuffix(opts)}';
      final cachedJson = await _weatherStorage.getForecastData(cacheKey);
      if (cachedJson != null) {
        return EnhancedWeatherData.fromJson(cachedJson);
      }
      rethrow;
    }
  }

  @override
  Future<EnhancedWeatherData> getWeatherWithForecastByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) async {
    try {
      final locKey = 'geo_${_coordsKey(lat, lon)}${_optionsSuffix(opts)}';
      final cachedJson = await _weatherStorage.getForecastData(locKey);
      if (cachedJson != null) {
        final expired = await _weatherStorage.isForecastDataExpired(locKey, _forecastCacheMaxAge);
        if (!expired) {
          return EnhancedWeatherData.fromJson(cachedJson);
        } else {
          // SWR
          () async {
            try {
              final fresh = await _weatherService.getWeatherWithForecastByCoordinates(lat, lon, opts: opts);
              await _weatherStorage.saveForecastData(locKey, fresh.toJson());
            } catch (_) {}
          }();
          return EnhancedWeatherData.fromJson(cachedJson);
        }
      }

      final fresh = await _weatherService.getWeatherWithForecastByCoordinates(lat, lon, opts: opts);
      await _weatherStorage.saveForecastData(locKey, fresh.toJson());
      return fresh;
    } catch (e) {
      final locKey = 'geo_${_coordsKey(lat, lon)}${_optionsSuffix(opts)}';
      final cachedJson = await _weatherStorage.getForecastData(locKey);
      if (cachedJson != null) {
        return EnhancedWeatherData.fromJson(cachedJson);
      }
      rethrow;
    }
  }
}