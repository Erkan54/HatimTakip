import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'app_design.dart';
import 'public_map.dart';
import 'quran.dart';
import 'repositories.dart';
import 'ui_feedback.dart';

export 'public_map.dart' show PublicMapScreen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repo, required this.quran});
  final HatimRepository repo;
  final Quran quran;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? name;
  Object? loadError;
  bool loading = true;
  bool busy = false;
  List<Map<String, dynamic>> groups = [];
  late final stateStream = widget.repo.state.snapshots();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final loaded = await widget.repo.loadName();
      final list = loaded == null
          ? <Map<String, dynamic>>[]
          : await widget.repo.myGroups();
      if (mounted) {
        setState(() {
          name = loaded;
          groups = list;
          loading = false;
          loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          loadError = e;
        });
      }
    }
  }

  Future<void> submitName(String value) async {
    setState(() => busy = true);
    try {
      await widget.repo.register(value);
      await refresh();
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    final value = await _ask(context,
        title: 'Birlikte bir hatim başlatın',
        description:
            'Grubunuza bir ad verin. Ardından davet kodunu sevdiklerinizle paylaşabilirsiniz.',
        label: 'Grup adı',
        action: 'Grubu oluştur',
        maxLength: 70);
    if (value == null || !mounted) return;
    setState(() => busy = true);
    try {
      final id = await widget.repo.createGroup(value);
      await refresh();
      if (mounted) {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GroupScreen(
                    repo: widget.repo, quran: widget.quran, id: id)));
      }
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> join() async {
    final value = await _ask(context,
        title: 'Halkaya katılın',
        description: 'Sizinle paylaşılan davet kodunu girin.',
        label: 'Davet kodu',
        action: 'Gruba katıl',
        code: true,
        maxLength: 32);
    if (value == null || !mounted) return;
    setState(() => busy = true);
    try {
      final id = await widget.repo.joinGroup(value);
      await refresh();
      if (mounted) {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => GroupScreen(
                    repo: widget.repo, quran: widget.quran, id: id)));
      }
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> read() async {
    setState(() => busy = true);
    try {
      final session = await widget.repo.startReading();
      if (mounted) {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ReaderScreen(
                    repo: widget.repo, quran: widget.quran, session: session)));
      }
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: AppBackground(
              child: AppStatus(title: 'Halkanız hazırlanıyor', loading: true)));
    }
    if (loadError != null && name == null) {
      return Scaffold(
          body: AppBackground(
              child: SafeArea(
                  child: AppStatus(
                      title: 'Biraz ara verelim',
                      message: friendly(loadError!),
                      onRetry: refresh,
                      icon: Icons.cloud_off_rounded))));
    }
    if (name == null) return OnboardingScreen(busy: busy, submit: submitName);
    return Scaffold(
      appBar: AppBar(
          title: const Row(children: [
        IconBadge(Icons.auto_stories_rounded, size: 34),
        SizedBox(width: 10),
        Text('Hatim Halkası')
      ])),
      body: AppBackground(
          child: SafeArea(
              top: false,
              child: PageFrame(
                  child: RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const Eyebrow('HER AYETTE BİRLİKTE'),
                      const SizedBox(height: 8),
                      Text('Hoş geldiniz,\n$name.',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 10),
                      const Text('Bugün de aynı niyette buluşalım.'),
                      const SizedBox(height: 26),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: stateStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return PaperCard(
                                  child: Text(friendly(snapshot.error!)));
                            }
                            return CommunityCard(
                                data: snapshot.data?.data(),
                                loading: !snapshot.hasData);
                          }),
                      const SizedBox(height: 18),
                      PrimaryAction(
                          label: 'Hızlı Hatime Katıl',
                          icon: Icons.menu_book_rounded,
                          busy: busy,
                          onPressed: read),
                      const SizedBox(height: 10),
                      const Text(
                          'Ortak hatimde size ayrılan ayetlerle devam edin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5)),
                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      Text('Kendi halkanız',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      const Text('Sevdiklerinizle bir hatimde buluşun.'),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final actions = [
                          _HomeAction(
                              icon: Icons.add_rounded,
                              title: 'Grup oluştur',
                              subtitle: 'Yeni bir halka başlat',
                              onTap: busy ? null : create),
                          _HomeAction(
                              icon: Icons.group_add_outlined,
                              title: 'Gruba katıl',
                              subtitle: 'Davet kodunu kullan',
                              onTap: busy ? null : join),
                        ];
                        if (constraints.maxWidth < 340 ||
                            MediaQuery.textScalerOf(context).scale(16) > 22) {
                          return Column(children: [
                            actions[0],
                            const SizedBox(height: 12),
                            actions[1]
                          ]);
                        }
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: actions[0]),
                              const SizedBox(width: 12),
                              Expanded(child: actions[1])
                            ]);
                      }),
                      const SizedBox(height: 28),
                      Text('Hatim gruplarım',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
                      if (loadError != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(friendly(loadError!))),
                      if (groups.isEmpty)
                        const PaperCard(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              IconBadge(Icons.people_outline_rounded),
                              SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Halkanız sizi bekliyor',
                                        style: TextStyle(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(height: 4),
                                    Text(
                                        'Bir grup oluşturun veya davet koduyla katılın.'),
                                  ])),
                            ])),
                      for (final g in groups)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                                child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              leading:
                                  const IconBadge(Icons.people_outline_rounded),
                              title: Text(g['name'] as String? ?? 'Hatim grubu',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              subtitle: Text(
                                  '${g['completedHatims'] ?? 0} tamamlanan hatim'),
                              trailing: const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.muted),
                              onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => GroupScreen(
                                              repo: widget.repo,
                                              quran: widget.quran,
                                              id: g['id'] as String)))
                                  .then((_) => refresh()),
                            ))),
                    ]),
              )))),
    );
  }
}

