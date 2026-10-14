import 'package:flutter_test/flutter_test.dart';
import 'package:hatim_halkasi/quran.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled Quran has complete and aligned verse, page and juz coverage', () async {
    final quran = await Quran.load();
    expect(quran.verses.length, 6236);
    expect(quran.verses.first.sura, 1);
    expect(quran.verses.first.ayah, 1);
    expect(quran.verses.last.sura, 114);
    expect(quran.verses.last.ayah, 6);
    expect(quran.verses.map((v) => v.sura).toSet().length, 114);
    expect(quran.verses.map((v) => v.page).toSet().length, 604);
    expect(quran.verses.map((v) => v.juz).toSet().length, 30);
    expect(quran.verses.every((v) => v.arabic.isNotEmpty && v.translation.isNotEmpty), true);
    for (var i = 1; i < quran.verses.length; i++) {
      final previous = quran.verses[i - 1];
      final current = quran.verses[i];
      expect(current.sura == previous.sura ? current.ayah == previous.ayah + 1 : current.ayah == 1, true);
      expect(current.page >= previous.page && current.juz >= previous.juz, true);
    }
  });

  test('page and juz progress share the same verse coverage', () async {
    final quran = await Quran.load();
    final allPages = <int>{for (var p = 1; p <= 604; p++) ...quran.indicesForPage(p)};
    final allJuzs = <int>{for (var j = 1; j <= 30; j++) ...quran.indicesForJuz(j)};
    expect(allPages.length, 6236);
    expect(allJuzs, allPages);
  });
}
