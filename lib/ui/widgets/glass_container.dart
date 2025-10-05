import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/utils/performance_utils.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Adaptive blur based on device refresh rate for better performance
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    final adaptiveBlur = refreshRate > 90 ? blur * 0.8 : blur; // Reduce blur on high refresh rate devices
    
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
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
                    ? (color ?? Colors.white).withValues(alpha: opacity)
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
                        blurRadius: refreshRate > 90 ? 15 : 20, // Reduce shadow blur on high refresh rate
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

/// A glass container with preset styles for different purposes
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive blur and opacity based on refresh rate
    final adaptiveBlur = refreshRate > 90 ? 12.0 : 15.0;
    final adaptiveOpacity = refreshRate > 90 
        ? (isDark ? 0.12 : 0.16) 
        : (isDark ? 0.15 : 0.2);

    final container = GlassContainer(
      blur: adaptiveBlur,
      opacity: adaptiveOpacity,
      color: isDark ? Colors.white : Colors.white,
      borderRadius: BorderRadius.circular(24),
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return RepaintBoundary(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: container,
        ),
      );
    }

    return container;
  }
}

/// A smaller glass container for detail items
class GlassDetailCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassDetailCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive blur and opacity for detail cards
    final adaptiveBlur = refreshRate > 90 ? 8.0 : 10.0;
    final adaptiveOpacity = refreshRate > 90 
        ? (isDark ? 0.08 : 0.12) 
        : (isDark ? 0.1 : 0.15);

    return RepaintBoundary(
      child: GlassContainer(
        blur: adaptiveBlur,
        opacity: adaptiveOpacity,
        color: isDark ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        padding: padding ?? const EdgeInsets.all(12),
        margin: margin,
        child: child,
      ),
    );
  }
}

