from pathlib import Path

p = Path('lib/cha_time_app.dart')
s = p.read_text()


def once(old: str, new: str, label: str):
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    s = s.replace(old, new, 1)


once(
    "import 'package:shared_preferences/shared_preferences.dart';",
    "import 'package:shared_preferences/shared_preferences.dart';\n\nimport 'season_specials.dart';\nimport 'weather_context.dart';",
    'feature imports',
)

once(
    """int relationshipStage(int visits) {\n  if (visits <= 6) return 1;\n  if (visits <= 20) return 2;\n  return 3;\n}""",
    """ChaSeason seasonForContext(DateTime date, bool rainySpell) {\n  return rainySpell ? ChaSeason.rainy : seasonForDate(date);\n}\n\nint relationshipStage(int visits) {\n  if (visits <= 6) return 1;\n  if (visits <= 20) return 2;\n  return 3;\n}""",
    'season context helper',
)

once(
    """    required this.fortune,\n    required this.updatedAt,\n  });\n\n  final String date;\n  final bool finished;\n  final int sips;\n  final int cups;\n  final String fortune;\n  final String updatedAt;""",
    """    required this.fortune,\n    required this.updatedAt,\n    this.weather = '',\n  });\n\n  final String date;\n  final bool finished;\n  final int sips;\n  final int cups;\n  final String fortune;\n  final String updatedAt;\n  final String weather;""",
    'DayRecord weather field',
)

once(
    """      fortune: json['fortune'] as String? ?? '',\n      updatedAt: json['updatedAt'] as String? ?? '',""",
    """      fortune: json['fortune'] as String? ?? '',\n      updatedAt: json['updatedAt'] as String? ?? '',\n      weather: json['weather'] as String? ?? '',""",
    'DayRecord weather decode',
)

once(
    """        'fortune': fortune,\n        'updatedAt': updatedAt,""",
    """        'fortune': fortune,\n        'updatedAt': updatedAt,\n        'weather': weather,""",
    'DayRecord weather encode',
)

once(
    """ChaWeather configuredWeather() {\n  const raw = String.fromEnvironment(\n    'CHA_TIME_WEATHER',\n    defaultValue: 'clear',\n  );\n  switch (raw.toLowerCase()) {\n    case 'cloudy':\n      return ChaWeather.cloudy;\n    case 'rain':\n      return ChaWeather.rain;\n    case 'snow':\n      return ChaWeather.snow;\n    default:\n      return ChaWeather.clear;\n  }\n}""",
    """ChaWeather configuredWeather() {\n  const raw = String.fromEnvironment(\n    'CHA_TIME_WEATHER',\n    defaultValue: 'clear',\n  );\n  return _weatherFromName(raw);\n}\n\nChaWeather weatherForContext(WeatherContextData data) {\n  const override = String.fromEnvironment('CHA_TIME_WEATHER', defaultValue: '');\n  if (override.isNotEmpty) return _weatherFromName(override);\n  switch (data.kind) {\n    case LiveWeatherKind.cloudy:\n      return ChaWeather.cloudy;\n    case LiveWeatherKind.rain:\n      return ChaWeather.rain;\n    case LiveWeatherKind.snow:\n      return ChaWeather.snow;\n    case LiveWeatherKind.clear:\n      return ChaWeather.clear;\n  }\n}\n\nChaWeather _weatherFromName(String raw) {\n  switch (raw.toLowerCase()) {\n    case 'cloudy':\n      return ChaWeather.cloudy;\n    case 'rain':\n      return ChaWeather.rain;\n    case 'snow':\n      return ChaWeather.snow;\n    default:\n      return ChaWeather.clear;\n  }\n}""",
    'weather context mapper',
)

once(
    "home: const ChaCalendarScreen(),",
    """home: WeatherContextBuilder(\n        builder: (context, weather) => ChaCalendarScreen(liveWeather: weather),\n      ),""",
    'root weather builder',
)

once(
    """class ChaCalendarScreen extends StatefulWidget {\n  const ChaCalendarScreen({super.key});\n\n  @override""",
    """class ChaCalendarScreen extends StatefulWidget {\n  const ChaCalendarScreen({super.key, required this.liveWeather});\n\n  final WeatherContextData liveWeather;\n\n  @override""",
    'calendar weather property',
)

once(
    "builder: (_) => ChaSessionScreen(initialSnapshot: _snapshot),",
    """builder: (_) => ChaSessionScreen(\n          initialSnapshot: _snapshot,\n          liveWeather: widget.liveWeather,\n        ),""",
    'pass weather to session',
)

