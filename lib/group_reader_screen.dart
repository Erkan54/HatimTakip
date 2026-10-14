import 'package:flutter/material.dart';
import 'app_design.dart';
import 'hatim_map_view.dart';
import 'quran.dart';
import 'settings.dart';

/// Unrestricted, offline page reading for private groups. This screen has no
/// repository or reading reservation: progress is explicitly marked in the group.
class GroupReaderScreen extends StatefulWidget {
  const GroupReaderScreen({
    super.key,
    required this.quran,
    required this.groupName,
    this.initialPage = 1,
  }) : assert(initialPage >= 1 && initialPage <= 604);

  final Quran quran;
  final String groupName;
  final int initialPage;

  @override
  State<GroupReaderScreen> createState() => _GroupReaderScreenState();
}

class _GroupReaderScreenState extends State<GroupReaderScreen> {
  late int page = widget.initialPage;
  late final controller = PageController(initialPage: page - 1);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void goTo(int target) {
    if (target < 1 || target > 604) return;
    controller.jumpToPage(target - 1);
  }

  Future<void> choosePage() async {
    final target = await findQuranPage(context);
    if (mounted && target != null) goTo(target);
  }

  void readingSettings() {
    final settings = AppSettings.of(context);
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ListenableBuilder(
            listenable: settings,
            builder: (context, _) => SafeArea(
                top: false,
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Okuma ayarları',
                              style: context.text.titleLarge),
                          const SizedBox(height: 16),
                          ArabicSizeControl(settings: settings),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Türkçe meali göster'),
                              value: settings.showTranslation,
                              onChanged: (value) =>
                                  settings.showTranslation = value),
                        ])))));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings = AppSettings.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('Kur’an oku'), actions: [
          IconButton(
              tooltip: 'Sayfa bul',
              icon: const Icon(Icons.search_rounded),
              onPressed: choosePage),
          IconButton(
              tooltip: 'Okuma ayarları',
              icon: const Icon(Icons.tune_rounded),
              onPressed: readingSettings),
        ]),
        body: AppBackground(
            child: SafeArea(
                top: false,
                child: PageFrame(
                    child: Column(children: [
                  Expanded(
                      child: PageView.builder(
                          controller: controller,
                          itemCount: 604,
                          onPageChanged: (index) =>
                              setState(() => page = index + 1),
                          itemBuilder: (context, index) => _QuranPage(
                              key: ValueKey('quran-page-${index + 1}'),
                              quran: widget.quran,
                              page: index + 1,
                              settings: settings))),
                  Container(
                      decoration: BoxDecoration(
                          color: p.background,
                          border: Border(top: BorderSide(color: p.line))),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Column(children: [
                        Row(children: [
                          IconButton(
                              tooltip: 'Önceki sayfa',
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed:
                                  page > 1 ? () => goTo(page - 1) : null),
                          Expanded(
                              child: Text(
                                  '$page / 604 · ${widget.quran.juzsOnPage(page).join('–')}. cüz',
                                  textAlign: TextAlign.center,
                                  style: context.text.titleSmall)),
                          IconButton(
                              tooltip: 'Sonraki sayfa',
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed:
                                  page < 604 ? () => goTo(page + 1) : null),
                        ]),
                        Text(widget.groupName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                            'Okuduğunuz sayfa veya cüzleri grupta işaretleyin.',
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall),
                      ])),
                ])))));
  }
}

class _QuranPage extends StatelessWidget {
  const _QuranPage(
      {super.key,
      required this.quran,
      required this.page,
      required this.settings});
  final Quran quran;
  final int page;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final verses = [
      for (final i in quran.indicesForPage(page)) quran.verses[i]
    ];
    final sections = <List<Verse>>[];
    for (final verse in verses) {
      if (sections.isEmpty || sections.last.last.sura != verse.sura) {
        sections.add([]);
      }
      sections.last.add(verse);
    }
    return ListView.builder(
        primary: false,
        // Each page keeps an independent scroll position when rebuilt by a
        // translation or text-size change; page navigation starts at the top.
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PaperCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Text('${section.first.displaySura} Suresi',
                        textAlign: TextAlign.center,
                        style: context.text.titleLarge),
                    const SizedBox(height: 16),
                    Text(
                        section
                            .map((v) => '${v.arabic} ۝${arabicDigits(v.ayah)}')
                            .join(' '),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 30 * settings.arabicScale,
                            height: 2,
                            color: context.palette.ink)),
                    if (settings.showTranslation) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const Eyebrow('TÜRKÇE MEAL'),
                      const SizedBox(height: 12),
                      Text(
                          section
                              .map((v) => '${v.ayah}. ${v.translation}')
                              .join('\n\n'),
                          style: TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              color: context.palette.ink)),
                    ],
                  ])));
        });
  }
}
