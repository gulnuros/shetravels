import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedLoadingSpiralLines extends StatefulWidget {
  final int numberOfLines;
  final double baseRadius;
  final Color color;
  final double strokeWidth;
  final double size;

  const AnimatedLoadingSpiralLines({
    super.key,
    this.numberOfLines = 5,
    this.baseRadius = 10.0,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
    this.size = 100.0, 
  });

  @override
  State<AnimatedLoadingSpiralLines> createState() =>
      _AnimatedLoadingSpiralLinesState();
}

class _AnimatedLoadingSpiralLinesState extends State<AnimatedLoadingSpiralLines>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.numberOfLines,
      (index) => AnimationController(
        duration: Duration(milliseconds: 1000 + (index * 200)),
        vsync: this,
      )..repeat(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(
          _controllers.length,
          (index) => AnimatedBuilder(
            animation: _controllers[index],
            builder:
                (_, __) => Transform.rotate(
                  angle: _controllers[index].value * 2 * pi,
                  child: CustomPaint(
                    painter: SemiCirclePainter(
                      radius: widget.baseRadius * (index + 1),
                      color: widget.color,
                      strokeWidth: widget.strokeWidth,
                    ),
                    size: Size(widget.size, widget.size),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double radius;
  final Color color;
  final double strokeWidth;

  const SemiCirclePainter({
    required this.radius,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, 0, pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant SemiCirclePainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
