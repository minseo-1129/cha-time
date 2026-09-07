import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'season_specials.dart';
import 'weather_context.dart';

const String kChaTimeName = 'cha-time';
const int kSipsPerCup = 6;

enum ChaSeason { spring, summer, rainy, autumn, winter }
enum ChaWeather { clear, cloudy, rain, snow }
enum ChaSessionPhase { session, empty, closing }

ChaSeason seasonForDate(DateTime date) {
  switch (date.month) {
    case 12:
    case 1:
    case 2:
      return ChaSeason.winter;
    case 3:
    case 4:
    case 5:
      return ChaSeason.spring;
    case 6:
    case 7:
    case 8:
      return ChaSeason.summer;
    default:
      return ChaSeason.autumn;
  }
}

ChaSeason seasonForContext(DateTime date, bool rainySpell) {
  return rainySpell ? ChaSeason.rainy : seasonForDate(date);
}

int relationshipStage(int visits) {
  if (visits <= 6) return 1;
  if (visits <= 20) return 2;
  return 3;
}

class ChaTimeFonts {
  static const String voiceFamily = 'ChaTimeVoice';
  static bool _loaded = false;

  static String? get voice => _loaded ? voiceFamily : null;

  static Future<void> loadVoice() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final candidates = manifest
          .listAssets()
          .where((path) =>
              path.startsWith('assets/fonts/') &&
              (path.toLowerCase().endsWith('.ttf') ||
                  path.toLowerCase().endsWith('.otf')))
          .toList();

      if (candidates.isEmpty) return;

      candidates.sort((a, b) {
        int score(String path) {
          final lower = path.toLowerCase();
          var value = 0;
          if (lower.contains('2025')) value -= 30;
          if (lower.contains('kyobo')) value -= 20;
          if (lower.endsWith('.ttf')) value -= 10;
          return value;
        }

        return score(a).compareTo(score(b));
      });

      final loader = FontLoader(voiceFamily);
      loader.addFont(rootBundle.load(candidates.first));
      await loader.load();
      _loaded = true;
    } catch (error) {
      debugPrint('Could not load cha-time voice font: $error');
    }
  }
}

class DayRecord {
  const DayRecord({
    required this.date,
    required this.finished,
    required this.sips,
    required this.cups,
    required this.fortune,
    required this.updatedAt,
    this.weather = '',
    this.season = '',
  });

  final String date;
  final bool finished;
  final int sips;
  final int cups;
  final String fortune;
  final String updatedAt;
  final String weather;
  final String season;

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      date: json['date'] as String,
      finished: json['finished'] as bool? ?? false,
      sips: (json['sips'] as num?)?.toInt() ?? 0,
      cups: (json['cups'] as num?)?.toInt() ?? 1,
      fortune: json['fortune'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      weather: json['weather'] as String? ?? '',
      season: json['season'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'finished': finished,
        'sips': sips,
        'cups': cups,
        'fortune': fortune,
        'updatedAt': updatedAt,
        'weather': weather,
        'season': season,
      };
}

class ChaSnapshot {
  const ChaSnapshot({required this.visits, required this.days});

  final int visits;
  final Map<String, DayRecord> days;
}

class ChaStore {
  static const String _key = 'cha_time_state_v2';
  static const String _legacyKey = 'tea_sessions_v1';

  static Future<ChaSnapshot> load() async {
    final prefs = SharedPreferencesAsync();

    try {
      final raw = await prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final days = <String, DayRecord>{};
          final rawDays = decoded['days'];
          if (rawDays is Map<String, dynamic>) {
            for (final entry in rawDays.entries) {
              final value = entry.value;
              if (value is Map<String, dynamic>) {
                days[entry.key] = DayRecord.fromJson(value);
              } else if (value is Map) {
                days[entry.key] =
                    DayRecord.fromJson(Map<String, dynamic>.from(value));
              }
            }
          }
          return ChaSnapshot(
            visits: (decoded['visits'] as num?)?.toInt() ?? 0,
            days: days,
          );
        }
      }
    } catch (error) {
      debugPrint('Could not load cha-time state: $error');
    }

