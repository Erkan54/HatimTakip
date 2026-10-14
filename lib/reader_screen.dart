import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_design.dart';
import 'motion.dart';
import 'public_map.dart';
import 'quran.dart';
import 'repositories.dart';
import 'settings.dart';
import 'ui_feedback.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen(
      {super.key,
      required this.repo,
      required this.quran,
      required this.session});
  final HatimRepository repo;
  final Quran quran;
  final ReadingSession session;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late ReadingSession session = widget.session;
  bool busy = false, finished = false;
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> advance() async {
    if (busy || finished) return;
    setState(() => busy = true);
    try {
      final next = await widget.repo.confirm(session);
      if (!mounted) return;
      if (Motion.enabled(context)) AppSettings.of(context).tap();
      setState(() {
        // No new reservation is made until the reader explicitly chooses to continue.
        finished = next == null ||
            next.next >= next.end ||
            next.next >= widget.quran.verses.length;
        if (!finished) session = next!;
      });
      if (scroll.hasClients) scroll.jumpTo(0);
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> continueReading() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final next = await widget.repo.startReading();
      if (mounted) {
        setState(() {
          session = next;
          finished = false;
        });
      }
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final p = context.palette;
    final verse = widget.quran.verses[session.next];
    final total = session.end - session.chunk * chunkSize;
    final confirmed =
        finished ? total : session.next - session.chunk * chunkSize;
    final last = session.next + 1 >= session.end;
    return Scaffold(
      appBar: AppBar(
          title: const Text('Birlikte Hatim',
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
                tooltip: 'Yazıyı küçült',
                icon: const Icon(Icons.text_decrease_rounded),
                onPressed: settings.arabicScale > AppSettings.minScale
                    ? () => settings.arabicScale -= 0.1
                    : null),
            IconButton(
                tooltip: 'Yazıyı büyüt',
                icon: const Icon(Icons.text_increase_rounded),
                onPressed: settings.arabicScale < AppSettings.maxScale
                    ? () => settings.arabicScale += 0.1
                    : null),
            IconButton(
                tooltip: 'Hatim Haritası',
                icon: const Icon(Icons.grid_view_rounded),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PublicMapScreen(
                            repo: widget.repo, quran: widget.quran)))),
          ]),
      body: AppBackground(
          child: SafeArea(
              top: false,
              child: PageFrame(
                  child: Column(children: [
                Expanded(
                    child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                              controller: scroll,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 18, 20, 24),
                              child: AnimatedSwitcher(
                                duration: Motion.of(context, Motion.medium),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                            position: Tween(
                                                    begin:
                                                        const Offset(0, 0.025),
                                                    end: Offset.zero)
                                                .animate(animation),
                                            child: child)),
                                child: finished
                                    ? _ReadingComplete(
                                        key: const ValueKey('reading-complete'),
                                        total: total)
                                    : Column(
                                        key: ValueKey(
                                            '${session.round}:${session.chunk}:${session.next}'),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                            Center(
                                                child: Eyebrow(
                                                    '${session.round}. HATİM')),
                                            const SizedBox(height: 10),
                                            Text('${verse.displaySura} Suresi',
                                                textAlign: TextAlign.center,
                                                style: context
                                                    .text.headlineMedium),
                                            const SizedBox(height: 12),
                                            Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _ReadingTag(
                                                      '${verse.ayah}. ayet'),
                                                  _ReadingTag(
                                                      '${verse.page}. sayfa'),
                                                  _ReadingTag(
                                                      '${verse.juz}. cüz'),
                                                ]),
                                            const SizedBox(height: 22),
                                            PaperCard(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 24),
                                                child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                        minHeight: math.max(
                                                            180,
                                                            box.maxHeight -
                                                                210)),
                                                    child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Text(
                                                              '${verse.arabic} ۝${arabicDigits(verse.ayah)}',
                                                              semanticsLabel:
                                                                  '${verse.displaySura} Suresi, ${verse.ayah}. ayet. ${verse.arabic}',
                                                              textDirection:
                                                                  TextDirection
                                                                      .rtl,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Amiri',
                                                                  fontSize: 34 *
                                                                      settings
                                                                          .arabicScale,
                                                                  height: 2,
                                                                  color:
                                                                      p.ink)),
                                                          const SizedBox(
                                                              height: 16),
                                                          TextButton.icon(
                                                              onPressed: () => settings
                                                                      .showTranslation =
                                                                  !settings
                                                                      .showTranslation,
                                                              icon: Icon(
                                                                  settings.showTranslation
                                                                      ? Icons
                                                                          .keyboard_arrow_up_rounded
                                                                      : Icons
                                                                          .translate_rounded,
                                                                  size: 19),
                                                              label: Text(settings
                                                                      .showTranslation
                                                                  ? 'Meali gizle'
                                                                  : 'Türkçe meali göster')),
                                                          AnimatedSize(
                                                              duration:
                                                                  Motion.of(
                                                                      context,
                                                                      Motion
                                                                          .fast),
                                                              alignment:
                                                                  Alignment
                                                                      .topCenter,
                                                              child: settings
                                                                      .showTranslation
                                                                  ? Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .stretch,
                                                                      children: [
                                                                          const Divider(),
                                                                          const Eyebrow(
                                                                              'TÜRKÇE MEAL'),
                                                                          const SizedBox(
                                                                              height: 12),
                                                                          Text(
                                                                              verse.translation,
                                                                              style: TextStyle(fontSize: 19, height: 1.8, color: p.ink)),
                                                                        ])
                                                                  : const SizedBox(
                                                                      width: double
                                                                          .infinity)),
                                                        ]))),
                                            if (!last &&
                                                verse.arabic.length < 180) ...[
                                              const SizedBox(height: 20),
                                              const Center(
                                                  child:
                                                      Eyebrow('SIRADAKİ AYET')),
                                              const SizedBox(height: 8),
                                              Text(
                                                  widget
                                                      .quran
                                                      .verses[session.next + 1]
                                                      .arabic,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontFamily: 'Amiri',
                                                      fontSize: 22 *
                                                          settings.arabicScale,
                                                      color: p.muted,
                                                      height: 1.7)),
                                            ],
                                          ]),
                              ),
                            ))),
                Container(
                    decoration: BoxDecoration(
                        color: p.background,
                        border: Border(top: BorderSide(color: p.line))),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedProgress(
                              total: total,
                              done: confirmed,
                              color: p.accent,
                              trackColor: p.unread),
                          const SizedBox(height: 8),
                          Text('Bu okumada $confirmed / $total ayet onaylandı',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: p.muted)),
                          const SizedBox(height: 8),
                          PrimaryAction(
                              label: finished
                                  ? 'Devam et'
                                  : last
                                      ? 'Okudum, tamamla'
                                      : 'Okudum, sonraki ayet',
                              busy: busy,
                              icon: finished
                                  ? Icons.menu_book_rounded
                                  : last
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                              onPressed: finished ? continueReading : advance),
                          if (finished)
                            TextButton(
                                onPressed:
                                    busy ? null : () => Navigator.pop(context),
                                child: const Text('Bitir')),
                          if (!finished) ...[
                            const SizedBox(height: 6),
                            Text(
                                'Ayetler 30 dakika size ayrılır; çıkarsanız kaldığınız yer korunur.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11, height: 1.4, color: p.muted)),
                          ],
                        ])),
              ])))),
    );
  }
}

class _ReadingComplete extends StatelessWidget {
  const _ReadingComplete({super.key, required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => SoftCelebration(
      color: context.palette.gold,
      child: PaperCard(
          child: Column(children: [
        const IconBadge(Icons.check_rounded, size: 76, dark: true),
        const SizedBox(height: 22),
        Text('$total ayet tamamlandı',
            textAlign: TextAlign.center, style: context.text.headlineMedium),
        const SizedBox(height: 12),
        const Text('Allah kabul etsin.\nOkumanız kaydedildi.',
            textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const Text('Dilerseniz yeni ayetlerle devam edin veya burada bitirin.',
            textAlign: TextAlign.center),
      ])));
}

class _ReadingTag extends StatelessWidget {
  const _ReadingTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: context.palette.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Text(label,
          style: TextStyle(
              color: context.palette.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600)));
}
