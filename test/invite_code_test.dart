import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatim_halkasi/invite_code.dart';

void main() {
  test('A pasted invitation becomes four readable groups with a stable caret',
      () {
    final formatter = InviteCodeFormatter();
    const pasted = TextEditingValue(
        text: 'abcd2345efgh6789',
        selection: TextSelection.collapsed(offset: 16));
    final formatted =
        formatter.formatEditUpdate(TextEditingValue.empty, pasted);
    expect(formatted.text, 'ABCD-2345-EFGH-6789');
    expect(formatted.selection.baseOffset, 19);
    expect(formatInviteCode(formatted.text), formatted.text);
  });
  test(
      'Editing an invitation in the middle keeps the selection beside that character',
      () {
    const edited = TextEditingValue(
        text: 'ABCD-2345-ZFGH-6789',
        selection: TextSelection.collapsed(offset: 11));
    final formatted =
        InviteCodeFormatter().formatEditUpdate(TextEditingValue.empty, edited);
    expect(formatted.text, edited.text);
    expect(formatted.selection.baseOffset, 11);
  });
}
