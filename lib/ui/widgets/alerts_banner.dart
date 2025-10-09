import 'package:flutter/material.dart';
import '../../data/models/forecast_models.dart';
import 'glass_container.dart';

class AlertsBanner extends StatelessWidget {
  final List<WeatherAlert> alerts;
  final VoidCallback? onTap;
  const AlertsBanner({super.key, required this.alerts, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final first = alerts.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () => Navigator.of(context).pushNamed('/alerts'),
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          blur: 8,
          opacity: 0.15,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.all(12),
          child: Row(
          children: [
            Icon(_iconForSeverity(first.severity), color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    first.event,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    first.headline.isNotEmpty ? first.headline : (first.areas.isNotEmpty ? first.areas : ''),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (alerts.length > 1) ...[
              const SizedBox(width: 8),
              _badge(context, '+${alerts.length - 1}')
            ]
          ],
        ),
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

  Widget _badge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}