    return _migrateLegacy(prefs);
  }

  static Future<ChaSnapshot> _migrateLegacy(SharedPreferencesAsync prefs) async {
    final days = <String, DayRecord>{};
    var visits = 0;

    try {
      final raw = await prefs.getString(_legacyKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final sessions = decoded['sessions'];
          if (sessions is Map<String, dynamic>) {
            for (final entry in sessions.entries) {
              final value = entry.value;
              if (value is! Map) continue;
              final map = Map<String, dynamic>.from(value);
              final finished = map['finished'] as bool? ?? false;
              final record = DayRecord(
                date: entry.key,
                finished: finished,
                sips: (map['sipCount'] as num?)?.toInt() ?? 0,
                cups: max(1, (map['cupsServed'] as num?)?.toInt() ?? 1),
                fortune: '',
                updatedAt: map['endedAt'] as String? ??
                    map['startedAt'] as String? ??
                    '',
              );
              days[entry.key] = record;
              if (finished) visits++;
            }
          }
        }
      }
    } catch (error) {
      debugPrint('Could not migrate old Tea state: $error');
    }

    final snapshot = ChaSnapshot(visits: visits, days: days);
    if (days.isNotEmpty) {
      await save(snapshot);
    }
    return snapshot;
  }

  static Future<void> save(ChaSnapshot snapshot) async {
    final prefs = SharedPreferencesAsync();
    final payload = jsonEncode({
      'version': 2,
      'visits': snapshot.visits,
      'days': {
        for (final entry in snapshot.days.entries)
          entry.key: entry.value.toJson(),
      },
    });
    await prefs.setString(_key, payload);
  }
}

class SeasonStyle {
  const SeasonStyle({
    required this.label,
    required this.paper,
    required this.teaTint,
    required this.steam,
  });

  final String label;
  final Color paper;
  final Color teaTint;
  final double steam;

  static SeasonStyle of(ChaSeason season) {
    switch (season) {
      case ChaSeason.spring:
        return const SeasonStyle(
          label: '봄',
          paper: Color(0xFFFAF7F2),
          teaTint: Color(0xFFFFFFFF),
          steam: .24,
        );
      case ChaSeason.summer:
        return const SeasonStyle(
          label: '여름',
          paper: Color(0xFFF7F9F3),
          teaTint: Color(0xFFE9F6D9),
          steam: .08,
        );
      case ChaSeason.rainy:
        return const SeasonStyle(
          label: '장마',
          paper: Color(0xFFF1F3F1),
          teaTint: Color(0xFFE6EEEA),
          steam: .18,
        );
      case ChaSeason.autumn:
        return const SeasonStyle(
          label: '가을',
          paper: Color(0xFFFAF4E9),
          teaTint: Color(0xFFF0D6AE),
          steam: .36,
        );
      case ChaSeason.winter:
        return const SeasonStyle(
          label: '겨울',
          paper: Color(0xFFF5F5F4),
          teaTint: Color(0xFFEBD9C6),
          steam: .52,
        );
    }
  }
}

class WeatherStyle {
  const WeatherStyle({
    required this.label,
    required this.steamMultiplier,
    required this.typingMultiplier,
  });

  final String label;
  final double steamMultiplier;
  final double typingMultiplier;

  static WeatherStyle of(ChaWeather weather) {
    switch (weather) {
      case ChaWeather.clear:
        return const WeatherStyle(
          label: '맑음',
          steamMultiplier: 1,
          typingMultiplier: 1,
        );
      case ChaWeather.cloudy:
        return const WeatherStyle(
          label: '흐림',
          steamMultiplier: 1.1,
          typingMultiplier: 1.05,
        );
      case ChaWeather.rain:
        return const WeatherStyle(
          label: '비',
          steamMultiplier: 1.25,
          typingMultiplier: 1.15,
        );
      case ChaWeather.snow:
        return const WeatherStyle(
          label: '눈',
          steamMultiplier: 1.4,
          typingMultiplier: 1.2,
        );
    }
  }
}

ChaWeather configuredWeather() {
  const raw = String.fromEnvironment(
    'CHA_TIME_WEATHER',
    defaultValue: 'clear',
  );
  return _weatherFromName(raw);
}

ChaWeather weatherForContext(WeatherContextData data) {
  const override = String.fromEnvironment('CHA_TIME_WEATHER', defaultValue: '');
  if (override.isNotEmpty) return _weatherFromName(override);
  switch (data.kind) {
    case LiveWeatherKind.cloudy:
      return ChaWeather.cloudy;
    case LiveWeatherKind.rain:
      return ChaWeather.rain;
    case LiveWeatherKind.snow:
      return ChaWeather.snow;
    case LiveWeatherKind.clear:
      return ChaWeather.clear;
  }
}

