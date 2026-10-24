import 'package:flutter/material.dart';
import 'models.dart';

class BirthDateSettingTile extends StatefulWidget {
  final VoidCallback? onChanged;

  const BirthDateSettingTile({super.key, this.onChanged});

  @override
  State<BirthDateSettingTile> createState() => _BirthDateSettingTileState();
}

class _BirthDateSettingTileState extends State<BirthDateSettingTile> {
  String get _dateLabel {
    final d = AppStorage().birthDate;
    if (d == null) return 'not set';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF08080F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _BirthDateEditSheet(
        initial: AppStorage().birthDate,
        onSaved: (date) async {
          await AppStorage().saveBirthDate(date);
          if (mounted) {
            setState(() {});
            widget.onChanged?.call();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF111122), width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x55FFD700), width: 0.8),
                color: const Color(0x0AFFD700),
              ),
              child: const Center(
                child: Text(
                  '✦',
                  style: TextStyle(color: Color(0xAAFFD700), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Birth Date',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel,
                    style: const TextStyle(
                      color: Color(0xFF555577),
                      fontSize: 12,
                      letterSpacing: 1.0,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Color(0xFF333355), size: 20),
          ],
        ),
      ),
    );
  }
}

class _BirthDateEditSheet extends StatefulWidget {
  final DateTime? initial;
  final Future<void> Function(DateTime) onSaved;

  const _BirthDateEditSheet({required this.initial, required this.onSaved});

  @override
  State<_BirthDateEditSheet> createState() => _BirthDateEditSheetState();
}

class _BirthDateEditSheetState extends State<_BirthDateEditSheet> {
  late int _day, _month, _year;
  late FixedExtentScrollController _dayCtrl, _monthCtrl, _yearCtrl;
  bool _saving = false;

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

  int get _maxDay => DateTime(_year, _month + 1, 0).day;
  List<String> get _dayItems =>
      List.generate(_maxDay, (i) => (i + 1).toString().padLeft(2, '0'));
  List<String> get _yearItems {
    final now = DateTime.now().year;
    return List.generate(now - 1929, (i) => '${1930 + i}');
  }

  @override
  void initState() {
    super.initState();
    final d = widget.initial ?? DateTime.now();
    _day = d.day;
    _month = d.month;
    _year = d.year.clamp(1930, DateTime.now().year);

    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _year - 1930);
  }

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

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
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onSaved(DateTime(_year, _month, _day));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF222233),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'choose your birth date',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 15,
                letterSpacing: 1.0,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SettingsDrum(
                  controller: _dayCtrl,
                  items: _dayItems,
                  width: 70,
                  onChanged: (i) {
                    _day = i + 1;
                    setState(() {});
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    ' · ',
                    style: TextStyle(color: Color(0xFF333355), fontSize: 24),
                  ),
                ),
                _SettingsDrum(
                  controller: _monthCtrl,
                  items: _months,
                  width: 70,
                  onChanged: (i) {
                    _month = i + 1;
                    _clampDay();
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    ' · ',
                    style: TextStyle(color: Color(0xFF333355), fontSize: 24),
                  ),
                ),
                _SettingsDrum(
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

            const SizedBox(height: 36),

            GestureDetector(
              onTap: _save,
              child: Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xAAFFD700),
                    width: 0.8,
                  ),
                  color: const Color(0x14FFD700),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33FFD700), blurRadius: 14),
                  ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFD700),
                            strokeWidth: 1.5,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 14,
                            letterSpacing: 2.0,
                            fontStyle: FontStyle.italic,
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
}

class _SettingsDrum extends StatefulWidget {
  final FixedExtentScrollController controller;
  final List<String> items;
  final double width;
  final ValueChanged<int> onChanged;

  const _SettingsDrum({
    required this.controller,
    required this.items,
    required this.width,
    required this.onChanged,
  });

  @override
  State<_SettingsDrum> createState() => _SettingsDrumState();
}

class _SettingsDrumState extends State<_SettingsDrum> {
  int _sel = 0;

  @override
  void initState() {
    super.initState();
    _sel = widget.controller.initialItem.clamp(0, widget.items.length - 1);
  }

  @override
  void didUpdateWidget(_SettingsDrum oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      final clamped = _sel.clamp(0, widget.items.length - 1);
      if (clamped != _sel) setState(() => _sel = clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    const itemH = 42.0;
    return SizedBox(
      width: widget.width,
      height: itemH * 5,
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: widget.controller,
            itemExtent: itemH,
            perspective: 0.002,
            diameterRatio: 2.0,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) {
              final c = i.clamp(0, widget.items.length - 1);
              setState(() => _sel = c);
              widget.onChanged(c);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.items.length,
              builder: (ctx, i) {
                final sel = i == _sel;
                return Center(
                  child: Text(
                    widget.items[i],
                    style: TextStyle(
                      color: sel
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF2D2D4A),
                      fontSize: sel ? 20 : 14,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w300,
                      letterSpacing: 0.4,
                    ),
                  ),
                );
              },
            ),
          ),
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
                    colors: [Color(0xFF08080F), Color(0x0008080F)],
                  ),
                ),
              ),
            ),
          ),
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
                    colors: [Color(0xFF08080F), Color(0x0008080F)],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: IgnorePointer(
              child: SizedBox(
                height: itemH,
                child: Column(
                  children: [
                    Container(height: 0.7, color: const Color(0x44FFD700)),
                    const Spacer(),
                    Container(height: 0.7, color: const Color(0x44FFD700)),
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
