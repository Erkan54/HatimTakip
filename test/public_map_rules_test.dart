import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hatim_halkasi/quran.dart';
import 'package:hatim_halkasi/repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('page boundaries in Firestore rules match the bundled Quran', () async {
    final quran = await Quran.load();
    final rules = await File('firestore.rules').readAsString();
    final function = RegExp(r'function pageEnd\(page\) \{([\s\S]*?)return int')
        .firstMatch(rules)?.group(1);
    expect(function, isNotNull);
    final encoded = RegExp("'([0-9]+)'").allMatches(function!)
        .map((match) => match.group(1)!).join();
    expect(encoded.length, 604 * 4);
    for (var page = 1; page <= 604; page++) {
      final actualEnd = int.parse(encoded.substring((page - 1) * 4, page * 4));
      expect(actualEnd, quran.indicesForPage(page).last + 1, reason: 'Page $page');
      final start = quran.indicesForPage(page).first;
      final touchedChunks = (actualEnd - 1) ~/ chunkSize - start ~/ chunkSize + 1;
      expect(touchedChunks, lessThanOrEqualTo(5), reason: 'Page $page');
    }
  });
}
