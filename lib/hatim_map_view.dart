import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_design.dart';
import 'page_grid.dart';

Future<int?> findQuranPage(BuildContext context) =>
    showDialog<int>(context: context, builder: (_) => const _FindPageDialog());

class HatimMapView extends StatelessWidget {
  const HatimMapView(
      {super.key,
      required this.round,
      required this.donePages,
      required this.onSelect,
      this.selectedPage,
      this.selectedSura,
      this.selectedJuz,
      this.fromCache = false,
      this.fetching = false});
  final int round;
  final Set<int> donePages;
  final ValueChanged<int> onSelect;
  final int? selectedPage;
  final String? selectedJuz;
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
                    ? context.text.titleLarge
                    : context.text.headlineMedium),
            Text('sayfa tamamlandı',
                style: TextStyle(fontSize: 12, color: context.palette.muted)),
            const SizedBox(height: 10),
            Wrap(spacing: 14, runSpacing: 6, children: [
              GridLegend(color: context.palette.done, label: 'Okundu'),
              GridLegend(color: context.palette.unread, label: 'Okunmadı'),
            ]),
            if (fetching || fromCache) ...[
              const SizedBox(height: 6),
              Text(fetching ? 'Güncelleniyor…' : 'Cihazdaki son kayıt',
                  style: TextStyle(fontSize: 11, color: context.palette.muted)),
            ],
          ]);

  Widget selection(BuildContext context) => Semantics(
      liveRegion: true,
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: context.palette.paper,
              border: Border.all(color: context.palette.line),
              borderRadius: BorderRadius.circular(14)),
          child: Text(
              selectedPage == null
                  ? '30 satır, 30 cüz. Sayfa bilgisi için bir kutuya dokunun.'
                  : '$selectedPage. sayfa · ${donePages.contains(selectedPage) ? 'Okundu' : 'Okunmadı'}'
                      '${selectedJuz == null ? '' : ' · $selectedJuz. cüz'}'
                      '${selectedSura == null ? '' : '\n$selectedSura Suresi'}',
              style: TextStyle(
                  fontSize: 12, height: 1.5, color: context.palette.ink))));

  Widget grid(BuildContext context) => Center(
      child: AspectRatio(
          aspectRatio: PageGridLayout.aspectRatio,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: context.palette.paper,
                  border: Border.all(color: context.palette.line),
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: PageGrid(
                    paintKey: const ValueKey('hatim-page-grid'),
                    done: donePages,
                    selected: selectedPage,
                    onSelect: onSelect,
                    semanticsLabel:
                        '604 sayfalık hatim haritası; 30 cüz satırı. ${donePages.length} sayfa okundu. '
                        'Belirli bir sayfa için Sayfa bul düğmesini kullanın.',
                  )))));

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final landscape = box.maxWidth > box.maxHeight && box.maxWidth >= 500;
        return Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: landscape
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        SizedBox(
                            width: box.maxWidth * 0.30,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                      child: SingleChildScrollView(
                                          child:
                                              summary(context, compact: true))),
                                  const SizedBox(height: 10),
                                  selection(context),
                                ])),
                        const SizedBox(width: 16),
                        Expanded(child: grid(context)),
                      ])
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        summary(context, compact: box.maxHeight < 500),
                        const SizedBox(height: 14),
                        Expanded(child: grid(context)),
                        const SizedBox(height: 12),
                        selection(context),
                      ]));
      });
}

class GridLegend extends StatelessWidget {
  const GridLegend({super.key, required this.color, required this.label});
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
            style: TextStyle(fontSize: 12, color: context.palette.muted)),
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
