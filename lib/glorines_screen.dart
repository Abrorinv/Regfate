import 'package:flutter/material.dart';
import 'models.dart';

// ═══════════════════════════════════════════════════════════════
//  ГЛАВНЫЙ ЭКРАН — ГЛОРИНЕС
//  Постоянные слова автора + кнопка в "Слова себе"
// ═══════════════════════════════════════════════════════════════

// Постоянные афоризмы — только автор меняет (прямо в коде)
const List<String> _authorWords = [
  'He who fails to complete the task on time has not lost. Because it can be done later — the main thing is not to give up until the task is completed.',
  'The time you wasted going in the wrong direction showed you where you really needed to go.',
  'The most important things in life almost never happen according to plan. They happen because you did not quit.',
  'Most people overestimate a year and underestimate ten years. Do not panic about the first and do not forget the second.',
  //'Start. The rest will follow.',
];

class GlorinesScreen extends StatelessWidget {
  const GlorinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white24),
        title: const Text(
          'Words',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 16,
            letterSpacing: 2.0,
            fontStyle: FontStyle.normal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Метка раздела ──────────────────────────────────
          /*
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'for all',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                letterSpacing: 2.0,
              ),
            ),
          ),
          */
          // ── Постоянные слова автора ────────────────────────
          ..._authorWords.map((text) => _AuthorWordCard(text: text)),

          const SizedBox(height: 32),

          // ── Кнопка в "Слова себе" ──────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WordsToSelfScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x22FFFFFF), width: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    color: Colors.white24,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  КАРТОЧКА СЛОВА АВТОРА
// ═══════════════════════════════════════════════════════════════

class _AuthorWordCard extends StatelessWidget {
  final String text;
  const _AuthorWordCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A2E), width: 0.7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Вертикальная линия слева — как засечка на линейке
          Container(
            width: 1.5,
            height: 14,
            margin: const EdgeInsets.only(top: 4, right: 14),
            color: const Color(0xFF444466),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ЭКРАН "СЛОВА СЕБЕ"
// ═══════════════════════════════════════════════════════════════

class WordsToSelfScreen extends StatefulWidget {
  const WordsToSelfScreen({super.key});
  @override
  State<WordsToSelfScreen> createState() => _WordsToSelfScreenState();
}

class _WordsToSelfScreenState extends State<WordsToSelfScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      AppStorage().addWord(UserWord(text: text));
      _ctrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  void _delete(int index) {
    setState(() => AppStorage().deleteWord(index));
  }

  void _edit(int index) {
    final word = AppStorage().words[index];
    _ctrl.text = word.text;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C0C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 300,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterStyle: TextStyle(color: Colors.white24, fontSize: 10),
                hintText: '......',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _ctrl.clear();
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A3A),
                  ),
                  onPressed: () {
                    final t = _ctrl.text.trim();
                    if (t.isNotEmpty) {
                      setState(() => AppStorage().editWord(index, t));
                    }
                    _ctrl.clear();
                    Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final words = AppStorage().words;
    return Scaffold(
      backgroundColor: const Color(0xFF05050D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05050D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white24),
        title: const Text(
          'my words',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 15,
            letterSpacing: 2.0,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Слова автора вверху (компактно) ───────────────────

          // ── Список слов пользователя ──────────────────────────
          Expanded(
            child: words.isEmpty
                ? const Center(
                    child: Text(
                      'no words yet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    itemCount: words.length,
                    itemBuilder: (_, i) => _SwipeWordTile(
                      onDelete: () => _delete(i),
                      onEdit: () => _edit(i),
                      child: _UserWordCard(word: words[i]),
                    ),
                  ),
          ),

          // ── Поле ввода + кнопка "добавить слова" ─────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF08080F),
              border: Border(
                top: BorderSide(color: Color(0xFF1A1A2E), width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    constraints: const BoxConstraints(
                      maxHeight: 300, // ≈ 16 строк
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1E1E3A),
                        width: 0.7,
                      ),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      maxLength: 10000,
                      style: const TextStyle(
                        color: Color.fromARGB(196, 255, 255, 255),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        counterText: '',
                        hintText: '......',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(76, 255, 255, 255),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _add,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2A2A4A),
                        width: 0.7,
                      ),
                    ),
                    child: const Text(
                      'add',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        letterSpacing: 0.7,
                        height: 0.9,
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
}

// ═══════════════════════════════════════════════════════════════
//  КАРТОЧКА СЛОВА ПОЛЬЗОВАТЕЛЯ
// ═══════════════════════════════════════════════════════════════

class _SwipeWordTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SwipeWordTile({
    required this.child,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SwipeWordTile> createState() => _SwipeWordTileState();
}

class _SwipeWordTileState extends State<_SwipeWordTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  // -1 = влево (delete), 0 = нейтраль, 1 = вправо (edit)
  int _direction = 0;
  static const double _revealOffset = 64.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -200 && _direction == 0) {
      // свайп влево → delete
      setState(() => _direction = -1);
      _ctrl.forward();
    } else if (v > 200 && _direction == 0) {
      // свайп вправо → edit
      setState(() => _direction = 1);
      _ctrl.forward();
    } else if (_direction != 0) {
      // закрыть
      _ctrl.reverse().then((_) {
        if (mounted) setState(() => _direction = 0);
      });
    }
  }

  void _close() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _direction = 0);
    });
  }

  void _onDelete() {
    _ctrl.animateTo(
      1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeIn,
    );
    Future.delayed(const Duration(milliseconds: 150), widget.onDelete);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _onDragEnd,
      onTap: _direction != 0 ? _close : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, child) {
          final offset = _anim.value * _revealOffset * _direction;
          return Stack(
            children: [
              // ── Кнопка DELETE (справа, при свайпе влево) ──
              if (_direction == -1)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _onDelete,
                    child: AnimatedOpacity(
                      opacity: _anim.value,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: _revealOffset + 8,
                        alignment: Alignment.center,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x44FF3333),
                            borderRadius: BorderRadius.circular(22),
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

              // ── Кнопка EDIT (слева, при свайпе вправо) ────
              if (_direction == 1)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _close();
                      widget.onEdit();
                    },
                    child: AnimatedOpacity(
                      opacity: _anim.value,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: _revealOffset + 8,
                        alignment: Alignment.center,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0x44334488),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0x884455AA),
                              width: 0.8,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xCC6677CC),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Сама карточка — сдвигается ─────────────────
              Transform.translate(offset: Offset(offset, 0), child: child),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _UserWordCard extends StatelessWidget {
  final UserWord word;
  const _UserWordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(118, 14, 14, 31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 39, 39, 55),
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.2,
            height: 12,
            margin: const EdgeInsets.only(top: 4, right: 12),
            color: const Color(0xFF333355),
          ),
          Expanded(
            child: Text(
              word.text,
              style: const TextStyle(
                color: Color.fromARGB(231, 170, 170, 170),
                fontSize: 15,
                fontStyle: FontStyle.normal,
                height: 1.6,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
