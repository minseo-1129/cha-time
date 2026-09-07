from pathlib import Path

app = Path('lib/cha_time_app.dart')
s = app.read_text()

# Shared non-opaque fortune route so the previous screen remains visible behind the card.
needle = """const List<String> fortuneFallbacks = [
  '오늘 한 말은 여기 두고 가.',
  '서둘러 답을 찾지 않아도 돼.',
  '내일의 자네가 알아서 할 거야.',
  '잘 지나간 하루도 하루야.',
  '한 모금씩이면 충분해.',
  '애쓴 건 자네만 알아도 돼.',
];
"""
addition = needle + """
Route<void> fortuneRoute({required String dateKey, required String text}) {
  return PageRouteBuilder<void>(
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => FortuneScreen(
      dateKey: dateKey,
      text: text,
    ),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
"""
if s.count(needle) != 1:
    raise SystemExit(f'fortune route insertion target expected once, found {s.count(needle)}')
s = s.replace(needle, addition, 1)

old_past = """    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FortuneScreen(
          dateKey: record.date,
          text: record.fortune,
        ),
      ),
    );
"""
new_past = """    await Navigator.of(context).push(
      fortuneRoute(dateKey: record.date, text: record.fortune),
    );
"""
if s.count(old_past) != 1:
    raise SystemExit(f'past fortune route target expected once, found {s.count(old_past)}')
s = s.replace(old_past, new_past, 1)

old_current = """    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FortuneScreen(
          dateKey: dateKey(DateTime.now()),
          text: _fortune,
        ),
      ),
    );
"""
new_current = """    await Navigator.of(context).push(
      fortuneRoute(dateKey: dateKey(DateTime.now()), text: _fortune),
    );
"""
if s.count(old_current) != 1:
    raise SystemExit(f'current fortune route target expected once, found {s.count(old_current)}')
s = s.replace(old_current, new_current, 1)

old_back = """                if (_phase == ChaSessionPhase.closing)
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
                  ),
"""
new_back = """                if (_phase == ChaSessionPhase.closing)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 56,
                    child: Semantics(
                      button: true,
                      label: '달력으로',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            height: 44,
                            child: Center(
                              child: Text(
                                '달력으로',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: .6,
                                  color: Color(0xFFA69D93),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
"""
if s.count(old_back) != 1:
    raise SystemExit(f'calendar back action target expected once, found {s.count(old_back)}')
s = s.replace(old_back, new_back, 1)

# Replace opaque FortuneScreen scaffold with a transparent overlay matching the prototype.
start = s.find('class FortuneScreen extends StatelessWidget {')
end = s.find('class TeaBowlImage extends StatelessWidget {')
if start == -1 or end == -1 or end <= start:
    raise SystemExit('could not locate FortuneScreen block')

replacement = r'''class FortuneScreen extends StatelessWidget {
  const FortuneScreen({
    super.key,
    required this.dateKey,
    required this.text,
  });

  final String dateKey;
  final String text;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(dateKey) ?? DateTime.now();
    final season = SeasonStyle.of(seasonForDate(date));

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: const Color(0x29544A40)),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: -1.1 * pi / 180,
                      child: Container(
                        width: 302,
                        padding: const EdgeInsets.fromLTRB(30, 28, 30, 26),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF8F0),
                          image: const DecorationImage(
                            image: AssetImage('design/tex/paper_card.png'),
                            repeat: ImageRepeat.repeat,
                            opacity: .36,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3D584A3A),
                              blurRadius: 40,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  shortDate(date),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.8,
                                    color: Color(0xFFB4A99E),
                                  ),
                                ),
                                Text(
                                  season.label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    color: Color(0xFFB4A99E),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Divider(color: Color(0xFFE8DFD1)),
                            ),
                            SizedBox(
                              height: 104,
                              child: Center(
                                child: Text(
                                  text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: ChaTimeFonts.voice,
                                    fontSize: 22,
                                    height: 1.6,
                                    color: const Color(0xFF4E4740),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/trace_blossom.png',
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  kChaTimeName,
                                  style: TextStyle(
                                    fontFamily: ChaTimeFonts.voice,
                                    fontSize: 12,
                                    color: const Color(0xFFB0A69B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Semantics(
                      button: true,
                      label: '접어두기',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            height: 44,
                            width: 120,
                            child: Center(
                              child: Text(
                                '접어두기',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: .6,
                                  color: Color(0xFFF3EDE3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

'''
s = s[:start] + replacement + s[end:]
app.write_text(s)
