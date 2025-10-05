import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/weather_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    'London',
    'New York',
    'Tokyo',
    'Paris',
    'Sydney',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          title: 'Search Location',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Search field with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter city name...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _searchLocation(value.trim());
                          }
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Search button with glass effect
                GlassContainer(
                  blur: 10,
                  opacity: 0.2,
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.zero,
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _searchController.text.trim().isNotEmpty
                          ? () => _searchLocation(_searchController.text.trim())
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          'Search',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _searchController.text.trim().isNotEmpty
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent searches
                if (_recentSearches.isNotEmpty) ...[
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Recent Searches',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _recentSearches.length,
                      itemBuilder: (context, index) {
                        final location = _recentSearches[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassContainer(
                            blur: 8,
                            opacity: 0.12,
                            borderRadius: BorderRadius.circular(16),
                            padding: EdgeInsets.zero,
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              leading: Icon(
                                Icons.history,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              title: Text(
                                location,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _recentSearches.removeAt(index);
                                  });
                                },
                              ),
                              onTap: () => _searchLocation(location),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchLocation(String location) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          const Center(child: CircularProgressIndicator()),
    );

    try {
      final weatherProvider = context.read<WeatherProvider>();
      await weatherProvider.loadWeatherData(location: location);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Return to home screen with new weather data
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load weather for "$location"'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _searchLocation(location),
            ),
          ),
        );
      }
    }
  }
}
