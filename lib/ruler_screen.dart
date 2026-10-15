import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

// ═══════════════════════════════════════════════════════════════
//  ГЕОМЕТРИЯ
// ═══════════════════════════════════════════════════════════════

class RulerGeometry {
  final double screenWidth;
  final double screenHeight;
  final double scale;
  final double scroll;

  const RulerGeometry({
    required this.screenWidth,
    required this.screenHeight,
    required this.scale,
    required this.scroll,
  });

  double get axisX => screenWidth * 0.18;
  double get maxBulge => screenWidth * 0.49 - axisX;
  double get hw => screenWidth * 0.035;
  static const double textGap = 14.0;

  double cx(double p) {
    const pk = 0.62;
    final t = p <= pk ? p / pk * 0.5 : 0.5 + (p - pk) / (1.0 - pk) * 0.5;
    return axisX + maxBulge * 4.0 * t * (1.0 - t);
  }

  double sy(double p) {
    final botY = screenHeight * 0.94;
    final topY = screenHeight * 0.025;
    return botY - p * (botY - topY) * scale + scroll;
  }

  double yToP(double y) {
    final botY = screenHeight * 0.94;
    final topY = screenHeight * 0.025;
    final h = (botY - topY) * scale;
    if (h <= 0) return 0.5;
    return ((botY + scroll - y) / h).clamp(0.0, 1.0);
  }
}

// ═══════════════════════════════════════════════════════════════
//  ЗАЧЁРКИВАНИЕ  ~~текст~~
// ═══════════════════════════════════════════════════════════════

List<InlineSpan> parseStrikethrough(String text, TextStyle base) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'~~(.*?)~~', dotAll: true);
  int last = 0;
  for (final m in re.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    spans.add(
      TextSpan(
        text: m.group(1),
        style: base.copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: base.color,
          decorationThickness: 1.4,
        ),
      ),
    );
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
  return spans;
}

// ═══════════════════════════════════════════════════════════════
//  ГЁТЕ
// ═══════════════════════════════════════════════════════════════

class RulerTick {
  final double progress;
  final String? label;
  final bool isPsych;
  final bool isNow;

  const RulerTick({
    required this.progress,
    this.label,
    required this.isPsych,
    required this.isNow,
  });
}

