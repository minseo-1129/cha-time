from pathlib import Path

app_path = Path('lib/cha_time_app.dart')
s = app_path.read_text()


def once(old: str, new: str, label: str):
    global s
    count = s.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected 1 match, found {count}')
    s = s.replace(old, new, 1)


once(
    "const int kSipsPerCup = 6;",
    "const int kSipsPerCup = 6;\nconst int kCupsPerDay = 1;",
    'daily cup constant',
)

once(
    """int relationshipStage(int visits) {
  if (visits <= 6) return 1;
  if (visits <= 20) return 2;
  return 3;
}""",
    """bool dailyCupFinished(DayRecord? record) => record?.finished == true;

bool dailyCupEmpty(DayRecord? record) =>
    record != null &&
    !record.finished &&
    (record.sips >= kSipsPerCup || record.cups > kCupsPerDay);

int relationshipStage(int visits) {
  if (visits <= 6) return 1;
  if (visits <= 20) return 2;
  return 3;
}""",
    'daily cup helpers',
)

old_open_today = """  Future<void> _openToday() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChaSessionScreen(
          initialSnapshot: _snapshot,
          liveWeather: widget.liveWeather,
        ),
      ),
    );
    await _load();
    if (!mounted) return;
    final now = DateTime.now();
    setState(() => _visibleMonth = DateTime(now.year, now.month));
  }"""
new_open_today = """  Future<void> _openToday() async {
    final today = _snapshot.days[dateKey(DateTime.now())];
    if (dailyCupFinished(today)) {
      if (today != null && today.fortune.isNotEmpty) {
        await _openPast(today);
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChaSessionScreen(
          initialSnapshot: _snapshot,
          liveWeather: widget.liveWeather,
        ),
      ),
    );
    await _load();
    if (!mounted) return;
    final now = DateTime.now();
    setState(() => _visibleMonth = DateTime(now.year, now.month));
  }"""
once(old_open_today, new_open_today, 'finished-day routing')

once(
    """    final stage = relationshipStage(_snapshot.visits);
    final voice = VoicePack.forStage(stage);

    return Scaffold(""",
    """    final stage = relationshipStage(_snapshot.visits);
    final voice = VoicePack.forStage(stage);
    final todayRecord = _snapshot.days[dateKey(now)];
    final todayFinished = dailyCupFinished(todayRecord);

    return Scaffold(""",
    'today finished calendar state',
)

once(
    """                          child: Text(
                            '${voice.cta}  →',
                            style: TextStyle(
                              fontFamily: ChaTimeFonts.voice,
                              fontSize: 15,
                            ),
                          ),""",
    """                          child: Text(
                            todayFinished
                                ? '오늘의 한 마디 보기'
                                : '${voice.cta}  →',
                            style: TextStyle(
                              fontFamily: ChaTimeFonts.voice,
                              fontSize: 15,
                            ),
                          ),""",
    'calendar CTA after completion',
)

once(
    "  int _cups = 1;\n",
    "",
    'remove mutable cup count',
)

old_restore = """    final record = _snapshot.days[dateKey(DateTime.now())];
    if (record != null && !record.finished) {
      _sips = record.sips.clamp(0, kSipsPerCup).toInt();
      _visualSips = _sips;
      _cups = max(1, record.cups);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _open());"""
new_restore = """    final record = _snapshot.days[dateKey(DateTime.now())];
    if (record != null && !record.finished) {
      if (dailyCupEmpty(record)) {
        _sips = kSipsPerCup;
        _visualSips = kSipsPerCup;
        _phase = ChaSessionPhase.empty;
      } else {
        _sips = record.sips.clamp(0, kSipsPerCup).toInt();
        _visualSips = _sips;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _open());"""
once(old_restore, new_restore, 'restore one-cup state')

refill_start = s.find('  Future<void> _refill() async {')
finish_start = s.find('  Future<void> _finish() async {')
if refill_start == -1 or finish_start == -1 or finish_start <= refill_start:
    raise SystemExit('refill method boundaries not found')
s = s[:refill_start] + s[finish_start:]

once(
    "      cups: _cups,",
    "      cups: kCupsPerDay,",
    'persist one cup',
)

old_closing_button = """                if (_phase == ChaSessionPhase.closing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 56,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '달력으로',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: .6,
                          color: Color(0xFFA69D93),
                        ),
                      ),
                    ),
                  ),"""
new_closing_button = """                if (_phase == ChaSessionPhase.closing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 56,
                    child: Center(
                      child: ChaActionButton(
                        label: '달력으로',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),"""
