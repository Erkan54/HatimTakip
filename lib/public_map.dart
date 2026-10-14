import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_design.dart';
import 'quran.dart';
import 'repositories.dart';
import 'ui_feedback.dart';

class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key, required this.repo, required this.quran});
  final HatimRepository repo;
  final Quran quran;
  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> state;
  bool fetching = true;
  int? selectedPage;
  @override
  void initState() {
    super.initState();
    state = load();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> load(
      {bool server = false}) async {
    try {
      return await widget.repo.state.get(server
          ? const GetOptions(source: Source.server)
          : const GetOptions());
    } finally {
      if (mounted) setState(() => fetching = false);
    }
  }

  void refresh() {
    if (fetching) return;
    setState(() {
      fetching = true;
      state = load(server: true);
    });
  }

  Future<void> findPage() async {
    final page = await showDialog<int>(
        context: context, builder: (_) => const _FindPageDialog());
    if (page != null && mounted) setState(() => selectedPage = page);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hatim Haritası'), actions: [
          IconButton(
              tooltip: 'Sayfa bul',
              onPressed: findPage,
              icon: const Icon(Icons.search_rounded)),
          IconButton(
              tooltip: 'Yenile',
              onPressed: fetching ? null : refresh,
              icon: const Icon(Icons.refresh_rounded)),
        ]),
        body: AppBackground(
            child: SafeArea(
                top: false,
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: state,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData && !snapshot.hasError) {
                        return const AppStatus(
                            title: 'Hatim haritası hazırlanıyor',
                            loading: true);
                      }
                      if (snapshot.hasError) {
                        return AppStatus(
                            title: 'Harita yüklenemedi',
                            message: friendly(snapshot.error!),
                            onRetry: refresh,
                            icon: Icons.cloud_off_rounded);
                      }
                      final data = snapshot.data?.data();
                      if (data == null) {
                        return const AppStatus(
                            title: 'Ortak hatim henüz başlamadı',
                            message:
                                'Hatim başladığında sayfaları burada görebilirsiniz.');
                      }
                      final donePages =
                          (data['completedPages'] as List<dynamic>? ?? [])
                              .whereType<num>()
                              .map((v) => v.toInt())
                              .where((p) => p >= 1 && p <= 604)
                              .toSet();
                      return PageFrame(
                          maxWidth: 1000,
                          child: HatimMapView(
                            round: data['round'] as int? ?? 1,
                            donePages: donePages,
                            selectedPage: selectedPage,
                            fromCache: snapshot.data!.metadata.isFromCache,
                            fetching: fetching,
                            selectedSura: selectedPage == null
                                ? null
                                : widget
                                    .quran
                                    .verses[widget.quran
                                        .indicesForPage(selectedPage!)
                                        .first]
                                    .suraName,
                            onSelect: (page) =>
                                setState(() => selectedPage = page),
                          ));
                    }))),
      );
}

