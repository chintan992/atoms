import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/weather_models.dart';
import '../../providers/settings_provider.dart';
import 'glass_container.dart';

class WeatherDetails extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherDetails({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final current = weatherData.current;
        final showAQI = context.read<SettingsProvider>().showAirQuality;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 16),
                child: Text(
                  'Weather Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildDetailCard(
                    context,
                    'Feels Like',
                    settingsProvider.getTemperatureDisplay(
                      current.feelslikeC,
                      current.feelslikeF,
                    ),
                    Icons.thermostat,
                  ),
                  _buildDetailCard(
                    context,
                    'Humidity',
                    '${current.humidity}%',
                    Icons.water_drop,
                  ),
                  _buildDetailCard(
                    context,
                    'Wind Speed',
                    '${current.windKph.round()} km/h',
                    Icons.air,
                  ),
                  _buildDetailCard(
                    context,
                    'Wind Direction',
                    current.windDir,
                    Icons.navigation,
                  ),
                  _buildDetailCard(
                    context,
                    'Pressure',
                    '${current.pressureMb.round()} mb',
                    Icons.speed,
                  ),
                  _buildDetailCard(
                    context,
                    'Visibility',
                    '${current.visKm.round()} km',
                    Icons.visibility,
                  ),
                  _buildDetailCard(
                    context,
                    'UV Index',
                    current.uv.round().toString(),
                    Icons.wb_sunny,
                  ),
                  _buildDetailCard(
                    context,
                    'Cloud Cover',
                    '${current.cloud}%',
                    Icons.cloud,
                  ),
                  if (showAQI && current.airQuality != null)
                    _buildDetailCard(
                      context,
                      'US EPA AQI',
                      (current.airQuality!.usEpaIndex ?? 0).toString(),
                      Icons.health_and_safety,
                    ),
                  if (current.airQuality != null)
                    _buildDetailCard(
                      context,
                      'PM2.5',
                      '${(current.airQuality!.pm2_5 ?? 0).toStringAsFixed(1)} µg/m³',
                      Icons.blur_on,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return GlassDetailCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
