import 'package:flutter_test/flutter_test.dart';
import 'package:hatim_halkasi/quran.dart';
import 'package:hatim_halkasi/page_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Arabic uses fully vowelled Imlaei without Uthmani wasla or zero marks',
      () async {
    final quran = await Quran.load();
    final text = quran.verses.map((v) => v.arabic).join();
    for (final mark in ['\u0671', '\u06df', '\u06e0']) {
      expect(text.contains(mark), isFalse);
    }
    // Fatha, damma, kasra, shadda, sukun, tanwin and source small alef remain.
    for (final mark in [
      '\u064e',
      '\u064f',
      '\u0650',
      '\u0651',
      '\u0652',
      '\u064b',
      '\u064c',
      '\u064d',
      '\u0670'
    ]) {
      expect(text.contains(mark), isTrue);
    }
    expect(quran.verses.first.arabic, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ');
    expect(quran.verses.singleWhere((v) => v.sura == 2 && v.ayah == 14).arabic,
        'وَإِذَا لَقُوا الَّذِينَ آمَنُوا قَالُوا آمَنَّا وَإِذَا خَلَوْا إِلَىٰ شَيَاطِينِهِمْ قَالُوا إِنَّا مَعَكُمْ إِنَّمَا نَحْنُ مُسْتَهْزِئُونَ');
  });

  test('bundled Quran has complete and aligned verse, page and juz coverage',
      () async {
    final quran = await Quran.load();
    expect(quran.verses.length, 6236);
    expect(quran.verses.first.sura, 1);
    expect(quran.verses.first.ayah, 1);
    expect(quran.verses.last.sura, 114);
    expect(quran.verses.last.ayah, 6);
    expect(quran.verses.map((v) => v.sura).toSet().length, 114);
    expect(quran.verses.map((v) => v.page).toSet().length, 604);
    expect(quran.verses.map((v) => v.juz).toSet().length, 30);
    expect(
        quran.verses
            .every((v) => v.arabic.isNotEmpty && v.translation.isNotEmpty),
        true);
    for (var i = 1; i < quran.verses.length; i++) {
      final previous = quran.verses[i - 1];
      final current = quran.verses[i];
      expect(
          current.sura == previous.sura
              ? current.ayah == previous.ayah + 1
              : current.ayah == 1,
          true);
      expect(
          current.page >= previous.page && current.juz >= previous.juz, true);
    }
  });

  test('page and juz progress share the same verse coverage', () async {
    final quran = await Quran.load();
    final allPages = <int>{
      for (var p = 1; p <= 604; p++) ...quran.indicesForPage(p)
    };
    final allJuzs = <int>{
      for (var j = 1; j <= 30; j++) ...quran.indicesForJuz(j)
    };
    expect(allPages.length, 6236);
    expect(allJuzs, allPages);
  });

  test('All 30 grid rows follow the actual bundled juz boundaries', () async {
    final quran = await Quran.load();
    for (var juz = 1; juz <= 30; juz++) {
      final pages = {
        for (var page = 1; page <= 604; page++)
          if (quran.juzOfPage(page) == juz) page
      };
      expect(PageGridLayout.juzStarts[juz - 1], pages.first);
      expect(PageGridLayout.rowLength(juz - 1), pages.length);
      expect(
          pages.every((page) => PageGridLayout.rowOf(page) == juz - 1), isTrue);
    }
    expect(turkishSuraNames.length, 114);
    expect(quran.verses.first.displaySura, 'Fâtiha');
    expect(quran.verses.last.displaySura, 'Nâs');
    expect(quran.juzsOnPage(62), [3, 4]);
    expect(quran.juzsOnPage(121), [6, 7]);
    expect(quran.juzsOnPage(201), [10, 11]);
    expect(quran.juzsOnPage(502), [25, 26]);
  });
}
