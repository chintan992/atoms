import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../core/utils/performance_utils.dart';

/// Performance monitor widget for debugging high refresh rate performance
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with TickerProviderStateMixin {
  late AnimationController _fpsController;
  late Animation<double> _fpsAnimation;
  
  double _currentFPS = 0.0;
  double _averageFPS = 0.0;
  DateTime _lastFrameTime = DateTime.now();
  final List<double> _fpsHistory = [];

  @override
  void initState() {
    super.initState();
    
    if (widget.enabled) {
      _fpsController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat();
      
      _fpsAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_fpsController);
      
      _fpsAnimation.addListener(_updateFPS);
      
      // Monitor frame rendering
      SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      _fpsController.dispose();
    }
    super.dispose();
  }

  void _onFrame(Duration timeStamp) {
    if (!widget.enabled) return;
    
    final now = DateTime.now();
    final deltaTime = now.difference(_lastFrameTime).inMicroseconds / 1000000.0;
    
    if (deltaTime > 0) {
      _currentFPS = 1.0 / deltaTime;
      
      // Update FPS history (keep last 60 frames)
      _fpsHistory.add(_currentFPS);
      if (_fpsHistory.length > 60) {
        _fpsHistory.removeAt(0);
      }
      
      // Calculate average FPS
      if (_fpsHistory.isNotEmpty) {
        _averageFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      }
    }
    
    _lastFrameTime = now;
  }

  void _updateFPS() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FPS: ${_currentFPS.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Avg: ${_averageFPS.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Refresh: ${PerformanceUtils.getEstimatedRefreshRate(context).toStringAsFixed(1)}Hz',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                // Performance indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _averageFPS >= 90 
                        ? Colors.green 
                        : _averageFPS >= 60 
                            ? Colors.yellow 
                            : Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// High performance scroll physics for smooth scrolling on high refresh rate devices
class HighPerformanceScrollPhysics extends BouncingScrollPhysics {
  const HighPerformanceScrollPhysics({super.parent});

  @override
  HighPerformanceScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HighPerformanceScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 50.0; // Reduced for smoother scrolling

  @override
  double get maxFlingVelocity => 8000.0; // Increased for high refresh rate

  @override
  double get dragStartDistanceMotionThreshold => 3.0; // Reduced for better responsiveness
}

/// Optimized scroll physics for different refresh rates
class AdaptiveScrollPhysics extends BouncingScrollPhysics {
  final double refreshRate;
  
  const AdaptiveScrollPhysics({
    super.parent,
    required this.refreshRate,
  });

  @override
  AdaptiveScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AdaptiveScrollPhysics(
      parent: buildParent(ancestor),
      refreshRate: refreshRate,
    );
  }

  @override
  double get minFlingVelocity {
    // Adjust based on refresh rate for optimal performance
    return refreshRate > 90 ? 40.0 : 50.0;
  }

  @override
  double get maxFlingVelocity {
    // Higher max velocity for high refresh rate devices
    return refreshRate > 90 ? 10000.0 : 8000.0;
  }

  @override
  double get dragStartDistanceMotionThreshold {
    // More sensitive on high refresh rate devices
    return refreshRate > 90 ? 2.0 : 3.0;
  }
}
