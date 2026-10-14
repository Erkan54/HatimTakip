import 'package:flutter/material.dart';
import 'app_design.dart';
import 'invite_code.dart';

Future<String?> askForText(BuildContext context,
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
                        inputFormatters:
                            widget.code ? [InviteCodeFormatter()] : null,
                        decoration: InputDecoration(
                            labelText: widget.label,
                            hintText:
                                widget.code ? 'ABCD-2345-EFGH-6789' : null),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '${widget.label} giriniz.';
                          }
                          if (widget.code &&
                              !RegExp(r'^[A-HJ-NP-Z2-9]{16}$').hasMatch(
                                  value.replaceAll('-', '').toUpperCase())) {
                            return '16 karakterlik geçerli davet kodunu girin.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submit()),
                    const SizedBox(height: 12),
                    PrimaryAction(label: widget.action, onPressed: submit),
                  ]))));
}
