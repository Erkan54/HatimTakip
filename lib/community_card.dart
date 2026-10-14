import 'package:flutter/material.dart';
import 'app_design.dart';
import 'motion.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key, required this.data, this.loading = false});
  final Map<String, dynamic>? data;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final pages = (data?['completedPages'] as List? ?? [])
        .whereType<num>()
        .where((n) => n >= 1 && n <= 604)
        .toSet()
        .length;
    final ring = Semantics(
      label: 'Tamamlanan sayfalar',
      value: '$pages / 604',
      child: ProgressRing(
        value: loading ? 0 : pages / 604,
        size: compact ? 78 : 108,
        stroke: 7,
        color: p.heroBar,
        trackColor: Colors.white.withOpacity(0.13),
        child: ExcludeSemantics(
            child: Text(loading ? '—' : '%${(pages * 100 / 604).round()}',
                style: TextStyle(
                    fontSize: compact ? 16 : 19,
                    color: Colors.white,
                    fontWeight: FontWeight.w700))),
      ),
    );
    return FadeSlideIn(
      child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          child: ColoredBox(
              color: p.hero,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('AYNI NİYETTE BULUŞUYORUZ', color: p.heroMuted),
                      const SizedBox(height: 18),
                      LayoutBuilder(builder: (context, box) {
                        final info = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  loading
                                      ? 'Hatim bilgisi yükleniyor…'
                                      : '${data?['round'] ?? 1}. hatimdeyiz',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: compact ? 18 : 20)),
                              const SizedBox(height: 8),
                              Text('$pages / 604 sayfa tamamlandı',
                                  style: TextStyle(
                                      color: p.heroMuted, fontSize: 12)),
                            ]);
                        if (MediaQuery.textScalerOf(context).scale(16) > 22) {
                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                info,
                                const SizedBox(height: 18),
                                Center(child: ring)
                              ]);
                        }
                        return Row(children: [
                          Expanded(child: info),
                          const SizedBox(width: 14),
                          ring
                        ]);
                      }),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: Colors.white.withOpacity(0.16)),
                      const SizedBox(height: 16),
                      Row(children: [
                        Icon(Icons.auto_stories_outlined,
                            size: 20, color: p.heroGold),
                        const SizedBox(width: 10),
                        Flexible(
                            child: loading
                                ? Text('Birazdan hazır',
                                    style: TextStyle(color: p.heroMuted))
                                : CountUpText(
                                    (data?['completedHatims'] as num?) ?? 0,
                                    format: (v) =>
                                        '${v.round()} hatim birlikte tamamlandı',
                                    style: TextStyle(
                                        color: p.heroGold, fontSize: 13))),
                      ]),
                    ]),
              ))),
    );
  }
}
