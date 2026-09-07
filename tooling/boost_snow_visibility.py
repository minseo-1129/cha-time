from pathlib import Path

path = Path('lib/season_specials.dart')
s = path.read_text()

old_opacity = """    final baseOpacity = widget.reducedOpacity ? .2 : .4;
"""
new_opacity = """    final baseOpacity = widget.weather == '눈'
        ? (widget.reducedOpacity ? .28 : .55)
        : (widget.reducedOpacity ? .2 : .4);
"""
if s.count(old_opacity) != 1:
    raise SystemExit(f'base opacity target expected once, found {s.count(old_opacity)}')
s = s.replace(old_opacity, new_opacity, 1)

old_count = """      SeasonSpecialKind.firstSnow => 7,
      _ => snow ? 7 : 8,
"""
new_count = """      SeasonSpecialKind.firstSnow => 15,
      _ => snow ? 10 : 8,
"""
if s.count(old_count) != 1:
    raise SystemExit(f'snow count target expected once, found {s.count(old_count)}')
s = s.replace(old_count, new_count, 1)

old_snow = """      if (snow) {
        final sizeMultiplier = special == SeasonSpecialKind.firstSnow ? 1.5 : 1.0;
        final radius = (2 + (i % 3)) * sizeMultiplier;
        final paint = Paint()..color = const Color(0x99FFFFFF);
        canvas.drawCircle(
          Offset(x + 18 * sin((progress + i) * pi * 2), y),
          radius,
          paint,
        );
      } else {
"""
new_snow = """      if (snow) {
        final sizeMultiplier = special == SeasonSpecialKind.firstSnow ? 1.5 : 1.0;
        final radius = (2.4 + (i % 3)) * sizeMultiplier;
        final center = Offset(
          x + 22 * sin((progress + i) * pi * 2),
          y,
        );
        final halo = Paint()
          ..color = const Color(0x42FFFFFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
        final paint = Paint()..color = const Color(0xCCFFFFFF);
        canvas.drawCircle(center, radius * 1.45, halo);
        canvas.drawCircle(center, radius, paint);
      } else {
"""
if s.count(old_snow) != 1:
    raise SystemExit(f'snow painter target expected once, found {s.count(old_snow)}')
s = s.replace(old_snow, new_snow, 1)

path.write_text(s)
