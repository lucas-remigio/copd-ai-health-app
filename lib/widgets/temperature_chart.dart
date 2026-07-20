import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A lightweight, dependency-free line chart for a temperature (°C) time series.
///
/// Samples are treated as evenly spaced because the caller polls on a fixed
/// interval. Kept deliberately simple (a single [CustomPainter]) to avoid adding
/// a charting dependency for one graph.
class TemperatureChart extends StatelessWidget {
  const TemperatureChart({super.key, required this.samples, this.height = 160});

  /// Temperature readings in °C, oldest first.
  final List<double> samples;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TemperatureChartPainter(
          samples: samples,
          lineColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.onSurfaceVariant,
          gridColor: theme.dividerColor,
        ),
      ),
    );
  }
}

class _TemperatureChartPainter extends CustomPainter {
  _TemperatureChartPainter({
    required this.samples,
    required this.lineColor,
    required this.labelColor,
    required this.gridColor,
  });

  final List<double> samples;
  final Color lineColor;
  final Color labelColor;
  final Color gridColor;

  static const double _leftPadding = 40;
  static const double _verticalPadding = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    // Pad the value range by 1°C so a nearly-flat series isn't drawn on the edge
    // and the axis never collapses to zero height.
    final low = (samples.reduce(math.min) - 1).floorToDouble();
    final high = (samples.reduce(math.max) + 1).ceilToDouble();
    final range = high - low == 0 ? 1.0 : high - low;

    final chartWidth = size.width - _leftPadding;
    final chartHeight = size.height - _verticalPadding * 2;
    final top = _verticalPadding;

    double xFor(int i) => samples.length == 1
        ? _leftPadding + chartWidth / 2
        : _leftPadding + (i / (samples.length - 1)) * chartWidth;
    double yFor(double value) => top + (1 - (value - low) / range) * chartHeight;

    _drawAxis(canvas, size, top, chartHeight, low, high);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(xFor(0), yFor(samples.first));
    for (var i = 1; i < samples.length; i++) {
      path.lineTo(xFor(i), yFor(samples[i]));
    }
    canvas.drawPath(path, linePaint);

    // Mark the latest reading.
    canvas.drawCircle(
      Offset(xFor(samples.length - 1), yFor(samples.last)),
      3,
      Paint()..color = lineColor,
    );
  }

  void _drawAxis(
    Canvas canvas,
    Size size,
    double top,
    double chartHeight,
    double low,
    double high,
  ) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(_leftPadding, top),
      Offset(size.width, top),
      gridPaint,
    );
    canvas.drawLine(
      Offset(_leftPadding, top + chartHeight),
      Offset(size.width, top + chartHeight),
      gridPaint,
    );

    _drawLabel(canvas, '${high.toStringAsFixed(0)}°', Offset(0, top - 6));
    _drawLabel(
      canvas,
      '${low.toStringAsFixed(0)}°',
      Offset(0, top + chartHeight - 6),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TemperatureChartPainter oldDelegate) {
    final old = oldDelegate.samples;
    if (old.length != samples.length) return true;
    if (samples.isEmpty) return false;
    return old.last != samples.last;
  }
}
