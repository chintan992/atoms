import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/weather_models.dart';
import '../../providers/settings_provider.dart';
import 'glass_container.dart';

class CurrentWeatherCard extends StatelessWidget {
  final WeatherData weatherData;

  const CurrentWeatherCard({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final current = weatherData.current;
        final location = weatherData.location;
        final showAQI = context.read<SettingsProvider>().showAirQuality;

        return GlassCard(
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${location.region}, ${location.country}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _formatTime(location.localtime),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main temperature and condition
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.9),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            settingsProvider.getTemperatureDisplay(
                              current.tempC,
                              current.tempF,
                            ),
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 72,
                                  color: Colors.white,
                                  height: 1.0,
                                  letterSpacing: -2,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          current.condition.text,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Feels like ${settingsProvider.getTemperatureDisplay(current.feelslikeC, current.feelslikeF)}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Weather icon with glass effect
                  GlassContainer(
                    blur: 8.0,
                    opacity: 0.15,
                    borderRadius: BorderRadius.circular(20),
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(0),
                    child: Icon(
                      _getWeatherIcon(current.condition.code),
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Additional info with glass chips
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
              if (showAQI && current.airQuality != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      context,
                      Icons.health_and_safety,
                      (current.airQuality!.usEpaIndex ?? 0).toString(),
                      'US EPA AQI',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.blur_on,
                      '${(current.airQuality!.pm2_5 ?? 0).toStringAsFixed(1)} µg/m³',
                      'PM2.5',
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      context,
                      Icons.blur_on,
                      '${(current.airQuality!.pm10 ?? 0).toStringAsFixed(1)} µg/m³',
                      'PM10',
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: GlassContainer(
        blur: 8.0,
        opacity: 0.12,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
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