once(
    """    final season = seasonForDate(now);\n    final seasonStyle = SeasonStyle.of(season);\n    final weather = configuredWeather();\n    final weatherStyle = WeatherStyle.of(weather);""",
    """    final season = seasonForContext(now, widget.liveWeather.rainySpell);\n    final seasonStyle = SeasonStyle.of(season);\n    final weather = weatherForContext(widget.liveWeather);\n    final weatherStyle = WeatherStyle.of(weather);\n    final special = seasonSpecialFor(seasonStyle.label, weatherStyle.label);\n    final paper = specialPaper(seasonStyle.paper, special);""",
    'calendar live season weather',
)

once('backgroundColor: seasonStyle.paper,', 'backgroundColor: paper,', 'calendar paper override')
once(
    """          Positioned.fill(child: WeatherWash(weather: weather)),\n          AmbientParticles(weather: weather),""",
    """          Positioned.fill(\n            child: SeasonWeatherWash(\n              weather: weatherStyle.label,\n              special: special,\n            ),\n          ),\n          SeasonAmbientParticles(\n            weather: weatherStyle.label,\n            special: special,\n          ),""",
    'calendar special ambience',
)

once(
    """                                  opacity: min(\n                                    .72,\n                                    seasonStyle.steam *\n                                        weatherStyle.steamMultiplier,\n                                  ),""",
    """                                  opacity: min(\n                                    .72,\n                                    specialSteam(\n                                      seasonStyle.steam,\n                                      weatherStyle.steamMultiplier,\n                                      special,\n                                    ),\n                                  ),""",
    'calendar special steam',
)

once(
    """                                child: TeaBowlImage(\n                                  sipCount: 0,\n                                  season: season,\n                                ),""",
    """                                child: Transform.scale(\n                                  scale: specialBowlScale(special),\n                                  child: TeaBowlImage(\n                                    sipCount: 0,\n                                    season: season,\n                                  ),\n                                ),""",
    'calendar cold rain bowl scale',
)

old_marker = """              if (record != null)\n                Image.asset(\n                  record.finished\n                      ? 'assets/images/trace_blossom.png'\n                      : 'assets/images/status_raindrop.png',\n                  width: record.finished ? 19 : 13,\n                  height: record.finished ? 19 : 13,\n                  fit: BoxFit.contain,\n                  opacity: const AlwaysStoppedAnimation(.88),\n                ),"""
new_marker = """              if (record != null) _recordMarker(record, date),"""
once(old_marker, new_marker, 'calendar record marker')

insert_before_legend = """  Widget _legend(String asset, String label, double size) {"""
record_method = """  Widget _recordMarker(DayRecord record, DateTime date) {\n    if (!record.finished) {\n      return Image.asset(\n        'assets/images/status_raindrop.png',\n        width: 13,\n        height: 13,\n        fit: BoxFit.contain,\n        opacity: const AlwaysStoppedAnimation(.88),\n      );\n    }\n    final season = SeasonStyle.of(seasonForDate(date)).label;\n    final weather = WeatherStyle.of(_weatherFromName(record.weather)).label;\n    final special = seasonSpecialFor(season, weather);\n    return Opacity(\n      opacity: .88,\n      child: SeasonClosingTrace(special: special, size: 19),\n    );\n  }\n\n  Widget _legend(String asset, String label, double size) {"""
once(insert_before_legend, record_method, 'calendar special marker helper')

once(
    """class ChaSessionScreen extends StatefulWidget {\n  const ChaSessionScreen({super.key, required this.initialSnapshot});\n\n  final ChaSnapshot initialSnapshot;""",
    """class ChaSessionScreen extends StatefulWidget {\n  const ChaSessionScreen({\n    super.key,\n    required this.initialSnapshot,\n    required this.liveWeather,\n  });\n\n  final ChaSnapshot initialSnapshot;\n  final WeatherContextData liveWeather;""",
    'session weather property',
)

once(
    """  late ChaSeason _season;\n  late ChaWeather _weather;""",
    """  late ChaSeason _season;\n  late ChaWeather _weather;\n  late SeasonSpecialKind _special;""",
    'session special field',
)

once(
    """    _season = seasonForDate(DateTime.now());\n    _weather = configuredWeather();""",
    """    _season = seasonForContext(DateTime.now(), widget.liveWeather.rainySpell);\n    _weather = weatherForContext(widget.liveWeather);\n    _special = seasonSpecialFor(\n      SeasonStyle.of(_season).label,\n      WeatherStyle.of(_weather).label,\n    );""",
    'session live weather init',
)

once(
    """      fortune: fortune.isNotEmpty ? fortune : previous?.fortune ?? '',\n      updatedAt: DateTime.now().toIso8601String(),""",
    """      fortune: fortune.isNotEmpty ? fortune : previous?.fortune ?? '',\n      updatedAt: DateTime.now().toIso8601String(),\n      weather: _weather.name,""",
    'persist weather',
)

