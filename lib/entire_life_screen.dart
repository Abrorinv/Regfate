import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'package:vibration/vibration.dart';

// ═══════════════════════════════════════════════════════════════
//  ТОЧКА ВХОДА — EntireLife
// ═══════════════════════════════════════════════════════════════

/// Главный экран EntireLife. Управляет шагами:
///   1. Ввод даты рождения (portrait, только первый раз)
///   2. Экран подготовки — поворот телефона (portrait → landscape)
///   3. Сам экран жизненной линейки (landscape, шаги 3–8)
class EntireLifeScreen extends StatefulWidget {
  const EntireLifeScreen({super.key});

  @override
  State<EntireLifeScreen> createState() => _EntireLifeScreenState();
}

enum _ELStep { birthInput, main }

class _EntireLifeScreenState extends State<EntireLifeScreen> {
  _ELStep _step = _ELStep.birthInput;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (!mounted) return;
    setState(() {
      _step = AppStorage().birthDate != null
          ? _ELStep
                .main // ← сразу main, минуя landscapePrepare
          : _ELStep.birthInput;
    });
  }

  /// Вызывается после сохранения даты рождения.
  void _onBirthDateSaved() => setState(() => _step = _ELStep.main);

  /// Вызывается когда пользователь повернул телефон и готов войти.

  @override
  void dispose() {
    // Восстанавливаем все ориентации при уходе с экрана
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _ELStep.birthInput:
        return _BirthInputScreen(onSaved: _onBirthDateSaved);
      case _ELStep.main:
        return _EntireLifeMain(birthDate: AppStorage().birthDate!);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  ШАГ 1 — Ввод даты рождения (portrait)
// ═══════════════════════════════════════════════════════════════

class _BirthInputScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const _BirthInputScreen({required this.onSaved});

  @override
  State<_BirthInputScreen> createState() => _BirthInputScreenState();
}

