import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/weather_provider.dart';
import '../../data/models/forecast_models.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/weather_background.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeatherProvider>();
    final alerts = provider.alerts;

    // Determine background condition using current weather if available
    WeatherCondition condition = WeatherCondition.clear;
    if (provider.state == WeatherState.loaded && provider.weatherData != null) {
      condition = WeatherBackground.getConditionFromCode(
        provider.weatherData!.current.condition.code,
        provider.weatherData!.current.isDay == 1,
      );
    }

    return WeatherBackground(
      condition: condition,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          title: 'Weather Alerts',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: alerts.isEmpty
              ? const Center(
                  child: Text('No active alerts', style: TextStyle(color: Colors.white)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, i) => _AlertCard(alert: alerts[i]),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final WeatherAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForSeverity(alert.severity), color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.event,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (alert.headline.isNotEmpty)
              Text(
                alert.headline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            if (alert.areas.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Areas: ${alert.areas}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
            const SizedBox(height: 6),
            if (alert.description != null && alert.description!.isNotEmpty)
              Text(
                alert.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (alert.effective != null)
                  _Chip(text: 'Effective: ${_fmt(alert.effective!)}'),
                const SizedBox(width: 8),
                if (alert.expires != null)
                  _Chip(text: 'Expires: ${_fmt(alert.expires!)}'),
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _iconForSeverity(String severity) {
    final s = severity.toLowerCase();
    if (s.contains('severe') || s.contains('warning')) return Icons.warning_amber_rounded;
    if (s.contains('watch')) return Icons.visibility_rounded;
    if (s.contains('advisory')) return Icons.info_rounded;
    return Icons.notifications_active_rounded;
  }

  String _fmt(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
    );
  }
}
