from pathlib import Path

app = Path('lib/cha_time_app.dart')
s = app.read_text()

# Add a calibrated water-surface position for each visible sip level.
needle = '''Duration sendMomentDuration(ChaWeather weather) {
  switch (weather) {
    case ChaWeather.clear:
      return const Duration(milliseconds: 400);
    case ChaWeather.cloudy:
      return Duration.zero;
    case ChaWeather.rain:
      return const Duration(milliseconds: 700);
    case ChaWeather.snow:
      return const Duration(milliseconds: 900);
  }
}
'''
addition = needle + '''\ndouble rainRippleTopForSip(int sipCount) {
  const tops = <double>[48, 50, 52, 54, 56, 58];
  final index = sipCount.clamp(0, 5).toInt();
  return tops[index];
}
'''
if s.count(needle) != 1:
    raise SystemExit(f'send moment helper target expected once, found {s.count(needle)}')
s = s.replace(needle, addition, 1)

old_bowl = '''                                Transform.scale(
                                  scale: specialBowlScale(_special),
                                  child: TeaBowlImage(
                                    sipCount: _visualSips,
                                    season: _season,
                                  ),
                                ),
                                if (_reactionNonce > 0 &&
                                    _weather == ChaWeather.rain)
                                  Positioned(
                                    top: 18,
                                    child: SendRainRipple(
                                      key: ValueKey('rain-$_reactionNonce'),
                                    ),
                                  ),
                                if (_reactionNonce > 0 &&
                                    _weather == ChaWeather.snow)
                                  Positioned(
                                    bottom: 179,
                                    child: SendSnowSteamPulse(
                                      key: ValueKey('snow-$_reactionNonce'),
                                    ),
                                  ),
'''
new_bowl = '''                                Transform.scale(
                                  scale: specialBowlScale(_special),
                                  child: SizedBox(
                                    width: 236,
                                    height: 205,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        TeaBowlImage(
                                          sipCount: _visualSips,
                                          season: _season,
                                        ),
                                        if (_reactionNonce > 0 &&
                                            _weather == ChaWeather.rain &&
                                            _visualSips < kSipsPerCup)
                                          AnimatedPositioned(
                                            duration: const Duration(
                                              milliseconds: 420,
                                            ),
                                            curve: Curves.easeOut,
                                            top: rainRippleTopForSip(
                                              _visualSips,
                                            ),
                                            left: 64,
                                            right: 64,
                                            child: SendRainRipple(
                                              key: ValueKey(
                                                'rain-$_reactionNonce',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_reactionNonce > 0 &&
                                    _weather == ChaWeather.snow)
                                  Positioned(
                                    bottom: 179,
                                    child: SendSnowSteamPulse(
                                      key: ValueKey('snow-$_reactionNonce'),
                                    ),
                                  ),
'''
if s.count(old_bowl) != 1:
    raise SystemExit(f'bowl/ripple target expected once, found {s.count(old_bowl)}')
s = s.replace(old_bowl, new_bowl, 1)

old_row = '''      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
'''
new_row = '''      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
'''
if s.count(old_row) != 1:
    raise SystemExit(f'input row target expected once, found {s.count(old_row)}')
s = s.replace(old_row, new_row, 1)

old_field = '''              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              cursorColor: const Color(0xFF81786F),
'''
new_field = '''              minLines: 1,
              maxLines: 3,
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              cursorColor: const Color(0xFF81786F),
'''
if s.count(old_field) != 1:
    raise SystemExit(f'text field target expected once, found {s.count(old_field)}')
s = s.replace(old_field, new_field, 1)

old_padding = '''                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
'''
new_padding = '''                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 12, bottom: 18),
'''
if s.count(old_padding) != 1:
    raise SystemExit(f'input padding target expected once, found {s.count(old_padding)}')
s = s.replace(old_padding, new_padding, 1)

app.write_text(s)

# Regression-test the calibrated waterline mapping.
test = Path('test/widget_test.dart')
t = test.read_text()
needle_test = """  test('relationship stages follow the design thresholds', () {
"""
addition_test = """  test('rain ripple follows each visible tea surface level', () {
    expect(rainRippleTopForSip(0), 48);
    expect(rainRippleTopForSip(1), 50);
    expect(rainRippleTopForSip(2), 52);
    expect(rainRippleTopForSip(3), 54);
    expect(rainRippleTopForSip(4), 56);
    expect(rainRippleTopForSip(5), 58);
    expect(rainRippleTopForSip(99), 58);
  });

"""
if t.count(needle_test) != 1:
    raise SystemExit(f'test target expected once, found {t.count(needle_test)}')
test.write_text(t.replace(needle_test, addition_test + needle_test, 1))
