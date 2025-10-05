import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/weather_models.dart';
import '../models/forecast_models.dart';

abstract class IWeatherService {
  Future<WeatherData> getCurrentWeather(String location);
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon);
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {int days = 3});
}

class WeatherService implements IWeatherService {
  final Dio _dio = ApiClient.instance;

  @override
  Future<WeatherData> getCurrentWeather(String location) async {
    try {
      final response = await _dio.get('/current.json', queryParameters: {
        'q': location,
      });

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
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon) async {
    try {
      final response = await _dio.get('/current.json', queryParameters: {
        'q': '$lat,$lon',
      });

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
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {int days = 3}) async {
    try {
      final response = await _dio.get('/forecast.json', queryParameters: {
        'q': location,
        'days': days,
      });

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
}