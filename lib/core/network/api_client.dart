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
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    // Add API key to all requests
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.queryParameters['key'] = AppConfig.weatherApiKey;
        handler.next(options);
      },
    ));

    // Error handling interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
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