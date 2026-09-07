from pathlib import Path

app = Path('lib/cha_time_app.dart')
s = app.read_text()

# 1) Add testable timing helper after weather enum.
needle = "enum ChaSessionPhase { session, empty, closing }\n"
addition = """enum ChaSessionPhase { session, empty, closing }\n\nDuration sendMomentDuration(ChaWeather weather) {\n  switch (weather) {\n    case ChaWeather.clear:\n      return const Duration(milliseconds: 400);\n    case ChaWeather.cloudy:\n      return Duration.zero;\n    case ChaWeather.rain:\n      return const Duration(milliseconds: 700);\n    case ChaWeather.snow:\n      return const Duration(milliseconds: 900);\n  }\n}\n"""
if s.count(needle) != 1:
    raise SystemExit(f'enum insertion target expected once, found {s.count(needle)}')
s = s.replace(needle, addition, 1)

# 2) Attach rain ripple and snow steam pulse to the actual bowl stack.
old_stack = """                                Transform.scale(\n                                  scale: specialBowlScale(_special),\n                                  child: TeaBowlImage(\n                                    sipCount: _visualSips,\n                                    season: _season,\n                                  ),\n                                ),\n"""
new_stack = """                                Transform.scale(\n                                  scale: specialBowlScale(_special),\n                                  child: TeaBowlImage(\n                                    sipCount: _visualSips,\n                                    season: _season,\n                                  ),\n                                ),\n                                if (_reactionNonce > 0 &&\n                                    _weather == ChaWeather.rain)\n                                  Positioned(\n                                    top: 18,\n                                    child: SendRainRipple(\n                                      key: ValueKey('rain-$_reactionNonce'),\n                                    ),\n                                  ),\n                                if (_reactionNonce > 0 &&\n                                    _weather == ChaWeather.snow)\n                                  Positioned(\n                                    bottom: 179,\n                                    child: SendSnowSteamPulse(\n                                      key: ValueKey('snow-$_reactionNonce'),\n                                    ),\n                                  ),\n"""
if s.count(old_stack) != 1:
    raise SystemExit(f'bowl stack target expected once, found {s.count(old_stack)}')
s = s.replace(old_stack, new_stack, 1)

# 3) Replace full-screen send reaction implementation with spec-accurate clear-only wash,
#    plus bowl-local rain ripple and snow steam pulse widgets.
start = s.find('class SendMomentOverlay extends StatefulWidget {')
end = s.find('class PngButton extends StatefulWidget {')
if start == -1 or end == -1 or end <= start:
    raise SystemExit('could not locate SendMomentOverlay block')

replacement = r'''class SendMomentOverlay extends StatefulWidget {
  const SendMomentOverlay({super.key, required this.weather});

  final ChaWeather weather;

  @override
  State<SendMomentOverlay> createState() => _SendMomentOverlayState();
}

class _SendMomentOverlayState extends State<SendMomentOverlay>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.weather == ChaWeather.clear) {
      _controller = AnimationController(
        vsync: this,
        duration: sendMomentDuration(widget.weather),
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
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final eased = Curves.easeOut.transform(controller.value);
          return Opacity(
            opacity: (1 - eased) * .13,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(.45, -.35),
                  radius: 1.05,
                  colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SendRainRipple extends StatefulWidget {
  const SendRainRipple({super.key});

  @override
  State<SendRainRipple> createState() => _SendRainRippleState();
}

class _SendRainRippleState extends State<SendRainRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: sendMomentDuration(ChaWeather.rain),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeOut.transform(_controller.value);
          return CustomPaint(
            size: const Size(108, 34),
            painter: RipplePainter(
              progress: progress,
              opacity: 1 - _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  RipplePainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..color = Color.fromRGBO(112, 139, 145, opacity.clamp(0, 1) * .62);
    final width = 8 + 58 * progress;
    final height = 2.5 + 14 * progress;
    canvas.drawOval(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: width,
        height: height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

class SendSnowSteamPulse extends StatefulWidget {
  const SendSnowSteamPulse({super.key});

  @override
  State<SendSnowSteamPulse> createState() => _SendSnowSteamPulseState();
}

class _SendSnowSteamPulseState extends State<SendSnowSteamPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: sendMomentDuration(ChaWeather.snow),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_controller.value);
          final pulse = sin(pi * t);
          return Opacity(
            opacity: (.72 * pulse).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -24 * pulse),
              child: Transform.scale(
                alignment: Alignment.bottomCenter,
                scale: 1 + .34 * pulse,
                child: SizedBox(
                  width: 78,
                  height: 66,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      _pulseLine(17, 33, .72),
                      _pulseLine(37, 48, .88),
                      _pulseLine(57, 29, .64),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pulseLine(double left, double height, double alpha) {
    return Positioned(
      left: left,
      bottom: 2,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 4.8, sigmaY: 5.2),
        child: Container(
          width: 5.5,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x00FFFFFF),
                Color.fromRGBO(205, 208, 207, alpha),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

'''
s = s[:start] + replacement + s[end:]
app.write_text(s)

# 4) Add timing regression test.
test = Path('test/widget_test.dart')
t = test.read_text()
needle_test = """  test('relationship stages follow the design thresholds', () {\n"""
addition_test = """  test('send-moment weather timings follow the design spec', () {\n    expect(sendMomentDuration(ChaWeather.clear), const Duration(milliseconds: 400));\n    expect(sendMomentDuration(ChaWeather.cloudy), Duration.zero);\n    expect(sendMomentDuration(ChaWeather.rain), const Duration(milliseconds: 700));\n    expect(sendMomentDuration(ChaWeather.snow), const Duration(milliseconds: 900));\n  });\n\n"""
if t.count(needle_test) != 1:
    raise SystemExit(f'test target expected once, found {t.count(needle_test)}')
test.write_text(t.replace(needle_test, addition_test + needle_test, 1))