ChaWeather _weatherFromName(String raw) {
  switch (raw.toLowerCase()) {
    case 'cloudy':
      return ChaWeather.cloudy;
    case 'rain':
      return ChaWeather.rain;
    case 'snow':
      return ChaWeather.snow;
    default:
      return ChaWeather.clear;
  }
}

class VoicePack {
  const VoicePack({
    required this.open,
    required this.responses,
    required this.close,
    required this.cta,
  });

  final String open;
  final List<String> responses;
  final String close;
  final String cta;

  static VoicePack forStage(int stage) {
    switch (stage) {
      case 2:
        return const VoicePack(
          open: '왔네. 오늘은 어땠어?',
          responses: [
            '그래, 그런 날도 있지.',
            '(호로록) 애썼네.',
            '음… 조금 더 들어볼까.',
            '그 말, 오래 참았구나.',
            '오늘은 목소리가 낮네.',
            '그럴 만했네.',
          ],
          close: '오늘도 잘 마쳤네.',
          cta: '오늘의 잔',
        );
      case 3:
        return const VoicePack(
          open: '자네구먼. 앉아.',
          responses: [
            '자네도 참.',
            '그럼, 그럴 수 있지.',
            '(호로록) 오래 왔네, 자네.',
            '말 안 해도 알겠어.',
            '……',
            '자네 얘기는 늘 뒤가 있지.',
          ],
          close: '가서 푹 쉬어, 자네.',
          cta: '자네 자리, 그대로 있어',
        );
      default:
        return const VoicePack(
          open: '오늘은 어떤 하루였어?',
          responses: [
            '그랬구나.',
            '응, 듣고 있어.',
            '천천히 말해도 돼.',
            '(호로록)',
            '그럴 수 있지.',
            '음, 그래.',
          ],
          close: '내일 또 들러줘.',
          cta: '오늘 한 잔 마시기',
        );
    }
  }
}

const List<String> fortuneFallbacks = [
  '오늘 한 말은 여기 두고 가.',
  '서둘러 답을 찾지 않아도 돼.',
  '내일의 자네가 알아서 할 거야.',
  '잘 지나간 하루도 하루야.',
  '한 모금씩이면 충분해.',
  '애쓴 건 자네만 알아도 돼.',
];

class ChaTimeApp extends StatelessWidget {
  const ChaTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: kChaTimeName,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
      ),
      home: WeatherContextBuilder(
        builder: (context, weather) => ChaCalendarScreen(liveWeather: weather),
      ),
    );
  }
}

class ChaCalendarScreen extends StatefulWidget {
  const ChaCalendarScreen({super.key, required this.liveWeather});

  final WeatherContextData liveWeather;

  @override
  State<ChaCalendarScreen> createState() => _ChaCalendarScreenState();
}

