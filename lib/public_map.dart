import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_design.dart';
import 'hatim_map_view.dart';

import 'quran.dart';
import 'repositories.dart';
import 'ui_feedback.dart';

export 'hatim_map_view.dart' show HatimMapView;

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
    final page = await findQuranPage(context);
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
                                    .displaySura,
                            selectedJuz: selectedPage == null
                                ? null
                                : widget.quran
                                    .juzsOnPage(selectedPage!)
                                    .join('–'),
                            onSelect: (page) =>
                                setState(() => selectedPage = page),
                          ));
                    }))),
      );
}
