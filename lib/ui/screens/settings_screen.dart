import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weather_provider.dart';
import 'package:atmos/core/config/app_config.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/weather_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    
    // Determine weather condition for background
    WeatherCondition condition = WeatherCondition.clear;
    if (weatherProvider.state == WeatherState.loaded &&
        weatherProvider.weatherData != null) {
      condition = WeatherBackground.getConditionFromCode(
        weatherProvider.weatherData!.current.condition.code,
        weatherProvider.weatherData!.current.isDay == 1,
      );
    }

    return WeatherBackground(
      condition: condition,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: 'Settings',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              if (settingsProvider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  // Temperature Unit Section
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temperature Unit',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your preferred temperature unit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTemperatureUnitOption(
                                context,
                                'Celsius',
                                '°C',
                                TemperatureUnit.celsius,
                                settingsProvider.temperatureUnit ==
                                    TemperatureUnit.celsius,
                                () => settingsProvider.setTemperatureUnit(
                                  TemperatureUnit.celsius,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTemperatureUnitOption(
                                context,
                                'Fahrenheit',
                                '°F',
                                TemperatureUnit.fahrenheit,
                                settingsProvider.temperatureUnit ==
                                    TemperatureUnit.fahrenheit,
                                () => settingsProvider.setTemperatureUnit(
                                  TemperatureUnit.fahrenheit,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // About Section
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAboutItem(
                          context,
                          Icons.info_outline,
                          'Version',
                          '1.0.0',
                        ),
                        const SizedBox(height: 12),
                        _buildAboutItem(
                          context,
                          Icons.api,
                          'Weather API',
                          'WeatherAPI.com',
                        ),
                        const SizedBox(height: 12),
                        _buildAboutItem(
                          context,
                          Icons.palette_outlined,
                          'Design',
                          'Glassmorphism',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureUnitOption(
    BuildContext context,
    String title,
    String symbol,
    TemperatureUnit unit,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              symbol,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
