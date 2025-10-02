import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/weather_models.dart';
import '../../providers/settings_provider.dart';

class WeatherDetails extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherDetails({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final current = weatherData.current;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
