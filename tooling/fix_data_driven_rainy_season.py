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
"""    case 6:
    case 7:
      return ChaSeason.rainy;
    case 8:
      return ChaSeason.summer;""",
"""    case 6:
    case 7:
    case 8:
      return ChaSeason.summer;""",
'data-driven rainy season mapping')

once(
"""    required this.updatedAt,
    this.weather = '',
  });

  final String date;
  final bool finished;
  final int sips;
  final int cups;
  final String fortune;
  final String updatedAt;
  final String weather;""",
"""    required this.updatedAt,
    this.weather = '',
    this.season = '',
  });

  final String date;
  final bool finished;
  final int sips;
  final int cups;
  final String fortune;
  final String updatedAt;
  final String weather;
  final String season;""",
'DayRecord season field')

once(
"""      updatedAt: json['updatedAt'] as String? ?? '',
      weather: json['weather'] as String? ?? '',""",
"""      updatedAt: json['updatedAt'] as String? ?? '',
      weather: json['weather'] as String? ?? '',
      season: json['season'] as String? ?? '',""",
'DayRecord season decode')

once(
"""        'updatedAt': updatedAt,
        'weather': weather,""",
"""        'updatedAt': updatedAt,
        'weather': weather,
        'season': season,""",
'DayRecord season encode')

once(
"""    final season = SeasonStyle.of(seasonForDate(date)).label;
    final weather = WeatherStyle.of(_weatherFromName(record.weather)).label;
    final special = seasonSpecialFor(season, weather);""",
"""    final season = record.season.isNotEmpty
        ? record.season
        : SeasonStyle.of(seasonForDate(date)).label;
    final weather = WeatherStyle.of(_weatherFromName(record.weather)).label;
    final special = seasonSpecialFor(season, weather);""",
'past marker saved season')

once(
"""      updatedAt: DateTime.now().toIso8601String(),
      weather: _weather.name,""",
"""      updatedAt: DateTime.now().toIso8601String(),
      weather: _weather.name,
      season: SeasonStyle.of(_season).label,""",
'persist season')

p.write_text(s)

test = Path('test/widget_test.dart')
t = test.read_text()
t = t.replace(
"""      updatedAt: '2026-09-07T20:00:00.000',
    );""",
"""      updatedAt: '2026-09-07T20:00:00.000',
      weather: 'rain',
      season: '가을',
    );""",
1)
t = t.replace(
"""    expect(restored.fortune, record.fortune);
  });""",
"""    expect(restored.fortune, record.fortune);
    expect(restored.weather, 'rain');
    expect(restored.season, '가을');
  });""",
1)
t = t.replace(
"""    expect(seasonForDate(DateTime(2026, 6, 1)), ChaSeason.rainy);
    expect(seasonForDate(DateTime(2026, 8, 1)), ChaSeason.summer);""",
"""    expect(seasonForDate(DateTime(2026, 6, 1)), ChaSeason.summer);
    expect(seasonForDate(DateTime(2026, 8, 1)), ChaSeason.summer);
    expect(
      seasonForContext(DateTime(2026, 6, 1), true),
      ChaSeason.rainy,
    );""",
1)
test.write_text(t)
