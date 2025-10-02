import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/weather_models.dart';
import '../../providers/settings_provider.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weatherData;

  const CurrentWeatherCard({
    super.key,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final current = weatherData.current;
        final location = weatherData.location;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location and time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${location.region}, ${location.country}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(location.localtime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main temperature and condition
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settingsProvider.getTemperatureDisplay(
                              current.tempC,
                              current.tempF,
                            ),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            current.condition.text,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Feels like ${settingsProvider.getTemperatureDisplay(current.feelslikeC, current.feelslikeF)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Weather icon placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getWeatherIcon(current.condition.code),
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Additional info
                Row(
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.water_drop,
                      '${current.humidity}%',
                      'Humidity',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.air,
                      '${current.windKph.round()} km/h',
                      'Wind',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.visibility,
                      '${current.visKm.round()} km',
                      'Visibility',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String localtime) {
    try {
      final dateTime = DateTime.parse(localtime);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  IconData _getWeatherIcon(int conditionCode) {
    // Simple weather icon mapping based on condition code
    if (conditionCode >= 1000 && conditionCode < 1100) {
      return Icons.wb_sunny; // Sunny/Clear
    } else if (conditionCode >= 1100 && conditionCode < 1200) {
      return Icons.wb_cloudy; // Partly cloudy
    } else if (conditionCode >= 1200 && conditionCode < 1300) {
      return Icons.cloud; // Cloudy/Overcast
    } else if (conditionCode >= 1300 && conditionCode < 1400) {
      return Icons.ac_unit; // Snow
    } else if (conditionCode >= 1400 && conditionCode < 2000) {
      return Icons.thunderstorm; // Thunderstorms
    } else {
      return Icons.wb_sunny; // Default to sunny
    }
  }
}