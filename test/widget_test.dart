import 'package:flutter_test/flutter_test.dart';

import 'package:cha_time/cha_time_app.dart';
import 'package:cha_time/season_specials.dart';
import 'package:cha_time/weather_context.dart';

void main() {
  test('DayRecord round-trips JSON', () {
    const record = DayRecord(
      date: '2026-09-07',
      finished: true,
      sips: 6,
      cups: 1,
      fortune: '오늘 한 말은 여기 두고 가.',
      updatedAt: '2026-09-07T20:00:00.000',
    );

    final restored = DayRecord.fromJson(record.toJson());

    expect(restored.date, record.date);
    expect(restored.finished, isTrue);
    expect(restored.sips, 6);
    expect(restored.cups, 1);
    expect(restored.fortune, record.fortune);
  });

  test('relationship stages follow the design thresholds', () {
    expect(relationshipStage(0), 1);
    expect(relationshipStage(6), 1);
    expect(relationshipStage(7), 2);
    expect(relationshipStage(20), 2);
    expect(relationshipStage(21), 3);
  });

  test('season mapping includes the rainy-season layer', () {
    expect(seasonForDate(DateTime(2026, 1, 1)), ChaSeason.winter);
    expect(seasonForDate(DateTime(2026, 4, 1)), ChaSeason.spring);
    expect(seasonForDate(DateTime(2026, 6, 1)), ChaSeason.rainy);
    expect(seasonForDate(DateTime(2026, 8, 1)), ChaSeason.summer);
    expect(seasonForDate(DateTime(2026, 10, 1)), ChaSeason.autumn);
  });


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

}
