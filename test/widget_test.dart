import 'package:flutter_test/flutter_test.dart';

import 'package:cha_time/cha_time_app.dart';

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
}
