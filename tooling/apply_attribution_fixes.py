from pathlib import Path

# Fix the two analyzer findings and add the required Open-Meteo attribution widget.
weather = Path('lib/weather_context.dart')
w = weather.read_text()
w = w.replace("import 'package:flutter/foundation.dart';\n", '')
w = w.replace(
    "import 'package:http/http.dart' as http;",
    "import 'package:http/http.dart' as http;\nimport 'package:url_launcher/url_launcher.dart';",
)
if 'class WeatherAttribution' not in w:
    w += r'''

class WeatherAttribution extends StatelessWidget {
  const WeatherAttribution({super.key});

  static final Uri _source = Uri.parse('https://open-meteo.com/');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: 'Weather data by Open-Meteo.com',
      child: InkWell(
        onTap: () => launchUrl(_source),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            'Weather data by Open-Meteo',
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: .15,
              color: Color(0xFFBDB2A7),
              decoration: TextDecoration.underline,
              decorationColor: Color(0x66BDB2A7),
            ),
          ),
        ),
      ),
    );
  }
}
'''
weather.write_text(w)

specials = Path('lib/season_specials.dart')
sp = specials.read_text().replace(
    'const Rect.fromCenter(center: Offset.zero, width: 5.5, height: 9)',
    'Rect.fromCenter(center: Offset.zero, width: 5.5, height: 9)',
)
specials.write_text(sp)

app = Path('lib/cha_time_app.dart')
s = app.read_text()

calendar_old = """                  Text(
                    '${seasonStyle.label} · ${weatherStyle.label}',
                    style: TextStyle(
                      fontFamily: ChaTimeFonts.voice,
                      fontSize: 14,
                      color: const Color(0xFFA69D93),
                    ),
                  ),"""
calendar_new = """                  Column(
                    children: [
                      Text(
                        '${seasonStyle.label} · ${weatherStyle.label}',
                        style: TextStyle(
                          fontFamily: ChaTimeFonts.voice,
                          fontSize: 14,
                          color: const Color(0xFFA69D93),
                        ),
                      ),
                      if (widget.liveWeather.fromLiveData)
                        const WeatherAttribution(),
                    ],
                  ),"""
if app.read_text().count(calendar_old) != 1:
    raise SystemExit('calendar attribution target not found exactly once')
s = s.replace(calendar_old, calendar_new, 1)

session_old = """                    child: Text(
                      '${seasonStyle.label} · ${weatherStyle.label}',
                      style: TextStyle(
                        fontFamily: ChaTimeFonts.voice,
                        fontSize: 13,
                        color: const Color(0xFFB0A69B),
                      ),
                    ),"""
session_new = """                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${seasonStyle.label} · ${weatherStyle.label}',
                          style: TextStyle(
                            fontFamily: ChaTimeFonts.voice,
                            fontSize: 13,
                            color: const Color(0xFFB0A69B),
                          ),
                        ),
                        if (widget.liveWeather.fromLiveData)
                          const WeatherAttribution(),
                      ],
                    ),"""
if s.count(session_old) != 1:
    raise SystemExit('session attribution target not found exactly once')
s = s.replace(session_old, session_new, 1)
app.write_text(s)