class _ChaCalendarScreenState extends State<ChaCalendarScreen> {
  late DateTime _visibleMonth;
  ChaSnapshot _snapshot = const ChaSnapshot(visits: 0, days: {});
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    final snapshot = await ChaStore.load();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _ready = true;
    });
  }

  Future<void> _openToday() async {
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
  }

  Future<void> _openPast(DayRecord record) async {
    if (!record.finished || record.fortune.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FortuneScreen(
          dateKey: record.date,
          text: record.fortune,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final season = seasonForContext(now, widget.liveWeather.rainySpell);
    final seasonStyle = SeasonStyle.of(season);
    final weather = weatherForContext(widget.liveWeather);
    final weatherStyle = WeatherStyle.of(weather);
    final special = seasonSpecialFor(seasonStyle.label, weatherStyle.label);
    final paper = specialPaper(seasonStyle.paper, special);
    final stage = relationshipStage(_snapshot.visits);
    final voice = VoicePack.forStage(stage);

    return Scaffold(
      backgroundColor: paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'design/tex/paper_soft.png',
              repeat: ImageRepeat.repeat,
              opacity: const AlwaysStoppedAnimation(.42),
              fit: BoxFit.none,
            ),
          ),
          Positioned.fill(
            child: SeasonWeatherWash(
              weather: weatherStyle.label,
              special: special,
            ),
          ),
          SeasonAmbientParticles(
            weather: weatherStyle.label,
            special: special,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Column(
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
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 152,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 112,
                          height: 76,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                top: 0,
                                child: Steam(
                                  opacity: min(
                                    .72,
                                    specialSteam(
                                      seasonStyle.steam,
                                      weatherStyle.steamMultiplier,
                                      special,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Transform.scale(
                                  scale: specialBowlScale(special),
                                  child: TeaBowlImage(
                                    sipCount: 0,
                                    season: season,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _openToday,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6E6259),
                            side: const BorderSide(color: Color(0xFFDCD3C6)),
                            backgroundColor: const Color(0x66FFFFFF),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            '${voice.cta}  →',
                            style: TextStyle(
                              fontFamily: ChaTimeFonts.voice,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWeekdays(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _ready ? _buildMonthGrid() : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFEAE2D6)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend('assets/images/trace_blossom.png', '마친 날', 13),
                        const SizedBox(width: 16),
                        _legend('assets/images/status_raindrop.png', '남겨둔 날', 10),
                        const SizedBox(width: 16),
                        Text(
                          '${_snapshot.visits}번째 잔',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFC2B8AC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const names = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${names[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: 2.2,
                color: Color(0xFF81786F),
              ),
            ),
          ),
          PngButton(
            assetPath: 'assets/ui/calendar_prev_default.png',
            visualSize: 34,
            hitSize: 40,
            onTap: () => setState(() {
              _visibleMonth = DateTime(
                _visibleMonth.year,
                _visibleMonth.month - 1,
              );
            }),
          ),
          PngButton(
            assetPath: 'assets/ui/calendar_next_default.png',
            visualSize: 34,
            hitSize: 40,
            onTap: () => setState(() {
              _visibleMonth = DateTime(
                _visibleMonth.year,
                _visibleMonth.month + 1,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdays() {
    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAE2D6))),
      ),
      child: Row(
        children: [
          for (final day in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
            Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBDB2A7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final lead = first.weekday - 1;
    final rows = ((lead + daysInMonth) / 7).ceil();
    final total = rows * 7;
    final todayKey = dateKey(DateTime.now());

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: rows <= 5 ? .78 : .92,
      ),
      itemCount: total,
      itemBuilder: (context, index) {
        final day = index - lead + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
        final key = dateKey(date);
        final record = _snapshot.days[key];
        final isToday = key == todayKey;
        final canOpenPast =
            record?.finished == true && (record?.fortune.isNotEmpty ?? false);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isToday
              ? _openToday
              : canOpenPast
                  ? () => _openPast(record!)
                  : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Container(
                width: isToday ? 29 : null,
                height: 29,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE1E7CB),
                        border: Border.all(color: const Color(0xFFBEC99B)),
                      )
                    : null,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: isToday ? 12 : 11.5,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w300,
                    color: isToday
                        ? const Color(0xFF586047)
                        : date.isAfter(DateTime.now())
                            ? const Color(0xFFD2C9BE)
                            : const Color(0xFFA69D93),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              if (record != null) _recordMarker(record, date),
            ],
          ),
        );
      },
    );
  }

  Widget _recordMarker(DayRecord record, DateTime date) {
    if (!record.finished) {
      return Image.asset(
        'assets/images/status_raindrop.png',
        width: 13,
        height: 13,
        fit: BoxFit.contain,
        opacity: const AlwaysStoppedAnimation(.88),
      );
    }
    final season = record.season.isNotEmpty
        ? record.season
        : SeasonStyle.of(seasonForDate(date)).label;
    final weather = WeatherStyle.of(_weatherFromName(record.weather)).label;
    final special = seasonSpecialFor(season, weather);
    return Opacity(
      opacity: .88,
      child: SeasonClosingTrace(special: special, size: 19),
    );
  }

  Widget _legend(String asset, String label, double size) {
    return Row(
      children: [
        Image.asset(asset, width: size, height: size),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFFB0A69B)),
        ),
      ],
    );
  }
}

class ChaSessionScreen extends StatefulWidget {
  const ChaSessionScreen({
    super.key,
    required this.initialSnapshot,
    required this.liveWeather,
  });

  final ChaSnapshot initialSnapshot;
  final WeatherContextData liveWeather;

  @override
  State<ChaSessionScreen> createState() => _ChaSessionScreenState();
}

class _ChaSessionScreenState extends State<ChaSessionScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  late ChaSnapshot _snapshot;
  late int _stage;
  late VoicePack _voice;
  late ChaSeason _season;
  late ChaWeather _weather;
  late SeasonSpecialKind _special;

  int _sips = 0;
  int _visualSips = 0;
  int _cups = 1;
  int _typingGeneration = 0;
  int _reactionNonce = 0;
  String _teaLine = '';
  String _userLine = '';
  String _fortune = '';
  bool _busy = true;
  bool _showBlossom = false;
  bool _showHint = false;
  ChaSessionPhase _phase = ChaSessionPhase.session;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    _stage = relationshipStage(_snapshot.visits);
    _voice = VoicePack.forStage(_stage);
    _season = seasonForContext(DateTime.now(), widget.liveWeather.rainySpell);
    _weather = weatherForContext(widget.liveWeather);
    _special = seasonSpecialFor(
      SeasonStyle.of(_season).label,
      WeatherStyle.of(_weather).label,
    );

    final record = _snapshot.days[dateKey(DateTime.now())];
    if (record != null && !record.finished) {
      _sips = record.sips.clamp(0, kSipsPerCup).toInt();
      _visualSips = _sips;
      _cups = max(1, record.cups);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void dispose() {
    _typingGeneration++;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final generation = ++_typingGeneration;
    setState(() {
      _teaLine = '';
      _busy = true;
    });
    await Future.delayed(const Duration(milliseconds: 620));
    if (!mounted || generation != _typingGeneration) return;
    await _type(_openingLine(), generation);
    if (!mounted || generation != _typingGeneration) return;
    setState(() => _busy = false);
  }

  String _openingLine() {
    final combo =
        '${SeasonStyle.of(_season).label}:${WeatherStyle.of(_weather).label}';
    const special = {
      '봄:비': '꽃 다 지겠다.',
      '봄:눈': '늦눈이구나. 앉아.',
      '여름:비': '한바탕 쏟아졌네.',
      '장마:맑음': '오늘은 개었네.',
      '가을:비': '비 오니 춥지.',
      '겨울:맑음': '햇빛이 얇네.',
      '겨울:눈': '눈 오는 날은 조용하지.',
    };
    return special[combo] ?? _voice.open;
  }

  Future<void> _send() async {
    if (_busy || _phase != ChaSessionPhase.session) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _sips >= kSipsPerCup) return;

    final generation = ++_typingGeneration;
    setState(() {
      _userLine = text;
      _teaLine = '';
      _busy = true;
      _reactionNonce++;
    });
    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 340));
    if (!mounted || generation != _typingGeneration) return;

    setState(() {
      _sips = min(kSipsPerCup, _sips + 1);
      _visualSips = _sips;
    });
    await _persist(finished: false);

    await Future.delayed(const Duration(milliseconds: 430));
    if (!mounted || generation != _typingGeneration) return;

    final line = _voice.responses[_random.nextInt(_voice.responses.length)];
    await _type(line, generation);
    if (!mounted || generation != _typingGeneration) return;

    if (_sips >= kSipsPerCup) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted || generation != _typingGeneration) return;
      _focusNode.unfocus();
      setState(() {
        _phase = ChaSessionPhase.empty;
        _teaLine = '잔이 비었어요';
        _userLine = '';
        _busy = false;
      });
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _refill() async {
    final generation = ++_typingGeneration;
    setState(() {
      _busy = true;
      _teaLine = '';
      _userLine = '';
      _visualSips = kSipsPerCup;
    });

    for (final step in const [(140, 4), (170, 2), (180, 0)]) {
      await Future.delayed(Duration(milliseconds: step.$1));
      if (!mounted || generation != _typingGeneration) return;
      setState(() => _visualSips = step.$2);
    }

    setState(() {
      _sips = 0;
      _cups += 1;
      _phase = ChaSessionPhase.session;
    });
    await _persist(finished: false);

    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted || generation != _typingGeneration) return;
    await _type(
      _stage == 3 ? '그래, 더 앉아 있어.' : '한 잔 더 우렸어.',
      generation,
    );
    if (!mounted || generation != _typingGeneration) return;
    setState(() => _busy = false);
    _focusNode.requestFocus();
  }

  Future<void> _finish() async {
    final generation = ++_typingGeneration;
    _focusNode.unfocus();

    setState(() {
      _phase = ChaSessionPhase.closing;
      _busy = true;
      _teaLine = '';
      _userLine = '';
      _showBlossom = false;
      _showHint = false;
    });

    await Future.delayed(const Duration(milliseconds: 560));
    if (!mounted || generation != _typingGeneration) return;
    setState(() => _showBlossom = true);

    _fortune = fortuneFallbacks[_random.nextInt(fortuneFallbacks.length)];
    await _persist(finished: true, fortune: _fortune);

    await _type(_voice.close, generation);
    if (!mounted || generation != _typingGeneration) return;

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted || generation != _typingGeneration) return;
    setState(() {
      _showHint = true;
      _busy = false;
    });
  }

  Future<void> _persist({required bool finished, String fortune = ''}) async {
    final key = dateKey(DateTime.now());
    final previous = _snapshot.days[key];
    final days = Map<String, DayRecord>.from(_snapshot.days);
    final record = DayRecord(
      date: key,
      finished: finished,
      sips: _sips,
      cups: _cups,
      fortune: fortune.isNotEmpty ? fortune : previous?.fortune ?? '',
      updatedAt: DateTime.now().toIso8601String(),
      weather: _weather.name,
      season: SeasonStyle.of(_season).label,
    );
    days[key] = record;

    var visits = _snapshot.visits;
    if (finished && previous?.finished != true) visits += 1;

    _snapshot = ChaSnapshot(visits: visits, days: days);
    await ChaStore.save(_snapshot);
  }

  Future<void> _type(String text, int generation) async {
    final chars = text.runes.toList();
    final multiplier = WeatherStyle.of(_weather).typingMultiplier;

    for (var i = 0; i < chars.length; i++) {
      final char = String.fromCharCode(chars[i]);
      var delay = 92 + _random.nextInt(53);
      if (char == ' ') delay = 60 + _random.nextInt(41);
      if ('.,!?'.contains(char)) delay = 190 + _random.nextInt(61);
      await Future.delayed(
        Duration(milliseconds: (delay * multiplier).round()),
      );
      if (!mounted || generation != _typingGeneration) return;
      setState(() {
        _teaLine = String.fromCharCodes(chars.take(i + 1));
      });
    }
  }

  Future<void> _openFortune() async {
    if (_fortune.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FortuneScreen(
          dateKey: dateKey(DateTime.now()),
          text: _fortune,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasonStyle = SeasonStyle.of(_season);
    final weatherStyle = WeatherStyle.of(_weather);
    final paper = specialPaper(seasonStyle.paper, _special);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'design/tex/paper_soft.png',
              repeat: ImageRepeat.repeat,
              opacity: const AlwaysStoppedAnimation(.42),
              fit: BoxFit.none,
            ),
          ),
          Positioned.fill(
            child: SeasonWeatherWash(
              weather: weatherStyle.label,
              special: _special,
            ),
          ),
          SeasonAmbientParticles(
            weather: weatherStyle.label,
            special: _special,
            reducedOpacity: keyboardOpen,
          ),
          if (_reactionNonce > 0)
            SendMomentOverlay(
              key: ValueKey(_reactionNonce),
              weather: _weather,
            ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 36,
                  left: 28,
                  child: Text(
                    shortDate(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.6,
                      color: Color(0xFF9A9088),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 10,
                  child: PngButton(
                    assetPath: 'assets/ui/calendar_default.png',
                    visualSize: 32,
                    hitSize: 46,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
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
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 104,
                  bottom: keyboardOpen ? keyboardHeight + 128 : 150,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 300,
                          height: 58,
                          child: Center(
                            child: Text(
                              _teaLine,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: ChaTimeFonts.voice,
                                fontSize: 18,
                                height: 1.55,
                                color: const Color(0xFF7E756C),
                              ),
                            ),
                          ),
                        ),
                        if (_phase != ChaSessionPhase.closing)
                          SizedBox(
                            width: 236,
                            height: 205,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned(
                                  top: 0,
                                  child: Steam(
                                    opacity: _visualSips >= kSipsPerCup
                                        ? 0
                                        : min(
                                            .8,
                                            specialSteam(
                                              seasonStyle.steam,
                                              weatherStyle.steamMultiplier,
                                              _special,
                                            ),
                                          ),
                                  ),
                                ),
                                Transform.scale(
                                  scale: specialBowlScale(_special),
                                  child: TeaBowlImage(
                                    sipCount: _visualSips,
                                    season: _season,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _showBlossom ? _openFortune : null,
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox(
                              width: 236,
                              height: 205,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/closing_saucer.png',
                                    width: 230,
                                  ),
                                  AnimatedOpacity(
                                    opacity: _showBlossom ? 1 : 0,
                                    duration: const Duration(milliseconds: 380),
                                    child: SeasonClosingTrace(
                                      special: _special,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 300,
                          height: 58,
                          child: Center(
                            child: Text(
                              _userLine,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: ChaTimeFonts.voice,
                                fontSize: 16,
                                height: 1.5,
                                color: const Color(0xFF514B45),
                              ),
                            ),
                          ),
                        ),
                        if (_phase == ChaSessionPhase.closing)
                          AnimatedOpacity(
                            opacity: _showHint ? 1 : 0,
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              '벚꽃을 누르면, 내일 기억할 한 마디',
                              style: TextStyle(
                                fontFamily: ChaTimeFonts.voice,
                                fontSize: 14,
                                color: const Color(0xFFB4A99E),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_phase == ChaSessionPhase.session)
                  Positioned(
                    left: 26,
                    right: 26,
                    bottom: keyboardOpen ? keyboardHeight + 14 : 48,
                    child: _input(),
                  ),
                if (_phase == ChaSessionPhase.empty)
                  Positioned(
                    left: 26,
                    right: 26,
                    bottom: 74,
                    child: _emptyActions(),
                  ),
                if (_phase == ChaSessionPhase.closing)
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _input() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56, maxHeight: 112),
      padding: const EdgeInsets.only(left: 20, right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDCD3C6)),
        color: const Color(0x57FFFFFF),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !_busy,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              cursorColor: const Color(0xFF81786F),
              style: TextStyle(
                fontFamily: ChaTimeFonts.voice,
                fontSize: 16,
                color: const Color(0xFF514B45),
              ),
              decoration: InputDecoration(
                hintText: '천천히 생각나는 대로',
                hintStyle: TextStyle(
                  fontFamily: ChaTimeFonts.voice,
                  color: const Color(0xFFB8ADA3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          PngButton(
            assetPath: 'assets/ui/send_default.png',
            disabledAssetPath: 'assets/ui/send_disabled.png',
            visualSize: 46,
            hitSize: 52,
            onTap: _busy ? null : _send,
          ),
        ],
      ),
    );
  }

  Widget _emptyActions() {
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
}

class FortuneScreen extends StatelessWidget {
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

    return Scaffold(
      backgroundColor: const Color(0xFF8A8078),
      body: SafeArea(
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
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '접어두기',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: .6,
                      color: Color(0xFFF3EDE3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TeaBowlImage extends StatelessWidget {
  const TeaBowlImage({
    super.key,
    required this.sipCount,
    required this.season,
  });

  final int sipCount;
  final ChaSeason season;

  String get path {
    switch (sipCount.clamp(0, kSipsPerCup).toInt()) {
      case 0:
        return 'assets/images/tea_bowl_v1.png';
      case 1:
        return 'assets/images/tea_bowl_5of6.png';
      case 2:
        return 'assets/images/tea_bowl_4of6.png';
      case 3:
        return 'assets/images/tea_bowl_3of6.png';
      case 4:
        return 'assets/images/tea_bowl_2of6.png';
      case 5:
        return 'assets/images/tea_bowl_1of6.png';
      default:
        return 'assets/images/tea_bowl_empty.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tint = SeasonStyle.of(season).teaTint;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: ColorFiltered(
        key: ValueKey(path),
        colorFilter: ColorFilter.mode(
          tint.withValues(alpha: .22),
          BlendMode.modulate,
        ),
        child: Image.asset(path, width: 236, fit: BoxFit.contain),
      ),
    );
  }
}

class Steam extends StatefulWidget {
  const Steam({super.key, required this.opacity});

  final double opacity;

  @override
  State<Steam> createState() => _SteamState();
}

class _SteamState extends State<Steam> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: widget.opacity.clamp(0, 1),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 78,
            height: 66,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _steamLine(18, 30, 0),
                _steamLine(38, 44, .28),
                _steamLine(57, 26, .58),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _steamLine(double left, double height, double phase) {
    final t = (_controller.value + phase) % 1;
    final opacity = sin(pi * t).clamp(0, 1).toDouble();
    return Positioned(
      left: left,
      bottom: 2 + 22 * t,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 4,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00FFFFFF), Color(0xB8999088)],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherWash extends StatelessWidget {
  const WeatherWash({super.key, required this.weather});

  final ChaWeather weather;

  @override
  Widget build(BuildContext context) {
    Gradient gradient;
    switch (weather) {
      case ChaWeather.clear:
        gradient = const RadialGradient(
          center: Alignment(.5, -.9),
          radius: 1.25,
          colors: [Color(0x80FFF4D6), Color(0x00FFF4D6)],
        );
        break;
      case ChaWeather.cloudy:
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0x4DCED1CE), Color(0x00CED1CE)],
        );
        break;
      case ChaWeather.rain:
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0x66B2BEC1), Color(0x0DB2BEC1)],
        );
        break;
      case ChaWeather.snow:
        gradient = const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xA8FFFFFF), Color(0x14ECF1F6)],
        );
        break;
    }

    return IgnorePointer(
      child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
    );
  }
}

