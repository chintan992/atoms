import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/weather_models.dart';
import '../data/models/forecast_models.dart';
import '../data/repositories/weather_repository.dart';
import '../data/services/weather_service.dart';
import '../data/storage/weather_storage.dart';

enum WeatherState { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  WeatherState _state = WeatherState.initial;
  WeatherData? _weatherData;
  String? _errorMessage;
  String _currentLocation = 'Current Location'; // Default location

  // Forecast + alerts state
  EnhancedWeatherData? _forecastData;
  bool _alertsLoading = false;

  final IWeatherRepository _weatherRepository;

  WeatherState get state => _state;
  WeatherData? get weatherData => _weatherData;
  String? get errorMessage => _errorMessage;
  String get currentLocation => _currentLocation;
  EnhancedWeatherData? get forecastData => _forecastData;
  List<WeatherAlert> get alerts => _forecastData?.alerts ?? const [];
  bool get alertsLoading => _alertsLoading;

  WeatherProvider({IWeatherRepository? repository})
      : _weatherRepository = repository ?? WeatherRepository(WeatherService(), WeatherStorage());

  Future<void> loadWeatherData({String? location}) async {
    _state = WeatherState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      if (location != null) {
        _currentLocation = location;
        _weatherData = await _weatherRepository.getCurrentWeather(_currentLocation);
      } else {
        await loadWeatherDataByLocation();
      }
      _state = WeatherState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = WeatherState.error;

      // Try to load cached data if available
      try {
        _weatherData = await _weatherRepository.getCachedWeather(_currentLocation);
        if (_weatherData != null) {
          _errorMessage = 'Using cached data. ${e.toString()}';
        }
      } catch (cacheError) {
        // Keep the original error if cache fails too
      }
    }

    notifyListeners();
  }

  Future<void> loadWeatherDataByLocation() async {
    try {
      final position = await _determinePosition();
      await loadWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      _errorMessage = e.toString();
      _state = WeatherState.error;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> loadWeatherByCoordinates(double lat, double lon) async {
    _state = WeatherState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _weatherData = await _weatherRepository.getWeatherByCoordinates(lat, lon);
      _currentLocation = _weatherData?.location.name ?? 'Current Location';
      _state = WeatherState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = WeatherState.error;
    }

    notifyListeners();
  }

  Future<EnhancedWeatherData?> loadForecastData({String? location, int days = 3, bool includeAqi = false, bool includeAlerts = false, String? lang}) async {
    try {
      final currentLocation = location ?? _currentLocation;
      final opts = WeatherRequestOptions(days: days, includeAqi: includeAqi, includeAlerts: includeAlerts, lang: lang);
      final data = await _weatherRepository.getWeatherWithForecast(currentLocation, opts: opts);
      _forecastData = data;
      if (kDebugMode) {
        debugPrint('Forecast loaded for $currentLocation: days=${data.forecast?.forecastday.length ?? 0}');
      }
      notifyListeners();
      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Forecast load failed: $e');
      }
      // Return null if forecast data fails, don't update UI state
      return null;
    }
  }

  Future<void> loadAlertsForCurrentLocation({int days = 1, String? lang}) async {
    _alertsLoading = true;
    notifyListeners();
    try {
      final opts = WeatherRequestOptions(days: days, includeAlerts: true, lang: lang);
      _forecastData = await _weatherRepository.getWeatherWithForecast(_currentLocation, opts: opts);
    } catch (_) {
      // keep previous alerts if any
    } finally {
      _alertsLoading = false;
      notifyListeners();
    }
  }

  Future<EnhancedWeatherData?> loadForecastByCoordinates(double lat, double lon, {int days = 3, bool includeAqi = false, bool includeAlerts = false, String? lang}) async {
    try {
      final opts = WeatherRequestOptions(days: days, includeAqi: includeAqi, includeAlerts: includeAlerts, lang: lang);
      final data = await _weatherRepository.getWeatherWithForecastByCoordinates(lat, lon, opts: opts);
      _forecastData = data;
      notifyListeners();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshWeather() async {
    await loadWeatherData(location: _currentLocation);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == WeatherState.error && _weatherData != null) {
      _state = WeatherState.loaded;
      notifyListeners();
    }
  }

  void reset() {
    _state = WeatherState.initial;
    _weatherData = null;
    _errorMessage = null;
    _currentLocation = 'Current Location';
    loadWeatherDataByLocation();
    notifyListeners();
  }
}