import 'package:flutter_test/flutter_test.dart';

import 'package:doodle/main.dart';

void main() {
  test('Tea session record round-trips JSON', () {
    const record = TeaSessionRecord(
      dateStarted: '2026-08-31',
      startedAt: '2026-08-31T20:00:00.000',
      endedAt: null,
      sipCount: 2,
      cupsServed: 1,
      finished: false,
      phase: 'chatting',
      systemText: '응, 듣고 있어.',
      lastUserMessage: '오늘은 괜찮았어.',
    );

    final restored =
        TeaSessionRecord.fromJson(record.toJson());

    expect(restored.dateStarted, record.dateStarted);
    expect(restored.startedAt, record.startedAt);
    expect(restored.endedAt, record.endedAt);
    expect(restored.sipCount, record.sipCount);
    expect(restored.cupsServed, record.cupsServed);
    expect(restored.finished, record.finished);
    expect(restored.phase, record.phase);
    expect(restored.systemText, record.systemText);
    expect(
      restored.lastUserMessage,
      record.lastUserMessage,
    );
  });
}
