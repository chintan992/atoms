import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ApiClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDioInstance();
    return _instance!;
  }

  static Dio _createDioInstance() {
    final dio = Dio();

    // Base configuration
    dio.options.baseUrl = AppConfig.weatherApiBaseUrl;
    final timeout = Duration(seconds: AppConfig.weatherRequestTimeoutSeconds);
    dio.options.connectTimeout = timeout;
    dio.options.receiveTimeout = timeout;
    dio.options.sendTimeout = timeout;

    // Add API key to all requests and apply defaults when not provided
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.queryParameters['key'] = AppConfig.weatherApiKey;
        // Apply default language if caller hasn't set one
        if (AppConfig.defaultLanguage != null && options.queryParameters['lang'] == null) {
          options.queryParameters['lang'] = AppConfig.defaultLanguage;
        }
        // Apply default AQI/alerts if caller hasn't set them
        if (AppConfig.defaultIncludeAqi && options.queryParameters['aqi'] == null) {
          options.queryParameters['aqi'] = 'yes';
        }
        if (AppConfig.defaultIncludeAlerts && options.queryParameters['alerts'] == null) {
          options.queryParameters['alerts'] = 'yes';
        }
        // Identify client
        options.headers['User-Agent'] = 'AtmosApp/"${AppConfig.appVersion}"';
        handler.next(options);
      },
    ));

    // Simple retry interceptor for transient errors
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        final reqOptions = e.requestOptions;
        final extra = reqOptions.extra;
        final attempt = (extra['retry_attempt'] as int?) ?? 0;
        final canRetryType = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown;
        final status = e.response?.statusCode ?? 0;
        final canRetryStatus = status >= 500 || status == 429;
        if (attempt < 2 && (canRetryType || canRetryStatus)) {
          final backoffFactor = (1 << attempt); // 1, 2
          await Future.delayed(Duration(milliseconds: 300 * backoffFactor));
          reqOptions.extra = Map.of(extra)..['retry_attempt'] = attempt + 1;
          try {
            final response = await dio.fetch(reqOptions);
            return handler.resolve(response);
          } catch (err) {
            // fallthrough to error handling
          }
        }
        _handleError(e);
        handler.next(e);
      },
    ));

    // Logging interceptor for debug mode
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }

    return dio;
  }

  static void _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException(
          'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = _getErrorMessageFromStatusCode(statusCode);
        throw ApiException(
          message,
          code: statusCode.toString(),
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        throw ApiException(
          'Request cancelled.',
          code: 'CANCELLED',
        );

      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          throw ApiException(
            'No internet connection. Please check your network.',
            code: 'NO_INTERNET',
          );
        }
        throw ApiException(
          'An unexpected error occurred. Please try again.',
          code: 'UNKNOWN',
        );

      default:
        throw ApiException(
          'Network error occurred. Please try again.',
          code: 'NETWORK_ERROR',
        );
    }
  }

  static String _getErrorMessageFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please check your API key.';
      case 403:
        return 'Forbidden. Access denied.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  ApiException(this.message, {required this.code, this.statusCode});

  @override
  String toString() => message;
}