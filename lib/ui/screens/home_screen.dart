import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../../providers/settings_provider.dart';
import 'package:atmos/core/config/app_config.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/weather_details.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/performance_monitor.dart';
import '../../core/utils/performance_utils.dart';
import '../widgets/alerts_banner.dart';
import '../widgets/forecast_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load weather data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final weather = context.read<WeatherProvider>();
      final settings = context.read<SettingsProvider>();
      final shouldLoadAlerts = settings.showAlerts;
      await weather.loadWeatherData();
      // Trigger forecast load
      weather.loadForecastData(
        days: AppConfig.maxForecastDays,
        includeAlerts: shouldLoadAlerts,
      );
      if (shouldLoadAlerts) {
        // Trigger alerts load in background
        weather.loadAlertsForCurrentLocation(days: 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        // Determine weather condition for background
        WeatherCondition condition = WeatherCondition.clear;
        if (weatherProvider.state == WeatherState.loaded &&
            weatherProvider.weatherData != null) {
          condition = WeatherBackground.getConditionFromCode(
            weatherProvider.weatherData!.current.condition.code,
            weatherProvider.weatherData!.current.isDay == 1,
          );
        }

        return PerformanceMonitor(
          enabled: false, // Hide FPS counter
          child: WeatherBackground(
            condition: condition,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: GlassAppBar(
                title: 'Atmos',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.pushNamed(context, '/search');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: _buildBody(weatherProvider),
              ),
              floatingActionButton: weatherProvider.state == WeatherState.loaded
                  ? GlassFloatingActionButton(
                      onPressed: () {
                        weatherProvider.refreshWeather();
                      },
                      icon: Icons.refresh,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(WeatherProvider weatherProvider) {
    switch (weatherProvider.state) {
      case WeatherState.initial:
      case WeatherState.loading:
        return const LoadingWidget();

      case WeatherState.error:
        return ErrorWidgetDisplay(
          errorMessage: weatherProvider.errorMessage ?? 'Unknown error',
          onRetry: () {
            weatherProvider.refreshWeather();
          },
        );

      case WeatherState.loaded:
        if (weatherProvider.weatherData == null) {
          return const ErrorWidgetDisplay(
            errorMessage: 'No weather data available',
            onRetry: null,
          );
        }

        return RefreshIndicator(
          onRefresh: () => weatherProvider.refreshWeather(),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          color: Colors.white,
          child: SingleChildScrollView(
            physics: AdaptiveScrollPhysics(
              refreshRate: PerformanceUtils.getEstimatedRefreshRate(context),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                CurrentWeatherCard(
                  weatherData: weatherProvider.weatherData!,
                ),
                WeatherDetails(
                  weatherData: weatherProvider.weatherData!,
                ),
                const ForecastSection(),
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    if (!settings.showAlerts) return const SizedBox(height: 8);
                    if (weatherProvider.alertsLoading) return const SizedBox(height: 8);
                    final alerts = weatherProvider.alerts;
                    if (alerts.isEmpty) return const SizedBox(height: 8);
                    return AlertsBanner(alerts: alerts);
                  },
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        );
    }
  }
}