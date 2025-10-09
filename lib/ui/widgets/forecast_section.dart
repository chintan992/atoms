import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';
import '../../data/models/forecast_models.dart';
import '../widgets/glass_container.dart';
import '../widgets/mini_charts.dart';

class ForecastSection extends StatelessWidget {
  const ForecastSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherProvider, SettingsProvider>(
      builder: (context, weather, settings, _) {
        final forecast = weather.forecastData?.forecast;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Forecast', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (forecast == null || forecast.forecastday.isEmpty) ...[
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No forecast available yet. Pull to refresh or pick a city from Search.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Hourly section
                Text('Hourly', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: forecast.forecastday.first.hour.length.clamp(0, 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _HourTile(hour: forecast.forecastday.first.hour[i]),
                  ),
                ),
                const SizedBox(height: 8),
                HourlyTempPrecipChart(hours: forecast.forecastday.first.hour),
                const SizedBox(height: 16),
                // Next days
                Text('Next days', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (var d in forecast.forecastday)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DayTile(day: d),
                      ),
                  ],
                )
              ]
            ],
          ),
        );
      },
    );
  }
}

class _HourTile extends StatelessWidget {
  final HourForecast hour;
  const _HourTile({required this.hour});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(hour.time);
    final hh = dt != null ? dt.hour.toString().padLeft(2, '0') : '--';
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70);
    return GlassCard(
      child: SizedBox(
        width: 90,
        child: SizedBox(
          height: 110,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$hh:00', style: textStyle, maxLines: 1, overflow: TextOverflow.clip),
                const SizedBox(height: 6),
                Icon(Icons.thermostat, color: Colors.white, size: 18),
                const SizedBox(height: 4),
                Text(
                  '${hour.tempC.round()}°C',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_drop, size: 14, color: Colors.white70),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '${hour.chanceOfRain}%',
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.air, size: 14, color: Colors.white70),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '${hour.windKph.round()} km/h',
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final ForecastDay day;
  const _DayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                day.date,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            Row(
              children: [
                Icon(Icons.water_drop, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text('${day.dailyChanceOfRain}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                const SizedBox(width: 12),
                Icon(Icons.air, size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text('${day.maxwindKph.round()} km/h', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                const SizedBox(width: 12),
                Text('${day.mintempC.round()}°', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(width: 8),
                Text('${day.maxtempC.round()}°', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
