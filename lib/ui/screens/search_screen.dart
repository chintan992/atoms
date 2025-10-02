import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter city name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _searchLocation(value.trim());
                }
              },
            ),
            const SizedBox(height: 16),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searchController.text.trim().isNotEmpty
                    ? () => _searchLocation(_searchController.text.trim())
                    : null,
                child: const Text('Search'),
              ),
            ),
            const SizedBox(height: 24),

            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    final location = _recentSearches[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(location),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _recentSearches.removeAt(index);
                            });
                          },
                        ),
                        onTap: () => _searchLocation(location),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _searchLocation(String location) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
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