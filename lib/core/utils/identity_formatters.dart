import 'package:flutter/services.dart';

import 'cedula_rules.dart';

class ContractNumberFormatter extends TextInputFormatter {
  const ContractNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 7) digits = digits.substring(0, 7);
    final cursor = _digitsBefore(newValue.text, newValue.selection.end).clamp(0, digits.length);
    return TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: cursor));
  }
}

class CedulaFormatter extends TextInputFormatter {
  const CedulaFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = CedulaRules.format(newValue.text);
    final count = _digitsBefore(newValue.text, newValue.selection.end).clamp(0, CedulaRules.digits(formatted).length);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: _offsetAtDigit(formatted, count)));
  }
}

int _digitsBefore(String text, int offset) {
  final end = offset.clamp(0, text.length);
  return text.substring(0, end).replaceAll(RegExp(r'\D'), '').length;
}

int _offsetAtDigit(String formatted, int count) {
  if (count <= 0) return 0;
  var seen = 0;
  for (var i = 0; i < formatted.length; i++) {
    final unit = formatted.codeUnitAt(i);
    if (unit >= 48 && unit <= 57) {
      seen++;
      if (seen >= count) return i + 1;
    }
  }
  return formatted.length;
}