class _BirthInputScreenState extends State<_BirthInputScreen>
    with SingleTickerProviderStateMixin {
  // Барабанные пикеры
  int _day = 1, _month = 1, _year = 2000;
  late FixedExtentScrollController _dayCtrl, _monthCtrl, _yearCtrl;

  // Анимация появления
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _months = [
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

  // Максимальное количество дней для текущего месяца/года
  int get _maxDay => DateTime(_year, _month + 1, 0).day;

  // Список дней с учётом текущего месяца
  List<String> get _dayItems =>
      List.generate(_maxDay, (i) => (i + 1).toString().padLeft(2, '0'));

  List<String> get _yearItems {
    final now = DateTime.now().year;
    return List.generate(now - 1929, (i) => '${1930 + i}');
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = 1;
    _month = now.month;
    _year = now.year - 25; // По умолчанию ~25 лет назад

    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _year - 1930);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// Если день выходит за пределы нового месяца — скроллим к последнему дню.
  void _clampDay() {
    if (_day > _maxDay) {
      _day = _maxDay;
      _dayCtrl.animateToItem(
        _day - 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    setState(() {});
  }

  Future<void> _save() async {
    final date = DateTime(_year, _month, _day);
    await AppStorage().saveBirthDate(date);
    if (mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      body: Stack(
        children: [
          // Фоновые звёзды (статичные)
          const Positioned.fill(child: _AnimatedStarfield(starCount: 320)),

          // Контент
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // ── Заголовок ──────────────────────────────────
                  const _GoldGlowText(
                    '✦ entire life ✦',
                    fontSize: 13,
                    letterSpacing: 4.0,
                    color: Color.fromARGB(255, 41, 48, 186),
                    glowRadius: 8,
                  ),
                  const SizedBox(height: 20),
                  const _GoldGlowText(
                    'Birth Date',
                    fontSize: 26,
                    letterSpacing: 1.5,
                    color: Color(0xFFEEEEEE),
                    glowRadius: 0,
                  ),

                  const SizedBox(height: 56),

                  // ── Барабанные пикеры ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // День
                        _DrumPicker(
                          controller: _dayCtrl,
                          items: _dayItems,
                          width: 70,
                          onChanged: (i) {
                            _day = i + 1;
                            setState(() {});
                          },
                        ),
                        _drumSeparator(),
                        // Месяц
                        _DrumPicker(
                          controller: _monthCtrl,
                          items: _months,
                          width: 70,
                          onChanged: (i) {
                            _month = i + 1;
                            _clampDay();
                          },
                        ),
                        _drumSeparator(),
                        // Год
                        _DrumPicker(
                          controller: _yearCtrl,
                          items: _yearItems,
                          width: 90,
                          onChanged: (i) {
                            _year = 1930 + i;
                            _clampDay();
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Кнопка сохранения ──────────────────────────
                  GestureDetector(
                    onTap: _save,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 80),
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color.fromARGB(0, 255, 217, 0),
                          width: 0.8,
                        ),
                        color: const Color.fromARGB(22, 50, 1, 130),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(68, 46, 1, 129),
                            blurRadius: 18,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Save...›',
                          style: TextStyle(
                            color: Color.fromARGB(255, 41, 48, 186),
                            fontSize: 19,
                            letterSpacing: 2.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drumSeparator() => const Padding(
    padding: EdgeInsets.only(bottom: 4),
    child: Text(
      '·',
      style: TextStyle(color: Color(0xFF333355), fontSize: 28, height: 1),
    ),
  );
}

// ── Барабанный пикер ───────────────────────────────────────────

class _DrumPicker extends StatefulWidget {
  final FixedExtentScrollController controller;
  final List<String> items;
  final double width;
  final ValueChanged<int> onChanged;

  const _DrumPicker({
    required this.controller,
    required this.items,
    required this.width,
    required this.onChanged,
  });

  @override
  State<_DrumPicker> createState() => _DrumPickerState();
}

class _DrumPickerState extends State<_DrumPicker> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.initialItem.clamp(0, widget.items.length - 1);
  }

  void didUpdateWidget(_DrumPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      final clamped = _selected.clamp(0, widget.items.length - 1);
      if (clamped != _selected) setState(() => _selected = clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    const itemH = 46.0;
    return SizedBox(
      width: widget.width,
      height: itemH * 5,
      child: Stack(
        children: [
          // Список
          ListWheelScrollView.useDelegate(
            controller: widget.controller,
            itemExtent: itemH,
            perspective: 0.002,
            diameterRatio: 2.0,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              final clamped = i.clamp(0, widget.items.length - 1);
              setState(() => _selected = clamped);
              widget.onChanged(clamped);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (ctx, i) {
                final isSel = i == _selected;
                return Center(
                  child: Text(
                    widget.items[i],
                    style: TextStyle(
                      color: isSel
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF333355),
                      fontSize: isSel ? 22 : 15,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),

          // Затухание сверху
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: itemH * 2,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF05050D), Color(0x0005050D)],
                  ),
                ),
              ),
            ),
          ),

          // Затухание снизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: itemH * 2,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF05050D), Color(0x0005050D)],
                  ),
                ),
              ),
            ),
          ),

          // Линии вокруг выбранного
          Center(
            child: IgnorePointer(
              child: SizedBox(
                height: itemH,
                child: Column(
                  children: [
                    Container(height: 0.8, color: const Color(0x55FFD700)),
                    const Spacer(),
                    Container(height: 0.8, color: const Color(0x55FFD700)),
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

// ═══════════════════════════════════════════════════════════════
//  ШАГ 2 — Подготовка: поверни телефон (portrait → landscape)
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
//  ШАГ 3–8 (заглушка) — сам экран EntireLife
//  Будет реализован в следующих шагах
// ═══════════════════════════════════════════════════════════════

class _EntireLifeMain extends StatefulWidget {
  final DateTime birthDate;
  const _EntireLifeMain({required this.birthDate});
  @override
  State<_EntireLifeMain> createState() => _EntireLifeMainState();
}

class _EntireLifeMainState extends State<_EntireLifeMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _trainCtrl;
  late Animation<Offset> _slideAnim;
  // final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _trainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1.15, 0.0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _trainCtrl, curve: const _TrainBrakeCurve()),
        );
    _enter();
  }

  Future<void> _enter() async {
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _vibrate();
    _playSound();
    _trainCtrl.forward();
  }

  void _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;
      await Vibration.vibrate(duration: 1500);
    } catch (_) {}
  }

  void _playSound() {}

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _trainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Звёздное небо — стоит на месте
          const Positioned.fill(child: _StaticStarfield(starCount: 320)),
          // Линейка жизни — въезжает с правой стороны
          Positioned.fill(
            child: SlideTransition(
              position: _slideAnim,
              child: _LifeRulerView(birthDate: widget.birthDate),
            ),
          ),
          Positioned(
            top: 14,
            left: 8,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white24,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
          ),
          // Подсказка поворота — как в ClockScreen но золотая
          Positioned(
            right: 16,
            bottom: 12,
            child: _ShakingLandscapeLabel(), // <-- вставь это
          ),
        ],
      ),
    );
  }
}

