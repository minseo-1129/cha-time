from pathlib import Path

path = Path('lib/cha_time_app.dart')
s = path.read_text()

old_import = "import 'dart:math';\n"
new_import = "import 'dart:math';\nimport 'dart:ui' as ui;\n"
if old_import not in s:
    raise SystemExit('dart:math import not found')
s = s.replace(old_import, new_import, 1)

old = '''  Widget _steamLine(double left, double height, double phase) {
    final t = (_controller.value + phase) % 1;
    final opacity = sin(pi * t).clamp(0, 1).toDouble();
    return Positioned(
      left: left,
      bottom: 2 + 22 * t,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 4,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FFFFFF), Color(0xB8999088)],
            ),
          ),
        ),
      ),
    );
  }'''

new = '''  Widget _steamLine(double left, double height, double phase) {
    final t = (_controller.value + phase) % 1;
    final opacity = t <= .30 ? t / .30 : (1 - t) / .70;
    final rise = 10 - (40 * t);

    return Positioned(
      left: left,
      bottom: 2,
      child: Opacity(
        opacity: opacity.clamp(0, 1).toDouble(),
        child: Transform.translate(
          offset: Offset(0, rise),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3.4, sigmaY: 3.4),
            child: Container(
              width: 4,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00FFFFFF), Color(0xD9999088)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }'''

if s.count(old) != 1:
    raise SystemExit(f'steam block expected once, found {s.count(old)}')
s = s.replace(old, new, 1)
path.write_text(s)
