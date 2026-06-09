import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hymn.dart';

class HymnRepository {
  static List<Hymn>? _englishHymns;
  static List<Hymn>? _lugandaHymns;

  static Future<List<Hymn>> loadEnglish() async {
    if (_englishHymns != null) return _englishHymns!;
    final raw   = await rootBundle.loadString('assets/data/hymns_en.json');
    final rawCh = await rootBundle.loadString('assets/data/songs_ch_en.json');
    final list   = jsonDecode(raw)   as List;
    final listCh = jsonDecode(rawCh) as List;
    _englishHymns = [
      ...list.map((e)   => Hymn.fromJson(e as Map<String, dynamic>)),
      ...listCh.map((e) => Hymn.fromJson(e as Map<String, dynamic>)),
    ];
    return _englishHymns!;
  }

  static Future<List<Hymn>> loadLuganda() async {
    if (_lugandaHymns != null) return _lugandaHymns!;
    final raw   = await rootBundle.loadString('assets/data/hymns_lg.json');
    final rawCh = await rootBundle.loadString('assets/data/songs_ch_lg.json');
    final list   = jsonDecode(raw)   as List;
    final listCh = jsonDecode(rawCh) as List;
    _lugandaHymns = [
      ...list.map((e)   => Hymn.fromJson(e as Map<String, dynamic>)),
      ...listCh.map((e) => Hymn.fromJson(e as Map<String, dynamic>)),
    ];
    return _lugandaHymns!;
  }

  /// Returns hymns matching number, title, or first line (case-insensitive).
  /// Also supports direct children's song number lookup, e.g. "c1" or "C1".
  static List<Hymn> search(List<Hymn> hymns, String query) {
    if (query.trim().isEmpty) return hymns;
    final q = query.trim().toLowerCase();
    final num = int.tryParse(q);
    return hymns.where((h) {
      if (num != null && h.number == num) return true;
      // exact match on children's song numbers like "c1", "C1"
      if (h.number.toString().toLowerCase() == q) return true;
      if (h.title.toLowerCase().contains(q)) return true;
      if (h.firstLine.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }
}