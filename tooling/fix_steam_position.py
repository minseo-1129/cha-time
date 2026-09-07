from pathlib import Path

path = Path('lib/cha_time_app.dart')
s = path.read_text()

old_calendar = '''                        SizedBox(
                          width: 112,
                          height: 76,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                top: 0,
                                child: Steam('''
new_calendar = '''                        SizedBox(
                          width: 106,
                          height: 66,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                bottom: 52,
                                child: Steam('''

if s.count(old_calendar) != 1:
    raise SystemExit(f'calendar steam anchor expected once, found {s.count(old_calendar)}')
s = s.replace(old_calendar, new_calendar, 1)

old_session = '''                          SizedBox(
                            width: 236,
                            height: 205,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  top: 0,
                                  child: Steam('''
new_session = '''                          SizedBox(
                            width: 236,
                            height: 205,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  bottom: 179,
                                  child: Steam('''

if s.count(old_session) != 1:
    raise SystemExit(f'session steam anchor expected once, found {s.count(old_session)}')
s = s.replace(old_session, new_session, 1)

path.write_text(s)