once(old_closing_button, new_closing_button, 'unified calendar button')

old_empty_actions = """  Widget _emptyActions() {
    return Column(
      children: [
        SizedBox(
          width: 224,
          child: FilledButton(
            onPressed: _busy ? null : _refill,
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFE1E7CB),
              foregroundColor: const Color(0xFF5C6349),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '한 잔 더 마실래',
              style: TextStyle(fontFamily: ChaTimeFonts.voice, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 224,
          child: OutlinedButton(
            onPressed: _busy ? null : _finish,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8E847B),
              side: const BorderSide(color: Color(0xFFDCD3C6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '오늘 이만 마칠래',
              style: TextStyle(fontFamily: ChaTimeFonts.voice, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}"""
new_empty_actions = """  Widget _emptyActions() {
    return Center(
      child: ChaActionButton(
        label: '오늘 이만 마칠래',
        onPressed: _busy ? null : _finish,
        filled: true,
      ),
    );
  }
}

class ChaActionButton extends StatelessWidget {
  const ChaActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        fontFamily: ChaTimeFonts.voice,
        fontSize: 16,
        height: 1.15,
      ),
    );

    return SizedBox(
      width: 224,
      height: 52,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE1E7CB),
                foregroundColor: const Color(0xFF5C6349),
                disabledBackgroundColor: const Color(0x80E1E7CB),
                disabledForegroundColor: const Color(0x808E847B),
                shape: const StadiumBorder(),
              ),
              child: text,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8E847B),
                backgroundColor: const Color(0x33FFFFFF),
                side: const BorderSide(color: Color(0xFFDCD3C6)),
                shape: const StadiumBorder(),
              ),
              child: text,
            ),
    );
  }
}"""
once(old_empty_actions, new_empty_actions, 'one action empty state')

old_fold = """                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '접어두기',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: .6,
                      color: Color(0xFFF3EDE3),
                    ),
                  ),
                ),"""
new_fold = """                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '접어두기',
                    style: TextStyle(
                      fontFamily: ChaTimeFonts.voice,
                      fontSize: 13,
                      letterSpacing: .6,
                      color: const Color(0xFFF3EDE3),
                    ),
                  ),
                ),"""
once(old_fold, new_fold, 'fortune action voice font')

app_path.write_text(s)

# Unit-level regression checks for the daily one-cup rule.
test_path = Path('test/widget_test.dart')
t = test_path.read_text()
needle = """  test('relationship stages follow the design thresholds', () {"""
insert = """  test('daily cup allows only one cup per day', () {
    const partial = DayRecord(
      date: '2026-09-07',
      finished: false,
      sips: 3,
      cups: 1,
      fortune: '',
      updatedAt: '',
    );
    const empty = DayRecord(
      date: '2026-09-07',
      finished: false,
      sips: 6,
      cups: 1,
      fortune: '',
      updatedAt: '',
    );
    const legacyRefill = DayRecord(
      date: '2026-09-07',
      finished: false,
      sips: 2,
      cups: 2,
      fortune: '',
      updatedAt: '',
    );
    const finished = DayRecord(
      date: '2026-09-07',
      finished: true,
      sips: 6,
      cups: 1,
      fortune: '오늘 한 말은 여기 두고 가.',
      updatedAt: '',
    );

    expect(kCupsPerDay, 1);
    expect(dailyCupEmpty(partial), isFalse);
    expect(dailyCupEmpty(empty), isTrue);
    expect(dailyCupEmpty(legacyRefill), isTrue);
    expect(dailyCupFinished(finished), isTrue);
  });

  test('relationship stages follow the design thresholds', () {"""
if t.count(needle) != 1:
    raise SystemExit('test insertion point not found')
t = t.replace(needle, insert, 1)
test_path.write_text(t)

# Keep product docs aligned with the shipping rule.
readme = Path('README.md')
r = readme.read_text()
r = r.replace(
    'calendar persistence, 6-sip cup progression, refill animation, closing/fortune flow,',
    'calendar persistence, a strict one-cup-per-day 6-sip progression, closing/fortune flow,',
)
r = r.replace(
    '- `design/sodam-prototype.html` — calendar → tea session → refill/finish → fortune card',
    '- `design/sodam-prototype.html` — calendar → tea session → finish → fortune card (the shipping app intentionally limits each day to one cup)',
)
readme.write_text(r)

typeface = Path('TYPEFACE.md')
tf = typeface.read_text().replace(
    '- refill/closing copy',
    '- empty-cup/closing copy',
)
typeface.write_text(tf)
