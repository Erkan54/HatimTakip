import 'dart:convert';
import 'package:flutter/services.dart';

/// Turkish sura names, indexed by `sura - 1`. The bundled data keeps its
/// transliterated names; these are only used for display.
const turkishSuraNames = <String>[
  'Fâtiha', 'Bakara', 'Âl-i İmrân', 'Nisâ', 'Mâide', 'En\'âm', 'A\'râf', //
  'Enfâl', 'Tevbe', 'Yûnus', 'Hûd', 'Yûsuf', 'Ra\'d', 'İbrâhîm', 'Hicr',
  'Nahl', 'İsrâ', 'Kehf', 'Meryem', 'Tâhâ', 'Enbiyâ', 'Hac', 'Mü\'minûn',
  'Nûr', 'Furkân', 'Şuarâ', 'Neml', 'Kasas', 'Ankebût', 'Rûm', 'Lokmân',
  'Secde', 'Ahzâb', 'Sebe\'', 'Fâtır', 'Yâsîn', 'Sâffât', 'Sâd', 'Zümer',
  'Mü\'min', 'Fussılet', 'Şûrâ', 'Zuhruf', 'Duhân', 'Câsiye', 'Ahkâf',
  'Muhammed', 'Fetih', 'Hucurât', 'Kâf', 'Zâriyât', 'Tûr', 'Necm', 'Kamer',
  'Rahmân', 'Vâkıa', 'Hadîd', 'Mücâdele', 'Haşr', 'Mümtehine', 'Saf', 'Cuma',
  'Münâfikûn', 'Teğâbün', 'Talâk', 'Tahrîm', 'Mülk', 'Kalem', 'Hâkka',
  'Meâric', 'Nûh', 'Cin', 'Müzzemmil', 'Müddessir', 'Kıyâme', 'İnsan',
  'Mürselât', 'Nebe\'', 'Nâziât', 'Abese', 'Tekvîr', 'İnfitâr', 'Mutaffifîn',
  'İnşikâk', 'Bürûc', 'Târık', 'A\'lâ', 'Gâşiye', 'Fecr', 'Beled', 'Şems',
  'Leyl', 'Duhâ', 'İnşirâh', 'Tîn', 'Alak', 'Kadir', 'Beyyine', 'Zilzâl',
  'Âdiyât', 'Kâria', 'Tekâsür', 'Asr', 'Hümeze', 'Fîl', 'Kureyş', 'Mâûn',
  'Kevser', 'Kâfirûn', 'Nasr', 'Tebbet', 'İhlâs', 'Felak', 'Nâs',
];

/// Converts a number to Arabic-Indic digits, e.g. 12 → ١٢.
String arabicDigits(int value) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((d) => digits[int.parse(d)]).join();
}

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

  /// Turkish display name, e.g. "Fâtiha".
  String get displaySura => turkishSuraNames[sura - 1];
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

  /// Distinct Turkish sura names that appear on a page, in reading order.
  List<String> surasOnPage(int page) =>
      {for (final i in indicesForPage(page)) verses[i].displaySura}.toList();

  /// Juz of the first verse on a page.
  int juzOfPage(int page) {
    final indices = indicesForPage(page);
    return indices.isEmpty ? 1 : verses[indices.first].juz;
  }

  List<int> juzsOnPage(int page) => {
        for (final index in indicesForPage(page)) verses[index].juz,
      }.toList();
}
