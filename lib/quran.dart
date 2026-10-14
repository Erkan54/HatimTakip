import 'dart:convert';
import 'package:flutter/services.dart';

class Verse {
  Verse(Map<String, dynamic> data)
      : sura = data['s'] as int,
        ayah = data['a'] as int,
        suraName = data['n'] as String,
        page = data['p'] as int,
        juz = data['j'] as int,
        arabic = data['ar'] as String,
        translation = data['tr'] as String;
  final int sura, ayah, page, juz;
  final String suraName, arabic, translation;
}

class Quran {
  Quran(this.verses) {
    for (var i = 0; i < verses.length; i++) {
      byPage.putIfAbsent(verses[i].page, () => []).add(i);
      byJuz.putIfAbsent(verses[i].juz, () => []).add(i);
    }
  }
  final List<Verse> verses;
  final Map<int, List<int>> byPage = {};
  final Map<int, List<int>> byJuz = {};
  static Future<Quran> load() async {
    final raw = await rootBundle.loadString('assets/quran/verses.json');
    final verses = (jsonDecode(raw) as List)
        .map((v) => Verse(v as Map<String, dynamic>))
        .toList();
    if (verses.length != 6236) throw StateError('Kur’an verisi eksik');
    return Quran(verses);
  }

  List<int> indicesForPage(int page) => byPage[page] ?? [];
  List<int> indicesForJuz(int juz) => byJuz[juz] ?? [];

  int completedIn(List<int> indices, Set<int> completed) =>
      indices.where(completed.contains).length;
}
