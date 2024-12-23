import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color color1;
  final Color color2;

  const AnimatedBackground({
    super.key,
    required this.child,
    required this.color1,
    required this.color2,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _BackgroundPainter(
                color1: widget.color1,
                color2: widget.color2,
                animation: _controller,
              ),
              child: Container(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final Animation<double> animation;

  _BackgroundPainter({
    required this.color1,
    required this.color2,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color1, color2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) * 0.8;

    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi + animation.value * 2 * math.pi;
      final x = centerX + radius * math.cos(angle) * math.sin(animation.value * math.pi);
      final y = centerY + radius * math.sin(angle) * math.cos(animation.value * math.pi);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
