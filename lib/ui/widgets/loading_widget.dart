import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../../core/utils/performance_utils.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Default duration
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Now we can safely access MediaQuery
    final refreshRate = PerformanceUtils.getEstimatedRefreshRate(context);
    
    // Adaptive animation duration based on refresh rate
    final animationDuration = refreshRate > 90 
        ? const Duration(milliseconds: 1200)  // Faster on high refresh rate
        : const Duration(milliseconds: 1500);
    
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
    return Center(
      child: GlassContainer(
        blur: 15,
        opacity: 0.2,
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading weather data...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.3;
                    final opacity = ((_controller.value + delay) % 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
