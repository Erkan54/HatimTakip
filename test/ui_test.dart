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
import 'package:hatim_halkasi/public_map.dart';
import 'package:hatim_halkasi/quran.dart';
import 'package:hatim_halkasi/repositories.dart';
import 'package:hatim_halkasi/screens.dart';

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
  @override
  DocumentReference<Map<String, dynamic>> get state => ref;
  @override
  String get uid => 'test-reader';
  @override
  Future<String?> loadName() async => 'Ahmet';
  @override
  Future<List<Map<String, dynamic>>> myGroups() async => [
        {'id': 'test', 'name': 'Aile Halkamız', 'completedHatims': 1}
      ];
  @override
  Future<ReadingSession> startReading() async => const ReadingSession(3, 0, 0);
  @override
  Future<ReadingSession?> confirm(ReadingSession session) async {
    confirmations++;
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
    return Stream.value(_Snapshot({
      'marks': {
        'p1': {'name': 'Ahmet', 'uid': 'test-reader'}
      }
    }));
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
      {Size size = const Size(390, 844), double scale = 1}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: screen)));
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
    expect(find.text(quran.verses[1].arabic), findsOneWidget);
    expect(find.text('Meali gizle'), findsNothing);
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
    await tester.tap(find.text('Halkaya katıl'));
    await tester.pumpAndSettle();
    expect(find.text('Lütfen adınızı girin.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ahmet');
    await tester.tap(find.text('Halkaya katıl'));
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
    });
  }

  test('All 604 page centers map to the correct page in portrait and landscape',
      () {
    for (final size in [const Size(260, 280), const Size(500, 260)]) {
      final cols = PageMapPainter.columns(size);
      final rows = (604 + cols - 1) ~/ cols;
      for (var page = 1; page <= 604; page++) {
        final point = Offset(((page - 1) % cols + 0.5) * size.width / cols,
            ((page - 1) ~/ cols + 0.5) * size.height / rows);
        expect(PageMapPainter.pageAt(point, size), page);
      }
      expect(PageMapPainter.pageAt(const Offset(-1, -1), size), isNull);
    }
  });
}
