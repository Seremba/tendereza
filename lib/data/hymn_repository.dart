import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hymn.dart';

class HymnRepository {
  static List<Hymn>? _englishHymns;
  static List<Hymn>? _lugandaHymns;

  static Future<List<Hymn>> loadEnglish() async {
    if (_englishHymns != null) return _englishHymns!;
    final raw = await rootBundle.loadString('assets/data/hymns_en.json');
    final list = jsonDecode(raw) as List;
    _englishHymns = list.map((e) => Hymn.fromJson(e)).toList();
    return _englishHymns!;
  }

  static Future<List<Hymn>> loadLuganda() async {
    if (_lugandaHymns != null) return _lugandaHymns!;
    final raw = await rootBundle.loadString('assets/data/hymns_lg.json');
    final list = jsonDecode(raw) as List;
    _lugandaHymns = list.map((e) => Hymn.fromJson(e)).toList();
    return _lugandaHymns!;
  }

  /// Returns hymns matching number, title, or first line (case-insensitive).
  static List<Hymn> search(List<Hymn> hymns, String query) {
    if (query.trim().isEmpty) return hymns;
    final q = query.trim().toLowerCase();
    // number match
    final num = int.tryParse(q);
    return hymns.where((h) {
      if (num != null && h.number == num) return true;
      if (h.title.toLowerCase().contains(q)) return true;
      if (h.firstLine.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }
}