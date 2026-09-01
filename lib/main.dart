import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TeaFonts.loadVoice();
  runApp(const TeaApp());
}

class TeaFonts {
  static const String voiceFamily = 'TeaVoice';
  static bool _voiceLoaded = false;

  static String? get voice =>
      _voiceLoaded ? voiceFamily : null;

  static Future<void> loadVoice() async {
    try {
      final manifest =
          await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );

      final candidates = manifest
          .listAssets()
          .where(
            (path) =>
                path.startsWith('assets/fonts/') &&
                (path.toLowerCase().endsWith('.ttf') ||
                    path.toLowerCase().endsWith('.otf')),
          )
          .toList();

      if (candidates.isEmpty) {
        return;
      }

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
      loader.addFont(
        rootBundle.load(candidates.first),
      );

      await loader.load();
      _voiceLoaded = true;
    } catch (error) {
      debugPrint(
        'Could not load Tea voice font: $error',
      );
    }
  }
}

class TeaApp extends StatelessWidget {
  const TeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tea',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
      ),
      home: const TeaCalendarHomeScreen(),
    );
  }
}

enum SessionPhase {
  chatting,
  emptyCup,
  finished,
}

class TeaSessionRecord {
  final String dateStarted;
  final String startedAt;
  final String? endedAt;
  final int sipCount;
  final int cupsServed;
  final bool finished;
  final String phase;
  final String systemText;
  final String lastUserMessage;

  const TeaSessionRecord({
    required this.dateStarted,
    required this.startedAt,
    required this.endedAt,
    required this.sipCount,
    required this.cupsServed,
    required this.finished,
    required this.phase,
    required this.systemText,
    required this.lastUserMessage,
  });

  factory TeaSessionRecord.fromJson(Map<String, dynamic> json) {
    return TeaSessionRecord(
      dateStarted: json['dateStarted'] as String,
      startedAt: json['startedAt'] as String,
      endedAt: json['endedAt'] as String?,
      sipCount: (json['sipCount'] as num?)?.toInt() ?? 0,
      cupsServed: (json['cupsServed'] as num?)?.toInt() ?? 1,
      finished: json['finished'] as bool? ?? false,
      phase: json['phase'] as String? ?? SessionPhase.chatting.name,
      systemText: json['systemText'] as String? ?? '',
      lastUserMessage: json['lastUserMessage'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateStarted': dateStarted,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'sipCount': sipCount,
      'cupsServed': cupsServed,
      'finished': finished,
      'phase': phase,
      'systemText': systemText,
      'lastUserMessage': lastUserMessage,
    };
  }
}

class TeaSessionScreen extends StatefulWidget {
  const TeaSessionScreen({super.key});

  @override
  State<TeaSessionScreen> createState() => _TeaSessionScreenState();
}

class _TeaSessionScreenState extends State<TeaSessionScreen> {
  static const String _storageKey = 'tea_sessions_v1';
  static const int _maxSips = 6;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  final Map<String, TeaSessionRecord> _sessions = {};
  Future<void> _saveQueue = Future<void>.value();

  String _systemText = '오늘은 어떤 하루였어?';
  String _lastUserMessage = '';

  int _sipCount = 0;
  int _cupsServed = 0;

  SessionPhase _phase = SessionPhase.chatting;

  String? _activeSessionDate;
  String? _startedAtIso;
  String? _endedAtIso;

  int _typingGeneration = 0;
  bool _isReady = false;
  bool _turnInProgress = false;

  static const List<String> _responses = [
    '그랬구나.',
    '그런 일이 있었구나.',
    '응, 듣고 있어.',
    '천천히 말해도 돼.',
    '(호로록)',
  ];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _typingGeneration++;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final raw = await _prefs.getString(_storageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          final rawSessions = decoded['sessions'];

          if (rawSessions is Map<String, dynamic>) {
            for (final entry in rawSessions.entries) {
              final value = entry.value;

              if (value is Map<String, dynamic>) {
                _sessions[entry.key] = TeaSessionRecord.fromJson(value);
              } else if (value is Map) {
                _sessions[entry.key] = TeaSessionRecord.fromJson(
                  Map<String, dynamic>.from(value),
                );
              }
            }
          }
        }
      }

