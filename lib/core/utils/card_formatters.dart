import 'package:flutter/services.dart';

import '../billing/card_rules.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return _digitsCursor(newValue, CardRules.formatPan(newValue.text));
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return _digitsCursor(newValue, CardRules.formatExpiry(newValue.text));
  }
}

class CvvFormatter extends TextInputFormatter {
  const CvvFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var code = CardRules.digits(newValue.text);
    if (code.length > CardRules.cvvMax) code = code.substring(0, CardRules.cvvMax);
    final cursor = _digitsBefore(newValue.text, newValue.selection.end).clamp(0, code.length);
    return TextEditingValue(text: code, selection: TextSelection.collapsed(offset: cursor));
  }
}

class CardHolderFormatter extends TextInputFormatter {
  static final _letter = RegExp(r'^\p{L}$', unicode: true);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final kept = StringBuffer();
    for (final rune in newValue.text.runes) {
      final char = String.fromCharCode(rune);
      if (char == ' ' || _letter.hasMatch(char)) kept.write(char);
    }
    var text = kept.toString().replaceAll(RegExp(r' {2,}'), ' ');
    if (text.startsWith(' ')) text = text.trimLeft();
    if (text.length > CardRules.holderMax) text = text.substring(0, CardRules.holderMax);
    final cursor = newValue.selection.end.clamp(0, text.length);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cursor));
  }
}

TextEditingValue _digitsCursor(TextEditingValue incoming, String formatted) {
  final count = _digitsBefore(incoming.text, incoming.selection.end).clamp(0, CardRules.digits(formatted).length);
  return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: _offsetAtDigit(formatted, count)));
}

int _digitsBefore(String text, int offset) {
  final end = offset.clamp(0, text.length);
  return CardRules.digits(text.substring(0, end)).length;
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
