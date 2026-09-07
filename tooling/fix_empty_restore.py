from pathlib import Path

path = Path('lib/cha_time_app.dart')
s = path.read_text()
old = """    final record = _snapshot.days[dateKey(DateTime.now())];
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
new = """    final record = _snapshot.days[dateKey(DateTime.now())];
    if (record != null && !record.finished) {
      if (dailyCupEmpty(record)) {
        _sips = kSipsPerCup;
        _visualSips = kSipsPerCup;
        _phase = ChaSessionPhase.empty;
        _teaLine = '잔이 비었어요';
        _busy = false;
      } else {
        _sips = record.sips.clamp(0, kSipsPerCup).toInt();
        _visualSips = _sips;
      }
    }

    if (_phase == ChaSessionPhase.session) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }"""
if s.count(old) != 1:
    raise SystemExit(f'empty restore target: expected 1, found {s.count(old)}')
path.write_text(s.replace(old, new, 1))
