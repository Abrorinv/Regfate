import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});
  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final AnimationController _hintCtrl;
  late final Animation<double> _hintAnim;
  late final AnimationController _tickCtrl;
  bool _hintDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _hintAnim = Tween<double>(
      begin: -0.15,
      end: 0.15,
    ).animate(CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut));
    _hintCtrl.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hintCtrl.stop();
        setState(() => _hintDone = true);
      }
    });

    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.removeObserver(this);
    _hintCtrl.dispose();
    _tickCtrl.dispose();
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 1, 1, 4),

      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _tickCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _Clock24Painter(now: DateTime.now()),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Container(width: 0.5, color: const Color(0xFF14142A)),
              const Expanded(child: YearlyDiagram()),
            ],
          ),

          if (!_hintDone)
            Positioned(
              right: 16,
              bottom: 12,
              child: AnimatedBuilder(
                animation: _hintAnim,
                builder: (_, child) =>
                    Transform.rotate(angle: _hintAnim.value, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1E1E38),
                      width: 0.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.screen_rotation_outlined,
                        color: Color(0xFF3A3A6A),
                        size: 17,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'landscape',
                        style: TextStyle(
                          color: Color.fromARGB(255, 72, 72, 130),
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white38),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Clock24Painter extends CustomPainter {
  final DateTime now;
  const _Clock24Painter({required this.now});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final c = Offset(cx, cy);
    final R = math.min(cx, cy) * 0.80;

    canvas.drawCircle(
      c,
      R,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: const [
            Color.fromARGB(103, 27, 27, 85),
            Color.fromARGB(80, 14, 14, 40),
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );

    canvas.drawCircle(
      c,
      R,
      Paint()
        ..color = const Color(0xFF1A1A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.drawCircle(
      c,
      R * 0.88,
      Paint()
        ..color = const Color.fromARGB(255, 20, 20, 43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    for (int h = 0; h < 24; h++) {
      final angle = -math.pi / 2 + h * (2 * math.pi / 24);
      final isMain = h % 6 == 0;
      final isMid = h % 3 == 0;

      final r1 = isMain
          ? R * 0.68
          : isMid
          ? R * 0.78
          : R * 0.84;
      final r2 = R * 0.88;

      final col = isMain
          ? const Color.fromARGB(255, 90, 90, 157)
          : isMid
          ? const Color.fromARGB(255, 82, 82, 166)
          : const Color.fromARGB(255, 89, 89, 184);
      final sw = isMain
          ? 1.2
          : isMid
          ? 0.7
          : 0.4;

      canvas.drawLine(
        Offset(cx + r1 * math.cos(angle), cy + r1 * math.sin(angle)),
        Offset(cx + r2 * math.cos(angle), cy + r2 * math.sin(angle)),
        Paint()
          ..color = col
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );

      if (isMain) {
        final label = h == 0 ? '24' : '$h';
        final lr = R * 0.58;
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color.fromARGB(255, 58, 106, 61),
              fontSize: 21,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            cx + lr * math.cos(angle) - tp.width / 2,
            cy + lr * math.sin(angle) - tp.height / 2,
          ),
        );
      }
    }

    final dayProg =
        (now.hour * 3600 + now.minute * 60 + now.second) / (24 * 3600);

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: R * 0.78),
      -math.pi / 2,
      dayProg * 2 * math.pi,
      false,
      Paint()
        ..color = const Color.fromARGB(255, 58, 58, 126)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    final minAngle =
        -math.pi / 2 + (now.minute + now.second / 60) * (2 * math.pi / 60);
    _hand(
      canvas,
      c,
      minAngle,
      R * 0.70,
      R * 0.009,
      const Color.fromARGB(255, 70, 70, 149),
    );

    final hrAngle =
        -math.pi / 2 +
        (now.hour + now.minute / 60 + now.second / 3600) * (2 * math.pi / 24);
    _hand(canvas, c, hrAngle, R * 0.50, R * 0.013, const Color(0xFF5555AA));

    /*
    final secAngle = -math.pi / 2 + now.second * (2 * math.pi / 60);
    _hand(canvas, c, secAngle, R * 0.76, R * 0.004, const Color(0xFF64B5F6));
    // Хвост
    _hand(
      canvas,
      c,
      secAngle + math.pi,
      R * 0.14,
      R * 0.004,
      const Color(0xFF3A6A8A),
    );
*/

    canvas.drawCircle(c, R * 0.022, Paint()..color = const Color(0xFF4A4A8A));
    canvas.drawCircle(c, R * 0.010, Paint()..color = const Color(0xFF64B5F6));
  }

  void _hand(
    Canvas canvas,
    Offset c,
    double angle,
    double len,
    double w,
    Color col,
  ) {
    canvas.drawLine(
      c,
      Offset(c.dx + len * math.cos(angle), c.dy + len * math.sin(angle)),
      Paint()
        ..color = col
        ..strokeWidth = w * 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Clock24Painter o) => false;
}

class YearNote {
  final int month;
  String text;
  YearNote({required this.month, required this.text});
  Map<String, dynamic> toJson() => {'month': month, 'text': text};
  factory YearNote.fromJson(Map<String, dynamic> j) =>
      YearNote(month: j['month'] as int, text: j['text'] as String);
}

class YearlyDiagram extends StatefulWidget {
  const YearlyDiagram({super.key});
  @override
  State<YearlyDiagram> createState() => _YearlyDiagramState();
}

class _YearlyDiagramState extends State<YearlyDiagram>
    with TickerProviderStateMixin {
  double _rotation = 0.0;
  double _rotBase = 0.0;
  double _dragStartAng = 0.0;
  double _velocity = 0.0;
  double _lastTs = 0.0;
  double _lastAng = 0.0;
  late final AnimationController _inertia;

  List<YearNote> _notes = [];
  bool _editOpen = false;
  int? _editMonth;
  final _editCtrl = TextEditingController();
  Offset _center = Offset.zero;

  String get _key => 'year_notes_${DateTime.now().year}';

  @override
  void initState() {
    super.initState();
    _inertia = AnimationController.unbounded(vsync: this)..addListener(_tick);
    _load();
  }

  void _tick() {
    setState(() {
      _rotation += _velocity * 0.016;
      _velocity *= 0.93;
      if (_velocity.abs() < 0.001) _inertia.stop();
    });
  }

  @override
  void dispose() {
    _inertia.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) return;
      final list = json.decode(s) as List;
      setState(
        () => _notes = list
            .map((e) => YearNote.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key,
        json.encode(_notes.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  double _ang(Offset pos) =>
      math.atan2(pos.dy - _center.dy, pos.dx - _center.dx);

  void _onTapUp(TapUpDetails d) {
    final dx = d.localPosition.dx - _center.dx;
    final dy = d.localPosition.dy - _center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final outerR = math.min(_center.dx, _center.dy) * 0.84;
    final innerR = outerR * 0.62;
    if (dist < innerR || dist > outerR) return;

    double a = (-math.pi / 2 + _rotation - _ang(d.localPosition));
    a = a % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    _openNote((a / (2 * math.pi) * 12).floor() % 12 + 1);
  }

  void _openNote(int month) {
    final ex = _notes.where((n) => n.month == month).firstOrNull;
    _editCtrl.text = ex?.text ?? '';
    setState(() {
      _editOpen = true;
      _editMonth = month;
    });
  }

  Future<void> _confirm() async {
    final text = _editCtrl.text.trim();
    final m = _editMonth!;
    setState(() {
      _notes.removeWhere((n) => n.month == m);
      if (text.isNotEmpty) _notes.add(YearNote(month: m, text: text));
      _editOpen = false;
      _editMonth = null;
    });
    _editCtrl.clear();
    FocusScope.of(context).unfocus();
    await _persist();
  }

  void _cancel() {
    setState(() {
      _editOpen = false;
      _editMonth = null;
    });
    _editCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _onScaleStart(ScaleStartDetails d) {
    _inertia.stop();
    _rotBase = _rotation;
    _dragStartAng = _ang(d.localFocalPoint);
    _lastTs = DateTime.now().millisecondsSinceEpoch.toDouble();
    _lastAng = _dragStartAng;
    _velocity = 0;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount > 1) return;
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final dt = (now - _lastTs) / 1000;
    final cur = _ang(d.localFocalPoint);
    if (dt > 0.001) {
      _velocity = (cur - _lastAng) / dt;
      _lastAng = cur;
      _lastTs = now;
    }
    setState(() => _rotation = _rotBase + (cur - _dragStartAng));
  }

  void _onScaleEnd(ScaleEndDetails _) {
    if (_velocity.abs() > 0.05) _inertia.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (_, c) {
              _center = Offset(c.maxWidth / 2, c.maxHeight / 2);
              return GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                onTapUp: _onTapUp,
                child: CustomPaint(
                  painter: _RingPainter(
                    rotation: _rotation,
                    now: DateTime.now(),
                    notes: List.from(_notes),
                    highlightMonth: _editOpen ? _editMonth : null,
                  ),
                  size: Size(c.maxWidth, c.maxHeight),
                ),
              );
            },
          ),
        ),
        if (_editOpen)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            child: _panel(),
          ),
      ],
    );
  }

  Widget _panel() {
    const mo = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = _editMonth != null ? mo[_editMonth! - 1] : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 16, right: 16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1414), width: 0.7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 3),

            TextField(
              controller: _editCtrl,
              autofocus: false,
              maxLength: 150,
              maxLines: 6,
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 15,
                height: 1,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF2A2A4A), width: 0.6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF2A2A4A), width: 0.6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF5A5AAA), width: 1),
                ),
                isDense: true,
                counterText: '',
                hintText: 'note...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                hintStyle: TextStyle(color: Color(0xFF3A3A5A), fontSize: 14),
              ),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthName,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 101, 101, 185),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _cancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF3A3A5A),
                            width: 0.6,
                          ),
                        ),
                        child: const Text(
                          'cancel',
                          style: TextStyle(
                            color: Color(0xFF6A6A8A),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _confirm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A3A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF4A4A8A),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'ok',
                          style: TextStyle(
                            color: Color(0xFFAAAAEE),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double rotation;
  final DateTime now;
  final List<YearNote> notes;
  final int? highlightMonth;

  const _RingPainter({
    required this.rotation,
    required this.now,
    required this.notes,
    this.highlightMonth,
  });

  double get _nowProg {
    final s = DateTime(now.year, 1, 1);
    final e = DateTime(now.year + 1, 1, 1);
    return now.difference(s).inSeconds / e.difference(s).inSeconds;
  }

  double _mAngle(int m) => -math.pi / 2 + rotation - m * (2 * math.pi / 12);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final c = Offset(cx, cy);
    final minR = math.min(cx, cy);
    final outerR = minR * 0.84;
    final innerR = outerR * 0.62;
    final ringW = outerR - innerR;
    final midR = (outerR + innerR) / 2;

    canvas.drawCircle(
      c,
      midR,
      Paint()
        ..color = const Color.fromARGB(83, 12, 12, 26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringW,
    );

    final seasons = [
      (const Color.fromARGB(55, 62, 62, 143), 11, 3),
      (const Color.fromARGB(55, 36, 103, 36), 2, 4),
      (const Color.fromARGB(52, 85, 60, 15), 6, 3),
      (const Color.fromARGB(48, 72, 25, 25), 8, 3),
    ];

    for (final s in seasons) {
      final col = s.$1;
      final startMonth = s.$2;
      final count = s.$3;
      final startAngle = _mAngle(startMonth);
      final sweepAngle = -count * (2 * math.pi / 12);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: midR),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringW,
      );
    }

    canvas.drawCircle(
      c,
      outerR,
      Paint()
        ..color = const Color(0xFF181828)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..color = const Color(0xFF181828)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    const mNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final noteSet = {for (final n in notes) n.month};

    for (int m = 0; m < 12; m++) {
      final angle = _mAngle(m);
      final isJan = m == 0;
      final hasNote = noteSet.contains(m + 1);
      final isHL = highlightMonth == m + 1;

      final pad = ringW * 0.18;
      final r1 = innerR + pad;
      final r2 = outerR - pad;

      final Color gc = isHL
          ? const Color(0xFFCC5555)
          : hasNote
          ? const Color(0xFF8A3535)
          : isJan
          ? const Color(0xFF8888CC)
          : const Color(0xFF2E2E50);

      canvas.drawLine(
        Offset(cx + r1 * math.cos(angle), cy + r1 * math.sin(angle)),
        Offset(cx + r2 * math.cos(angle), cy + r2 * math.sin(angle)),
        Paint()
          ..color = gc
          ..strokeWidth = isJan ? 1.8 : 1.0
          ..strokeCap = StrokeCap.round,
      );

      if (isJan || m % 3 == 0) {
        final lr = outerR + 12;
        final tp = TextPainter(
          text: TextSpan(
            text: mNames[m],
            style: TextStyle(
              color: isJan
                  ? const Color(0xFF6666AA)
                  : const Color.fromARGB(255, 59, 59, 102),
              fontSize: 13,
              fontStyle: isJan ? FontStyle.italic : FontStyle.normal,
              letterSpacing: 0.6,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            cx + lr * math.cos(angle) - tp.width / 2,
            cy + lr * math.sin(angle) - tp.height / 2,
          ),
        );
      }

      if (hasNote) {
        canvas.drawCircle(
          Offset(
            cx + (outerR + 8) * math.cos(angle),
            cy + (outerR + 8) * math.sin(angle),
          ),
          1.8,
          Paint()..color = const Color(0xFF7A3030),
        );
      }
    }

    final nowAngle = -math.pi / 2 + rotation - _nowProg * 2 * math.pi;
    final nPad = ringW * 0.18;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: midR),
      -math.pi / 2 + rotation,
      -_nowProg * 2 * math.pi,
      false,
      Paint()
        ..color = const Color(0x1564B5F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringW * 0.5,
    );

    canvas.drawLine(
      Offset(
        cx + (innerR + nPad) * math.cos(nowAngle),
        cy + (innerR + nPad) * math.sin(nowAngle),
      ),
      Offset(
        cx + (outerR - nPad) * math.cos(nowAngle),
        cy + (outerR - nPad) * math.sin(nowAngle),
      ),
      Paint()
        ..color = const Color(0xFF64B5F6)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(
        cx + outerR * math.cos(nowAngle),
        cy + outerR * math.sin(nowAngle),
      ),
      2.2,
      Paint()..color = const Color(0xFF64B5F6),
    );

    final ntp = TextPainter(
      text: const TextSpan(
        text: 'now',
        style: TextStyle(
          color: Color(0xFF64B5F6),
          fontSize: 12,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.7,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final nlr = outerR + 14;
    ntp.paint(
      canvas,
      Offset(
        cx + nlr * math.cos(nowAngle) - ntp.width / 2,
        cy + nlr * math.sin(nowAngle) - ntp.height / 2,
      ),
    );

    final ytp = TextPainter(
      text: TextSpan(
        text: '${now.year}',
        style: const TextStyle(
          color: Color.fromARGB(255, 59, 59, 110),
          fontSize: 21,
          letterSpacing: 4,
          fontWeight: FontWeight.w200,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ytp.paint(canvas, Offset(cx - ytp.width / 2, cy - ytp.height / 2));
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.rotation != rotation ||
      o.notes.length != notes.length ||
      o.highlightMonth != highlightMonth;
}
