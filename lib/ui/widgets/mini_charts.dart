import 'package:flutter/material.dart';
import '../../data/models/forecast_models.dart';

class HourlyTempPrecipChart extends StatelessWidget {
  final List<HourForecast> hours;
  final int maxHours;
  const HourlyTempPrecipChart({super.key, required this.hours, this.maxHours = 12});

  @override
  Widget build(BuildContext context) {
    final slice = hours.take(maxHours).toList();
    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _HourlyChartPainter(slice, Theme.of(context).colorScheme),
        child: Container(),
      ),
    );
  }
}

class _HourlyChartPainter extends CustomPainter {
  final List<HourForecast> hours;
  final ColorScheme colors;
  _HourlyChartPainter(this.hours, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (hours.isEmpty) return;
    final padding = 12.0;
    final chartRect = Rect.fromLTWH(padding, padding, size.width - 2 * padding, size.height - 2 * padding);

    // Background grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartRect.top + chartRect.height * (i / 4);
      canvas.drawLine(Offset(chartRect.left, y), Offset(chartRect.right, y), gridPaint);
    }

    // Compute ranges
    final temps = hours.map((h) => h.tempC).toList();
    final minT = temps.reduce((a, b) => a < b ? a : b);
    final maxT = temps.reduce((a, b) => a > b ? a : b);
    final tRange = (maxT - minT).abs() < 0.001 ? 1.0 : (maxT - minT);

    // X step
    final count = hours.length;
    final stepX = chartRect.width / (count - 1).clamp(1, double.infinity);

    // Precip bars (chanceOfRain)
    final barWidth = (chartRect.width / count) * 0.6;
    final barPaint = Paint()..color = Colors.blueAccent.withValues(alpha: 0.35);
    for (int i = 0; i < count; i++) {
      final h = hours[i];
      final chance = (h.chanceOfRain.clamp(0, 100)) / 100.0;
      final x = chartRect.left + i * stepX;
      final barLeft = x - barWidth / 2;
      final barTop = chartRect.bottom - chartRect.height * chance;
      final rect = Rect.fromLTWH(barLeft, barTop, barWidth, chartRect.bottom - barTop);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), barPaint);
    }

    // Temperature line
    final linePath = Path();
    for (int i = 0; i < count; i++) {
      final t = (hours[i].tempC - minT) / tRange;
      final x = chartRect.left + i * stepX;
      final y = chartRect.bottom - t * chartRect.height;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Points
    final pointPaint = Paint()..color = Colors.orangeAccent.withValues(alpha: 0.9);
    for (int i = 0; i < count; i++) {
      final t = (hours[i].tempC - minT) / tRange;
      final x = chartRect.left + i * stepX;
      final y = chartRect.bottom - t * chartRect.height;
      canvas.drawCircle(Offset(x, y), 2.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter oldDelegate) {
    return oldDelegate.hours != hours;
  }
}