      final today = _dateKey(DateTime.now());
      TeaSessionRecord? sessionToRestore;

      final unfinished = _sessions.values
          .where((session) => !session.finished)
          .toList()
        ..sort(
          (a, b) => DateTime.parse(a.startedAt).compareTo(
            DateTime.parse(b.startedAt),
          ),
        );

      if (unfinished.isNotEmpty) {
        sessionToRestore = unfinished.last;
      } else {
        sessionToRestore = _sessions[today];
      }

      if (sessionToRestore != null) {
        _restoreSession(sessionToRestore);
      }
    } catch (error) {
      debugPrint('Could not load tea session data: $error');
    }

    if (!mounted) return;

    setState(() {
      _isReady = true;
    });
  }

  void _restoreSession(TeaSessionRecord session) {
    _activeSessionDate = session.dateStarted;
    _startedAtIso = session.startedAt;
    _endedAtIso = session.endedAt;

    _sipCount = session.sipCount.clamp(0, _maxSips).toInt();
    _cupsServed = max(1, session.cupsServed);

    _phase = session.finished
        ? SessionPhase.finished
        : _phaseFromName(session.phase);

    _lastUserMessage = session.lastUserMessage;

    if (_phase == SessionPhase.finished) {
      _systemText = '내일 또 들러줘.';
      _lastUserMessage = '';
    } else if (_phase == SessionPhase.emptyCup) {
      _systemText = '';
      _lastUserMessage = '';
    } else if (session.systemText.isNotEmpty) {
      _systemText = session.systemText;
    } else if (_sipCount == 0) {
      _systemText = '오늘은 어떤 하루였어?';
    } else {
      _systemText = '';
    }
  }

  SessionPhase _phaseFromName(String value) {
    for (final phase in SessionPhase.values) {
      if (phase.name == value) {
        return phase;
      }
    }
    return SessionPhase.chatting;
  }

  void _ensureSessionStarted() {
    if (_activeSessionDate != null && _startedAtIso != null) {
      return;
    }

    final now = DateTime.now();

    _activeSessionDate = _dateKey(now);
    _startedAtIso = now.toIso8601String();
    _endedAtIso = null;
    _cupsServed = 1;
  }

  void _queueSave() {
    final activeDate = _activeSessionDate;
    final startedAt = _startedAtIso;

    if (activeDate == null || startedAt == null) {
      return;
    }

    final record = TeaSessionRecord(
      dateStarted: activeDate,
      startedAt: startedAt,
      endedAt: _endedAtIso,
      sipCount: _sipCount,
      cupsServed: max(1, _cupsServed),
      finished: _phase == SessionPhase.finished,
      phase: _phase.name,
      systemText: _systemText,
      lastUserMessage: _lastUserMessage,
    );

    _sessions[activeDate] = record;

    final payload = jsonEncode({
      'version': 1,
      'sessions': {
        for (final entry in _sessions.entries)
          entry.key: entry.value.toJson(),
      },
    });

    _saveQueue = _saveQueue.then((_) async {
      try {
        await _prefs.setString(_storageKey, payload);
      } catch (error) {
        debugPrint('Could not save tea session data: $error');
      }
    });
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String get _displayDate {
    final dateString = _activeSessionDate ?? _dateKey(DateTime.now());
    final parts = dateString.split('-');

    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '$day ${months[month - 1]}';
  }

  Future<void> _sendMessage() async {
    if (_phase != SessionPhase.chatting || _turnInProgress) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _ensureSessionStarted();

    final response = _responses[_random.nextInt(_responses.length)];
    final generation = ++_typingGeneration;

    // 1. The user's words arrive first and get a quiet moment on screen.
    setState(() {
      _lastUserMessage = text;
      _systemText = '';
      _turnInProgress = true;
    });

    _controller.clear();
    _focusNode.requestFocus();
    _queueSave();

    await Future.delayed(
      const Duration(milliseconds: 340),
    );

    if (!mounted || generation != _typingGeneration) return;

    // 2. Only then does the tea level change.
    setState(() {
      _sipCount = min(_maxSips, _sipCount + 1);
    });

    _queueSave();

    await Future.delayed(
      const Duration(milliseconds: 430),
    );

    if (!mounted || generation != _typingGeneration) return;

    // 3. After another small breath, the system begins speaking.
    await _typeSystemText(
      response,
      generation,
    );
  }

  Future<void> _typeSystemText(
    String text,
    int generation,
  ) async {
    final characters = text.runes.toList();

    for (var i = 0; i < characters.length; i++) {
      final character = String.fromCharCode(characters[i]);
      final delay = _typingDelayFor(character);

      await Future.delayed(
        Duration(milliseconds: delay),
      );

      if (!mounted || generation != _typingGeneration) return;

      setState(() {
        _systemText = String.fromCharCodes(
          characters.take(i + 1),
        );
      });
    }

    _queueSave();

    if (_sipCount == _maxSips &&
        _phase == SessionPhase.chatting &&
        generation == _typingGeneration) {
      _focusNode.unfocus();

      await Future.delayed(
        const Duration(milliseconds: 520),
      );

      if (!mounted || generation != _typingGeneration) return;

      setState(() {
        _phase = SessionPhase.emptyCup;
        _systemText = '';
        _lastUserMessage = '';
        _turnInProgress = false;
      });

      _queueSave();
      return;
    }

    if (mounted &&
        generation == _typingGeneration &&
        _phase == SessionPhase.chatting) {
      setState(() {
        _turnInProgress = false;
      });
    }
  }

  int _typingDelayFor(String character) {
    if (character == '.' ||
        character == ',' ||
        character == '!' ||
        character == '?') {
      return 190 + _random.nextInt(60);
    }

    if (character == ' ') {
      return 60 + _random.nextInt(40);
    }

    return 95 + _random.nextInt(55);
  }

  void _refillTea() {
    _typingGeneration++;
    _controller.clear();

    setState(() {
      _sipCount = 0;
      _cupsServed += 1;
      _phase = SessionPhase.chatting;
      _systemText = '';
      _lastUserMessage = '';
      _turnInProgress = false;
    });

    _queueSave();
    _focusNode.requestFocus();
  }

  Future<void> _finishSession() async {
    final generation = ++_typingGeneration;
    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _phase = SessionPhase.finished;
      _endedAtIso = DateTime.now().toIso8601String();
      _systemText = '';
      _lastUserMessage = '';
      _turnInProgress = false;
    });

    _queueSave();

    // Let the saucer and blossom settle before the goodbye line arrives.
    await Future.delayed(
      const Duration(milliseconds: 620),
    );

    if (!mounted ||
        generation != _typingGeneration ||
        _phase != SessionPhase.finished) {
      return;
    }

    setState(() {
      _systemText = '내일 또 들러줘.';
    });

    _queueSave();
  }


  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF7F2),
      );
    }

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            _buildDate(),
            _buildCalendarButton(),
            _buildRitualArea(
              keyboardHeight,
              keyboardOpen,
            ),
            if (_phase == SessionPhase.chatting)
              _buildInput(
                keyboardHeight,
                keyboardOpen,
              ),
            if (_phase == SessionPhase.emptyCup)
              _buildEmptyCupActions(),
          ],
        ),
      ),
    );
  }

  void _returnToCalendar() {
    _focusNode.unfocus();
    Navigator.of(context).pop();
  }

  Widget _buildCalendarButton() {
    return Positioned(
      top: 6,
      right: 10,
      child: _PngAssetButton(
        assetPath:
            'assets/ui/calendar_default.png',
        onTap: _returnToCalendar,
        semanticsLabel: 'Calendar',
        visualSize: 34,
        hitSize: 48,
      ),
    );
  }

  Widget _buildDate() {
    return Positioned(
      left: 28,
      top: 22,
      child: Text(
        _displayDate,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1.5,
          color: Color(0xFF81786F),
        ),
      ),
    );
  }

  Widget _buildRitualArea(
    double keyboardHeight,
    bool keyboardOpen,
  ) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      top: 78,
      bottom: keyboardOpen
          ? keyboardHeight + 38
          : 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 290,
              height: 50,
              child: Center(
                child: _phase == SessionPhase.finished
                    ? AnimatedOpacity(
                        opacity: _systemText.isEmpty ? 0 : 1,
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOut,
                        child: Text(
                          _systemText,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontFamily: TeaFonts.voice,
                            fontSize: 17,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF9A8F85),
                          ),
                        ),
                      )
                    : Text(
                        _phase == SessionPhase.emptyCup
                            ? '잔이 비었어요'
                            : _systemText,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: TeaFonts.voice,
                          fontSize: 17,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E847B),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _phase == SessionPhase.finished
                  ? const ClosingTrace(
                      key: ValueKey('closing'),
                    )
                  : TeaBowl(
                      key: const ValueKey('tea'),
                      sipCount: _sipCount,
                    ),
            ),
            const SizedBox(height: 0),
            SizedBox(
              width: 290,
              height: 50,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _lastUserMessage.isEmpty
                      ? const SizedBox.shrink()
                      : Text(
                          _lastUserMessage,
                          key: ValueKey(_lastUserMessage),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: TeaFonts.voice,
                            fontSize: 16,
                            height: 1.5,
                            color: const Color(0xFF514B45),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    double keyboardHeight,
    bool keyboardOpen,
  ) {
    return Positioned(
      left: 28,
      right: 28,
      bottom: keyboardOpen
          ? keyboardHeight + 14
          : 52,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 52,
          maxHeight: 110,
        ),
        padding: const EdgeInsets.only(
          left: 18,
          right: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFD9D1C7),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                cursorColor: const Color(0xFF81786F),
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  _sendMessage();
                },
                style: TextStyle(
                  fontFamily: TeaFonts.voice,
                  fontSize: 15,
                  height: 1.4,
                  color: const Color(0xFF514B45),
                ),
                decoration: InputDecoration(
                  hintText: '천천히 생각나는 대로',
                  hintStyle: TextStyle(
                    fontFamily: TeaFonts.voice,
                    color: const Color(
                      0xFFB8ADA3,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
            _PngAssetButton(
              assetPath:
                  'assets/ui/send_default.png',
              disabledAssetPath:
                  'assets/ui/send_disabled.png',
              onTap: _turnInProgress
                  ? null
                  : () {
                      _sendMessage();
                    },
              semanticsLabel: 'Send',
              visualSize: 48,
              hitSize: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCupActions() {
    return Positioned(
      left: 28,
      right: 28,
      bottom: 108,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (
          context,
          value,
          child,
        ) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(
                0,
                7 * (1 - value),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              child: FilledButton(
                onPressed: _refillTea,
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFE3E6D3),
                  foregroundColor: const Color(0xFF625D55),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '한 잔 더 마실래',
                  style: TextStyle(
                    fontFamily: TeaFonts.voice,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: _finishSession,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8E847B),
                  side: const BorderSide(
                    color: Color(0xFFD9D1C7),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '오늘 이만 마칠래',
                  style: TextStyle(
                    fontFamily: TeaFonts.voice,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class TeaBowl extends StatelessWidget {
  final int sipCount;

  const TeaBowl({
    super.key,
    required this.sipCount,
  });

  String get _assetPath {
    switch (sipCount) {
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
    return SizedBox(
      width: 225,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        child: Image.asset(
          _assetPath,
          key: ValueKey(_assetPath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class ClosingTrace extends StatefulWidget {
  const ClosingTrace({
    super.key,
  });

  @override
  State<ClosingTrace> createState() => _ClosingTraceState();
}

class _ClosingTraceState extends State<ClosingTrace> {
  bool _showBlossom = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 260),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _showBlossom = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 225,
      height: 186,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/closing_saucer.png',
            width: 225,
            fit: BoxFit.contain,
          ),
          AnimatedOpacity(
            opacity: _showBlossom ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: Image.asset(
              'assets/images/trace_blossom.png',
              width: 30,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────
// Calendar home
// ─────────────────────────────

class TeaCalendarHomeScreen extends StatefulWidget {
  const TeaCalendarHomeScreen({
    super.key,
  });

  @override
  State<TeaCalendarHomeScreen> createState() =>
      _TeaCalendarHomeScreenState();
}

class _TeaCalendarHomeScreenState
    extends State<TeaCalendarHomeScreen> {
  static const String _storageKey = 'tea_sessions_v1';

  final SharedPreferencesAsync _prefs =
      SharedPreferencesAsync();

  final Map<String, TeaSessionRecord> _sessions = {};

  late DateTime _visibleMonth;
  bool _isReady = false;

  static const List<String> _monthNames = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];

  static const List<String> _weekdays = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _visibleMonth = DateTime(
      now.year,
      now.month,
    );

    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final loaded = <String, TeaSessionRecord>{};

    try {
      final raw =
          await _prefs.getString(_storageKey);

      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);

        if (decoded is Map<String, dynamic>) {
          final rawSessions =
              decoded['sessions'];

          if (rawSessions
              is Map<String, dynamic>) {
            for (final entry
                in rawSessions.entries) {
              final value = entry.value;

              if (value
                  is Map<String, dynamic>) {
                loaded[entry.key] =
                    TeaSessionRecord.fromJson(
                  value,
                );
              } else if (value is Map) {
                loaded[entry.key] =
                    TeaSessionRecord.fromJson(
                  Map<String, dynamic>.from(
                    value,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (error) {
      debugPrint(
        'Could not load calendar data: $error',
      );
    }

    if (!mounted) return;

    setState(() {
      _sessions
        ..clear()
        ..addAll(loaded);

      _isReady = true;
    });
  }

  String get _monthTitle {
    return '${_monthNames[_visibleMonth.month - 1]} '
        '${_visibleMonth.year}';
  }

  String _dateKey(DateTime date) {
    final year =
        date.year.toString().padLeft(4, '0');
    final month =
        date.month.toString().padLeft(2, '0');
    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + 1,
      );
    });
  }

  Future<void> _openTodaySession() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const TeaSessionScreen(),
      ),
    );

    await _loadSessions();

    if (!mounted) return;

    final now = DateTime.now();

    setState(() {
      _visibleMonth = DateTime(
        now.year,
        now.month,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            28,
            6,
            28,
            24,
          ),
          child: Column(
            children: [
              _buildHeader(),

              const SizedBox(height: 12),

              _buildIllustrationWindow(),

              const SizedBox(height: 18),

              _buildWeekdays(),

              const SizedBox(height: 14),

              Expanded(
                child: _isReady
                    ? AnimatedSwitcher(
                        duration:
                            const Duration(
                          milliseconds: 180,
                        ),
                        switchInCurve:
                            Curves.easeOut,
                        switchOutCurve:
                            Curves.easeIn,
                        child:
                            _buildMonthGrid(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              _monthTitle,
              style: const TextStyle(
                fontSize: 15,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w400,
                color: Color(0xFF81786F),
              ),
            ),
          ),

          _MonthArrowButton(
            assetPath: 'assets/ui/calendar_prev_default.png',
            onPressed: _previousMonth,
          ),

          const SizedBox(width: 4),

          _MonthArrowButton(
            assetPath: 'assets/ui/calendar_next_default.png',
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildIllustrationWindow() {
    // Reserved breathing room for weather / seasonal motifs.
    // Keep this visually empty until the seasonal system is introduced.
    return const SizedBox(
      height: 96,
      width: double.infinity,
    );
  }

  Widget _buildWeekdays() {
    return Row(
      children: [
        for (final weekday in _weekdays)
          Expanded(
            child: Center(
              child: Text(
                weekday,
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: Color(0xFFB8ADA3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final leadingEmptyCells =
        firstDay.weekday - 1;

    final usedCells =
        leadingEmptyCells + daysInMonth;

    final rowCount =
        (usedCells / 7).ceil();

    final totalCells =
        rowCount * 7;

    return GridView.builder(
      key: ValueKey(
        '${_visibleMonth.year}-${_visibleMonth.month}',
      ),
      physics:
          const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio:
            rowCount <= 5 ? 0.78 : 0.92,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemCount: totalCells,
      itemBuilder: (
        context,
        index,
      ) {
        final day =
            index - leadingEmptyCells + 1;

        if (day < 1 ||
            day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          day,
        );

        final record =
            _sessions[_dateKey(date)];

        final isToday =
            _isToday(date);

        return _CalendarDayCell(
          date: date,
          record: record,
          isToday: isToday,
          onTap: isToday
              ? _openTodaySession
              : null,
        );
      },
    );
  }
}

class _MonthArrowButton
    extends StatelessWidget {
  final String assetPath;
  final VoidCallback onPressed;

  const _MonthArrowButton({
    required this.assetPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _PngAssetButton(
      assetPath: assetPath,
      onTap: onPressed,
      visualSize: 38,
      hitSize: 42,
    );
  }
}

class _PngAssetButton
    extends StatefulWidget {
  final String assetPath;
  final String? disabledAssetPath;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final double visualSize;
  final double hitSize;

  const _PngAssetButton({
    required this.assetPath,
    required this.onTap,
    required this.visualSize,
    required this.hitSize,
    this.disabledAssetPath,
    this.semanticsLabel,
  });

  @override
  State<_PngAssetButton> createState() =>
      _PngAssetButtonState();
}

class _PngAssetButtonState
    extends State<_PngAssetButton> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = !_enabled &&
            widget.disabledAssetPath != null
        ? widget.disabledAssetPath!
        : widget.assetPath;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: _enabled
            ? (_) => _setPressed(true)
            : null,
        onTapUp: _enabled
            ? (_) => _setPressed(false)
            : null,
        onTapCancel: _enabled
            ? () => _setPressed(false)
            : null,
        child: SizedBox(
          width: widget.hitSize,
          height: widget.hitSize,
          child: Center(
            child: AnimatedScale(
              scale: _pressed ? 0.94 : 1,
              duration: const Duration(
                milliseconds: 110,
              ),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _pressed ? 0.82 : 1,
                duration: const Duration(
                  milliseconds: 90,
                ),
                child: Image.asset(
                  imagePath,
                  width: widget.visualSize,
                  height: widget.visualSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarDayCell
    extends StatelessWidget {
  final DateTime date;
  final TeaSessionRecord? record;
  final bool isToday;
  final VoidCallback? onTap;

  const _CalendarDayCell({
    required this.date,
    required this.record,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final marker =
            _buildMarker(
          constraints.maxWidth,
        );

        final child = Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: isToday ? 0 : 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: isToday ? 29 : null,
                  height: isToday ? 29 : null,
                  alignment: Alignment.center,
                  decoration: isToday
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFE1E7CB,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFBEC99B,
                            ),
                            width: 1.1,
                          ),
                        )
                      : null,
                  child: Text(
                    '${date.day}',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: isToday
                          ? 12
                          : 11,
                      fontWeight: isToday
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isToday
                          ? const Color(
                              0xFF586047,
                            )
                          : const Color(
                              0xFFA69D93,
                            ),
                    ),
                  ),
                ),
              ),
            ),

            if (marker != null)
              Positioned(
                top:
                    constraints.maxHeight *
                        (isToday ? 0.48 : 0.38),
                left: 0,
                right: 0,
                child: Center(
                  child: marker,
                ),
              ),
          ],
        );

        if (onTap == null) {
          return child;
        }

        return InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(24),
          splashColor:
              Colors.transparent,
          highlightColor:
              Colors.transparent,
          child: child,
        );
      },
    );
  }

  Widget? _buildMarker(
    double cellWidth,
  ) {
    final session = record;

    if (session == null) {
      return null;
    }

    final seed =
        date.day +
        date.month * 31 +
        date.year;

    final dx =
        ((seed % 5) - 2) * 0.55;

    final dy =
        (((seed ~/ 3) % 5) - 2) *
        0.45;

    final rotation =
        (((seed % 7) - 3) * 0.018);

    final markerWidth =
        session.finished
            ? min(
                22.0,
                cellWidth * 0.43,
              )
            : min(
                19.0,
                cellWidth * 0.36,
              );

    return Transform.translate(
      offset: Offset(
        dx,
        dy,
      ),
      child: Transform.rotate(
        angle: rotation,
        child: Image.asset(
          session.finished
              ? 'assets/images/trace_blossom.png'
              : 'assets/images/status_raindrop.png',
          width: markerWidth,
          height: markerWidth,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