old_session_build = """    final seasonStyle = SeasonStyle.of(_season);\n    final weatherStyle = WeatherStyle.of(_weather);\n    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;"""
new_session_build = """    final seasonStyle = SeasonStyle.of(_season);\n    final weatherStyle = WeatherStyle.of(_weather);\n    final paper = specialPaper(seasonStyle.paper, _special);\n    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;"""
once(old_session_build, new_session_build, 'session special paper')

# There are now two backgroundColor occurrences; replace the remaining session one.
idx = s.find('backgroundColor: seasonStyle.paper,')
if idx == -1:
    raise SystemExit('session background paper: no remaining match')
s = s[:idx] + 'backgroundColor: paper,' + s[idx + len('backgroundColor: seasonStyle.paper,'):]

once(
    """          Positioned.fill(child: WeatherWash(weather: _weather)),\n          AmbientParticles(weather: _weather, reducedOpacity: keyboardOpen),""",
    """          Positioned.fill(\n            child: SeasonWeatherWash(\n              weather: weatherStyle.label,\n              special: _special,\n            ),\n          ),\n          SeasonAmbientParticles(\n            weather: weatherStyle.label,\n            special: _special,\n            reducedOpacity: keyboardOpen,\n          ),""",
    'session special ambience',
)

once(
    """                                            .8,\n                                            seasonStyle.steam *\n                                                weatherStyle.steamMultiplier,\n                                          ),""",
    """                                            .8,\n                                            specialSteam(\n                                              seasonStyle.steam,\n                                              weatherStyle.steamMultiplier,\n                                              _special,\n                                            ),\n                                          ),""",
    'session special steam',
)

once(
    """                                TeaBowlImage(\n                                  sipCount: _visualSips,\n                                  season: _season,\n                                ),""",
    """                                Transform.scale(\n                                  scale: specialBowlScale(_special),\n                                  child: TeaBowlImage(\n                                    sipCount: _visualSips,\n                                    season: _season,\n                                  ),\n                                ),""",
    'session cold rain bowl scale',
)

once(
    """                                    child: Image.asset(\n                                      'assets/images/trace_blossom.png',\n                                      width: 30,\n                                    ),""",
    """                                    child: SeasonClosingTrace(\n                                      special: _special,\n                                      size: 30,\n                                    ),""",
    'closing special trace',
)

p.write_text(s)

# Extend tests for data-driven rainy-season and special mapping.
test = Path('test/widget_test.dart')
t = test.read_text()
t = t.replace(
    "import 'package:cha_time/cha_time_app.dart';",
    "import 'package:cha_time/cha_time_app.dart';\nimport 'package:cha_time/season_specials.dart';\nimport 'package:cha_time/weather_context.dart';",
)
insert = """

  test('rainy spell detection uses sustained warm precipitation', () {
    final rainy = detectRainySpell({
      'precipitation_sum': [5, 6, 4, 8, 3, 2, 0, 1],
      'rain_sum': [5, 6, 4, 8, 3, 2, 0, 1],
      'snowfall_sum': [0, 0, 0, 0, 0, 0, 0, 0],
      'precipitation_hours': [5, 6, 4, 5, 3, 2, 0, 1],
      'precipitation_probability_max': [80, 90, 75, 85, 70, 60, 20, 30],
      'temperature_2m_mean': [22, 23, 21, 22, 24, 23, 25, 24],
    });
    expect(rainy, isTrue);

    final winterRain = detectRainySpell({
      'precipitation_sum': [5, 6, 4, 8, 3, 2, 0, 1],
      'rain_sum': [5, 6, 4, 8, 3, 2, 0, 1],
      'snowfall_sum': [0, 0, 0, 0, 0, 0, 0, 0],
      'precipitation_hours': [5, 6, 4, 5, 3, 2, 0, 1],
      'precipitation_probability_max': [80, 90, 75, 85, 70, 60, 20, 30],
      'temperature_2m_mean': [5, 6, 4, 8, 7, 5, 6, 4],
    });
    expect(winterRain, isFalse);
  });

  test('six Season Matrix exceptions map exactly', () {
    expect(seasonSpecialFor('봄', '비'), SeasonSpecialKind.flowerRain);
    expect(seasonSpecialFor('여름', '비'), SeasonSpecialKind.summerShower);
    expect(seasonSpecialFor('장마', '맑음'), SeasonSpecialKind.clearedSky);
    expect(seasonSpecialFor('가을', '비'), SeasonSpecialKind.coldRain);
    expect(seasonSpecialFor('겨울', '맑음'), SeasonSpecialKind.drySunlight);
    expect(seasonSpecialFor('겨울', '눈'), SeasonSpecialKind.firstSnow);
  });
"""
if not t.rstrip().endswith('}'):
    raise SystemExit('test file ending not recognized')
t = t.rstrip()[:-1] + insert + '\n}\n'
test.write_text(t)
