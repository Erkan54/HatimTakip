import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'app_design.dart';
import 'group_reader_screen.dart';
import 'hatim_map_view.dart';
import 'invite_code.dart';
import 'motion.dart';
import 'page_grid.dart';
import 'quran.dart';
import 'repositories.dart';
import 'settings.dart';
import 'ui_feedback.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen(
      {super.key, required this.repo, required this.quran, required this.id});
  final HatimRepository repo;
  final Quran quran;
  final String id;
  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool pages = true, busy = false;
  int? members, selectedPage;
  late Stream<DocumentSnapshot<Map<String, dynamic>>> groupStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? progressStream;
  int? progressRound;

  @override
  void initState() {
    super.initState();
    groupStream = widget.repo.groupStream(widget.id);
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      final snapshot = await widget.repo.db
          .collection('groups/${widget.id}/members')
          .count()
          .get();
      if (mounted) setState(() => members = snapshot.count);
    } catch (_) {/* A member count is optional and never blocks reading. */}
  }

  void retry() => setState(() {
        groupStream = widget.repo.groupStream(widget.id);
        progressRound = null;
      });

  Set<int> covered(Map<String, dynamic> marks) => {
        for (var page = 1; page <= 604; page++)
          if (marks.containsKey('p$page')) ...widget.quran.indicesForPage(page),
        for (var juz = 1; juz <= 30; juz++)
          if (marks.containsKey('j$juz')) ...widget.quran.indicesForJuz(juz),
      };

  Future<void> mark(int round, String key, bool value,
      {bool offerUndo = true}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.repo.mark(widget.id, round, key, value);
      if (!mounted) return;
      if (Motion.enabled(context)) AppSettings.of(context).tap();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(value ? 'Okumanız kaydedildi.' : 'İşaretleme geri alındı.'),
          action: value && offerUndo
              ? SnackBarAction(
                  label: 'Geri al',
                  onPressed: () => mark(round, key, false, offerUndo: false))
              : null));
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> newRound(int round) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.repo.nextPrivateRound(widget.id, round);
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> shareInvite(String invite) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
          top: false,
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Eyebrow('HATİM GRUBUNUZU PAYLAŞIN'),
                    const SizedBox(height: 12),
                    SelectableText(formatInviteCode(invite),
                        style: TextStyle(
                            fontSize: 19,
                            color: ctx.palette.accent,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, children: [
                      TextButton.icon(
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Kopyala'),
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: formatInviteCode(invite)));
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text('Davet kodu kopyalandı.')));
                            }
                          }),
                      TextButton.icon(
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('Paylaş'),
                          onPressed: () async {
                            try {
                              await Share.share(
                                  'Hatim Zinciri grubuma katıl: ${formatInviteCode(invite)}');
                            } catch (e) {
                              if (ctx.mounted) notice(ctx, e);
                            }
                          }),
                    ]),
                  ]))));

  void openReader(int page, String groupName) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => GroupReaderScreen(
                quran: widget.quran, groupName: groupName, initialPage: page)));
  }

  Future<void> showUnit(int number, int round, Map<String, dynamic> marks,
      Set<int> done, String owner,
      {required bool isPage, required String groupName}) async {
    if (busy) return;
    final key = '${isPage ? 'p' : 'j'}$number';
    final indices = isPage
        ? widget.quran.indicesForPage(number)
        : widget.quran.indicesForJuz(number);
    final read = widget.quran.completedIn(indices, done);
    final info = marks[key] as Map?;
    final canUndo = info == null ||
        info['uid'] == widget.repo.uid ||
        owner == widget.repo.uid;
    final completedByOtherUnit = read == indices.length && info == null;
    final readingPage = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => SafeArea(
            top: false,
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(isPage ? '$number. Sayfa' : '$number. Cüz',
                          style: ctx.text.titleLarge),
                      const SizedBox(height: 8),
                      Text('$read / ${indices.length} ayet tamamlandı'),
                      if (isPage)
                        Text(
                            '${widget.quran.juzsOnPage(number).join('–')}. cüz · ${widget.quran.surasOnPage(number).join(', ')}'),
                      if (info != null) Text('İşaretleyen: ${info['name']}'),
                      if (!canUndo)
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                                'Yalnızca kendi işaretinizi veya grubun kurucusuysanız diğer işaretleri geri alabilirsiniz.')),
                      if (completedByOtherUnit)
                        const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                                'Bu bölüm başka sayfa/cüz işaretleriyle tamamlanmış.')),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                          icon: const Icon(Icons.menu_book_outlined),
                          label: Text(
                              isPage ? 'Bu sayfadan oku' : 'Bu cüzden oku'),
                          onPressed: () => Navigator.pop(
                              ctx, widget.quran.verses[indices.first].page)),
                      const SizedBox(height: 12),
                      PrimaryAction(
                          label: info != null
                              ? 'İşaretlemeyi geri al'
                              : isPage
                                  ? 'Bu sayfayı okudum'
                                  : 'Bu cüzü okudum',
                          icon: info != null
                              ? Icons.undo_rounded
                              : Icons.check_rounded,
                          onPressed: !canUndo || completedByOtherUnit
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  mark(round, key, info == null);
                                }),
                    ]))));
    if (readingPage != null && mounted) openReader(readingPage, groupName);
  }

  Widget status(String title,
          {String? message, bool loading = false, VoidCallback? onRetry}) =>
      Scaffold(
          appBar: AppBar(title: const Text('Hatim grubum')),
          body: AppBackground(
              child: AppStatus(
                  title: title,
                  message: message,
                  loading: loading,
                  onRetry: onRetry)));

  @override
  Widget build(BuildContext context) => StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
      stream: groupStream,
      builder: (context, groupSnap) {
        if (groupSnap.hasError) {
          return status('Gruba ulaşılamadı',
              message: friendly(groupSnap.error!), onRetry: retry);
        }
        if (!groupSnap.hasData) {
          return status('Grubunuz hazırlanıyor', loading: true);
        }
        final group = groupSnap.data!.data();
        if (group == null) return status('Grup bulunamadı', onRetry: retry);
        final round = group['round'] as int;
        if (progressRound != round) {
          progressRound = round;
          progressStream = widget.repo.progressStream(widget.id, round);
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: progressStream,
            builder: (context, progressSnap) {
              if (progressSnap.hasError) {
                return status('İlerleme yüklenemedi',
                    message: friendly(progressSnap.error!), onRetry: retry);
              }
              if (!progressSnap.hasData) {
                return status('Okuma bilgileri yükleniyor', loading: true);
              }
              final marks = Map<String, dynamic>.from(
                  progressSnap.data?.data()?['marks'] ?? {});
              final done = covered(marks);
              final complete = done.length == verseCount;
              final p = context.palette;
              final donePages = <int>{}, partialPages = <int>{};
              for (var page = 1; page <= 604; page++) {
                final indices = widget.quran.indicesForPage(page);
                final read = widget.quran.completedIn(indices, done);
                if (read == indices.length) {
                  donePages.add(page);
                } else if (read > 0) {
                  partialPages.add(page);
                }
              }
              final doneJuzs = [
                for (var juz = 1; juz <= 30; juz++)
                  if (widget.quran.indicesForJuz(juz).every(done.contains)) juz
              ];
              return Scaffold(
                  appBar: AppBar(
                      title: Text(group['name'] as String,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      actions: [
                        if (pages)
                          IconButton(
                              tooltip: 'Sayfa bul',
                              icon: const Icon(Icons.search_rounded),
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final page = await findQuranPage(context);
                                      if (page != null && mounted) {
                                        setState(() => selectedPage = page);
                                        showUnit(page, round, marks, done,
                                            group['owner'] as String,
                                            isPage: true,
                                            groupName: group['name'] as String);
                                      }
                                    }),
                        IconButton(
                            tooltip: 'Davet kodunu paylaş',
                            icon: const Icon(Icons.ios_share_rounded),
                            onPressed: () =>
                                shareInvite(group['inviteCode'] as String)),
                      ]),
                  body: AppBackground(
                      child: SafeArea(
                          top: false,
                          child: PageFrame(
                              child: CustomScrollView(slivers: [
                            SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                sliver: SliverToBoxAdapter(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                      FadeSlideIn(
                                          child: SoftCelebration(
                                              color: p.gold,
                                              trigger: complete,
                                              enabled: complete,
                                              child: PaperCard(
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                    Eyebrow('$round. HATİM'),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                        '${doneJuzs.length} / 30 cüz · ${donePages.length} / 604 sayfa okundu'),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        complete
                                                            ? 'Allah kabul etsin.'
                                                            : 'Birlikte tamamlıyoruz.',
                                                        style: context.text
                                                            .headlineMedium),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        '${members == null ? 'Grubumuz' : '$members kişi'} · ${group['completedHatims']} tamamlanan hatim'),
                                                    const SizedBox(height: 18),
                                                    Semantics(
                                                        label:
                                                            'Hatim ilerlemesi',
                                                        value:
                                                            '${done.length} / $verseCount ayet',
                                                        child:
                                                            LinearProgressIndicator(
                                                                value: done
                                                                        .length /
                                                                    verseCount,
                                                                minHeight: 8)),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                        '${done.length} / $verseCount ayet · %${(done.length * 100 / verseCount).toStringAsFixed(1)}'),
                                                    if (complete &&
                                                        group['owner'] ==
                                                            widget
                                                                .repo.uid) ...[
                                                      const SizedBox(
                                                          height: 18),
                                                      PrimaryAction(
                                                          label:
                                                              'Yeni hatim başlat',
                                                          busy: busy,
                                                          onPressed: () =>
                                                              newRound(round)),
                                                    ],
                                                  ])))),
                                      const SizedBox(height: 24),
                                      PrimaryAction(
                                          label: 'Kur’an oku',
                                          icon: Icons.menu_book_outlined,
                                          onPressed: () => openReader(
                                              selectedPage ?? 1,
                                              group['name'] as String)),
                                      const SizedBox(height: 12),
                                      Text(
                                          'Dilediğiniz kadar okuyun. Evde veya uygulamada okuduğunuz bölümleri aşağıdan işaretleyebilirsiniz.',
                                          style: context.text.bodySmall),
                                      const SizedBox(height: 24),
                                      Text('Okuma takibi',
                                          style: context.text.titleLarge),
                                      const SizedBox(height: 12),
                                      SegmentedButton<bool>(
                                          segments: const [
                                            ButtonSegment(
                                                value: true,
                                                label: Text('Sayfalar')),
                                            ButtonSegment(
                                                value: false,
                                                label: Text('Cüzler'))
                                          ],
                                          selected: {
                                            pages
                                          },
                                          onSelectionChanged: (s) =>
                                              setState(() => pages = s.first)),
                                      const SizedBox(height: 16),
                                      Wrap(
                                          spacing: 14,
                                          runSpacing: 6,
                                          children: [
                                            GridLegend(
                                                color: p.done, label: 'Okundu'),
                                            GridLegend(
                                                color: p.partial,
                                                label: 'Kısmen'),
                                            GridLegend(
                                                color: p.unread, label: 'Boş')
                                          ]),
                                      const SizedBox(height: 12),
                                      Text(
                                          pages
                                              ? 'Her satır bir cüzdür. Sayfa seçerek okuyun veya okuduğunuzu işaretleyin; küçük hücreler için Sayfa bul kullanın.'
                                              : 'Bir cüz seçerek okumaya başlayın veya okuduğunuzu işaretleyin.',
                                          style: context.text.bodySmall),
                                    ]))),
                            SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                sliver: SliverToBoxAdapter(
                                    child: pages
                                        ? Card(
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: AspectRatio(
                                                    aspectRatio: PageGridLayout
                                                        .aspectRatio,
                                                    child: PageGrid(
                                                        done: donePages,
                                                        partial: partialPages,
                                                        paintKey: const ValueKey(
                                                            'group-page-grid'),
                                                        selected: selectedPage,
                                                        semanticsLabel:
                                                            'Grup sayfa ızgarası. ${donePages.length} sayfa tamamlandı. Sayfa bul ile bölüm seçebilirsiniz.',
                                                        onSelect: (page) {
                                                          setState(() =>
                                                              selectedPage =
                                                                  page);
                                                          showUnit(
                                                              page,
                                                              round,
                                                              marks,
                                                              done,
                                                              group['owner']
                                                                  as String,
                                                              isPage: true,
                                                              groupName: group[
                                                                      'name']
                                                                  as String);
                                                        }))))
                                        : LayoutBuilder(
                                            builder: (context, box) {
                                            final scale =
                                                MediaQuery.textScalerOf(context)
                                                        .scale(14) /
                                                    14;
                                            final columns = (box.maxWidth /
                                                    (130 * math.sqrt(scale)))
                                                .floor()
                                                .clamp(1, 6);
                                            return GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: 30,
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: columns,
                                                        mainAxisExtent: 112 *
                                                            scale.clamp(1, 2),
                                                        crossAxisSpacing: 10,
                                                        mainAxisSpacing: 10),
                                                itemBuilder: (context, index) {
                                                  final number = index + 1,
                                                      indices = widget.quran
                                                          .indicesForJuz(
                                                              index + 1);
                                                  final read = widget.quran
                                                      .completedIn(
                                                          indices, done);
                                                  final isDone =
                                                      read == indices.length;
                                                  return SoftPressable(
                                                      enabled: !busy,
                                                      child: Card(
                                                          child: InkWell(
                                                        onTap: busy
                                                            ? null
                                                            : () => showUnit(
                                                                number,
                                                                round,
                                                                marks,
                                                                done,
                                                                group['owner']
                                                                    as String,
                                                                isPage: false,
                                                                groupName: group[
                                                                        'name']
                                                                    as String),
                                                        child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
                                                            child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                      isDone
                                                                          ? Icons
                                                                              .check_circle_rounded
                                                                          : Icons
                                                                              .menu_book_outlined,
                                                                      color: isDone
                                                                          ? p.done
                                                                          : read > 0
                                                                              ? p.partial
                                                                              : p.muted,
                                                                      size: 24),
                                                                  const SizedBox(
                                                                      height:
                                                                          8),
                                                                  Text(
                                                                      '$number. Cüz',
                                                                      style: context
                                                                          .text
                                                                          .titleMedium),
                                                                  const SizedBox(
                                                                      height:
                                                                          4),
                                                                  Text(
                                                                      '%${(read * 100 / indices.length).round()}',
                                                                      style: context
                                                                          .text
                                                                          .bodySmall),
                                                                ])),
                                                      )));
                                                });
                                          }))),
                          ])))));
            });
      });
}
