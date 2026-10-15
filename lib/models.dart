// ═══════════════════════════════════════════════════════════════
//  MODELS — общие модели данных всего приложения
// ═══════════════════════════════════════════════════════════════
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ── Цель на линейке ────────────────────────────────────────────

class GoalItem {
  double progress;
  String text;
  final bool isCustomTick;
  final bool goLeft;
  bool isDone; // ← добавь

  GoalItem({
    required this.progress,
    required this.text,
    this.isCustomTick = false,
    this.goLeft = true,
    this.isDone = false, // ← добавь
  });

  Map<String, dynamic> toJson() => {
    'p': progress, 't': text,
    'c': isCustomTick, 'l': goLeft,
    'd': isDone, // ← добавь
  };

  factory GoalItem.fromJson(Map<String, dynamic> j) => GoalItem(
    progress: (j['p'] as num).toDouble(),
    text: j['t'] as String,
    isCustomTick: j['c'] as bool? ?? false,
    goLeft: j['l'] as bool? ?? true,
    isDone: j['d'] as bool? ?? false, // ← добавь
  );
}

// ── Сохранённая линейка ────────────────────────────────────────

class RulerSaveData {
  final String name;
  final DateTime start, end;
  final List<GoalItem> goals;

  RulerSaveData({
    required this.name,
    required this.start,
    required this.end,
    required this.goals,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'goals': goals.map((g) => g.toJson()).toList(),
  };

  factory RulerSaveData.fromJson(Map<String, dynamic> j) => RulerSaveData(
    name: j['name'] as String,
    start: DateTime.parse(j['start'] as String),
    end: DateTime.parse(j['end'] as String),
    goals: (j['goals'] as List)
        .map((g) => GoalItem.fromJson(g as Map<String, dynamic>))
        .toList(),
  );
}

// ── Личное слово пользователя (для экрана "Слова себе") ────────

class UserWord {
  String text;
  UserWord({required this.text});

  Map<String, dynamic> toJson() => {'text': text};

  factory UserWord.fromJson(Map<String, dynamic> json) =>
      UserWord(text: json['text'] as String);
}

// ═══════════════════════════════════════════════════════════════
//  ХРАНИЛИЩЕ
// ═══════════════════════════════════════════════════════════════

class AppStorage {
  static final AppStorage _instance = AppStorage._();
  factory AppStorage() => _instance;
  AppStorage._();

  static const String _rulersKey = 'saved_rulers';
  static const String _wordsKey = 'user_words';
  static const String _birthDateKey = 'birth_date';
  static const String _calendarNotesKey = 'calendar_notes';

  // ── Линейки ────────────────────────────────────────────────
  static const int maxRulers = 20;
  final List<RulerSaveData> rulers = [];
  DateTime? _birthDate;
  DateTime? get birthDate => _birthDate;

  bool get canSave => rulers.length < maxRulers;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final String? rulersJson = prefs.getString(_rulersKey);
    if (rulersJson != null) {
      final List<dynamic> list = json.decode(rulersJson);
      rulers.clear();
      rulers.addAll(list.map((item) => RulerSaveData.fromJson(item)));
      final String? bdStr = prefs.getString(_birthDateKey);
      if (bdStr != null) {
        _birthDate = DateTime.tryParse(bdStr);
      }
    }

    final String? wordsJson = prefs.getString(_wordsKey);
    if (wordsJson != null) {
      final List<dynamic> list = json.decode(wordsJson);
      words.clear();
      words.addAll(list.map((item) => UserWord.fromJson(item)));
    }
    final String? calendarJson = prefs.getString(_calendarNotesKey);
    if (calendarJson != null) {
      final Map<String, dynamic> map = json.decode(calendarJson);
      _calendarNotes.clear();
      map.forEach((key, value) {
        _calendarNotes[key] = value as String;
      });
    }
  }

  Future<void> _saveRulers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _rulersKey,
      json.encode(rulers.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _wordsKey,
      json.encode(words.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveCalendarNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_calendarNotes);
    await prefs.setString(_calendarNotesKey, jsonStr);
  }

  Future<void> save(RulerSaveData data) async {
    if (rulers.length >= maxRulers) rulers.removeAt(0);
    rulers.add(data);
    await _saveRulers();
  }

  Future<void> updateRuler(int index, RulerSaveData data) async {
    if (index >= 0 && index < rulers.length) {
      rulers[index] = data;
      await _saveRulers();
    }
  }

  Future<void> delete(int index) async {
    rulers.removeAt(index);
    await _saveRulers();
  }

  Future<void> saveBirthDate(DateTime date) async {
    _birthDate = DateTime(date.year, date.month, date.day);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_birthDateKey, _birthDate!.toIso8601String());
  }

  Future<void> clearBirthDate() async {
    _birthDate = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_birthDateKey);
  }

  // ── Заметки календаря ───────────────────────────────────────
  final Map<String, String> _calendarNotes = {};

  String _calKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? getCalNote(DateTime d) => _calendarNotes[_calKey(d)];

  void setCalNote(DateTime d, String text) {
    if (text.trim().isEmpty) {
      _calendarNotes.remove(_calKey(d));
    } else {
      _calendarNotes[_calKey(d)] = text.trim();
    }
    _saveCalendarNotes(); // ← добавить эту строку
  }

  // ── Личные слова ────────────────────────────────────────────
  final List<UserWord> words = [];

  void addWord(UserWord word) {
    words.add(word);
    _saveWords();
  }

  void deleteWord(int index) {
    words.removeAt(index);
    _saveWords();
  }

  void editWord(int index, String newText) {
    words[index].text = newText;
    _saveWords();
  }
}
