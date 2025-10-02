import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/weather_details.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeatherData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atmos Weather'),
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
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
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
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      CurrentWeatherCard(
                        weatherData: weatherProvider.weatherData!,
                      ),
                      WeatherDetails(
                        weatherData: weatherProvider.weatherData!,
                      ),
                    ],
                  ),
                ),
              );
          }
        },
      ),
      floatingActionButton: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          if (weatherProvider.state == WeatherState.loaded) {
            return FloatingActionButton(
              onPressed: () {
                weatherProvider.refreshWeather();
              },
              child: const Icon(Icons.refresh),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}