class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key, required this.data, this.loading = false});
  final Map<String, dynamic>? data;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final completed = (data?['completedPages'] as List<dynamic>? ?? []).length;
    return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
            color: AppColors.green,
            child: Stack(children: [
              const Positioned(
                  right: -58,
                  top: -58,
                  width: 240,
                  height: 240,
                  child: IgnorePointer(
                      child: CustomPaint(
                          painter: OrnamentPainter(color: Color(0x25e4cd93))))),
              Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('BİRLİKTE TAMAMLADIK',
                            color: Color(0xffd4dfce)),
                        const SizedBox(height: 14),
                        Wrap(
                            spacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Text(
                                  loading
                                      ? '—'
                                      : '${data?['completedHatims'] ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 52,
                                      height: 1.1,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -2)),
                              const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text('hatim',
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Color(0xffe5d6af)))),
                            ]),
                        const SizedBox(height: 22),
                        Container(
                            height: 1, color: Colors.white.withOpacity(0.16)),
                        const SizedBox(height: 18),
                        Text(
                            loading
                                ? 'Hatim bilgisi yükleniyor…'
                                : data == null
                                    ? 'Ortak hatim hazırlanıyor'
                                    : '${data!['round'] ?? 1}. hatimde buluşuyoruz',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 10),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                                value: loading ? null : completed / 604,
                                minHeight: 5,
                                backgroundColor: Colors.white.withOpacity(0.13),
                                color: const Color(0xffdbc58d),
                                semanticsLabel: 'Tamamlanan sayfalar',
                                semanticsValue: '$completed / 604')),
                        const SizedBox(height: 8),
                        Text(
                            loading
                                ? 'Birazdan hazır'
                                : '$completed / 604 sayfa tamamlandı',
                            style: const TextStyle(
                                color: Color(0xffd4dfce), fontSize: 12)),
                      ])),
            ])));
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon,
                        color:
                            onTap == null ? AppColors.muted : AppColors.green,
                        size: 26),
                    const SizedBox(height: 16),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                  ]))));
}

Future<String?> _ask(BuildContext context,
        {required String title,
        required String description,
        required String label,
        required String action,
        bool code = false,
        int maxLength = 70}) =>
    showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _EntrySheet(
            title: title,
            description: description,
            label: label,
            action: action,
            code: code,
            maxLength: maxLength));

