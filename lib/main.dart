import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const TeaApp());
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
      home: const TeaSessionScreen(),
    );
  }
}

enum SessionPhase {
  chatting,
  emptyCup,
  finished,
}

class TeaSessionScreen extends StatefulWidget {
  const TeaSessionScreen({super.key});

  @override
  State<TeaSessionScreen> createState() =>
      _TeaSessionScreenState();
}

class _TeaSessionScreenState extends State<TeaSessionScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  String _systemText = '오늘은 어떤 하루였어?';
  String _lastUserMessage = '';

  int _sipCount = 0;

  static const int _maxSips = 6;

  SessionPhase _phase =
      SessionPhase.chatting;

  int _typingGeneration = 0;

  static const List<String> _responses = [
    '그랬구나.',
    '그런 일이 있었구나.',
    '응, 듣고 있어.',
    '천천히 말해도 돼.',
    '(호로록)',
  ];

  @override
  void dispose() {
    _typingGeneration++;

    _controller.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  String get _today {
    final now = DateTime.now();

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

    return '${now.day} ${months[now.month - 1]}';
  }

  // ─────────────────────────────
  // Conversation
  //
  // USER
  // ↓
  // TEA LEVEL CHANGE
  // ↓
  // 300 ms
  // ↓
  // SYSTEM TYPEWRITER
  // ─────────────────────────────

  void _sendMessage() {
    if (_phase != SessionPhase.chatting) {
      return;
    }

    final text =
        _controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    final response =
        _responses[
          _random.nextInt(
            _responses.length,
          )
        ];

    final generation =
        ++_typingGeneration;

    setState(() {
      _lastUserMessage = text;
      _systemText = '';

      _sipCount = min(
        _maxSips,
        _sipCount + 1,
      );
    });

    _controller.clear();

    // Keep the typing surface stable during ordinary turns.
    _focusNode.requestFocus();

    // Give the tea image time to visibly change
    // before the system starts speaking.
    Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
      () {
        if (!mounted ||
            generation !=
                _typingGeneration) {
          return;
        }

        _typeSystemText(
          response,
          generation,
        );
      },
    );
  }

  Future<void> _typeSystemText(
    String text,
    int generation,
  ) async {
    final characters =
        text.runes.toList();

    for (
      var i = 0;
      i < characters.length;
      i++
    ) {
      final character =
          String.fromCharCode(
        characters[i],
      );

      final delay =
          _typingDelayFor(
        character,
      );

      await Future.delayed(
        Duration(
          milliseconds: delay,
        ),
      );

      if (!mounted ||
          generation !=
              _typingGeneration) {
        return;
      }

      setState(() {
        _systemText =
            String.fromCharCodes(
          characters.take(i + 1),
        );
      });
    }

    // Final sip:
    // last system response finishes,
    // rests briefly,
    // then only the two buttons remain.
    if (_sipCount ==
            _maxSips &&
        _phase ==
            SessionPhase.chatting &&
        generation ==
            _typingGeneration) {
      // The last response has finished.
      // Start closing the keyboard during the quiet hold,
      // then reveal only the choices.
      _focusNode.unfocus();

      await Future.delayed(
        const Duration(
          milliseconds: 280,
        ),
      );

      if (!mounted ||
          generation !=
              _typingGeneration) {
        return;
      }

      setState(() {
        _phase =
            SessionPhase.emptyCup;

        _systemText = '';
        _lastUserMessage = '';
      });
    }
  }

  int _typingDelayFor(
    String character,
  ) {
    if (character == '.' ||
        character == ',' ||
        character == '!' ||
        character == '?') {
      return 140 +
          _random.nextInt(70);
    }

    if (character == ' ') {
      return 45 +
          _random.nextInt(30);
    }

    return 75 +
        _random.nextInt(55);
  }

  // ─────────────────────────────
  // Tea ritual
  // ─────────────────────────────

  void _refillTea() {
    _typingGeneration++;

    _controller.clear();

    setState(() {
      // Refill is intentionally instant:
      // empty → full.
      _sipCount = 0;

      _phase =
          SessionPhase.chatting;

      _systemText = '';
      _lastUserMessage = '';
    });

    _focusNode.requestFocus();
  }

  void _finishSession() {
    _typingGeneration++;

    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _phase =
          SessionPhase.finished;

      _systemText = '';
      _lastUserMessage = '';
    });
  }

  // ─────────────────────────────
  // UI
  // ─────────────────────────────

  @override
  Widget build(
    BuildContext context,
  ) {
    final keyboardHeight =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    final keyboardOpen =
        keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset:
          false,
      body: SafeArea(
        child: Stack(
          children: [
            _buildDate(),

            _buildRitualArea(
              keyboardHeight,
              keyboardOpen,
            ),

            if (_phase ==
                SessionPhase.chatting)
              _buildInput(
                keyboardHeight,
                keyboardOpen,
              ),

            if (_phase ==
                SessionPhase.emptyCup)
              _buildEmptyCupActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDate() {
    return Positioned(
      left: 28,
      top: 22,
      child: Text(
        _today,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1.5,
          color:
              Color(0xFF81786F),
        ),
      ),
    );
  }

  Widget _buildRitualArea(
    double keyboardHeight,
    bool keyboardOpen,
  ) {
    final isEmptyCup =
        _phase == SessionPhase.emptyCup;

    return AnimatedPositioned(
      duration: const Duration(
        milliseconds: 220,
      ),
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
            // SYSTEM
            SizedBox(
              width: 290,
              height: 50,
              child: Center(
                child: Text(
                  _phase == SessionPhase.emptyCup
                      ? '잔이 비었어요'
                      : _systemText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.55,
                    fontWeight: FontWeight.w400,

                    // system은 계속 muted
                    color: Color(0xFF8E847B),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // TEA / CLOSING
            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 480,
              ),
              switchInCurve:
                  Curves.easeOutCubic,
              switchOutCurve:
                  Curves.easeInCubic,
              child: _phase ==
                      SessionPhase.finished
                  ? const ClosingTrace(
                      key: ValueKey(
                        'closing',
                      ),
                    )
                  : TeaBowl(
                      key: const ValueKey(
                        'tea',
                      ),
                      sipCount:
                          _sipCount,
                    ),
            ),

            // 컵 ↔ 사용자 발화 간격
            const SizedBox(
              height: 0,
            ),

            // USER
            SizedBox(
              width: 290,
              height: 50,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  child:
                      _lastUserMessage.isEmpty
                          ? const SizedBox
                              .shrink()
                          : Text(
                              _lastUserMessage,
                              key: ValueKey(
                                _lastUserMessage,
                              ),
                              textAlign:
                                  TextAlign.center,
                              maxLines: 3,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Color(
                                  0xFF514B45,
                                ),
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
        constraints:
            const BoxConstraints(
          minHeight: 52,
          maxHeight: 110,
        ),
        padding:
            const EdgeInsets.only(
          left: 18,
          right: 6,
        ),
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            28,
          ),
          border: Border.all(
            color:
                const Color(
              0xFFD9D1C7,
            ),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller:
                    _controller,
                focusNode:
                    _focusNode,
                cursorColor:
                    const Color(
                  0xFF81786F,
                ),
                minLines: 1,
                maxLines: 3,
                textInputAction:
                    TextInputAction
                        .send,
                onSubmitted: (_) {
                  _sendMessage();
                },
                style:
                    const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color:
                      Color(
                    0xFF514B45,
                  ),
                ),
                decoration:
                    const InputDecoration(
                  hintText:
                      '천천히 생각나는 대로',
                  hintStyle:
                      TextStyle(
                    color:
                        Color(
                      0xFFB8ADA3,
                    ),
                  ),
                  border:
                      InputBorder.none,
                  contentPadding:
                      EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed:
                  _sendMessage,
              icon: const Icon(
                Icons
                    .arrow_upward_rounded,
                size: 20,
                color:
                    Color(
                  0xFF81786F,
                ),
              ),
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

      // 기존보다 컵 쪽으로 올림
      bottom: 108,

      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: 1,
        ),
        duration: const Duration(
          milliseconds: 240,
        ),
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
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              child: FilledButton(
                onPressed:
                    _refillTea,
                style:
                    FilledButton.styleFrom(
                  elevation: 0,

                  // 아주 옅은 tea green
                  backgroundColor:
                      const Color(
                    0xFFE3E6D3,
                  ),

                  foregroundColor:
                      const Color(
                    0xFF625D55,
                  ),

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),

                  shape:
                      const StadiumBorder(),
                ),
                child: const Text(
                  '한 잔 더 마실래',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed:
                    _finishSession,
                style:
                    OutlinedButton
                        .styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF8E847B,
                  ),

                  side:
                      const BorderSide(
                    color: Color(
                      0xFFD9D1C7,
                    ),
                  ),

                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),

                  shape:
                      const StadiumBorder(),
                ),
                child: const Text(
                  '오늘 이만 마칠래',
                  style: TextStyle(
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

// ─────────────────────────────
// Tea visual
//
// 0 = full
// 1 = 5/6
// 2 = 4/6
// 3 = 3/6
// 4 = 2/6
// 5 = 1/6
// 6 = empty
// ─────────────────────────────

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
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 225,
      child: AnimatedSwitcher(
        duration:
            const Duration(
          milliseconds: 220,
        ),
        switchInCurve:
            Curves.easeOut,
        switchOutCurve:
            Curves.easeIn,
        child: Image.asset(
          _assetPath,
          key:
              ValueKey(
            _assetPath,
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────
// Closing
// ─────────────────────────────

class ClosingTrace
    extends StatefulWidget {
  const ClosingTrace({
    super.key,
  });

  @override
  State<ClosingTrace>
      createState() =>
          _ClosingTraceState();
}

class _ClosingTraceState
    extends State<ClosingTrace> {
  bool _showBlossom = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(
        milliseconds: 260,
      ),
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
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 225,
      height: 186,
      child: Stack(
        alignment:
            Alignment.center,
        children: [
          Image.asset(
            'assets/images/closing_saucer.png',
            width: 225,
            fit:
                BoxFit.contain,
          ),
          AnimatedOpacity(
            opacity:
                _showBlossom
                    ? 1
                    : 0,
            duration:
                const Duration(
              milliseconds: 350,
            ),
            curve:
                Curves.easeOut,
            child: Image.asset(
              'assets/images/trace_blossom.png',
              width: 30,
              fit:
                  BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
