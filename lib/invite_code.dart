import 'package:flutter/services.dart';

String formatInviteCode(String value) {
  final raw = value.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  return [
    for (var i = 0; i < raw.length; i += 4)
      raw.substring(i, i + 4 > raw.length ? raw.length : i + 4)
  ].join('-');
}

/// Groups a 16-character invitation without losing the caret during edits.
class InviteCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.composing.isCollapsed) return newValue;
    final raw = newValue.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final bounded = raw.substring(0, raw.length.clamp(0, 16));
    int caret(int offset) {
      final before =
          newValue.text.substring(0, offset.clamp(0, newValue.text.length));
      final count = before
          .replaceAll(RegExp('[^a-zA-Z0-9]'), '')
          .length
          .clamp(0, bounded.length);
      return count == 0 ? 0 : count + (count - 1) ~/ 4;
    }

    return TextEditingValue(
      text: formatInviteCode(bounded),
      selection: TextSelection(
          baseOffset: caret(newValue.selection.baseOffset),
          extentOffset: caret(newValue.selection.extentOffset)),
    );
  }
}
