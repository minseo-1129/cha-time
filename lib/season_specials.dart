import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum SeasonSpecialKind {
  none,
  flowerRain,
  summerShower,
  clearedSky,
  coldRain,
  drySunlight,
  firstSnow,
}

SeasonSpecialKind seasonSpecialFor(String season, String weather) {
  if (season == '봄' && weather == '비') return SeasonSpecialKind.flowerRain;
  if (season == '여름' && weather == '비') {
    return SeasonSpecialKind.summerShower;
  }
  if (season == '장마' && weather == '맑음') {
    return SeasonSpecialKind.clearedSky;
  }
  if (season == '가을' && weather == '비') return SeasonSpecialKind.coldRain;
  if (season == '겨울' && weather == '맑음') {
    return SeasonSpecialKind.drySunlight;
  }
  if (season == '겨울' && weather == '눈') return SeasonSpecialKind.firstSnow;
  return SeasonSpecialKind.none;
}

Color specialPaper(Color base, SeasonSpecialKind special) {
  switch (special) {
    case SeasonSpecialKind.flowerRain:
      return const Color(0xFFF8F5F1);
    case SeasonSpecialKind.summerShower:
      return const Color(0xFFF5F8F2);
    case SeasonSpecialKind.clearedSky:
      return const Color(0xFFF6F8F4);
    case SeasonSpecialKind.coldRain:
      return const Color(0xFFF7F1E7);
    case SeasonSpecialKind.drySunlight:
      return const Color(0xFFF6F6F4);
    case SeasonSpecialKind.firstSnow:
      return const Color(0xFFF4F5F5);
    case SeasonSpecialKind.none:
      return base;
  }
}

double specialSteam(
  double base,
  double weatherMultiplier,
  SeasonSpecialKind special,
) {
  if (special == SeasonSpecialKind.coldRain) return .45;
  return min(.8, base * weatherMultiplier);
}

double specialBowlScale(SeasonSpecialKind special) =>
    special == SeasonSpecialKind.coldRain ? 1.06 : 1.0;

class SeasonWeatherWash extends StatefulWidget {
  const SeasonWeatherWash({
    super.key,
    required this.weather,
    required this.special,
  });

  final String weather;
  final SeasonSpecialKind special;

  @override
  State<SeasonWeatherWash> createState() => _SeasonWeatherWashState();
}

class _SeasonWeatherWashState extends State<SeasonWeatherWash>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.special == SeasonSpecialKind.clearedSky) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..forward();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient();
    final controller = _controller;
    if (controller == null) {
      return IgnorePointer(
        child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      );
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Opacity(
          opacity: Curves.easeOut.transform(controller.value),
          child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        ),
      ),
    );
  }

  Gradient _gradient() {
    if (widget.special == SeasonSpecialKind.drySunlight) {
      return const RadialGradient(
        center: Alignment(-.7, -.9),
        radius: 1.25,
        colors: [Color(0x73E8F0F6), Color(0x00E8F0F6)],
      );
    }
    if (widget.special == SeasonSpecialKind.clearedSky) {
      return const RadialGradient(
        center: Alignment(.45, -.9),
        radius: 1.2,
        colors: [Color(0x8FFFFFFF), Color(0x00FFFFFF)],
      );
    }
    switch (widget.weather) {
      case '흐림':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0x4DCED1CE), Color(0x00CED1CE)],
        );
      case '비':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0x66B2BEC1), Color(0x0DB2BEC1)],
        );
      case '눈':
        return const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xA8FFFFFF), Color(0x14ECF1F6)],
        );
      default:
        return const RadialGradient(
          center: Alignment(.5, -.9),
          radius: 1.25,
          colors: [Color(0x80FFF4D6), Color(0x00FFF4D6)],
        );
    }
  }
}

class SeasonAmbientParticles extends StatefulWidget {
  const SeasonAmbientParticles({
    super.key,
    required this.weather,
    required this.special,
    this.reducedOpacity = false,
  });

  final String weather;
  final SeasonSpecialKind special;
  final bool reducedOpacity;

  @override
  State<SeasonAmbientParticles> createState() => _SeasonAmbientParticlesState();
}

