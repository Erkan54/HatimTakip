// Firestore SDK types are replaced only by local UI fixtures in this file.
// ignore_for_file: subtype_of_sealed_class, must_be_immutable
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatim_halkasi/app_design.dart';
import 'package:hatim_halkasi/page_grid.dart';
import 'package:hatim_halkasi/settings.dart';
import 'package:hatim_halkasi/quran.dart';
import 'package:hatim_halkasi/repositories.dart';
import 'package:hatim_halkasi/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local fixtures: these tests never connect to Firebase or consume its quota.
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic> value;
  @override
  Map<String, dynamic> data() => value;
  @override
  SnapshotMetadata get metadata => _Metadata();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Metadata implements SnapshotMetadata {
  @override
  bool get isFromCache => false;
  @override
  bool get hasPendingWrites => false;
}

class _Reference implements DocumentReference<Map<String, dynamic>> {
  int reads = 0;
  int listeners = 0;
  final value = _Snapshot({
    'round': 3,
    'completedHatims': 2,
    'completedPages': List.generate(87, (i) => i + 1)
  });
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    reads++;
    return value;
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots(
      {bool includeMetadataChanges = false,
      ListenSource source = ListenSource.defaultSource}) {
    listeners++;
    return Stream.value(value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements HatimRepository {
  final ref = _Reference();
  int groupSubscriptions = 0, progressSubscriptions = 0, confirmations = 0;
  int starts = 0, nameReads = 0;
  String name = 'Ahmet';
  bool finishOnConfirm = false;
  Map<String, dynamic> groupMarks = {
    'p1': {'name': 'Ahmet', 'uid': 'test-reader'}
  };
  final markCalls = <(String, bool)>[];
  @override
  DocumentReference<Map<String, dynamic>> get state => ref;
  @override
  String get uid => 'test-reader';
  @override
  Future<String?> loadName() async {
    nameReads++;
    return name;
  }

  @override
  Future<void> updateName(String value) async {
    name = value;
  }

  @override
  Future<void> mark(String id, int round, String key, bool done) async {
    markCalls.add((key, done));
  }

  @override
  Future<List<Map<String, dynamic>>> myGroups() async => [
        {'id': 'test', 'name': 'Aile Halkamız', 'completedHatims': 1}
      ];
  @override
  Future<ReadingSession> startReading() async {
    starts++;
    return const ReadingSession(3, 0, 0);
  }

  @override
  Future<ReadingSession?> confirm(ReadingSession session) async {
    confirmations++;
    if (finishOnConfirm) return null;
    return ReadingSession(session.round, session.chunk, session.next + 1);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> groupStream(String id) {
    groupSubscriptions++;
    return Stream.value(_Snapshot({
      'name': 'Aile Halkamız',
      'round': 2,
      'inviteCode': 'ABCD1234EFGH5678',
      'completedHatims': 1,
      'owner': 'test-reader'
    }));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> progressStream(
      String id, int round) {
    progressSubscriptions++;
    return Stream.value(_Snapshot({'marks': groupMarks}));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Quran quran;
  setUpAll(() async {
    quran = await Quran.load();
    final manrope = FontLoader('Manrope');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      manrope.addFont(rootBundle.load('assets/fonts/Manrope-$weight.ttf'));
    }
    await manrope.load();
    for (final font in {
      'Amiri': 'assets/fonts/Amiri-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });

  Future<void> show(WidgetTester tester, Widget screen,
      {Size size = const Size(390, 844),
      double scale = 1,
      AppSettings? settings,
      bool disableAnimations = false}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferences = settings ?? AppSettings();
    await tester.pumpWidget(SettingsScope(
        settings: preferences,
        child: ListenableBuilder(
            listenable: preferences,
            builder: (context, _) => RepaintBoundary(
                key: const ValueKey('preview'),
                child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: buildAppTheme(),
                    darkTheme: buildAppTheme(brightness: Brightness.dark),
                    themeMode: preferences.theme,
                    builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                            disableAnimations: disableAnimations),
                        child: child!),
                    home: screen)))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> preview(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('WRITE_UI_PREVIEWS')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui-previews').create(recursive: true);
      await File('build/ui-previews/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('Home has no map shortcut; reader retains map access',
      (tester) async {
    final repo = _Repo();
    await show(tester, HomeScreen(repo: repo, quran: quran));
    expect(find.byTooltip('Hatim Haritası'), findsNothing);
    expect(find.text('Hatim Haritası'), findsNothing);
    await preview(tester, 'home');
    await tester.tap(find.text('Hızlı Hatime Katıl'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hatim Haritası'), findsOneWidget);
    expect(repo.ref.listeners, 1);
    await preview(tester, 'reader');
    await tester.tap(find.byTooltip('Hatim Haritası'));
    await tester.pumpAndSettle();
    expect(repo.ref.reads, 1);
    await preview(tester, 'map');
    await tester.tap(find.byTooltip('Sayfa bul'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '604');
    await tester.tap(find.text('Göster'));
    await tester.pumpAndSettle();
    expect(find.textContaining('604. sayfa'), findsOneWidget);
    expect(repo.ref.reads, 1, reason: 'Page selection must remain local.');
    await tester.tap(find.byTooltip('Yenile'));
    await tester.pumpAndSettle();
    expect(repo.ref.reads, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reader translation and confirmation retain behavior',
      (tester) async {
    final repo = _Repo();
    await show(
        tester,
        ReaderScreen(
            repo: repo, quran: quran, session: const ReadingSession(3, 0, 0)));
    await tester.ensureVisible(find.text('Türkçe meali göster'));
    await tester.tap(find.text('Türkçe meali göster'));
    await tester.pumpAndSettle();
    expect(find.text(quran.verses.first.translation), findsOneWidget);
    await preview(tester, 'reader-meal');
    await tester.tap(find.text('Okudum, sonraki ayet'));
    await tester.pumpAndSettle();
    expect(repo.confirmations, 1);
    expect(find.textContaining(quran.verses[1].arabic), findsOneWidget);
    expect(find.text('Meali gizle'), findsOneWidget);
    expect(find.text(quran.verses[1].translation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Group list and segment changes reuse the existing streams',
      (tester) async {
    final repo = _Repo();
    await show(tester, GroupScreen(repo: repo, quran: quran, id: 'test'));
    await preview(tester, 'group');
    await tester.ensureVisible(find.text('Cüzler'));
    await tester.tap(find.text('Cüzler'));
    await tester.pumpAndSettle();
    expect(repo.groupSubscriptions, 1);
    expect(repo.progressSubscriptions, 1);
    await tester.scrollUntilVisible(find.text('1. Cüz'), 200,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('1. Cüz'));
    await tester.pumpAndSettle();
    expect(find.text('Bu cüzü okudum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding validates name and works above keyboard',
      (tester) async {
    String? submitted;
    await show(
        tester,
        OnboardingScreen(
            busy: false,
            submit: (value) async {
              submitted = value;
            }));
    await preview(tester, 'onboarding');
    await tester.tap(find.text('Zincire katıl'));
    await tester.pumpAndSettle();
    expect(find.text('Lütfen adınızı girin.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ahmet');
    await tester.tap(find.text('Zincire katıl'));
    await tester.pumpAndSettle();
    expect(submitted, 'Ahmet');
  });

  for (final spec in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
    (const Size(844, 390), 2.0)
  ]) {
    testWidgets('Screens fit ${spec.$1} at text scale ${spec.$2}',
        (tester) async {
      final repo = _Repo();
      await show(tester, HomeScreen(repo: repo, quran: quran),
          size: spec.$1, scale: spec.$2);
      if (spec.$1 == const Size(320, 568) && spec.$2 == 1) {
        final action = find
            .ancestor(
                of: find.text('Hızlı Hatime Katıl'),
                matching: find.byType(FilledButton))
            .first;
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(spec.$1.height),
            reason:
                'The primary reading action should be visible without scrolling on a small screen.');
      }
      await show(tester, OnboardingScreen(busy: false, submit: (_) async {}),
          size: spec.$1, scale: spec.$2);
      await show(tester, GroupScreen(repo: repo, quran: quran, id: 'test'),
          size: spec.$1, scale: spec.$2);
      await show(
          tester,
          ReaderScreen(
              repo: repo, quran: quran, session: const ReadingSession(3, 0, 0)),
          size: spec.$1,
          scale: spec.$2);
      await show(tester, PublicMapScreen(repo: repo, quran: quran),
          size: spec.$1, scale: spec.$2);
      final grid = find.byKey(const ValueKey('hatim-page-grid'));
      expect(tester.getSize(grid).height, greaterThan(30));
      expect(tester.getRect(grid).bottom, lessThanOrEqualTo(spec.$1.height));
      await show(
          tester,
          GroupReaderScreen(
              quran: quran, groupName: 'Aile Halkamız', initialPage: 48),
          size: spec.$1,
          scale: spec.$2);
      await show(tester, const SettingsScreen(name: 'Ahmet'),
          size: spec.$1, scale: spec.$2);
    });
  }

  test('All 604 page centers map to the correct page in portrait and landscape',
      () {
    for (final size in [const Size(260, 280), const Size(500, 260)]) {
      for (var page = 1; page <= 604; page++) {
        final point = PageGridLayout.rectFor(page, size).center;
        expect(PageGridLayout.pageAt(point, size), page);
      }
      expect(PageGridLayout.pageAt(const Offset(-1, -1), size), isNull);
    }
  });

  testWidgets('Last interval ends without reserving more verses until Continue',
      (tester) async {
    final repo = _Repo()..finishOnConfirm = true;
    await show(
        tester,
        ReaderScreen(
            repo: repo,
            quran: quran,
            session: const ReadingSession(3, 623, 6235)));
    await tester.tap(find.text('Okudum, tamamla'));
    await tester.pumpAndSettle();
    expect(find.text('6 ayet tamamlandı'), findsOneWidget);
    expect(repo.confirmations, 1);
    expect(repo.starts, 0);
    await preview(tester, 'reading-complete');
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(repo.starts, 1);
    expect(find.text('Fâtiha Suresi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Settings change theme and profile without new Firestore subscriptions',
      (tester) async {
    final repo = _Repo();
    await show(tester, HomeScreen(repo: repo, quran: quran));
    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text(quran.verses.first.arabic), findsOneWidget);
    expect(find.text('Sistem'), findsNothing);
    expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(2));
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark);
    await preview(tester, 'settings-dark');
    await tester.tap(find.text('Ahmet'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Nurullah  ');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(repo.name, 'Nurullah');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Nurullah.'), findsOneWidget);
    expect(repo.ref.listeners, 1);
    expect(repo.nameReads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Group search marks a page and Undo uses the same progress stream',
      (tester) async {
    final repo = _Repo();
    await show(tester, GroupScreen(repo: repo, quran: quran, id: 'test'));
    await tester.tap(find.byTooltip('Sayfa bul'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.tap(find.text('Göster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bu sayfayı okudum'));
    await tester.pumpAndSettle();
    expect(repo.markCalls, [('p2', true)]);
    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(repo.markCalls, [('p2', true), ('p2', false)]);
    expect(repo.groupSubscriptions, 1);
    expect(repo.progressSubscriptions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reader displays the Imlaei source text for Bakara 14',
      (tester) async {
    final index = quran.verses.indexWhere((v) => v.sura == 2 && v.ayah == 14);
    await show(
        tester,
        ReaderScreen(
            repo: _Repo(),
            quran: quran,
            session: ReadingSession(3, index ~/ chunkSize, index)));
    expect(find.text('${quran.verses[index].arabic} ۝${arabicDigits(14)}'),
        findsOneWidget);
    await preview(tester, 'reader-imlai-bakara14');
  });

  testWidgets('First launch stays light even when the device is dark',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await show(tester, HomeScreen(repo: _Repo(), quran: quran),
        settings: settings);
    expect(settings.theme, ThemeMode.light);
    expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.light);
    settings.dispose();
  });

  testWidgets(
      'Private group reading crosses ten verses without reservations or marks',
      (tester) async {
    final repo = _Repo();
    await show(tester, GroupScreen(repo: repo, quran: quran, id: 'test'));
    await tester.ensureVisible(find.text('Kur’an oku'));
    await tester.tap(find.text('Kur’an oku'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupReaderScreen), findsOneWidget);
    expect(find.text('1 / 604 · 1. cüz'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_left_rounded))
            .onPressed,
        isNull);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Sonraki sayfa'));
      await tester.pumpAndSettle();
    }
    expect(find.text('4 / 604 · 1. cüz'), findsOneWidget);
    final index = quran.indicesForPage(4).first;
    expect(index, greaterThan(10));
    expect(find.textContaining(quran.verses[index].arabic), findsOneWidget);
    expect(find.text('Okudum, sonraki ayet'), findsNothing);
    expect(find.textContaining('ayet onaylandı'), findsNothing);
    expect(repo.starts, 0);
    expect(repo.confirmations, 0);
    expect(repo.markCalls, isEmpty);
    await preview(tester, 'group-reader');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(GroupScreen), findsOneWidget);
    expect(repo.groupSubscriptions, 1);
    expect(repo.progressSubscriptions, 1);
  });

  testWidgets(
      'Selected group page opens in reader and can jump to the last page',
      (tester) async {
    final repo = _Repo();
    await show(tester, GroupScreen(repo: repo, quran: quran, id: 'test'));
    await tester.tap(find.byTooltip('Sayfa bul'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '48');
    await tester.tap(find.text('Göster'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bu sayfadan oku'));
    await tester.pumpAndSettle();
    expect(find.text('48 / 604 · 3. cüz'), findsOneWidget);
    expect(
        find.textContaining(quran.verses
            .singleWhere((v) => v.sura == 2 && v.ayah == 282)
            .arabic),
        findsOneWidget);
    await tester.tap(find.byTooltip('Sayfa bul'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '604');
    await tester.tap(find.text('Göster'));
    await tester.pumpAndSettle();
    expect(find.text('604 / 604 · 30. cüz'), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.chevron_right_rounded))
            .onPressed,
        isNull);
    await tester.scrollUntilVisible(
        find.textContaining(quran.verses.last.arabic), 400,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    expect(find.textContaining(quran.verses.last.arabic), findsOneWidget);
    expect(repo.starts, 0);
    expect(repo.confirmations, 0);
    expect(repo.markCalls, isEmpty);
  });

  testWidgets(
      'Group juz reading leaves manual tracking and covered juz counts intact',
      (tester) async {
    final repo = _Repo();
    repo.groupMarks['j1'] = {'name': 'Ahmet', 'uid': 'test-reader'};
    await show(tester, GroupScreen(repo: repo, quran: quran, id: 'test'));
    expect(find.text('1 / 30 cüz · 21 / 604 sayfa okundu'), findsOneWidget);
    await tester.ensureVisible(find.text('Cüzler'));
    await tester.tap(find.text('Cüzler'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('2. Cüz'), 200,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    await tester.tap(find.text('2. Cüz'));
    await tester.pumpAndSettle();
    expect(find.text('Bu cüzü okudum'), findsOneWidget);
    await tester.tap(find.text('Bu cüzden oku'));
    await tester.pumpAndSettle();
    expect(find.text('22 / 604 · 2. cüz'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Cüz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bu cüzü okudum'));
    await tester.pumpAndSettle();
    expect(repo.markCalls, [('j2', true)]);
    expect(repo.starts, 0);
    expect(repo.confirmations, 0);
    expect(repo.groupSubscriptions, 1);
    expect(repo.progressSubscriptions, 1);
  });

  testWidgets(
      'Private page reader shares meal and text preferences and fits large text',
      (tester) async {
    final settings = AppSettings()..theme = ThemeMode.dark;
    await show(
        tester,
        GroupReaderScreen(
            quran: quran, groupName: 'Aile Halkamız', initialPage: 48),
        settings: settings,
        size: const Size(320, 568),
        scale: 2);
    await tester.tap(find.byTooltip('Okuma ayarları'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Yazıyı büyüt'));
    await tester.tap(find.byTooltip('Yazıyı büyüt'));
    await tester.pumpAndSettle();
    expect(settings.arabicScale, 1.1);
    await tester.ensureVisible(find.text('Türkçe meali göster'));
    await tester.tap(find.text('Türkçe meali göster'));
    await tester.pumpAndSettle();
    expect(settings.showTranslation, isTrue);
    Navigator.pop(tester.element(find.text('Okuma ayarları')));
    await tester.pumpAndSettle();
    final verse = quran.verses.singleWhere((v) => v.sura == 2 && v.ayah == 282);
    final vertical = find
        .descendant(
            of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    expect(tester.state<ScrollableState>(vertical).position.maxScrollExtent,
        greaterThan(0));
    await tester.scrollUntilVisible(find.textContaining(verse.translation), 500,
        scrollable: vertical, maxScrolls: 100);
    expect(find.textContaining(verse.translation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Old system theme migrates to light while explicit dark remains saved',
      () async {
    for (final stored in [0, 1, 2, -1, 99]) {
      SharedPreferences.setMockInitialValues({'theme': stored});
      final settings = await AppSettings.load();
      expect(settings.theme, stored == 2 ? ThemeMode.dark : ThemeMode.light);
      settings.dispose();
    }
    expect(AppSettings().theme, ThemeMode.light);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets(
        'Longest verse remains scrollable in dark mode at large text: $size',
        (tester) async {
      final index =
          quran.verses.indexWhere((v) => v.sura == 2 && v.ayah == 282);
      final preferences = AppSettings()
        ..theme = ThemeMode.dark
        ..arabicScale = 1.6
        ..showTranslation = true;
      await show(
          tester,
          ReaderScreen(
              repo: _Repo(),
              quran: quran,
              session: ReadingSession(3, index ~/ chunkSize, index)),
          size: size,
          scale: 2,
          settings: preferences,
          disableAnimations: true);
      expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .maxScrollExtent,
          greaterThan(0));
      expect(tester.takeException(), isNull);
      await preview(tester,
          size.width < 500 ? 'reader-dark-long' : 'reader-dark-landscape');
    });
  }

  test('Preferences survive a reload of the local settings store', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    settings.theme = ThemeMode.dark;
    settings.showTranslation = true;
    settings.arabicScale = 1.4;
    settings.haptics = false;
    final loaded = await AppSettings.load();
    expect(loaded.theme, ThemeMode.dark);
    expect(loaded.showTranslation, isTrue);
    expect(loaded.arabicScale, 1.4);
    expect(loaded.haptics, isFalse);
    settings.dispose();
    loaded.dispose();
  });
}
