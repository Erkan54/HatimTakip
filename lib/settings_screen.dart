import 'package:flutter/material.dart';
import 'app_design.dart';
import 'motion.dart';
import 'settings.dart';
import 'ui_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.name, this.onNameChanged});
  final String? name;
  final Future<void> Function(String)? onNameChanged;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String? name = widget.name;
  bool saving = false;

  Future<void> editName() async {
    final value = await showDialog<String>(
        context: context, builder: (_) => _EditNameDialog(name: name!));
    if (!mounted || value == null || value == name) return;
    setState(() => saving = true);
    try {
      await widget.onNameChanged!(value);
      if (mounted) {
        setState(() => name = value);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Adınız güncellendi.')));
      }
    } catch (e) {
      if (mounted) notice(context, e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final p = context.palette;
    Widget section(int index, String title, List<Widget> children) =>
        FadeSlideIn(
            index: index,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                          child: Eyebrow(title)),
                      Card(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children)),
                    ])));
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: AppBackground(
          child: SafeArea(
              top: false,
              child: PageFrame(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      if (name != null)
                        section(0, 'PROFİL', [
                          ListTile(
                            leading: const Icon(Icons.person_outline_rounded),
                            title: Text(name!),
                            subtitle: const Text('Grupta görünecek adınız'),
                            trailing: saving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.edit_outlined),
                            onTap: widget.onNameChanged == null || saving
                                ? null
                                : editName,
                          )
                        ]),
                      section(1, 'GÖRÜNÜM', [
                        for (final mode in [ThemeMode.light, ThemeMode.dark])
                          RadioListTile<ThemeMode>(
                              value: mode,
                              groupValue: settings.theme,
                              title: Text(
                                  mode == ThemeMode.light ? 'Açık' : 'Koyu'),
                              secondary: Icon(mode == ThemeMode.light
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded),
                              onChanged: (v) {
                                if (v != null) settings.theme = v;
                              }),
                      ]),
                      section(2, 'OKUMA', [
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text('Arapça yazı boyutu',
                                style: context.text.titleMedium)),
                        Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: ArabicSizeControl(settings: settings)),
                        Divider(height: 1, color: p.line),
                        SwitchListTile(
                            value: settings.showTranslation,
                            onChanged: (v) => settings.showTranslation = v,
                            title: const Text('Türkçe meali açık başlat'),
                            subtitle: const Text(
                                'Meal tercihiniz sonraki ayetlerde korunur.')),
                        Divider(height: 1, color: p.line),
                        SwitchListTile(
                            value: settings.haptics,
                            onChanged: (v) => settings.haptics = v,
                            title: const Text('Titreşimli geri bildirim'),
                            subtitle:
                                const Text('Ayet onayında hafif titreşim.')),
                      ]),
                      section(3, 'HESAP', [
                        const ListTile(
                            leading: Icon(Icons.shield_outlined),
                            title: Text('Anonim hesap'),
                            subtitle: Text(
                                'Uygulama verileri silinirse veya cihaz değişirse hesabınız ve grup üyelikleriniz kurtarılamaz.'))
                      ]),
                      section(4, 'HAKKINDA', [
                        ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: const Text('Lisanslar'),
                            subtitle: const Text(
                                'Yazı tipleri ve açık kaynak bileşenler'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => showLicensePage(
                                context: context,
                                applicationName: 'Hatim Zinciri',
                                applicationVersion: '1.0.0'))
                      ]),
                      const Text('Hatim Zinciri · Ücretsiz ve reklamsız',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12)),
                    ]),
              ))),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.name});
  final String name;
  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final controller = TextEditingController(text: widget.name);
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
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Adınızı değiştirin'),
          content: Form(
              key: form,
              child: TextFormField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  onFieldSubmitted: (_) => submit(),
                  decoration: const InputDecoration(labelText: 'Adınız'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Lütfen adınızı girin.'
                      : null)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç')),
            FilledButton(onPressed: submit, child: const Text('Kaydet'))
          ]);
}
