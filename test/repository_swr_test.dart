import 'package:flutter_test/flutter_test.dart';
import 'package:atmos/data/models/forecast_models.dart';
import 'package:atmos/data/models/weather_models.dart';
import 'package:atmos/data/repositories/weather_repository.dart';
import 'package:atmos/data/services/weather_service.dart';
import 'package:atmos/data/storage/weather_storage.dart';

class _FakeWeatherService implements IWeatherService {
  int forecastCalls = 0;
  final EnhancedWeatherData response;
  _FakeWeatherService(this.response);

  @override
  Future<EnhancedWeatherData> getWeatherWithForecast(String location, {WeatherRequestOptions? opts}) async {
    forecastCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return response;
  }

  @override
  Future<EnhancedWeatherData> getWeatherWithForecastByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) async {
    return getWeatherWithForecast('$lat,$lon', opts: opts);
  }

  // Unused in this test
  @override
  Future<WeatherData> getCurrentWeather(String location, {WeatherRequestOptions? opts}) => throw UnimplementedError();
  @override
  Future<WeatherData> getWeatherByCoordinates(double lat, double lon, {WeatherRequestOptions? opts}) => throw UnimplementedError();
  @override
  Future<List<LocationSuggestion>> searchLocations(String query) => throw UnimplementedError();
}

class _FakeStorage implements IWeatherStorage {
  Map<String, String> stringStore = {};
  Map<String, int> intStore = {};
  bool expired = true;

  @override
  Future<void> saveForecastData(String key, Map<String, dynamic> enhancedWeatherJson) async {
    stringStore['forecast_data_$key'] = enhancedWeatherJson.toString();
    intStore['forecast_data_${key}_timestamp'] = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Future<Map<String, dynamic>?> getForecastData(String key) async {
    final str = stringStore['forecast_data_$key'];
    if (str == null) return null;
    // This is a bit hacky: in real code we store JSON; here we just construct minimal structure
    return {
      'location': {'name': 'Cache City','region':'','country':'','lat':0,'lon':0,'tz_id':'UTC','localtime_epoch':0,'localtime':'2025-01-01 00:00'},
      'current': {'temp_c': 1,'temp_f': 34,'condition': {'text': 'Cached', 'icon': '', 'code': 1000},'wind_kph':0,'wind_mph':0,'wind_dir':'N','pressure_mb':0,'pressure_in':0,'precip_mm':0,'precip_in':0,'humidity':0,'cloud':0,'feelslike_c':1,'feelslike_f':34,'vis_km':0,'vis_miles':0,'uv':0,'gust_mph':0,'gust_kph':0,'is_day':1},
      'forecast': {'forecastday': []}
    };
  }

  @override
  Future<bool> isForecastDataExpired(String key, Duration maxAge) async => expired;

  // Unused methods
  @override
  Future<void> clearAllWeatherData() async {}
  @override
  Future<void> clearForecastData(String key) async {}
  @override
  Future<void> clearWeatherData(String key) async {}
  @override
  Future<WeatherData?> getWeatherData(String key) async => null;
  @override
  Future<bool> isWeatherDataExpired(String key, Duration maxAge) async => true;
  @override
  Future<void> saveWeatherData(String key, WeatherData weatherData) async {}
}

void main() {
  test('Repository returns stale forecast immediately and refreshes in background', () async {
    final sample = EnhancedWeatherData(
      location: const Location(name: 'Svc City', region: '', country: '', lat: 0, lon: 0, tzId: 'UTC', localtimeEpoch: 0, localtime: '2025-01-01 00:00'),
      current: CurrentWeather(
        tempC: 2, tempF: 36, condition: const WeatherCondition(text: 'Svc', icon: '', code: 1003),
        windMph: 0, windKph: 0, windDir: 'N', pressureMb: 0, pressureIn: 0, precipMm: 0, precipIn: 0,
        humidity: 0, cloud: 0, feelslikeC: 2, feelslikeF: 36, visKm: 0, visMiles: 0, uv: 0, gustMph: 0, gustKph: 0, isDay: 1,
      ),
      forecast: const Forecast(forecastday: []),
    );

    final fakeService = _FakeWeatherService(sample);
    final fakeStorage = _FakeStorage();

    // Seed cache entry and mark as expired
    await fakeStorage.saveForecastData('loc_Test', {'seed': true});
    fakeStorage.expired = true;

    final repo = WeatherRepository(fakeService, fakeStorage);

    // First call should return cached (stale) data synchronously-ish
    final res = await repo.getWeatherWithForecast('Test');
    expect(res.location.name, 'Cache City');
    // Service should have been scheduled and eventually called
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(fakeService.forecastCalls, greaterThanOrEqualTo(1));
  });
}
