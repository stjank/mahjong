import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HofEntry {
  final int seconds;
  final DateTime date;

  const HofEntry(this.seconds, this.date);

  Map<String, dynamic> toJson() => {
        'seconds': seconds,
        'date': date.toIso8601String(),
      };

  factory HofEntry.fromJson(Map<String, dynamic> json) => HofEntry(
        json['seconds'] as int,
        DateTime.parse(json['date'] as String),
      );
}

class HallOfFame extends ChangeNotifier {
  static const _prefKey = 'hof_v1';
  static const _maxEntries = 5;

  final Map<String, List<HofEntry>> _entries = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _entries
      ..clear()
      ..addAll(map.map((k, v) => MapEntry(
            k,
            (v as List)
                .map((e) => HofEntry.fromJson(e as Map<String, dynamic>))
                .toList(),
          )));
  }

  List<HofEntry> getEntries(String layoutId) =>
      List.unmodifiable(_entries[layoutId] ?? []);

  /// Adds [seconds] for [layoutId], keeps top [_maxEntries] sorted ascending.
  /// Returns the 1-based rank of the new entry, or null if it didn't make the list.
  Future<int?> addEntry(String layoutId, int seconds) async {
    final list = List<HofEntry>.from(_entries[layoutId] ?? []);
    list.add(HofEntry(seconds, DateTime.now()));
    list.sort((a, b) => a.seconds.compareTo(b.seconds));

    final rank = list.indexWhere((e) => e.seconds == seconds) + 1;

    _entries[layoutId] = list.take(_maxEntries).toList();

    await _save();
    notifyListeners();

    return rank <= _maxEntries ? rank : null;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
    );
    await prefs.setString(_prefKey, encoded);
  }
}
