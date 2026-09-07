from pathlib import Path

app = Path('lib/cha_time_app.dart')
s = app.read_text()

old_fn = '''ChaSeason seasonForContext(DateTime date, bool rainySpell) {
  return rainySpell ? ChaSeason.rainy : seasonForDate(date);
}
'''
new_fn = '''ChaSeason seasonForContext(DateTime date, bool rainySpell) {
  return rainySpell ? ChaSeason.rainy : seasonForDate(date);
}

ChaSeason configuredSeason(DateTime date, bool rainySpell) {
  const raw = String.fromEnvironment(
    'CHA_TIME_SEASON',
    defaultValue: '',
  );
  switch (raw.toLowerCase()) {
    case 'spring':
      return ChaSeason.spring;
    case 'summer':
      return ChaSeason.summer;
    case 'rainy':
      return ChaSeason.rainy;
    case 'autumn':
    case 'fall':
      return ChaSeason.autumn;
    case 'winter':
      return ChaSeason.winter;
    default:
      return seasonForContext(date, rainySpell);
  }
}
'''
if s.count(old_fn) != 1:
    raise SystemExit(f'season function target expected once, found {s.count(old_fn)}')
s = s.replace(old_fn, new_fn, 1)

old_calendar = 'final season = seasonForContext(now, widget.liveWeather.rainySpell);'
new_calendar = 'final season = configuredSeason(now, widget.liveWeather.rainySpell);'
if s.count(old_calendar) != 1:
    raise SystemExit(f'calendar season target expected once, found {s.count(old_calendar)}')
s = s.replace(old_calendar, new_calendar, 1)

old_session = '_season = seasonForContext(DateTime.now(), widget.liveWeather.rainySpell);'
new_session = '_season = configuredSeason(DateTime.now(), widget.liveWeather.rainySpell);'
if s.count(old_session) != 1:
    raise SystemExit(f'session season target expected once, found {s.count(old_session)}')
s = s.replace(old_session, new_session, 1)
app.write_text(s)

readme = Path('README.md')
r = readme.read_text()
old_docs = '''For visual QA, weather can still be overridden without changing production logic:

```bash
flutter run --dart-define=CHA_TIME_WEATHER=rain
```

Supported QA values: `clear`, `cloudy`, `rain`, `snow`.
'''
new_docs = '''For visual QA, weather and season can be overridden without changing production logic:

```bash
flutter run --dart-define=CHA_TIME_SEASON=spring --dart-define=CHA_TIME_WEATHER=rain
```

Supported weather QA values: `clear`, `cloudy`, `rain`, `snow`.
Supported season QA values: `spring`, `summer`, `rainy`, `autumn` (or `fall`), `winter`.
When `CHA_TIME_SEASON` is omitted, the app continues to use the real calendar season plus the Open-Meteo rainy-spell rule.
'''
if r.count(old_docs) != 1:
    raise SystemExit(f'README QA block expected once, found {r.count(old_docs)}')
readme.write_text(r.replace(old_docs, new_docs, 1))

# Add a lightweight test for the normal, non-override season function; compile-time
# dart-defines themselves are exercised manually/at run time.
test = Path('test/widget_test.dart')
t = test.read_text()
needle = """  test('relationship stages follow the design thresholds', () {
"""
addition = """  test('configured season falls back to calendar context without QA define', () {
    expect(configuredSeason(DateTime(2026, 4, 1), false), ChaSeason.spring);
    expect(configuredSeason(DateTime(2026, 7, 1), false), ChaSeason.summer);
    expect(configuredSeason(DateTime(2026, 7, 1), true), ChaSeason.rainy);
  });

"""
if t.count(needle) != 1:
    raise SystemExit(f'test insertion target expected once, found {t.count(needle)}')
test.write_text(t.replace(needle, addition + needle, 1))
