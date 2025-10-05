import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance utilities for high refresh rate optimization
class PerformanceUtils {
  static bool _isHighRefreshRate = false;
  static double _currentRefreshRate = 60.0;
  
  /// Initialize performance monitoring
  static void initialize(BuildContext context) {
    // Use device pixel ratio and screen size to estimate refresh rate capability
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenSize = MediaQuery.of(context).size;
    final screenArea = screenSize.width * screenSize.height;
    
    // Estimate refresh rate based on device characteristics
    // High-end devices typically have higher pixel ratios and larger screens
    _currentRefreshRate = _estimateRefreshRate(devicePixelRatio, screenArea);
    _isHighRefreshRate = _currentRefreshRate > 90;
    
    // Monitor frame rendering performance
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _monitorFramePerformance(timeStamp);
    });
  }
  
  /// Estimate refresh rate based on device characteristics
  static double _estimateRefreshRate(double devicePixelRatio, double screenArea) {
    // This is a heuristic approach since refreshRate is not available in all Flutter versions
    // High-end devices typically have:
    // - Higher pixel ratios (3.0+)
    // - Larger screens (more pixels to push)
    // - Better GPUs that can handle higher refresh rates
    
    if (devicePixelRatio >= 3.5 && screenArea > 2000000) {
      return 120.0; // Likely 120Hz device
    } else if (devicePixelRatio >= 3.0 && screenArea > 1500000) {
      return 90.0; // Likely 90Hz device
    } else if (devicePixelRatio >= 2.5) {
      return 75.0; // Mid-range device
    } else {
      return 60.0; // Standard 60Hz device
    }
  }
  
  /// Get current refresh rate
  static double get refreshRate => _currentRefreshRate;
  
  /// Check if device supports high refresh rate
  static bool get isHighRefreshRate => _isHighRefreshRate;
  
  /// Get adaptive blur value based on refresh rate
  static double getAdaptiveBlur(double baseBlur) {
    return _isHighRefreshRate ? baseBlur * 0.8 : baseBlur;
  }
  
  /// Get adaptive opacity based on refresh rate
  static double getAdaptiveOpacity(double baseOpacity, bool isDark) {
    if (_isHighRefreshRate) {
      return isDark ? baseOpacity * 0.8 : baseOpacity * 0.8;
    }
    return baseOpacity;
  }
  
  /// Get adaptive animation duration based on refresh rate
  static Duration getAdaptiveDuration(Duration baseDuration) {
    return _isHighRefreshRate 
        ? Duration(milliseconds: (baseDuration.inMilliseconds * 0.8).round())
        : baseDuration;
  }
  
  /// Get adaptive shadow blur radius
  static double getAdaptiveShadowBlur(double baseBlur) {
    return _isHighRefreshRate ? baseBlur * 0.75 : baseBlur;
  }
  
  /// Monitor frame performance for debugging
  static void _monitorFramePerformance(Duration timeStamp) {
    // This can be used for performance monitoring in debug mode
    if (kDebugMode) {
      // Log frame timing if needed for debugging
    }
  }
  
  /// Check if we should reduce visual effects for better performance
  static bool shouldReduceEffects() {
    // Reduce effects on very high refresh rate devices (120Hz+) for better performance
    return _currentRefreshRate >= 120;
  }
  
  /// Get optimal blur sigma for current device
  static double getOptimalBlurSigma(double preferredBlur) {
    if (shouldReduceEffects()) {
      return preferredBlur * 0.6; // Significantly reduce blur on 120Hz+ devices
    } else if (_isHighRefreshRate) {
      return preferredBlur * 0.8; // Slightly reduce blur on 90Hz+ devices
    }
    return preferredBlur;
  }
  
  /// Get optimal shadow blur radius for current device
  static double getOptimalShadowBlur(double preferredBlur) {
    if (shouldReduceEffects()) {
      return preferredBlur * 0.5; // Significantly reduce shadow blur
    } else if (_isHighRefreshRate) {
      return preferredBlur * 0.75; // Slightly reduce shadow blur
    }
    return preferredBlur;
  }
  
  /// Get estimated refresh rate for a given context
  static double getEstimatedRefreshRate(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final screenSize = MediaQuery.of(context).size;
    final screenArea = screenSize.width * screenSize.height;
    return _estimateRefreshRate(devicePixelRatio, screenArea);
  }
}

/// High performance glass container that automatically adapts to device capabilities
class HighPerformanceGlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const HighPerformanceGlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize performance monitoring if not already done
    PerformanceUtils.initialize(context);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adaptiveBlur = PerformanceUtils.getOptimalBlurSigma(blur);
    final adaptiveOpacity = PerformanceUtils.getAdaptiveOpacity(opacity, isDark);
    final adaptiveShadowBlur = PerformanceUtils.getOptimalShadowBlur(20.0);
    
    return RepaintBoundary(
      child: Container(
        width: null,
        height: null,
        margin: margin,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: adaptiveBlur, 
              sigmaY: adaptiveBlur,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: gradient == null
                    ? (color ?? Colors.white).withValues(alpha: adaptiveOpacity)
                    : null,
                gradient: gradient,
                borderRadius: borderRadius ?? BorderRadius.circular(20),
                border: border ??
                    Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                boxShadow: boxShadow ??
                    [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: adaptiveShadowBlur,
                        offset: const Offset(0, 10),
                      ),
                    ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