/// All 604 cells are painted in the available area, with no scrolling or network work.
class HatimMapView extends StatelessWidget {
  const HatimMapView(
      {super.key,
      required this.round,
      required this.donePages,
      required this.onSelect,
      this.selectedPage,
      this.selectedSura,
      this.fromCache = false,
      this.fetching = false});
  final int round;
  final Set<int> donePages;
  final ValueChanged<int> onSelect;
  final int? selectedPage;
  final String? selectedSura;
  final bool fromCache, fetching;
  Widget summary(BuildContext context, {bool compact = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Eyebrow('$round. HATİM'),
            const SizedBox(height: 6),
            Text('${donePages.length} / 604',
                style: compact
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.headlineMedium),
            const Text('sayfa tamamlandı',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 10),
            const Wrap(spacing: 14, runSpacing: 6, children: [
              _MapLegend(color: AppColors.green, label: 'Okundu'),
              _MapLegend(color: AppColors.unread, label: 'Okunmadı'),
            ]),
            if (fetching || fromCache) ...[
              const SizedBox(height: 6),
              Text(fetching ? 'Güncelleniyor…' : 'Cihazdaki son kayıt',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted))
            ],
          ]);
  Widget selection() => Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14)),
        child: Text(
            selectedPage == null
                ? 'Sayfa bilgisi için bir kutuya dokunun.'
                : '$selectedPage. sayfa · ${donePages.contains(selectedPage) ? 'Okundu' : 'Okunmadı'}${selectedSura == null ? '' : '\n$selectedSura Suresi'}',
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: AppColors.ink)),
      ));
  Widget grid() => DecoratedBox(
      decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Semantics(
                label:
                    '604 sayfalık hatim haritası. ${donePages.length} sayfa okundu. Belirli bir sayfa için üstteki Sayfa bul düğmesini kullanın.',
                image: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final page =
                        PageMapPainter.pageAt(details.localPosition, size);
                    if (page != null) onSelect(page);
                  },
                  child: CustomPaint(
                      key: const ValueKey('hatim-page-grid'),
                      size: size,
                      painter: PageMapPainter(donePages, selectedPage)),
                ));
          })));
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight &&
            constraints.maxWidth >= 500;
        return Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: landscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        SizedBox(
                            width: constraints.maxWidth * 0.30,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      child: SingleChildScrollView(
                                          child:
                                              summary(context, compact: true))),
                                  const SizedBox(height: 10),
                                  selection(),
                                ])),
                        const SizedBox(width: 16),
                        Expanded(child: grid()),
                      ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        summary(context, compact: constraints.maxHeight < 500),
                        const SizedBox(height: 14),
                        Expanded(child: grid()),
                        const SizedBox(height: 12),
                        selection(),
                      ]));
      });
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}

class _FindPageDialog extends StatefulWidget {
  const _FindPageDialog();
  @override
  State<_FindPageDialog> createState() => _FindPageDialogState();
}

class _FindPageDialogState extends State<_FindPageDialog> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      Navigator.pop(context, int.parse(controller.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Sayfa bul'),
          content: Form(
              key: form,
              child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3)
                  ],
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                      labelText: 'Sayfa numarası', hintText: '1–604'),
                  validator: (value) {
                    final page = int.tryParse(value ?? '');
                    return page == null || page < 1 || page > 604
                        ? '1 ile 604 arasında bir sayı girin.'
                        : null;
                  },
                  onFieldSubmitted: (_) => submit())),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç')),
            FilledButton(onPressed: submit, child: const Text('Göster'))
          ]);
}

class PageMapPainter extends CustomPainter {
  PageMapPainter(this.donePages, this.selectedPage);
  final Set<int> donePages;
  final int? selectedPage;
  static int columns(Size size) =>
      max(1, min(604, sqrt(604 * size.width / size.height).round()));
  static int? pageAt(Offset offset, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        offset.dx < 0 ||
        offset.dy < 0 ||
        offset.dx >= size.width ||
        offset.dy >= size.height) return null;
    final cols = columns(size);
    final rows = (604 + cols - 1) ~/ cols;
    final page = (offset.dy / (size.height / rows)).floor() * cols +
        (offset.dx / (size.width / cols)).floor() +
        1;
    return page <= 604 ? page : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cols = columns(size);
    final rows = (604 + cols - 1) ~/ cols;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final gap = min(cellWidth, cellHeight) * 0.17;
    final fill = Paint();
    final outline = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var page = 1; page <= 604; page++) {
      final x = ((page - 1) % cols) * cellWidth;
      final y = ((page - 1) ~/ cols) * cellHeight;
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
              x + gap / 2, y + gap / 2, cellWidth - gap, cellHeight - gap),
          Radius.circular(min(cellWidth, cellHeight) * 0.2));
      fill.color =
          donePages.contains(page) ? AppColors.green : AppColors.unread;
      canvas.drawRRect(rect, fill);
      if (selectedPage == page) {
        canvas.drawRRect(rect.deflate(0.5), outline);
        canvas.drawCircle(
            rect.outerRect.center,
            min(cellWidth, cellHeight) * 0.12,
            Paint()
              ..color =
                  donePages.contains(page) ? Colors.white : AppColors.ink);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PageMapPainter oldDelegate) =>
      !setEquals(oldDelegate.donePages, donePages) ||
      oldDelegate.selectedPage != selectedPage;
}
