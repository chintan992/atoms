import 'package:flutter/material.dart';
import '../../core/utils/performance_utils.dart';

enum WeatherCondition {
  sunny,
  cloudy,
  rainy,
  snowy,
  thunderstorm,
  night,
  partlyCloudy,
  clear,
}

class WeatherBackground extends StatelessWidget {
  final WeatherCondition condition;
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.condition,
    required this.child,
  });

  static WeatherCondition getConditionFromCode(int code, bool isDay) {
    // Weather API condition codes
    if (!isDay) {
      return WeatherCondition.night;
    }

    if (code == 1000) {
      return WeatherCondition.sunny;
    } else if (code >= 1003 && code <= 1009) {
      return WeatherCondition.partlyCloudy;
    } else if (code >= 1030 && code <= 1147) {
      return WeatherCondition.cloudy;
    } else if (code >= 1150 && code <= 1201 || code >= 1240 && code <= 1246) {
      return WeatherCondition.rainy;
    } else if (code >= 1204 && code <= 1237 || code >= 1249 && code <= 1282) {
      return WeatherCondition.snowy;
    } else if (code >= 1273 && code <= 1282) {
      return WeatherCondition.thunderstorm;
    }

    return WeatherCondition.clear;
  }

  static WeatherCondition getConditionFromText(String text, bool isDay) {
    final textLower = text.toLowerCase();

    if (!isDay) {
      return WeatherCondition.night;
    }

    if (textLower.contains('sunny') || textLower.contains('clear')) {
      return WeatherCondition.sunny;
    } else if (textLower.contains('partly cloudy')) {
      return WeatherCondition.partlyCloudy;
    } else if (textLower.contains('cloudy') || textLower.contains('overcast')) {
      return WeatherCondition.cloudy;
    } else if (textLower.contains('rain') || textLower.contains('drizzle')) {
      return WeatherCondition.rainy;
    } else if (textLower.contains('snow') || textLower.contains('sleet')) {
      return WeatherCondition.snowy;
    } else if (textLower.contains('thunder') || textLower.contains('storm')) {
      return WeatherCondition.thunderstorm;
    }

    return WeatherCondition.clear;
  }

  LinearGradient _getGradientForCondition() {
    switch (condition) {
      case WeatherCondition.sunny:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF50C9FF),
            Color(0xFFFFA751),
            Color(0xFFFFE259),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );

      case WeatherCondition.partlyCloudy:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5D9CEC),
            Color(0xFF86B8E8),
            Color(0xFFA8D5F7),
            Color(0xFFCAE8FF),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        );

      case WeatherCondition.cloudy:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF606C88),
            Color(0xFF7E8BA3),
            Color(0xFF9FA8BA),
            Color(0xFFBCC4D1),
          ],
        );

      case WeatherCondition.rainy:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF3D566E),
            Color(0xFF4E6E8C),
            Color(0xFF607D9E),
          ],
        );

      case WeatherCondition.snowy:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF83A4D4),
            Color(0xFFA6BDDB),
            Color(0xFFD4E3F4),
            Color(0xFFE8F4FF),
          ],
        );

      case WeatherCondition.thunderstorm:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF232526),
            Color(0xFF414345),
            Color(0xFF4B4E52),
            Color(0xFF5A5D61),
          ],
        );

      case WeatherCondition.night:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
            Color(0xFF3A6073),
          ],
        );

      case WeatherCondition.clear:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF56CCF2),
            Color(0xFF2F80ED),
            Color(0xFF1E5FC9),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive animation duration based on refresh rate
    final animationDuration = refreshRate > 90 
        ? const Duration(milliseconds: 600)  // Faster on high refresh rate
        : const Duration(milliseconds: 800);
    
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: _getGradientForCondition(),
        ),
        child: child,
      ),
    );
  }
}

/// Weather background with animated particles (optional enhanced version)
class AnimatedWeatherBackground extends StatefulWidget {
  final WeatherCondition condition;
  final Widget child;

  const AnimatedWeatherBackground({
    super.key,
    required this.condition,
    required this.child,
  });

  @override
  State<AnimatedWeatherBackground> createState() =>
      _AnimatedWeatherBackgroundState();
}

class _AnimatedWeatherBackgroundState extends State<AnimatedWeatherBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Default duration
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Now we can safely access MediaQuery
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive animation duration based on refresh rate
    final animationDuration = refreshRate > 90 
        ? const Duration(seconds: 2)  // Faster on high refresh rate
        : const Duration(seconds: 3);
    
    // Update controller duration if it's different
    if (_controller.duration != animationDuration) {
      _controller.duration = animationDuration;
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WeatherBackground(
          condition: widget.condition,
          child: widget.child,
        ),
        // Optional: Add animated particles or effects here
        // This would require additional animation logic
      ],
    );
  }
}

