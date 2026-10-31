class CedulaRules {
  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String format(String raw) {
    final source = digits(raw);
    final clipped = source.length > 11 ? source.substring(0, 11) : source;
    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 3 || i == 10) buffer.write('-');
      buffer.write(clipped[i]);
    }
    return buffer.toString();
  }

  /// Dígito verificador de la cédula dominicana (módulo 10, pesos 1 y 2).
  static bool hasValidCheckDigit(String raw) {
    final value = digits(raw);
    if (value.length != 11) return false;
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final digit = value.codeUnitAt(i) - 48;
      if (digit < 0 || digit > 9) return false;
      var product = digit * (i.isEven ? 1 : 2);
      if (product > 9) product -= 9;
      sum += product;
    }
    final expected = (10 - (sum % 10)) % 10;
    return expected == value.codeUnitAt(10) - 48;
  }
}
