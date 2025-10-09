import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/weather_models.dart';
import '../models/forecast_models.dart';

class WeatherRequestOptions {
  final int days;
  final bool includeAqi;
  final bool includeAlerts;
  final String? lang;
  const WeatherRequestOptions({
    this.days = 3,
    this.includeAqi = false,
    this.includeAlerts = false,
    this.lang,
  });
}

class LocationSuggestion {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;
  final String? url;
  const LocationSuggestion({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
    this.url,
  });
  factory LocationSuggestion.fromJson(Map<String, dynamic> json) => LocationSuggestion(
        name: json['name'] ?? '',
        region: json['region'] ?? '',
        country: json['country'] ?? '',
        lat: (json['lat'] ?? 0).toDouble(),
        lon: (json['lon'] ?? 0).toDouble(),
        url: json['url'],
      );
}

abstract class IWeatherService {
  Future<WeatherData> getCurrentWeather(String location, {WeatherRequestOptions? opts});
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon, {WeatherRequestOptions? opts});
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {WeatherRequestOptions? opts});
  Future<EnhancedWeatherData> getWeatherWithForecastByCoordinates(double lat, double lon, {WeatherRequestOptions? opts});
  Future<List<LocationSuggestion>> searchLocations(String query);
}

class WeatherService implements IWeatherService {
  final Dio _dio = ApiClient.instance;

  Map<String, dynamic> _buildQuery(Object q, WeatherRequestOptions? opts) {
    return {
      'q': q,
      if (opts?.lang != null) 'lang': opts!.lang,
      if (opts?.includeAqi == true) 'aqi': 'yes',
      if (opts?.includeAlerts == true) 'alerts': 'yes',
      if (opts?.days != null) 'days': opts!.days,
    };
  }

  @override
  Future<WeatherData> getCurrentWeather(String location, {WeatherRequestOptions? opts}) async {
    try {
      final response = await _dio.get('/current.json', queryParameters: _buildQuery(location, opts));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to fetch weather data',
          code: response.statusCode.toString(),
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'An unexpected error occurred while fetching weather data',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) async {
    try {
      final response = await _dio.get('/current.json', queryParameters: _buildQuery('$lat,$lon', opts));

      if (response.statusCode == 200) {
        return WeatherData.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to fetch weather data',
          code: response.statusCode.toString(),
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'An unexpected error occurred while fetching weather data',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {WeatherRequestOptions? opts}) async {
    try {
      final response = await _dio.get('/forecast.json', queryParameters: _buildQuery(location, opts));

      if (response.statusCode == 200) {
        return EnhancedWeatherData.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to fetch weather forecast',
          code: response.statusCode.toString(),
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'An unexpected error occurred while fetching weather forecast',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<EnhancedWeatherData> getWeatherWithForecastByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) async {
    try {
      final response = await _dio.get('/forecast.json', queryParameters: _buildQuery('$lat,$lon', opts));
      if (response.statusCode == 200) {
        return EnhancedWeatherData.fromJson(response.data);
      } else {
        throw ApiException(
          'Failed to fetch weather forecast',
          code: response.statusCode.toString(),
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'An unexpected error occurred while fetching weather forecast',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  @override
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    try {
      final response = await _dio.get('/search.json', queryParameters: {'q': query});
      if (response.statusCode == 200) {
        final list = (response.data as List<dynamic>?) ?? [];
        return list.map((e) => LocationSuggestion.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          'Failed to search locations',
          code: response.statusCode.toString(),
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'An unexpected error occurred while searching locations',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }
}
