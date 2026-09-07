from pathlib import Path

p = Path('lib/cha_time_app.dart')
s = p.read_text()

old = """                                            child: SendRainRipple(\n                                              key: ValueKey(\n                                                'rain-$_reactionNonce',\n                                              ),\n                                            ),"""
new = """                                            child: Transform.scale(\n                                              scale: _visualSips == 5 ? .78 : 1,\n                                              child: SendRainRipple(\n                                                key: ValueKey(\n                                                  'rain-$_reactionNonce',\n                                                ),\n                                              ),\n                                            ),"""
if old not in s:
    raise SystemExit('rain ripple placement pattern not found')
s = s.replace(old, new, 1)

old = "contentPadding: const EdgeInsets.only(top: 12, bottom: 18),"
new = "contentPadding: const EdgeInsets.only(top: 14, bottom: 16),"
if old not in s:
    raise SystemExit('input padding pattern not found')
s = s.replace(old, new, 1)

old = """      ..strokeWidth = 1.05\n      ..color = Color.fromRGBO(112, 139, 145, opacity.clamp(0, 1) * .62);"""
new = """      ..strokeWidth = .9\n      ..color = Color.fromRGBO(112, 139, 145, opacity.clamp(0, 1) * .38);"""
if old not in s:
    raise SystemExit('ripple paint pattern not found')
s = s.replace(old, new, 1)

p.write_text(s)