List<RulerTick> buildRulerTicks(DateTime start, DateTime end, DateTime now) {
  final diff = end.difference(start).inDays;
  final List<RulerTick> ticks = [];
  const mo = [
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
  bool sd(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String z(int n) => n.toString().padLeft(2, '0');

  if (diff == 0) {
    for (int h = 0; h <= 48; h++) {
      final tm = h * 30;
      final hr = tm ~/ 60;
      final mn = tm % 60;
      final isP = mn == 0 && hr % 3 == 0;
      final isN =
          sd(start, now) && hr == now.hour && (mn - now.minute).abs() < 30;
      ticks.add(
        RulerTick(
          progress: h / 48.0,
          label: isP ? '${z(hr)}:00' : null,
          isPsych: isP,
          isNow: isN,
        ),
      );
    }
  } else if (diff <= 7) {
    final total = diff * 4;
    for (int i = 0; i <= total; i++) {
      final d = start.add(Duration(hours: i * 6));
      final isP = d.hour == 0;
      final isN = sd(d, now);
      ticks.add(
        RulerTick(
          progress: i / total.toDouble(),
          label: isP ? '${d.day} ${mo[d.month - 1]}' : null,
          isPsych: isP,
          isNow: isN,
        ),
      );
    }
  } else if (diff <= 90) {
    for (int i = 0; i <= diff; i++) {
      final d = start.add(Duration(days: i));
      final isP = d.day == 1 || i == 0 || i == diff || d.day % 7 == 0;
      final isN = sd(d, now);
      ticks.add(
        RulerTick(
          progress: i / diff.toDouble(),
          label: isP ? '${d.day} ${mo[d.month - 1]} ${d.year}' : null,
          isPsych: isP,
          isNow: isN,
        ),
      );
    }
  } else if (diff <= 365 * 3) {
    int mc = 0;
    DateTime cur = DateTime(start.year, start.month);
    int total = (end.year - start.year) * 12 + (end.month - start.month);
    if (total < 1) total = 1;
    while (!cur.isAfter(end)) {
      final isP =
          cur.month == 1 ||
          cur.month == 4 ||
          cur.month == 7 ||
          cur.month == 10 ||
          mc == 0 ||
          !cur.isBefore(end);
      final isN = cur.year == now.year && cur.month == now.month;
      ticks.add(
        RulerTick(
          progress: (mc / total).clamp(0.0, 1.0),
          label: isP ? '${mo[cur.month - 1]} ${cur.year}' : null,
          isPsych: isP,
          isNow: isN,
        ),
      );
      mc++;
      cur = cur.month == 12
          ? DateTime(cur.year + 1, 1)
          : DateTime(cur.year, cur.month + 1);
    }
  } else {
    final totalY = end.year - start.year;
    for (int y = start.year; y <= end.year; y++) {
      final i = y - start.year;
      final isP = y % 5 == 0 || i == 0 || i == totalY;
      final isN = y == now.year;
      ticks.add(
        RulerTick(
          progress: totalY > 0 ? (i / totalY).clamp(0.0, 1.0) : 0.0,
          label: isP ? '$y' : null,
          isPsych: isP,
          isNow: isN,
        ),
      );
    }
  }
  // Минимум 6 гёте — добавляем промежуточные без подписей
  while (ticks.length < 6) {
    final extra = <RulerTick>[];
    for (int i = 0; i < ticks.length - 1; i++) {
      final mid = (ticks[i].progress + ticks[i + 1].progress) / 2;
      final tooClose = ticks.any((t) => (t.progress - mid).abs() < 0.005);
      if (!tooClose) {
        extra.add(
          RulerTick(progress: mid, label: null, isPsych: false, isNow: false),
        );
      }
    }
    if (extra.isEmpty) break;
    ticks.addAll(extra);
    ticks.sort((a, b) => a.progress.compareTo(b.progress));
  }
  return ticks;
}

// ═══════════════════════════════════════════════════════════════
//  ДИАЛОГ СОХРАНЕНИЯ
// ═══════════════════════════════════════════════════════════════

class SaveNameDialog extends StatefulWidget {
  const SaveNameDialog({super.key});
  @override
  State<SaveNameDialog> createState() => _SaveNameDialogState();
}

class _SaveNameDialogState extends State<SaveNameDialog> {
  final _c = TextEditingController();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF0C0C1E),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Plan name',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter plan name...',
              hintStyle: TextStyle(color: Colors.white24),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
            ),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(228, 17, 66, 146),
                ),
                onPressed: () {
                  if (_c.text.trim().isNotEmpty)
                    Navigator.pop(context, _c.text.trim());
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  ЭКРАН ЛИНЕЙКИ
// ═══════════════════════════════════════════════════════════════

class RulerScreen extends StatefulWidget {
  final DateTime start, end;
  final List<GoalItem>? savedGoals;
  final int? existingIndex; // новое поле
  const RulerScreen({
    super.key,
    required this.start,
    required this.end,
    this.savedGoals,
    this.existingIndex, // новый параметр
  });
  @override
  State<RulerScreen> createState() => _RulerScreenState();
}

class _RulerScreenState extends State<RulerScreen> {
  // Скролл / зум
  double _scale = 1.0,
      _scaleBase = 1.0,
      _scroll = 0.0,
      _focalY0 = 0.0,
      _scroll0 = 0.0;
  bool _wasTap = false;
  Offset _tapDown = Offset.zero;

  // Цели
  final List<GoalItem> _goals = [];

  // Редактор
  double? _editP;
  GoalItem? _editExisting;
  bool _editIsCustom = false;
  bool _editGoLeft = true;
  final TextEditingController _editCtrl = TextEditingController();
  final FocusNode _editFocus = FocusNode();

  // Размеры
  double _bodyW = 375.0, _bodyH = 600.0;

  RulerGeometry get _geo => RulerGeometry(
    screenWidth: _bodyW,
    screenHeight: _bodyH,
    scale: _scale,
    scroll: _scroll,
  );

  String _z(int n) => n.toString().padLeft(2, '0');
  String _fmt(DateTime d) => '${_z(d.day)}.${_z(d.month)}.${d.year}';

  @override
  void initState() {
    super.initState();
    if (widget.savedGoals != null) _goals.addAll(widget.savedGoals!);
    _editFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_editFocus.hasFocus && _editP != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editP != null) _confirmEdit();
      });
    }
  }

  @override
  void dispose() {
    _editFocus.removeListener(_onFocusChange);
    _editCtrl.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  // ── Зачёркивание ───────────────────────────────────────────

  void _toggleStrikethrough() {
    final sel = _editCtrl.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final text = _editCtrl.text;
    final selected = text.substring(sel.start, sel.end);
    final String replacement;
    final int newEnd;
    if (selected.startsWith('~~') &&
        selected.endsWith('~~') &&
        selected.length > 4) {
      replacement = selected.substring(2, selected.length - 2);
      newEnd = sel.start + replacement.length;
    } else {
      replacement = '~~$selected~~';
      newEnd = sel.start + replacement.length;
    }
    final newText =
        text.substring(0, sel.start) + replacement + text.substring(sel.end);
    _editCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newEnd),
    );
    setState(() {});
    _autoSaveIfExisting();
  }

  // ── Отметить как сделанное ─────────────────────────────────

  //void _toggleDone()

  // ── Поиск / проверки ───────────────────────────────────────

  GoalItem? _findGoal(double p) {
    for (final g in _goals) {
      if ((g.progress - p).abs() < 0.004) return g;
    }
    return null;
  }

  bool _tooClose(double p) {
    const minPx = 14.0;
    final ticks = buildRulerTicks(widget.start, widget.end, DateTime.now());
    for (final t in ticks) {
      if ((_geo.sy(t.progress) - _geo.sy(p)).abs() < minPx) return true;
    }
    for (final g in _goals) {
      if ((_geo.sy(g.progress) - _geo.sy(p)).abs() < minPx) return true;
    }
    return false;
  }

  // ── Тап ────────────────────────────────────────────────────

  void _handleTap(Offset pos) {
    if (_editP != null) {
      _confirmEdit();
      return;
    }
    final yBot = _geo.sy(0.0), yTop = _geo.sy(1.0);
    if (pos.dy > yBot || pos.dy < yTop) return;

    final pTapped = _geo.yToP(pos.dy);
    final ticks = buildRulerTicks(widget.start, widget.end, DateTime.now());
    double nearDist = double.infinity;
    double? nearP;
    for (final t in ticks) {
      final d = (_geo.sy(t.progress) - pos.dy).abs();
      if (d < nearDist) {
        nearDist = d;
        nearP = t.progress;
      }
    }
    for (final g in _goals) {
      final d = (_geo.sy(g.progress) - pos.dy).abs();
      if (d < nearDist) {
        nearDist = d;
        nearP = g.progress;
      }
    }

    final tapGoLeft = pos.dx < _geo.cx(pTapped);
    const snapPx = 22.0;
    if (nearDist <= snapPx && nearP != null) {
      final existing = _findGoal(nearP);
      _startEditing(
        nearP,
        goLeft: existing?.goLeft ?? tapGoLeft,
        existing: existing,
      );
    } else {
      if (!_tooClose(pTapped)) {
        _startEditing(pTapped, isCustomTick: true, goLeft: tapGoLeft);
      }
    }
  }

  void _startEditing(
    double p, {
    bool isCustomTick = false,
    GoalItem? existing,
    bool goLeft = true,
  }) {
    setState(() {
      _editP = p;
      _editIsCustom = isCustomTick;
      _editExisting = existing;
      _editGoLeft = goLeft;
      _editCtrl.text = existing?.text ?? '';
      if (existing != null) {
        _editCtrl.selection = TextSelection(
          baseOffset: 0,
          extentOffset: existing.text.length,
        );
      }
    });
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _editFocus.requestFocus();
    });
  }

  void _confirmEdit() {
    if (_editP == null) return;
    final text = _editCtrl.text.trimRight();
    final p = _editP!;
    final existing = _editExisting;
    final isCustom = _editIsCustom;
    final goLeft = _editGoLeft;

    _editP = null;
    _editExisting = null;
    _editIsCustom = false;
    _editGoLeft = true;

    if (text.isEmpty && existing != null) {
      _goals.remove(existing);
    } else if (text.isNotEmpty) {
      if (existing != null) {
        final idx = _goals.indexOf(existing);
        if (idx >= 0)
          _goals[idx] = GoalItem(
            progress: existing.progress,
            text: text,
            isCustomTick: existing.isCustomTick,
            goLeft: existing.goLeft,
            isDone: existing.isDone,
          );
      } else {
        _goals.add(
          GoalItem(
            progress: p,
            text: text,
            isCustomTick: isCustom,
            goLeft: goLeft,
          ),
        );
      }
    }
    _editCtrl.clear();
    _editFocus.unfocus();
    setState(() {});
    _autoSaveIfExisting();
  }

  Future<void> _onSave() async {
    // 1. Подготавливаем список целей (эта часть осталась без изменений)
    final goalsToSave = _goals
        .map(
          (g) => GoalItem(
            progress: g.progress,
            text: g.text,
            isCustomTick: g.isCustomTick,
            goLeft: g.goLeft,
            isDone: g.isDone,
          ),
        )
        .toList();

    // 2. Если линейка была открыта из сохранённых (передан индекс) — обновляем её
    if (widget.existingIndex != null) {
      // Берём существующую линейку из хранилища по индексу
      final existingRuler = AppStorage().rulers[widget.existingIndex!];
      // Создаём обновлённую копию: имя оставляем прежним, даты и цели — текущие
      final updatedRuler = RulerSaveData(
        name: existingRuler.name, // имя не меняем
        start: widget.start,
        end: widget.end,
        goals: goalsToSave,
      );
      // Сохраняем изменения через новый метод updateRuler (его нужно добавить в AppStorage)
      await AppStorage().updateRuler(widget.existingIndex!, updatedRuler);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated → Settings → Saved')),
        );
        // При желании можно сразу закрыть экран:
        // Navigator.pop(context);
      }
      return; // Завершаем, ничего больше не делаем
    }

    // 3. Иначе (новая линейка) — работаем по старому сценарию
    if (!AppStorage().canSave) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The database is full (max 20). Delete one in Settings.',
          ),
        ),
      );
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SaveNameDialog(),
    );
    if (!mounted || name == null || name.isEmpty) return;
    await AppStorage().save(
      RulerSaveData(
        name: name,
        start: widget.start,
        end: widget.end,
        goals: goalsToSave,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved → Settings → Saved')));
  }

  Future<void> _autoSaveIfExisting() async {
    // Сохраняем только если это существующая линейка
    if (widget.existingIndex == null) return;

    final goalsToSave = _goals
        .map(
          (g) => GoalItem(
            progress: g.progress,
            text: g.text,
            isCustomTick: g.isCustomTick,
            goLeft: g.goLeft,
            isDone: g.isDone,
          ),
        )
        .toList();

    final existingRuler = AppStorage().rulers[widget.existingIndex!];
    final updatedRuler = RulerSaveData(
      name: existingRuler.name,
      start: widget.start,
      end: widget.end,
      goals: goalsToSave,
    );
    await AppStorage().updateRuler(widget.existingIndex!, updatedRuler);
  }

  // ── Виджеты ────────────────────────────────────────────────

  Widget _buildEditor() {
    final p = _editP!, y = _geo.sy(p), cx = _geo.cx(p);
    final leftEdge = cx - _geo.hw;
    final rightEdge = cx + _geo.hw;
    const gap = RulerGeometry.textGap;
    final leftAvail = (leftEdge - gap - 8.0).clamp(60.0, 170.0);
    final rightAvail = (_bodyW - rightEdge - gap - 8.0).clamp(60.0, 170.0);
    final goLeft = _editGoLeft;
    final double edW = math.min(goLeft ? leftAvail : rightAvail, 170.0);
    final double edL = goLeft ? leftEdge - gap - edW : rightEdge + gap;
    final double fromBottom = (_bodyH - y).clamp(0.0, _bodyH - 30);

    return Positioned(
      left: edL,
      width: edW,
      bottom: fromBottom,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 18),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF888888), width: 1.4),
            ),
          ),
          child: TextField(
            controller: _editCtrl,
            focusNode: _editFocus,
            maxLength: 100,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: Color.fromARGB(255, 165, 165, 165),
              fontSize: 14,
              fontStyle: FontStyle.normal,
              letterSpacing: 0.6,
              height: 1.45,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 4),
            ),
            onSubmitted: (_) => _confirmEdit(),
          ),
        ),
      ),
    );
  }

  // Widget _buildKbPreview(BuildContext ctx) --Тут был!

  // ── AppBar action: кнопка "✓" ──────────────────────────────

  // ── AppBar action: кнопка "S̶" ──────────────────────────────

  Widget _strikeBtn() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _editCtrl,
      builder: (_, val, __) {
        final active = val.selection.isValid && !val.selection.isCollapsed;
        return GestureDetector(
          onTap: active ? _toggleStrikethrough : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0x22FFFFFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? const Color(0x44FFFFFF)
                    : const Color(0x18FFFFFF),
                width: 0.6,
              ),
            ),
            child: Center(
              child: Text(
                'Done',
                style: TextStyle(
                  color: active
                      ? const Color.fromARGB(137, 28, 169, 9)
                      : Colors.white24,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: active ? Colors.white54 : Colors.white24,
                  decorationThickness: 1.6,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = _editP != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _autoSaveIfExisting();
        if (mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF05050D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF05050D),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white24),
          title: Text(
            '${_fmt(widget.start)}  –  ${_fmt(widget.end)}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            // ✓ Сделано — только для существующей цели
            //if (editing && _editExisting != null) _doneBtn(),
            // S̶ Зачёркивание — только при редактировании
            if (editing) _strikeBtn(),
            // Сохранить
            if (_goals.isNotEmpty && widget.existingIndex == null)
              GestureDetector(
                onTap: _onSave,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 10,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x33448AFF),
                    border: Border.all(
                      color: const Color(0x88448AFF),
                      width: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'Save',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: LayoutBuilder(
          builder: (ctx, constraints) {
            _bodyW = constraints.maxWidth;
            _bodyH = constraints.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (d) {
                    _scaleBase = _scale;
                    _focalY0 = d.localFocalPoint.dy;
                    _scroll0 = _scroll;
                    _wasTap = d.pointerCount == 1;
                    _tapDown = d.localFocalPoint;
                  },
                  onScaleUpdate: (d) {
                    setState(() {
                      if (d.pointerCount >= 2) {
                        _wasTap = false;
                        _scale = (_scaleBase * d.scale).clamp(1.0, 1.5);
                      } else {
                        final moved = (d.localFocalPoint - _tapDown).distance;
                        if (moved > 8) {
                          _wasTap = false;
                          final ns =
                              _scroll0 + (d.localFocalPoint.dy - _focalY0);
                          _scroll = ns.clamp(
                            -_bodyH * (_scale - 1.0) * 0.5,
                            _bodyH * (_scale - 1.0) * 0.5,
                          );
                        }
                      }
                    });
                  },
                  onScaleEnd: (_) {
                    if (_wasTap) _handleTap(_tapDown);
                    _wasTap = false;
                  },
                  child: CustomPaint(
                    painter: RulerPainter(
                      start: widget.start,
                      end: widget.end,
                      now: DateTime.now(),
                      scale: _scale,
                      scroll: _scroll,
                      screenWidth: _bodyW,
                      screenHeight: _bodyH,
                      goals: List.from(_goals),
                      editProgress: _editP,
                    ),
                    size: Size(_bodyW, _bodyH),
                  ),
                ),
                if (_editP != null) _buildEditor(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PAINTER
// ═══════════════════════════════════════════════════════════════

class RulerPainter extends CustomPainter {
  final DateTime start, end, now;
  final double scale, scroll, screenWidth, screenHeight;
  final List<GoalItem> goals;
  final double? editProgress;

  RulerPainter({
    required this.start,
    required this.end,
    required this.now,
    required this.scale,
    required this.scroll,
    required this.screenWidth,
    required this.screenHeight,
    required this.goals,
    this.editProgress,
  });

  RulerGeometry get _geo => RulerGeometry(
    screenWidth: screenWidth,
    screenHeight: screenHeight,
    scale: scale,
    scroll: scroll,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final ticks = buildRulerTicks(start, end, now);
    if (ticks.length < 2) return;
    _paintBody(canvas);
    _paintEnds(canvas);
    _paintAutoTicks(canvas, ticks, size);
    _paintCustomTicks(canvas, size);
    _paintGoals(canvas, size);
  }

  void _paintBody(Canvas canvas) {
    final g = _geo;
    final botY = g.sy(0), topY = g.sy(1);
    const steps = 100;
    final lp = Path(), rp = Path(), bp = Path();
    for (int i = 0; i <= steps; i++) {
      final p = i / steps.toDouble(), cx = g.cx(p), y = g.sy(p);
      if (i == 0) {
        lp.moveTo(cx - g.hw, y);
        rp.moveTo(cx + g.hw, y);
        bp.moveTo(cx - g.hw, y);
      } else {
        lp.lineTo(cx - g.hw, y);
        rp.lineTo(cx + g.hw, y);
        bp.lineTo(cx - g.hw, y);
      }
    }
    for (int i = steps; i >= 0; i--) {
      bp.lineTo(g.cx(i / steps.toDouble()) + g.hw, g.sy(i / steps.toDouble()));
    }
    bp.close();
    final gr = Rect.fromLTRB(
      g.axisX - g.hw,
      topY < botY ? topY : botY,
      g.axisX + g.maxBulge + g.hw,
      topY > botY ? topY : botY,
    );
    canvas.drawPath(
      bp,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF060609),
            Color(0xFF0A0A18),
            Color(0xFF0E0E22),
            Color(0xFF0A0A18),
            Color(0xFF060609),
          ],
          stops: [0.0, 0.2, 0.5, 0.78, 1.0],
        ).createShader(gr),
    );
    canvas.drawPath(
      lp,
      Paint()
        ..color = const Color(0x99000000)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      lp,
      Paint()
        ..color = const Color(0x66D8D8C0)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      rp,
      Paint()
        ..color = const Color(0xCCE8E8D0)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintEnds(Canvas canvas) {
    final g = _geo;
    for (final p in [0.0, 1.0]) {
      final y = g.sy(p), cx = g.cx(p);
      final rect = Rect.fromCenter(
        center: Offset(cx, y),
        width: (g.hw + 8) * 2,
        height: 20,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFF060609),
              Color(0xFF0E0E20),
              Color(0xFF060609),
            ],
          ).createShader(rect)
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..color = const Color(0x77D8D8C0)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _paintAutoTicks(Canvas canvas, List<RulerTick> ticks, Size size) {
    final g = _geo;
    final diffDays = end.difference(start).inDays;
    final nowLabel = diffDays <= 7 ? 'today' : 'now';
    final List<double> occupiedY = [];

    for (final t in ticks) {
      final y = g.sy(t.progress);
      if (y < -40 || y > size.height + 40) continue;
      final cx = g.cx(t.progress);
      final ip = t.isPsych ? 7.5 : 9.5;
      final Color gc;
      final double gw;
      if (t.isNow) {
        gc = const Color(0xFF64B5F6);
        gw = 5.0;
      } else if (t.isPsych) {
        gc = const Color(0xFFAAAAAA);
        gw = 2.8;
      } else {
        gc = const Color(0xFF555570);
        gw = 2.2;
      }
      canvas.drawLine(
        Offset(cx - g.hw + ip, y),
        Offset(cx + g.hw - ip, y),
        Paint()
          ..color = gc
          ..strokeWidth = gw
          ..strokeCap = StrokeCap.round,
      );
      final labelText = t.isNow ? nowLabel : t.label;
      if (labelText == null) continue;
      _drawLabelAvoid(
        canvas,
        labelText,
        cx,
        y,
        t.isNow,
        t.isPsych,
        g,
        occupiedY,
      );
    }
  }

  void _paintCustomTicks(Canvas canvas, Size size) {
    final g = _geo;
    for (final goal in goals) {
      if (!goal.isCustomTick) continue;
      final y = g.sy(goal.progress);
      if (y < -40 || y > size.height + 40) continue;
      final cx = g.cx(goal.progress);
      // Цвет гёте зависит от isDone
      final color = goal.isDone
          ? const Color(0xFF2A4A2A)
          : const Color(0xFF555570);
      canvas.drawLine(
        Offset(cx - g.hw + 9.5, y),
        Offset(cx + g.hw - 9.5, y),
        Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawLabelAvoid(
    Canvas canvas,
    String text,
    double cx,
    double y,
    bool isNow,
    bool isPsych,
    RulerGeometry g,
    List<double> occupiedY,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: isNow ? const Color(0xFF64B5F6) : const Color(0xFF888888),
          fontSize: isPsych ? 11.5 : 10,
          fontStyle: isNow ? FontStyle.italic : FontStyle.normal,
          letterSpacing: isNow ? 0.8 : 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final leftX = cx - g.hw - 8 - tp.width;
    final bool goLeft = leftX >= 2;
    final double textX = goLeft ? leftX : cx + g.hw + 8;
    double textY = y - tp.height / 2;
    const minGap = 3.0;
    bool shifted = true;
    int tries = 0;
    while (shifted && tries < 10) {
      shifted = false;
      for (final oy in occupiedY) {
        if ((textY - oy).abs() < tp.height + minGap) {
          textY = oy - tp.height - minGap;
          shifted = true;
          break;
        }
      }
      tries++;
    }
    occupiedY.add(textY);
    tp.paint(canvas, Offset(textX, textY));
  }

  void _paintGoals(Canvas canvas, Size size) {
    final g = _geo;
    const gap = RulerGeometry.textGap;
    const lineLen = 38.0;
    final List<double> occupiedLeft = [], occupiedRight = [];

    for (final goal in goals) {
      if (editProgress != null && (goal.progress - editProgress!).abs() < 0.004)
        continue;
      final y = g.sy(goal.progress);
      if (y < -200 || y > size.height + 200) continue;

      final cx = g.cx(goal.progress);
      final leftEdge = cx - g.hw;
      final rightEdge = cx + g.hw;
      final bool goLeft = goal.goLeft;
      final double maxTW = goLeft
          ? math.min(leftEdge - gap - 8.0, 160.0).clamp(40.0, 160.0)
          : math
                .min(screenWidth - rightEdge - gap - 8.0, 160.0)
                .clamp(40.0, 160.0);

      // Стиль текста: если isDone — тусклее
      final baseStyle = TextStyle(
        color: goal.isDone
            ? const Color(0xFF444455)
            : const Color.fromARGB(255, 165, 165, 165),
        fontSize: 13,
        fontStyle: FontStyle.normal,
        letterSpacing: 0.5,
        height: 1.45,
      );

      final spans = parseStrikethrough(goal.text, baseStyle);
      final tp = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr,
        maxLines: 6,
      )..layout(maxWidth: maxTW);

      final occupied = goLeft ? occupiedLeft : occupiedRight;
      double textY = y - tp.height - 5;
      const minGap = 4.0;
      bool shifted = true;
      int tries = 0;
      while (shifted && tries < 15) {
        shifted = false;
        for (final oy in occupied) {
          if ((textY - oy).abs() < tp.height + minGap) {
            textY = oy - tp.height - minGap;
            shifted = true;
            break;
          }
        }
        tries++;
      }
      occupied.add(textY);

      // Цвет линии и точки зависит от isDone
      final lineColor = goal.isDone
          ? const Color(0x332A5A2A)
          : const Color(0x55AAAAAA);
      final dotColor = goal.isDone
          ? const Color(0xFF2A5A2A)
          : const Color(0x88AAAAAA);

      if (goLeft) {
        final lsX = leftEdge - gap;
        final leX = math.max(8.0, lsX - lineLen);
        canvas.drawLine(
          Offset(lsX, y),
          Offset(leX, y),
          Paint()
            ..color = lineColor
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(Offset(lsX, y), 2.0, Paint()..color = dotColor);

        // Галочка ✓ рядом с точкой если isDone

        tp.paint(canvas, Offset(math.max(8.0, leX - tp.width), textY));
      } else {
        final lsX = rightEdge + gap;
        final leX = math.min(screenWidth - 8.0, lsX + lineLen);
        canvas.drawLine(
          Offset(lsX, y),
          Offset(leX, y),
          Paint()
            ..color = lineColor
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(Offset(lsX, y), 2.0, Paint()..color = dotColor);

        // if (goal.isDone) {

        tp.paint(canvas, Offset(lsX, textY));
      }
    }
  }

  @override
  @override
  bool shouldRepaint(RulerPainter o) =>
      o.scale != scale ||
      o.scroll != scroll ||
      o.start != start ||
      o.end != end ||
      o.goals.length != goals.length ||
      o.editProgress != editProgress;
}
