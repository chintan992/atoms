import 'package:flutter_test/flutter_test.dart';
import 'package:atmos/providers/weather_provider.dart';
import 'package:atmos/data/repositories/weather_repository.dart';
import 'package:atmos/data/services/weather_service.dart';
import 'package:atmos/data/models/forecast_models.dart';
import 'package:atmos/data/models/weather_models.dart';

class _FakeRepo implements IWeatherRepository {
  EnhancedWeatherData? nextForecast;
  WeatherData? nextCurrent;

  @override
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {WeatherRequestOptions? opts}) async {
    return nextForecast ??
        EnhancedWeatherData(
          location: const Location(name: 'City', region: '', country: '', lat: 0, lon: 0, tzId: 'UTC', localtimeEpoch: 0, localtime: '2025-01-01 00:00'),
          current: CurrentWeather(
            tempC: 10, tempF: 50, condition: const WeatherCondition(text: 'Cloudy', icon: '', code: 1003),
            windMph: 0, windKph: 0, windDir: 'N', pressureMb: 0, pressureIn: 0, precipMm: 0, precipIn: 0,
            humidity: 0, cloud: 0, feelslikeC: 10, feelslikeF: 50, visKm: 0, visMiles: 0, uv: 0, gustMph: 0, gustKph: 0, isDay: 1,
          ),
          forecast: const Forecast(forecastday: []),
        );
  }

  @override
  Future<EnhancedWeatherData> getWeatherWithForecastByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) => getWeatherWithForecast('$lat,$lon', opts: opts);

  @override
  Future<WeatherData> getCurrentWeather(String location, {WeatherRequestOptions? opts}) async => nextCurrent ??
      WeatherData(
        location: const Location(name: 'City', region: '', country: '', lat: 0, lon: 0, tzId: 'UTC', localtimeEpoch: 0, localtime: '2025-01-01 00:00'),
        current: CurrentWeather(
          tempC: 10, tempF: 50, condition: const WeatherCondition(text: 'Cloudy', icon: '', code: 1003),
          windMph: 0, windKph: 0, windDir: 'N', pressureMb: 0, pressureIn: 0, precipMm: 0, precipIn: 0,
          humidity: 0, cloud: 0, feelslikeC: 10, feelslikeF: 50, visKm: 0, visMiles: 0, uv: 0, gustMph: 0, gustKph: 0, isDay: 1,
        ),
      );

  // Unused
  @override
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) => getCurrentWeather('$lat,$lon', opts: opts);
  @override
  Future<WeatherData?> getCachedWeather(String location) async => null;
  @override
  Future<void> cacheWeather(String location, WeatherData weatherData) async {}
}

void main() {
  test('WeatherProvider loads alerts and updates state', () async {
    final repo = _FakeRepo();
    final provider = WeatherProvider(repository: repo);

    // Start with no alerts
    expect(provider.alerts, isEmpty);

    // Prepare forecast with one alert
    repo.nextForecast = EnhancedWeatherData(
      location: const Location(name: 'City', region: '', country: '', lat: 0, lon: 0, tzId: 'UTC', localtimeEpoch: 0, localtime: '2025-01-01 00:00'),
      current: CurrentWeather(
        tempC: 10, tempF: 50, condition: const WeatherCondition(text: 'Cloudy', icon: '', code: 1003),
        windMph: 0, windKph: 0, windDir: 'N', pressureMb: 0, pressureIn: 0, precipMm: 0, precipIn: 0,
        humidity: 0, cloud: 0, feelslikeC: 10, feelslikeF: 50, visKm: 0, visMiles: 0, uv: 0, gustMph: 0, gustKph: 0, isDay: 1,
      ),
      forecast: const Forecast(forecastday: []),
      alerts: const [WeatherAlert(headline: 'H', event: 'E', severity: 'Severe', areas: 'Area')],
    );

    await provider.loadAlertsForCurrentLocation(days: 1);
    expect(provider.alertsLoading, false);
    expect(provider.alerts, isNotEmpty);
    expect(provider.alerts.first.event, 'E');
  });
}
