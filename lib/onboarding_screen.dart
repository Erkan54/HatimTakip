import 'package:flutter/material.dart';
import 'app_design.dart';

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
                    const Center(child: Eyebrow('AYNI NİYETLE BİRLİKTE')),
                    const SizedBox(height: 12),
                    Text('Hatim Zinciri',
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
                              label: 'Zincire katıl',
                              busy: widget.busy,
                              onPressed: submit),
                        ])),
                    const SizedBox(height: 20),
                    const ListTile(
                        leading: Icon(Icons.menu_book_outlined),
                        title: Text('Ayet ayet ortak hatim')),
                    const ListTile(
                        leading: Icon(Icons.people_outline_rounded),
                        title: Text('Aileyle özel grup')),
                    const ListTile(
                        leading: Icon(Icons.favorite_outline_rounded),
                        title: Text('Ücretsiz ve reklamsız')),
                  ])),
        ),
      )))));
}
