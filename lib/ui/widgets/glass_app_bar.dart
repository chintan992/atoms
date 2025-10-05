import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/utils/performance_utils.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final double blur;
  final double opacity;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.blur = 10.0,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive blur based on refresh rate
    final adaptiveBlur = refreshRate > 90 ? blur * 0.8 : blur;

    return RepaintBoundary(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: adaptiveBlur, sigmaY: adaptiveBlur),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: opacity),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: AppBar(
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: centerTitle,
              backgroundColor: Colors.transparent,
              elevation: elevation,
              leading: leading,
              actions: actions,
              iconTheme: IconThemeData(
                color: isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// A glassmorphic floating action button
class GlassFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double blur;
  final double opacity;

  const GlassFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.blur = 10.0,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive blur and shadow based on refresh rate
    final adaptiveBlur = refreshRate > 90 ? blur * 0.8 : blur;
    final adaptiveShadowBlur = refreshRate > 90 ? 15.0 : 20.0;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: adaptiveBlur, sigmaY: adaptiveBlur),
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.white).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: adaptiveShadowBlur,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