class _EntrySheet extends StatefulWidget {
  const _EntrySheet(
      {required this.title,
      required this.description,
      required this.label,
      required this.action,
      required this.code,
      required this.maxLength});
  final String title, description, label, action;
  final bool code;
  final int maxLength;
  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (form.currentState!.validate()) {
      Navigator.pop(context, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SafeArea(
          top: false,
          child: Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(widget.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(widget.description),
                    const SizedBox(height: 24),
                    TextFormField(
                        controller: controller,
                        autofocus: true,
                        maxLength: widget.maxLength,
                        textCapitalization: widget.code
                            ? TextCapitalization.characters
                            : TextCapitalization.words,
                        autocorrect: !widget.code,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(labelText: widget.label),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? '${widget.label} giriniz.'
                                : null,
                        onFieldSubmitted: (_) => submit()),
                    const SizedBox(height: 12),
                    PrimaryAction(label: widget.action, onPressed: submit),
                  ]))));
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.busy, required this.submit});
  final bool busy;
  final Future<void> Function(String) submit;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    if (!widget.busy && form.currentState!.validate()) {
      widget.submit(controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: AppBackground(
              child: SafeArea(
                  child: Center(
                      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                        child: IconBadge(Icons.auto_stories_rounded,
                            size: 88, dark: true)),
                    const SizedBox(height: 32),
                    const Center(child: Eyebrow('AYNI NİYETTE, AYNI HALKADA')),
                    const SizedBox(height: 12),
                    Text('Hatim Halkası',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 16),
                    const Text(
                        'Her ayet bir katkı.\nBirlikte okuyalım, birlikte tamamlayalım.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 36),
                    PaperCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Text('Sizi nasıl çağıralım?',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: controller,
                              enabled: !widget.busy,
                              maxLength: 40,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => submit(),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Lütfen adınızı girin.'
                                      : null,
                              decoration: const InputDecoration(
                                  labelText: 'Adınız',
                                  hintText: 'Adınızı yazın',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded))),
                          const SizedBox(height: 12),
                          PrimaryAction(
                              label: 'Halkaya katıl',
                              busy: widget.busy,
                              onPressed: submit),
                        ])),
                    const SizedBox(height: 20),
                    const Text('Ücretsiz ve reklamsız.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ])),
        ),
      )))));
}

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
  bool pages = true;
  bool busy = false;
  int? members;
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
    } catch (_) {
      /* The group's content remains usable without a member count. */
    }
  }

  void retry() => setState(() {
        groupStream = widget.repo.groupStream(widget.id);
        progressRound = null;
      });
  Set<int> covered(Map<String, dynamic> marks) {
    final result = <int>{};
    for (var page = 1; page <= 604; page++) {
      if (marks.containsKey('p$page')) {
        result.addAll(widget.quran.indicesForPage(page));
      }
    }
    for (var juz = 1; juz <= 30; juz++) {
      if (marks.containsKey('j$juz')) {
        result.addAll(widget.quran.indicesForJuz(juz));
      }
    }
    return result;
  }

  Future<void> toggle(int round, String key, bool isMarked) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.repo.mark(widget.id, round, key, !isMarked);
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
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: groupStream,
          builder: (context, groupSnap) {
            if (groupSnap.hasError) {
              return status('Gruba ulaşılamadı',
                  message: friendly(groupSnap.error!), onRetry: retry);
            }
            if (!groupSnap.hasData) {
              return status('Halkanız hazırlanıyor', loading: true);
            }
            final group = groupSnap.data!.data();
            if (group == null) {
              return status('Grup bulunamadı',
                  message: 'Grup bilgilerini yeniden kontrol edin.',
                  onRetry: retry);
            }
            final round = group['round'] as int;
            final invite = group['inviteCode'] as String;
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
                  final count = pages ? 604 : 30;
                  return Scaffold(
                    appBar: AppBar(title: Text(group['name'] as String)),
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
                                        PaperCard(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Eyebrow('$round. HATİM'),
                                              const SizedBox(height: 12),
                                              Text(
                                                  complete
                                                      ? 'Allah kabul etsin.'
                                                      : 'Birlikte tamamlıyoruz.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium),
                                              const SizedBox(height: 8),
                                              Text(
                                                  '${members == null ? 'Halkamız' : '$members kişi'} · ${group['completedHatims']} tamamlanan hatim'),
                                              const SizedBox(height: 24),
                                              Text(
                                                  '%${(done.length * 100 / verseCount).toStringAsFixed(1)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineLarge),
                                              const SizedBox(height: 12),
                                              ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: LinearProgressIndicator(
                                                      value: done.length /
                                                          verseCount,
                                                      minHeight: 8,
                                                      semanticsLabel:
                                                          'Hatim ilerlemesi',
                                                      semanticsValue:
                                                          '${done.length} / $verseCount ayet')),
                                              const SizedBox(height: 10),
                                              Text(
                                                  '${done.length} / $verseCount ayet tamamlandı'),
                                              if (complete &&
                                                  group['owner'] ==
                                                      widget.repo.uid) ...[
                                                const SizedBox(height: 18),
                                                PrimaryAction(
                                                    label: 'Yeni hatim başlat',
                                                    busy: busy,
                                                    onPressed: () =>
                                                        newRound(round))
                                              ],
                                            ])),
                                        const SizedBox(height: 16),
                                        PaperCard(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              const Eyebrow(
                                                  'HALKANIZI PAYLAŞIN'),
                                              const SizedBox(height: 8),
                                              SelectableText(invite,
                                                  style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.green,
                                                      letterSpacing: 1)),
                                              const SizedBox(height: 6),
                                              Wrap(spacing: 8, children: [
                                                TextButton.icon(
                                                    onPressed: () async {
                                                      await Clipboard.setData(
                                                          ClipboardData(
                                                              text: invite));
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        'Davet kodu kopyalandı.')));
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.copy_rounded,
                                                        size: 18),
                                                    label:
                                                        const Text('Kopyala')),
                                                TextButton.icon(
                                                    onPressed: () async {
                                                      try {
                                                        await Share.share(
                                                            'Hatim Halkası grubuma katıl: $invite');
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          notice(context, e);
                                                        }
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.ios_share_rounded,
                                                        size: 18),
                                                    label:
                                                        const Text('Paylaş')),
                                              ]),
                                            ])),
                                        const SizedBox(height: 26),
                                        Text('Okuma takibi',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge),
                                        const SizedBox(height: 14),
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
                                            onSelectionChanged: (s) => setState(
                                                () => pages = s.first)),
                                      ]))),
                              SliverPadding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                  sliver: SliverList.builder(
                                      itemCount: count,
                                      itemBuilder: (context, index) {
                                        final number = index + 1;
                                        final key =
                                            '${pages ? 'p' : 'j'}$number';
                                        final indices = pages
                                            ? widget.quran
                                                .indicesForPage(number)
                                            : widget.quran
                                                .indicesForJuz(number);
                                        final read = widget.quran
                                            .completedIn(indices, done);
                                        final marked = marks.containsKey(key);
                                        final info = marked
                                            ? Map<String, dynamic>.from(
                                                marks[key])
                                            : null;
                                        final isComplete =
                                            read == indices.length;
                                        return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Card(
                                                child: ListTile(
                                              enabled: !busy,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              leading: IconBadge(
                                                  isComplete
                                                      ? Icons.check_rounded
                                                      : Icons
                                                          .menu_book_outlined,
                                                  size: 42,
                                                  dark: isComplete),
                                              title: Text(
                                                  pages
                                                      ? '$number. Sayfa'
                                                      : '$number. Cüz',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium),
                                              subtitle: Text(
                                                  '$read / ${indices.length} ayet${info == null ? '' : '\n${info['name']}'}'),
                                              trailing: const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: AppColors.muted),
                                              onTap: busy
                                                  ? null
                                                  : () => showModalBottomSheet<
                                                          void>(
                                                      context: context,
                                                      isScrollControlled: true,
                                                      useSafeArea: true,
                                                      builder: (ctx) =>
                                                          SafeArea(
                                                              top: false,
                                                              child:
                                                                  SingleChildScrollView(
                                                                      padding: const EdgeInsets
                                                                          .fromLTRB(
                                                                          24,
                                                                          0,
                                                                          24,
                                                                          24),
                                                                      child: Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.stretch,
                                                                          children: [
                                                                            Text(pages ? '$number. Sayfa' : '$number. Cüz',
                                                                                style: Theme.of(context).textTheme.titleLarge),
                                                                            const SizedBox(height: 8),
                                                                            Text('$read / ${indices.length} ayet tamamlandı'),
                                                                            const SizedBox(height: 24),
                                                                            PrimaryAction(
                                                                                label: marked
                                                                                    ? 'İşaretlemeyi geri al'
                                                                                    : pages
                                                                                        ? 'Bu sayfayı okudum'
                                                                                        : 'Bu cüzü okudum',
                                                                                icon: marked ? Icons.undo_rounded : Icons.check_rounded,
                                                                                onPressed: () {
                                                                                  Navigator.pop(ctx);
                                                                                  toggle(round, key, marked);
                                                                                }),
                                                                          ])))),
                                            )));
                                      })),
                            ])))),
                  );
                });
          });
}

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
  bool showTranslation = false;
  bool busy = false;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> advance() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final next = await widget.repo.confirm(session);
      if (next == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Okumanız kaydedildi. Allah kabul etsin.')));
          Navigator.pop(context);
        }
        return;
      }
      if (next.next >= next.end) {
        final fresh = await widget.repo.startReading();
        if (mounted) {
          setState(() {
            session = fresh;
            showTranslation = false;
          });
        }
      } else if (mounted) {
        setState(() {
          session = next;
          showTranslation = false;
        });
      }
      if (scroll.hasClients) scroll.jumpTo(0);
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verse = widget.quran.verses[session.next];
    final lastInSession = session.next + 1 >= session.end;
    final confirmed = session.next - session.chunk * chunkSize;
    final total = session.end - session.chunk * chunkSize;
    return Scaffold(
        appBar: AppBar(title: const Text('Birlikte Hatim'), actions: [
          IconButton(
              tooltip: 'Hatim Haritası',
              icon: const Icon(Icons.grid_view_rounded),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PublicMapScreen(
                          repo: widget.repo, quran: widget.quran)))),
          const SizedBox(width: 8),
        ]),
        body: AppBackground(
            child: SafeArea(
                top: false,
                child: PageFrame(
                    child: Column(children: [
                  Expanded(
                      child: SingleChildScrollView(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                    child: Eyebrow('${session.round}. HATİM')),
                                const SizedBox(height: 10),
                                Text('${verse.suraName} Suresi',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                                const SizedBox(height: 12),
                                Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ReadingTag('${verse.ayah}. ayet'),
                                      _ReadingTag('${verse.page}. sayfa'),
                                      _ReadingTag('${verse.juz}. cüz'),
                                    ]),
                                const SizedBox(height: 24),
                                PaperCard(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 32),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Icon(
                                              Icons.auto_stories_outlined,
                                              size: 20,
                                              color: AppColors.gold),
                                          const SizedBox(height: 22),
                                          Text(verse.arabic,
                                              textAlign: TextAlign.center,
                                              textDirection: TextDirection.rtl,
                                              style: const TextStyle(
                                                  fontSize: 34,
                                                  height: 2.0,
                                                  fontFamily: 'Amiri',
                                                  color: AppColors.ink)),
                                          const SizedBox(height: 18),
                                          TextButton.icon(
                                              onPressed: () => setState(() =>
                                                  showTranslation =
                                                      !showTranslation),
                                              icon: Icon(
                                                  showTranslation
                                                      ? Icons
                                                          .keyboard_arrow_up_rounded
                                                      : Icons.translate_rounded,
                                                  size: 19),
                                              label: Text(showTranslation
                                                  ? 'Meali gizle'
                                                  : 'Türkçe meali göster')),
                                          AnimatedSize(
                                              duration: MediaQuery
                                                      .disableAnimationsOf(
                                                          context)
                                                  ? Duration.zero
                                                  : const Duration(
                                                      milliseconds: 180),
                                              alignment: Alignment.topCenter,
                                              child: showTranslation
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
                                                              style: const TextStyle(
                                                                  fontSize: 19,
                                                                  height: 1.8,
                                                                  color:
                                                                      AppColors
                                                                          .ink)),
                                                        ])
                                                  : const SizedBox(
                                                      width: double.infinity)),
                                        ])),
                              ]))),
                  Container(
                      decoration: const BoxDecoration(
                          color: AppColors.background,
                          border:
                              Border(top: BorderSide(color: AppColors.line))),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                                'Bu okumada $confirmed / $total ayet onaylandı',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                            const SizedBox(height: 10),
                            PrimaryAction(
                                label: lastInSession
                                    ? 'Okudum, tamamla'
                                    : 'Okudum, sonraki ayet',
                                busy: busy,
                                icon: lastInSession
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                onPressed: advance),
                          ])),
                ])))));
  }
}

class _ReadingTag extends StatelessWidget {
  const _ReadingTag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.greenLight, borderRadius: BorderRadius.circular(30)),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600)));
}
