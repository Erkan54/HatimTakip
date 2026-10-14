import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_design.dart';
import 'quran.dart';
import 'repositories.dart';
import 'ui_feedback.dart';
import 'settings.dart';
import 'group_screen.dart';
import 'reader_screen.dart';
import 'onboarding_screen.dart';
import 'entry_sheet.dart';
import 'community_card.dart';

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
    final value = await askForText(context,
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
    final value = await askForText(context,
        title: 'Gruba katılın',
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
              child: AppStatus(title: 'Grubunuz hazırlanıyor', loading: true)));
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
        title: const Text('Hatim Zinciri',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                          name: name,
                          onNameChanged: (value) async {
                            await widget.repo.updateName(value);
                            if (mounted) setState(() => name = value);
                          })))),
        ],
      ),
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
                          style: Theme.of(context).textTheme.headlineMedium),
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
                      Text('Ortak hatimde size ayrılan ayetlerle devam edin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.palette.muted,
                              height: 1.5)),
                      const SizedBox(height: 28),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      Text('Kendi hatim grubunuz',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      const Text('Sevdiklerinizle bir hatimde buluşun.'),
                      const SizedBox(height: 16),
                      LayoutBuilder(builder: (context, constraints) {
                        final actions = [
                          _HomeAction(
                              icon: Icons.add_rounded,
                              title: 'Grup oluştur',
                              subtitle: 'Yeni bir hatim grubu başlat',
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
                        PaperCard(
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              const IconBadge(Icons.people_outline_rounded),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('Grubunuz sizi bekliyor',
                                        style: TextStyle(
                                            color: context.palette.ink,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    const Text(
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
                                  '${g['round'] ?? 1}. hatim · ${g['completedHatims'] ?? 0} tamamlanan'),
                              trailing: Icon(Icons.chevron_right_rounded,
                                  color: context.palette.muted),
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
                        color: onTap == null
                            ? context.palette.muted
                            : context.palette.accent,
                        size: 26),
                    const SizedBox(height: 16),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, height: 1.5)),
                  ]))));
}