class _SeasonAmbientParticlesState extends State<SeasonAmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _showerTimer;
  bool _showerPassed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration(),
    )..repeat();
    if (widget.special == SeasonSpecialKind.summerShower) {
      _showerTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) setState(() => _showerPassed = true);
      });
    }
  }

  @override
  void dispose() {
    _showerTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Duration _duration() {
    switch (widget.special) {
      case SeasonSpecialKind.flowerRain:
        return const Duration(milliseconds: 10400);
      case SeasonSpecialKind.summerShower:
        return const Duration(milliseconds: 2800);
      case SeasonSpecialKind.firstSnow:
        return const Duration(seconds: 18);
      default:
        return const Duration(seconds: 8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather != '비' && widget.weather != '눈') {
      return const SizedBox.shrink();
    }
    final baseOpacity = widget.reducedOpacity ? .2 : .4;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1500),
        opacity: _showerPassed ? 0 : baseOpacity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: SeasonParticlePainter(
              progress: _controller.value,
              weather: widget.weather,
              special: widget.special,
            ),
          ),
        ),
      ),
    );
  }
}

class SeasonParticlePainter extends CustomPainter {
  SeasonParticlePainter({
    required this.progress,
    required this.weather,
    required this.special,
  });

  final double progress;
  final String weather;
  final SeasonSpecialKind special;

  @override
  void paint(Canvas canvas, Size size) {
    final snow = weather == '눈';
    final count = switch (special) {
      SeasonSpecialKind.flowerRain => 8,
      SeasonSpecialKind.summerShower => 14,
      SeasonSpecialKind.firstSnow => 7,
      _ => snow ? 7 : 8,
    };

    for (var i = 0; i < count; i++) {
      final seed = (i * .137 + .08) % 1;
      var x = size.width * ((seed * 7.3) % 1);
      final y = size.height * ((progress + seed) % 1);

      if (special == SeasonSpecialKind.flowerRain) {
        x += 20 * sin((progress * 2 * pi) + i * .9);
        if (i == 1 || i == 4 || i == 7) {
          _drawPetal(canvas, Offset(x, y), progress + i);
          continue;
        }
      }

      if (snow) {
        final sizeMultiplier = special == SeasonSpecialKind.firstSnow ? 1.5 : 1.0;
        final radius = (2 + (i % 3)) * sizeMultiplier;
        final paint = Paint()..color = const Color(0x99FFFFFF);
        canvas.drawCircle(
          Offset(x + 18 * sin((progress + i) * pi * 2), y),
          radius,
          paint,
        );
      } else {
        final shower = special == SeasonSpecialKind.summerShower;
        final paint = Paint()
          ..strokeWidth = shower ? 1.68 : 1.2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x66829AA4);
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 2, y + 11 + (i % 3) * 3),
          paint,
        );
      }
    }
  }

  void _drawPetal(Canvas canvas, Offset center, double phase) {
    final paint = Paint()..color = const Color(0xB8E3B9BE);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sin(phase * pi) * .55);
    canvas.drawOval(
      const Rect.fromCenter(center: Offset.zero, width: 5.5, height: 9),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SeasonParticlePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.weather != weather ||
      oldDelegate.special != special;
}

class SeasonClosingTrace extends StatelessWidget {
  const SeasonClosingTrace({
    super.key,
    required this.special,
    this.size = 30,
  });

  final SeasonSpecialKind special;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (special == SeasonSpecialKind.firstSnow) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: SnowflakeTracePainter()),
      );
    }
    if (special == SeasonSpecialKind.flowerRain) {
      return SizedBox(
        width: size * 1.4,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(-size * .13, 0),
              child: Transform.rotate(
                angle: -.18,
                child: Image.asset(
                  'assets/images/trace_blossom.png',
                  width: size,
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(size * .13, size * .02),
              child: Transform.rotate(
                angle: .18,
                child: Image.asset(
                  'assets/images/trace_blossom.png',
                  width: size,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Image.asset('assets/images/trace_blossom.png', width: size);
  }
}

class SnowflakeTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) * .42;
    final paint = Paint()
      ..color = const Color(0xFFB8C5CC)
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final end = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawLine(center, end, paint);
      final branchCenter = center + Offset(cos(angle), sin(angle)) * radius * .58;
      for (final sign in const [-1.0, 1.0]) {
        final branchAngle = angle + sign * pi / 5;
        final branchEnd = branchCenter +
            Offset(cos(branchAngle), sin(branchAngle)) * radius * .25;
        canvas.drawLine(branchCenter, branchEnd, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
