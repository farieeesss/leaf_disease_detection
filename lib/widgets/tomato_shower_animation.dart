import 'dart:math';
import 'package:flutter/material.dart';

class TomatoShowerAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const TomatoShowerAnimation({super.key, required this.onComplete});

  @override
  State<TomatoShowerAnimation> createState() => _TomatoShowerAnimationState();
}

class _TomatoShowerAnimationState extends State<TomatoShowerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<TomatoParticle> _tomatoes;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4500),
      vsync: this,
    );

    // Create tomatoes with staggered delays for continuous shower effect
    _tomatoes = List.generate(35, (index) {
      final normalizedIndex = index / 35;
      return TomatoParticle(
        startX: _random.nextDouble(),
        startY: -0.12 - (_random.nextDouble() * 0.15),
        endY: 1.25 + (_random.nextDouble() * 0.05), // Far beyond screen
        size: 70 + _random.nextDouble() * 30,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 3,
        swayAmount: 0.05 + _random.nextDouble() * 0.1,
        swayFrequency: 1.5 + _random.nextDouble() * 1.5,
        delay: normalizedIndex * 0.2, // Better spread
        duration: 1.0 + _random.nextDouble() * 0.2, // Consistent speed
      );
    });

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _tomatoes.map((tomato) {
            return _buildTomato(tomato);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTomato(TomatoParticle tomato) {
    // Calculate individual progress with delay and duration
    final rawProgress = (_controller.value - tomato.delay) / tomato.duration;
    final progress = rawProgress.clamp(0.0, 1.0);

    if (progress == 0) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Smooth easing curve - accelerate then decelerate
    final easedProgress = _smoothEaseInOut(progress);

    // Vertical position - smooth from start to end
    final verticalPosition = _lerp(tomato.startY, tomato.endY, easedProgress);

    // Horizontal sway - smooth sine wave motion
    final swayProgress = progress * tomato.swayFrequency;
    final sway = sin(swayProgress * pi * 2) * tomato.swayAmount;
    final horizontalPosition = tomato.startX + sway;

    // Smooth rotation
    final rotationProgress = _smoothEaseInOut(progress);
    final rotation =
        tomato.rotation + (rotationProgress * tomato.rotationSpeed * pi * 2);

    // Smooth fade in and fade out - fade only when truly off screen
    double opacity;
    if (progress < 0.08) {
      // Quick fade in
      opacity = progress / 0.08;
    } else if (progress > 0.95) {
      // Fade out only at very end
      opacity = 1.0 - ((progress - 0.95) / 0.05);
    } else {
      opacity = 1.0;
    }

    // Smooth scale animation
    final scaleProgress = sin(progress * pi);
    final scale = 0.7 + (scaleProgress * 0.3);

    // Shadow intensity based on position
    final shadowIntensity = 0.15 + (easedProgress * 0.1);
    final shadowBlur = 10.0 + (easedProgress * 8.0);

    return Positioned(
      left: horizontalPosition * screenWidth - (tomato.size * scale / 2),
      top: verticalPosition * screenHeight - (tomato.size * scale / 2),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: tomato.size,
              height: tomato.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(shadowIntensity * opacity),
                    blurRadius: shadowBlur,
                    spreadRadius: 1,
                    offset: Offset(0, easedProgress * 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/pic/tomato.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Smooth ease in-out curve for natural motion
  double _smoothEaseInOut(double t) {
    if (t < 0.5) {
      return 2 * t * t;
    } else {
      final f = t - 1;
      return 1 - 2 * f * f;
    }
  }

  // Linear interpolation
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

class TomatoParticle {
  final double startX;
  final double startY;
  final double endY;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double swayAmount;
  final double swayFrequency;
  final double delay;
  final double duration;

  TomatoParticle({
    required this.startX,
    required this.startY,
    required this.endY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmount,
    required this.swayFrequency,
    required this.delay,
    required this.duration,
  });
}
