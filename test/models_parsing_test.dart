import 'package:flutter_test/flutter_test.dart';
import 'package:atmos/data/models/weather_models.dart';
import 'package:atmos/data/models/forecast_models.dart';

void main() {
  group('Models parsing', () {
    test('WeatherData parses with AirQuality when present', () {
      final json = {
        'location': {
          'name': 'Test City',
          'region': 'Test Region',
          'country': 'TC',
          'lat': 1.23,
          'lon': 4.56,
          'tz_id': 'UTC',
          'localtime_epoch': 0,
          'localtime': '2025-01-01 00:00',
        },
        'current': {
          'temp_c': 20.5,
          'temp_f': 68.9,
          'condition': {'text': 'Sunny', 'icon': '//cdn', 'code': 1000},
          'wind_kph': 10,
          'wind_mph': 6,
          'wind_dir': 'N',
          'pressure_mb': 1013,
          'pressure_in': 29.9,
          'precip_mm': 0,
          'precip_in': 0,
          'humidity': 40,
          'cloud': 0,
          'feelslike_c': 21,
          'feelslike_f': 69,
          'vis_km': 10,
          'vis_miles': 6,
          'uv': 5,
          'gust_mph': 8,
          'gust_kph': 12,
          'is_day': 1,
          'air_quality': {
            'co': 1.1,
            'no2': 2.2,
            'o3': 3.3,
            'so2': 4.4,
            'pm2_5': 5.5,
            'pm10': 6.6,
            'us-epa-index': 2,
            'gb-defra-index': 3
          }
        }
      };

      final data = WeatherData.fromJson(json);
      expect(data.location.name, 'Test City');
      expect(data.current.airQuality, isNotNull);
      expect(data.current.airQuality!.pm2_5, 5.5);
      expect(data.current.airQuality!.usEpaIndex, 2);
    });

    test('EnhancedWeatherData parses forecast and alerts', () {
      final json = {
        'location': {
          'name': 'City', 'region': '', 'country': '', 'lat': 0, 'lon': 0, 'tz_id': 'UTC', 'localtime_epoch': 0, 'localtime': '2025-01-01 00:00'
        },
        'current': {
          'temp_c': 10,
          'temp_f': 50,
          'condition': {'text': 'Cloudy', 'icon': '', 'code': 1003},
          'wind_kph': 5,'wind_mph': 3,'wind_dir': 'N',
          'pressure_mb': 1000,'pressure_in': 30,'precip_mm': 0,'precip_in': 0,
          'humidity': 50,'cloud': 50,'feelslike_c': 9,'feelslike_f': 48,
          'vis_km': 10,'vis_miles': 6,'uv': 3,'gust_mph': 4,'gust_kph': 6,'is_day': 1
        },
        'forecast': {
          'forecastday': [
            {
              'date': '2025-01-01', 'date_epoch': 0,
              'astro': {'sunrise': '07:00','sunset': '17:00','moonrise': '','moonset': '','moon_phase': '','moon_illumination': 0},
              'day': {
                'maxtemp_c': 12,'maxtemp_f': 53,'mintemp_c': 6,'mintemp_f': 43,'avgtemp_c': 9,'avgtemp_f': 48,
                'maxwind_mph': 10,'maxwind_kph': 16,'totalprecip_mm': 0,'totalprecip_in': 0,
                'avgvis_km': 10,'avgvis_miles': 6,'avghumidity': 60,
                'daily_will_it_rain': 1,'daily_chance_of_rain': 70,'daily_will_it_snow': 0,'daily_chance_of_snow': 0,
                'uv': 3,
                'condition': {'text': 'Cloudy','icon': '','code': 1003}
              },
              'hour': [
                {
                  'time_epoch': 0, 'time': '2025-01-01 01:00', 'temp_c': 8,'temp_f': 46,'is_day': 0,
                  'condition': {'text': 'Cloudy','icon': '','code': 1003},
                  'wind_mph': 5,'wind_kph': 8,'wind_dir': 'N','pressure_mb': 1000,'pressure_in': 30,
                  'precip_mm': 0,'precip_in': 0,'humidity': 60,'cloud': 80,
                  'feelslike_c': 7,'feelslike_f': 45,'windchill_c': 7,'windchill_f': 45,
                  'heatindex_c': 8,'heatindex_f': 46,'dewpoint_c': 2,'dewpoint_f': 36,
                  'will_it_rain': 1,'chance_of_rain': 60,'will_it_snow': 0,'chance_of_snow': 0,
                  'vis_km': 10,'vis_miles': 6,'uv': 1
                }
              ]
            }
          ]
        },
        'alerts': {
          'alert': [
            {
              'headline': 'Severe Weather Warning',
              'event': 'Wind Warning',
              'severity': 'Severe',
              'areas': 'Coastal',
              'desc': 'High winds expected.',
              'effective': '2025-01-01T00:00:00Z',
              'expires': '2025-01-01T06:00:00Z'
            }
          ]
        }
      };

      final enhanced = EnhancedWeatherData.fromJson(json);
      expect(enhanced.forecast, isNotNull);
      expect(enhanced.forecast!.forecastday, isNotEmpty);
      expect(enhanced.alerts, isNotNull);
      expect(enhanced.alerts!.first.event, contains('Wind Warning'));
    });
  });
}
