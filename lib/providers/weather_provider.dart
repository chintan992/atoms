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

  final WeatherRepository _weatherRepository;

  WeatherState get state => _state;
  WeatherData? get weatherData => _weatherData;
  String? get errorMessage => _errorMessage;
  String get currentLocation => _currentLocation;

  WeatherProvider()
      : _weatherRepository = WeatherRepository(WeatherService(), WeatherStorage());

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

  Future<EnhancedWeatherData?> loadForecastData({String? location, int days = 3}) async {
    try {
      final currentLocation = location ?? _currentLocation;
      return await _weatherRepository.getWeatherWithForecast(currentLocation, days: days);
    } catch (e) {
      // Return null if forecast data fails, don't update UI state
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