// ── Кривая торможения поезда ───────────────────────────────────
class _TrainBrakeCurve extends Curve {
  const _TrainBrakeCurve();
  @override
  double transform(double t) => 1.0 - math.pow(1.0 - t, 5.0).toDouble();
}

// ═══════════════════════════════════════════════════════════════
//  ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ
// ═══════════════════════════════════════════════════════════════

// ── Статичное звёздное небо ────────────────────────────────────

class _StaticStarfield extends StatelessWidget {
  final int starCount;
  const _StaticStarfield({required this.starCount});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarfieldPainter(seed: 42, count: starCount));
  }
}

class _StarfieldPainter extends CustomPainter {
  final int seed;
  final int count;
  const _StarfieldPainter({required this.seed, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.6 + 0.2;
      final bright = rng.nextDouble();

      // Яркость звезды: от почти невидимой до заметной
      final alpha = (0.15 + bright * 0.75).clamp(0.0, 1.0);

      // Небольшая часть звёзд — синеватые, остальные белые/жёлтые
      final Color color;
      final colorRoll = rng.nextDouble();
      if (colorRoll < 0.12) {
        color = Color.fromRGBO(160, 180, 255, alpha); // голубые
      } else if (colorRoll < 0.22) {
        color = Color.fromRGBO(255, 230, 180, alpha); // тёплые
      } else {
        color = Color.fromRGBO(220, 220, 235, alpha); // белые
      }

      final paint = Paint()..color = color;

      // Крупные звёзды рисуем с мягким свечением
      if (r > 1.2) {
        canvas.drawCircle(
          Offset(x, y),
          r * 2.5,
          Paint()
            ..color = Color.fromRGBO(220, 220, 255, alpha * 0.08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // Несколько очень ярких "больших" звёзд с крестообразными лучами
    final rng2 = math.Random(seed + 1);
    for (int i = 0; i < 6; i++) {
      final x = rng2.nextDouble() * size.width;
      final y = rng2.nextDouble() * size.height;
      const r = 2.0;
      const alpha = 0.85;

      // Свечение
      canvas.drawCircle(
        Offset(x, y),
        r * 6,
        Paint()
          ..color = const Color.fromRGBO(200, 210, 255, 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = const Color.fromRGBO(240, 240, 255, alpha),
      );

      // Лучи
      final rayPaint = Paint()
        ..color = const Color.fromRGBO(240, 240, 255, 0.25)
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round;
      const rayLen = 10.0;
      for (final angle in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
        canvas.drawLine(
          Offset(x + math.cos(angle) * r, y + math.sin(angle) * r),
          Offset(x + math.cos(angle) * rayLen, y + math.sin(angle) * rayLen),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter o) => false;
}

// ── Анимированное звёздное небо (мерцание) ────────────────────
// Используется только на главном экране EntireLife.
// На экранах ввода и подготовки — статичное (_StaticStarfield).

class _AnimatedStarfield extends StatefulWidget {
  final int starCount;
  const _AnimatedStarfield({required this.starCount});

  @override
  State<_AnimatedStarfield> createState() => _AnimatedStarfieldState();
}

class _AnimatedStarfieldState extends State<_AnimatedStarfield>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _AnimatedStarfieldPainter(
          seed: 42,
          count: widget.starCount,
          time: _ctrl.value, // 0.0..1.0 циклически
        ),
      ),
    );
  }
}

class _AnimatedStarfieldPainter extends CustomPainter {
  final int seed, count;
  final double time; // 0..1

  const _AnimatedStarfieldPainter({
    required this.seed,
    required this.count,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);

    for (int i = 0; i < count; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.6 + 0.2;
      final base = 0.18 + rng.nextDouble() * 0.70;
      final phase = rng.nextDouble() * math.pi * 2; // уникальная фаза
      final speed = 0.4 + rng.nextDouble() * 0.8; // скорость мерцания
      final roll = rng.nextDouble();

      // Мерцание: плавное sin с индивидуальной фазой и скоростью
      final flicker =
          0.75 + 0.25 * math.sin(time * math.pi * 2 * speed + phase);
      final alpha = (base * flicker).clamp(0.0, 1.0);

      final Color color;
      if (roll < 0.12)
        color = Color.fromRGBO(160, 180, 255, alpha);
      else if (roll < 0.22)
        color = Color.fromRGBO(255, 230, 180, alpha);
      else
        color = Color.fromRGBO(220, 220, 235, alpha);

      if (r > 1.2) {
        canvas.drawCircle(
          Offset(x, y),
          r * 2.5,
          Paint()
            ..color = Color.fromRGBO(220, 220, 255, alpha * 0.10)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color);
    }

    // Яркие звёзды с лучами — тоже мерцают
    final rng2 = math.Random(seed + 1);
    for (int i = 0; i < 7; i++) {
      final x = rng2.nextDouble() * size.width;
      final y = rng2.nextDouble() * size.height;
      final phase = rng2.nextDouble() * math.pi * 2;
      final flk = 0.65 + 0.35 * math.sin(time * math.pi * 2 * 0.5 + phase);

      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = Color.fromRGBO(200, 210, 255, 0.07 * flk)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        Offset(x, y),
        2.0,
        Paint()..color = Color.fromRGBO(240, 240, 255, 0.88 * flk),
      );

      final rp = Paint()
        ..color = Color.fromRGBO(240, 240, 255, 0.22 * flk)
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round;
      for (final a in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
        canvas.drawLine(
          Offset(x + math.cos(a) * 2, y + math.sin(a) * 2),
          Offset(x + math.cos(a) * 11, y + math.sin(a) * 11),
          rp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AnimatedStarfieldPainter o) => o.time != time;
}

// ── Иконка телефона (нарисованная) ────────────────────────────

// ── Текст с золотым свечением ──────────────────────────────────

class _GoldGlowText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  final Color color;
  final double glowRadius;

  const _GoldGlowText(
    this.text, {
    required this.fontSize,
    required this.letterSpacing,
    required this.color,
    required this.glowRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        letterSpacing: letterSpacing,
        fontStyle: FontStyle.italic,
        shadows: glowRadius > 0
            ? [
                Shadow(color: const Color(0xAAFFD700), blurRadius: glowRadius),
                Shadow(
                  color: const Color(0x55FFD700),
                  blurRadius: glowRadius * 2.5,
                ),
              ]
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ЛИНЕЙКА ЖИЗНИ — геометрия + ромбы (Шаг 5)
// ═══════════════════════════════════════════════════════════════

// Вычисляет количество серых ромбов (будущее) по возрасту
int _greyCount(int ageYears) {
  if (ageYears < 15) return 40;
  if (ageYears < 30) return 30;
  if (ageYears < 50) return 20;
  return 10;
}

class _LifeRulerView extends StatefulWidget {
  final DateTime birthDate;
  const _LifeRulerView({required this.birthDate});
  @override
  State<_LifeRulerView> createState() => _LifeRulerViewState();
}

class _LifeRulerViewState extends State<_LifeRulerView>
    with TickerProviderStateMixin {
  late AnimationController _breathCtrl, _pulseCtrl;
  late Animation<double> _breathAnim, _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Дыхание — медленное, едва заметное
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

    // Пульс — быстрый, как сердце
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnim, _pulseAnim]),
      builder: (_, __) => CustomPaint(
        painter: _LifeRulerPainter(
          birthDate: widget.birthDate,
          breathValue: _breathAnim.value,
          pulseValue: _pulseAnim.value,
        ),
      ),
    );
  }
}

class _LifeRulerPainter extends CustomPainter {
  final DateTime birthDate;
  final double breathValue;
  final double pulseValue;

  const _LifeRulerPainter({
    required this.birthDate,
    required this.breathValue,
    required this.pulseValue,
  });

  // ── Возраст в полных годах ─────────────────────────────────
  int get _ageYears {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    final hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age.clamp(0, 150);
  }

  // ── Точная дробная часть текущего года (0.0..1.0) ─────────
  double get _ageFraction {
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    final nextYearBirthday = DateTime(
      now.year + 1,
      birthDate.month,
      birthDate.day,
    );
    final since = now.difference(thisYearBirthday).inSeconds;
    final total = nextYearBirthday.difference(thisYearBirthday).inSeconds;
    return (since / total).clamp(0.0, 1.0);
  }

  // ── Геометрия дуги ─────────────────────────────────────────
  // p=0 → рождение (правый край)
  // p=1 → смерть   (левый край, чуть выше)
  // Прогиб вниз, пик смещён левее центра (pk=0.58)
  Offset _pos(double p, Size s) {
    final x = s.width * 0.94 - p * s.width * 0.88;
    const pk = 0.58;
    final t = p <= pk ? p / pk * 0.5 : 0.5 + (p - pk) / (1.0 - pk) * 0.5;
    final dip = 4.0 * t * (1.0 - t);
    final baseY = s.height * 0.33 - p * s.height * 0.08;
    final y = baseY + s.height * 0.34 * dip;
    return Offset(x, y);
  }

  // ── Размер ромба зависит от общего числа ──────────────────
  double _diamondSize(int total) {
    const base = 8.5;
    const minSize = 5.5;
    if (total <= 70) return base;
    final t = ((total - 70) / 40.0).clamp(0.0, 1.0);
    return base - (base - minSize) * t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final age = _ageYears;
    final fraction = _ageFraction;
    final greyC = _greyCount(age);
    final totalC = age + greyC;
    final dSz = _diamondSize(totalC);

    // ── 1. Дуга ───────────────────────────────────────────────
    final arcPath = Path();
    const steps = 160;
    for (int i = 0; i <= steps; i++) {
      final pt = _pos(i / steps.toDouble(), size);
      if (i == 0)
        arcPath.moveTo(pt.dx, pt.dy);
      else
        arcPath.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(
      arcPath,
      Paint()
        ..color = const Color(0x18FFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..strokeCap = StrokeCap.round,
    );

    // ── 2. Ромбы ──────────────────────────────────────────────
    for (int i = 0; i < totalC; i++) {
      final p = totalC > 1 ? i / (totalC - 1).toDouble() : 0.0;
      final pt = _pos(p, size);
      final isGold = i < age;

      if (isGold) {
        _drawGoldDiamond(canvas, pt, dSz);
      } else {
        final greyIdx = i - age;
        final opacity = 0.57 - (greyIdx / greyC.toDouble()) * 0.40;
        _drawGreyDiamond(canvas, pt, dSz, opacity);
      }
    }

    // ── 3. Стикер рождения ────────────────────────────────────
    _drawBirthSticker(canvas, _pos(0.0, size), size);

    // ── 4. Стикер смерти ──────────────────────────────────────
    _drawDeathSticker(canvas, _pos(1.0, size), size);

    // ── 5. Маркер возраста (дыхание + пульс) ─────────────────
    final ageP = totalC > 1 ? (age + fraction) / (totalC - 1).toDouble() : 0.0;
    final agePt = _pos(ageP.clamp(0.0, 1.0), size);
    _drawAgeMarker(canvas, agePt, dSz);
  }

  // ── Золотой ромб ──────────────────────────────────────────

  void _drawGoldDiamond(Canvas canvas, Offset c, double sz) {
    final path = _diamondPath(c, sz);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x28FFD060)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sz * 1.8
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 2.2),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x1AFFD060)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xEEFFCC44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ── Серебряный ромб ───────────────────────────────────────

  void _drawGreyDiamond(Canvas canvas, Offset c, double sz, double opacity) {
    final path = _diamondPath(c, sz);
    final a = opacity.clamp(0.0, 1.0);

    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(180, 190, 220, a * 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sz * 1.6
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 2.0),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(160, 170, 200, a * 0.10)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(190, 200, 230, a * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ── Контур ромба ──────────────────────────────────────────

  Path _diamondPath(Offset c, double sz) {
    final hw = sz * 0.65;
    final hh = sz;
    return Path()
      ..moveTo(c.dx, c.dy - hh)
      ..lineTo(c.dx + hw, c.dy)
      ..lineTo(c.dx, c.dy + hh)
      ..lineTo(c.dx - hw, c.dy)
      ..close();
  }

  // ── Стикер рождения ───────────────────────────────────────

  void _drawBirthSticker(Canvas canvas, Offset pt, Size s) {
    canvas.drawCircle(
      pt,
      18,
      Paint()
        ..color = const Color(0x1AFFD700)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: '✦',
        style: TextStyle(color: Color(0xCCFFD700), fontSize: 15),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dp = TextPainter(
      text: TextSpan(
        text: '${birthDate.year}',
        style: const TextStyle(
          color: Color(0x88FFD700),
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, pt.translate(-tp.width / 2, -tp.height - 6));
    dp.paint(canvas, pt.translate(-dp.width / 2, -tp.height - dp.height - 8));
  }

  // ── Стикер смерти ─────────────────────────────────────────

  void _drawDeathSticker(Canvas canvas, Offset pt, Size s) {
    canvas.drawCircle(
      pt,
      18,
      Paint()
        ..color = const Color(0x12888888)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: '∞',
        style: TextStyle(color: Color(0x66AAAAAA), fontSize: 17),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pt.translate(-tp.width / 2, -tp.height - 6));
  }

  // ── Маркер возраста: дыхание + пульс ─────────────────────

  void _drawAgeMarker(Canvas canvas, Offset pt, double dSz) {
    // Овал дышит: от baseR до baseR + delta
    final baseR = dSz * 2.4;
    final delta = dSz * 0.5;
    final radius = baseR + delta * breathValue;

    // Внешнее свечение (дышит)
    canvas.drawCircle(
      pt,
      radius * 1.6,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.04 + 0.04 * breathValue)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.9),
    );

    // Тело овала — почти прозрачное
    canvas.drawOval(
      Rect.fromCenter(center: pt, width: radius * 1.1, height: radius * 1.55),
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.06 + 0.04 * breathValue)
        ..style = PaintingStyle.fill,
    );

    // Контур овала
    canvas.drawOval(
      Rect.fromCenter(center: pt, width: radius * 1.1, height: radius * 1.55),
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.35 + 0.20 * breathValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Красная точка — пульсирует
    final pulseR = dSz * 0.38 + dSz * 0.22 * pulseValue;

    // Свечение пульса
    canvas.drawCircle(
      pt,
      pulseR * 2.2,
      Paint()
        ..color = Color.fromRGBO(255, 50, 60, 0.12 + 0.14 * pulseValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Тело красной точки
    canvas.drawCircle(
      pt,
      pulseR,
      Paint()..color = Color.fromRGBO(180, 20, 30, 0.75 + 0.25 * pulseValue),
    );
  }

  @override
  bool shouldRepaint(_LifeRulerPainter o) =>
      o.birthDate != birthDate ||
      o.breathValue != breathValue ||
      o.pulseValue != pulseValue;
}

// Класс тряски и затухания лейбла "landscape" в правом нижнем углу.

class _ShakingLandscapeLabel extends StatefulWidget {
  @override
  State<_ShakingLandscapeLabel> createState() => _ShakingLandscapeLabelState();
}

class _ShakingLandscapeLabelState extends State<_ShakingLandscapeLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // темп тряски
    );
    _shakeController.repeat(reverse: true); // мотание туда-сюда

    // Через 3 секунды остановить тряску и начать плавное исчезновение
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _shakeController.stop();
      setState(() => _fadeOut = true);
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFD700), width: 0.5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.screen_rotation_outlined,
            color: Color(0x88FFD700),
            size: 17,
          ),
          SizedBox(width: 5),
          Text(
            'landscape',
            style: TextStyle(
              color: Color.fromARGB(194, 255, 217, 0),
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(seconds: 2), // затухание за 2 сек
      opacity: _fadeOut ? 0.0 : 1.0,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (_, child) =>
            Transform.rotate(angle: angle.value, child: child),
        child: label,
      ),
    );
  }
}