class AmbientParticles extends StatefulWidget {
  const AmbientParticles({
    super.key,
    required this.weather,
    this.reducedOpacity = false,
  });

  final ChaWeather weather;
  final bool reducedOpacity;

  @override
  State<AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<AmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather != ChaWeather.rain &&
        widget.weather != ChaWeather.snow) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: widget.reducedOpacity ? .2 : .4,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: ParticlePainter(
              progress: _controller.value,
              snow: widget.weather == ChaWeather.snow,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter({required this.progress, required this.snow});

  final double progress;
  final bool snow;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = snow ? 2 : 1.2
      ..color = snow
          ? const Color(0x99FFFFFF)
          : const Color(0x66829AA4);

    const count = 11;
    for (var i = 0; i < count; i++) {
      final seed = (i * 0.137 + .08) % 1;
      final x = size.width * ((seed * 7.3) % 1);
      final y = size.height * ((progress + seed) % 1);
      if (snow) {
        canvas.drawCircle(
          Offset(x + 18 * sin((progress + i) * pi * 2), y),
          2 + (i % 3),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 2, y + 11 + (i % 3) * 3),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.snow != snow;
}

class SendMomentOverlay extends StatefulWidget {
  const SendMomentOverlay({super.key, required this.weather});

  final ChaWeather weather;

  @override
  State<SendMomentOverlay> createState() => _SendMomentOverlayState();
}

class _SendMomentOverlayState extends State<SendMomentOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.weather == ChaWeather.snow ? 900 : 700,
      ),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weather == ChaWeather.cloudy) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final fade = sin(pi * _controller.value).clamp(0, 1).toDouble();
          if (widget.weather == ChaWeather.rain) {
            return Center(
              child: CustomPaint(
                size: const Size(180, 180),
                painter: RipplePainter(
                  progress: _controller.value,
                  opacity: fade,
                ),
              ),
            );
          }
          return Opacity(
            opacity: fade * (widget.weather == ChaWeather.clear ? .13 : .08),
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  RipplePainter({required this.progress, required this.opacity});

  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color.fromRGBO(120, 145, 150, opacity * .55);
    canvas.drawCircle(
      size.center(Offset.zero),
      12 + 58 * progress,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

class PngButton extends StatefulWidget {
  const PngButton({
    super.key,
    required this.assetPath,
    required this.visualSize,
    required this.hitSize,
    required this.onTap,
    this.disabledAssetPath,
  });

  final String assetPath;
  final String? disabledAssetPath;
  final double visualSize;
  final double hitSize;
  final VoidCallback? onTap;

  @override
  State<PngButton> createState() => _PngButtonState();
}

class _PngButtonState extends State<PngButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final path = !enabled && widget.disabledAssetPath != null
        ? widget.disabledAssetPath!
        : widget.assetPath;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: SizedBox(
        width: widget.hitSize,
        height: widget.hitSize,
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? .94 : 1,
            duration: const Duration(milliseconds: 110),
            child: AnimatedOpacity(
              opacity: _pressed ? .82 : 1,
              duration: const Duration(milliseconds: 90),
              child: Image.asset(
                path,
                width: widget.visualSize,
                height: widget.visualSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String shortDate(DateTime date) {
  const mon = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  return '${date.day} ${mon[date.month - 1]}';
}
