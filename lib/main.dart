import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animated_analog_clock/animated_analog_clock.dart';
import 'models.dart';
import 'ruler_screen.dart';
import 'glorines_screen.dart';
import 'clock_screen.dart';
import 'entire_life_screen.dart';

void main() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class DualDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final raw = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 16) return old;
    final buf = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i == 8) buf.write(' | ');
      if (i == 2 || i == 4) buf.write('.');
      if (i == 10 || i == 12) buf.write('.');
      buf.write(raw[i]);
    }
    final s = buf.toString();
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Regfate',
    theme: ThemeData.dark(),
    home: const _AppLoader(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: child!,
    ),
  );
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();
  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    AppStorage().load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded)
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white12)),
      );
    return const MainScreen();
  }
}

// ═══════════════════════════════════════════════════════════════
//  ГЛАВНЫЙ ЭКРАН
// ═══════════════════════════════════════════════════════════════

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  DateTime _selectedDay = DateTime.now();
  final _ctrl = TextEditingController();
  DateTime? _start, _end;

  // ── Заметка календаря ──────────────────────────────────────
  bool _calNoteOpen = false;
  final TextEditingController _calNoteCtrl = TextEditingController();
  final FocusNode _calNoteFocus = FocusNode(); // ← добавь
  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChange);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _ctrl.dispose();
    _calNoteCtrl.dispose();
    _calNoteFocus.dispose(); // ← добавь
    super.dispose();
  }

  DateTime? _parse(String d) {
    if (d.length < 8) return null;
    final dd = int.tryParse(d.substring(0, 2));
    final mm = int.tryParse(d.substring(2, 4));
    final yy = int.tryParse(d.substring(4, 8));
    if (dd == null || mm == null || yy == null) return null;
    if (dd < 1 || dd > 31 || mm < 1 || mm > 12 || yy < 1924 || yy > 2124)
      return null;
    try {
      return DateTime(yy, mm, dd);
    } catch (_) {
      return null;
    }
  }

  void _onChange() {
    final raw = _ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      _start = raw.length >= 8 ? _parse(raw.substring(0, 8)) : null;
      _end = raw.length >= 16 ? _parse(raw.substring(8, 16)) : null;
    });
  }

  bool get _ready =>
      _start != null && _end != null && _end!.difference(_start!).inDays >= 3;

  void _go(Widget w) {
    FocusScope.of(context).unfocus();
    if (_calNoteOpen) _dismissCalNote();
    Navigator.push(context, MaterialPageRoute(builder: (_) => w));
  }

  // ── Заметки календаря ──────────────────────────────────────

  void _openCalNote(DateTime day) {
    final existing = AppStorage().getCalNote(day);
    _calNoteCtrl.text = existing ?? '';
    setState(() => _calNoteOpen = true);
  }

  void _closeCalNote() {
    AppStorage().setCalNote(_selectedDay, _calNoteCtrl.text);
    _calNoteCtrl.clear();
    setState(() => _calNoteOpen = false);
    Future.delayed(const Duration(milliseconds: 50), () {
      _calNoteFocus.unfocus();
    });
  }

  void _dismissCalNote() {
    _calNoteCtrl.clear();
    setState(() => _calNoteOpen = false);
    Future.delayed(const Duration(milliseconds: 50), () {
      _calNoteFocus.unfocus();
    });
  }

  Widget _buildCalNoteOverlay() {
    final d = _selectedDay;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');

    return AnimatedSlide(
      offset: _calNoteOpen ? Offset.zero : const Offset(0, -1.5),
      duration: const Duration(milliseconds: 300),
      curve: _calNoteOpen ? Curves.easeOutCubic : Curves.easeInCubic,
      child: AnimatedOpacity(
        opacity: _calNoteOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: GestureDetector(
            onTap: () {}, // не закрывать при тапе внутри
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF08080F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E1E38), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Дата слева
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$dd.$mm',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 132, 132, 214),
                          fontSize: 20,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2.0,
                        ),
                      ),
                      Text(
                        '${d.year}',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 114, 114, 187),
                          fontSize: 13,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),
                  Container(
                    width: 0.5,
                    height: 38,
                    color: const Color(0xFF1A1A30),
                  ),
                  const SizedBox(width: 14),

                  // Поле ввода
                  Expanded(
                    child: TextField(
                      controller: _calNoteCtrl,
                      // стало:
                      autofocus: false,
                      focusNode: _calNoteFocus,
                      maxLength: 150,
                      maxLines: 6,
                      style: const TextStyle(
                        color: Color.fromARGB(238, 148, 148, 148),
                        fontSize: 16,
                        height: 1.45,
                        fontStyle: FontStyle.normal,
                        letterSpacing: 0.8,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        counterText: '',
                        hintText: 'note for the day...',
                        contentPadding: EdgeInsets.zero,
                        hintStyle: TextStyle(
                          color: Color.fromARGB(255, 123, 123, 175),
                          fontSize: 16,
                        ),
                      ),
                      onSubmitted: (_) => _closeCalNote(),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Кнопки
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _closeCalNote,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0C20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF252545),
                              width: 0.6,
                            ),
                          ),
                          child: const Text(
                            'ok',
                            style: TextStyle(
                              color: Color(0xFF5555AA),
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _dismissCalNote,
                        child: const Text(
                          'cancel',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Кнопка ─────────────────────────────────────────────────

  Widget _styledCircleButton({
    required VoidCallback onTap,
    double size = 60,
    Color borderColor = const Color.fromARGB(255, 49, 42, 148),
    double borderWidth = 2.0,
    Color bgColor = Colors.black,
    Widget? child,
    bool isVerticalCapsule = false, // новый параметр
  }) {
    final double capsuleWidth = size * 1.0; // уже
    final double capsuleHeight = size * 1.6; // выше
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isVerticalCapsule ? capsuleWidth : size,
        height: isVerticalCapsule ? capsuleHeight : size,

        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: isVerticalCapsule
              ? BorderRadius.circular(capsuleWidth / 2) // закруглённые концы
              : null,
          shape: isVerticalCapsule ? BoxShape.rectangle : BoxShape.circle,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Закрыть заметку при тапе вне панели
      onTap: _calNoteOpen ? _closeCalNote : null,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Основной layout ──────────────────────────────────
            Column(
              children: [
                Expanded(
                  flex: 55,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        left: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 255,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        47,
                                        40,
                                        142,
                                      ),
                                      width: 2.0,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _ctrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [DualDateFormatter()],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 203, 203, 203),
                                      fontSize: 16,
                                      letterSpacing: 0.8,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'DD.MM.YYYY | DD.MM.YYYY',
                                      hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    onSubmitted: (_) {
                                      if (_ready)
                                        _go(
                                          RulerScreen(
                                            start: _start!,
                                            end: _end!,
                                          ),
                                        );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_ready)
                                  _styledCircleButton(
                                    size: 40,
                                    borderColor: const Color.fromARGB(
                                      255,
                                      20,
                                      17,
                                      53,
                                    ),
                                    borderWidth: 2,
                                    bgColor: const Color.fromARGB(
                                      255,
                                      42,
                                      37,
                                      118,
                                    ),
                                    onTap: () => _go(
                                      RulerScreen(start: _start!, end: _end!),
                                    ),
                                    child: const Icon(
                                      Icons.timeline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 70),
                            AnimatedAnalogClock(
                              size: 280,
                              backgroundColor: Colors.transparent,
                              backgroundGradient: const RadialGradient(
                                center: Alignment.center,
                                radius: 0.9,
                                colors: [
                                  Color.fromARGB(255, 27, 14, 50),
                                  Color(0xFF0A0A18),
                                  Color(0xFF060609),
                                ],
                                stops: [0.0, 0.6, 1.0],
                              ),
                              hourHandColor: Colors.white70,
                              minuteHandColor: Colors.white70,
                              secondHandColor: const Color.fromARGB(
                                255,
                                42,
                                37,
                                118,
                              ),
                              centerDotColor: const Color.fromARGB(
                                255,
                                42,
                                37,
                                118,
                              ),
                              hourDashColor: Colors.white54,
                              minuteDashColor: Colors.white38,
                              dialType: DialType.numberAndDashes,
                              numberColor: Colors.white70,
                              showSecondHand: true,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 40,
                        right: 15,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _styledCircleButton(
                              onTap: () => _go(const SettingsScreen()),
                              child: const Icon(
                                Icons.legend_toggle,
                                color: Colors.white70,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _styledCircleButton(
                              onTap: () => _go(const ClockScreen()),
                              isVerticalCapsule: true,
                              child: const Icon(
                                Icons.access_time,
                                color: Colors.white70,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _styledCircleButton(
                              onTap: () => _go(const GlorinesScreen()),
                              child: const Icon(
                                Icons.hive,
                                color: Colors.white70,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _styledCircleButton(
                              onTap: () => _go(const EntireLifeScreen()),
                              isVerticalCapsule: true,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white70,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 45,
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _selectedDay,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    onDaySelected: (s, _) {
                      setState(() => _selectedDay = s);
                      _openCalNote(s); // ← перенесли открытие сюда
                    },
                    // Точки на датах с заметками
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (ctx, day, events) {
                        final hasNote = AppStorage().getCalNote(day) != null;
                        if (!hasNote) return const SizedBox.shrink();
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 129, 40, 30),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: Colors.white70),
                      weekendTextStyle: const TextStyle(
                        color: Color.fromARGB(255, 71, 64, 166),
                      ),
                      todayTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromARGB(255, 76, 11, 136),
                          width: 1,
                        ),
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromARGB(255, 49, 42, 148),
                          width: 1,
                        ),
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                      formatButtonVisible: false,
                      titleCentered: true,
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Color.fromARGB(198, 251, 251, 252),
                        size: 24,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Color.fromARGB(198, 251, 251, 252),
                        size: 24,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(color: Colors.white70),
                      weekendStyle: TextStyle(
                        color: Color.fromARGB(255, 71, 64, 166),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Панель заметки (поверх всего, спускается сверху) ─
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: _buildCalNoteOverlay(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  СВАЙП ДЛЯ УДАЛЕНИЯ
// ═══════════════════════════════════════════════════════════════

class _SwipeToDeleteTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeToDeleteTile({
    super.key,
    required this.child,
    required this.onDelete,
  });

  @override
  State<_SwipeToDeleteTile> createState() => _SwipeToDeleteTileState();
}

class _SwipeToDeleteTileState extends State<_SwipeToDeleteTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;

  static const double _revealOffset = 56.0;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-_revealOffset, 0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
      if (!_revealed) {
        setState(() => _revealed = true);
        _ctrl.forward();
      }
    }
    if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
      if (_revealed) {
        setState(() => _revealed = false);
        _ctrl.reverse();
      }
    }
  }

  void _onTapOutside() {
    if (_revealed) {
      setState(() => _revealed = false);
      _ctrl.reverse();
    }
  }

  void _onDelete() {
    _ctrl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeIn,
    );
    Future.delayed(const Duration(milliseconds: 180), () {
      widget.onDelete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onTap: _onTapOutside,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _revealed ? _onDelete : null,
                child: AnimatedOpacity(
                  opacity: _revealed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: _revealOffset + 8,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0x44FF3333),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0x88FF4444),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Color(0xCCFF4444),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (_, child) =>
                Transform.translate(offset: _slideAnim.value, child: child),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  НАСТРОЙКИ
// ═══════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _z(int n) => n.toString().padLeft(2, '0');
  String _fmt(DateTime d) => '${_z(d.day)}.${_z(d.month)}.${d.year}';

  Future<void> _editBirthDate() async {
    final current = AppStorage().birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: Color.fromARGB(255, 9, 9, 22), // Фон всего диалога
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue,
            onPrimary: Colors.white,
            surface: Color(0xFF0C0C1E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      await AppStorage().saveBirthDate(picked);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulers = AppStorage().rulers;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Data'), backgroundColor: Colors.black),
      body: ListView(
        children: [
          // ── Сохранённые линейки ──────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Text(
              'saved rulers',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 12,
                letterSpacing: 1.8,
              ),
            ),
          ),
          if (rulers.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'Empty — open a period, add goals, and Save',
                style: TextStyle(
                  color: Color.fromARGB(107, 255, 255, 255),
                  fontSize: 15,
                ),
              ),
            )
          else ...[
            ...List.generate(rulers.length, (i) {
              final r = rulers[i];
              return _SwipeToDeleteTile(
                key: ObjectKey(r),
                onDelete: () {
                  AppStorage().delete(i);
                  setState(() {});
                },
                child: ListTile(
                  title: Text(
                    r.name,
                    style: const TextStyle(
                      color: Color.fromARGB(231, 255, 255, 255),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${_fmt(r.start)} – ${_fmt(r.end)}  ·  ${r.goals.length} goals',
                    style: const TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white24,
                    size: 14,
                  ),
                  onTap: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RulerScreen(
                            start: r.start,
                            end: r.end,
                            savedGoals: r.goals,
                            existingIndex: i,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      }),
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                '← swipe left to delete',
                style: TextStyle(
                  color: Color.fromARGB(73, 255, 255, 255),
                  fontSize: 12,
                ),
              ),
            ),
          ],

          // ── Entire Life ──────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 8),
            child: Text(
              'entire life',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 11,
                letterSpacing: 1.8,
              ),
            ),
          ),
          ListTile(
            title: const Text(
              'birth date',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Text(
              AppStorage().birthDate != null
                  ? _fmt(AppStorage().birthDate!)
                  : 'not set',
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            trailing: const Icon(Icons.edit, color: Colors.white24, size: 16),
            onTap: () => _editBirthDate(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ОСТАЛЬНЫЕ ЭКРАНЫ
// ═══════════════════════════════════════════════════════════════
/*
class EntireLifeScreen extends StatelessWidget {
  const EntireLifeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(title: const Text('Entire Life')),
    body: const Center(
      child: Text(
        'Линейка жизни — в разработке',
        style: TextStyle(color: Colors.white70),
      ),
    ),
  );
}
*/
