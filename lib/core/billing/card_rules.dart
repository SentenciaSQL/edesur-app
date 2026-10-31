import '../mock/demo_clock.dart';
import '../../domain/entities/entities.dart';

class CardDraft {
  const CardDraft({
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.funding,
  });

  final CardBrand brand;
  final String last4;
  final String holderName;
  final int expiryMonth;
  final int expiryYear;
  final CardFunding funding;

  bool isExpiredAt(DateTime moment) {
    return expiryYear < moment.year || (expiryYear == moment.year && expiryMonth < moment.month);
  }
}

class CardRules {
  static const holderMin = 5;
  static const holderMax = 26;

  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static int maxDigits(String raw) => brandFromPrefix(raw) == CardBrand.amex ? 15 : 16;

  static const cvvMin = 3;
  static const cvvMax = 4;

  /// Marca reconocible por el prefijo, aunque el número todavía esté incompleto.
  static CardBrand? brandFromPrefix(String raw) {
    final pan = digits(raw);
    if (pan.isEmpty) return null;
    if (pan.startsWith('34') || pan.startsWith('37')) return CardBrand.amex;
    if (pan.startsWith('4')) return CardBrand.visa;
    if (pan.length >= 2) {
      final prefix2 = int.tryParse(pan.substring(0, 2));
      if (prefix2 != null && prefix2 >= 51 && prefix2 <= 55) return CardBrand.mastercard;
    }
    if (pan.length >= 4) {
      final prefix4 = int.tryParse(pan.substring(0, 4));
      if (prefix4 != null && prefix4 >= 2221 && prefix4 <= 2720) return CardBrand.mastercard;
    }
    return null;
  }

  static bool prefixCanBeBrand(String raw) {
    final pan = digits(raw);
    if (pan.isEmpty || brandFromPrefix(pan) != null) return true;
    if (pan.startsWith('3')) return pan == '3';
    if (pan.startsWith('5')) return pan == '5';
    if (!pan.startsWith('2')) return false;
    if (pan.length >= 4) {
      final prefix4 = int.tryParse(pan.substring(0, 4));
      return prefix4 != null && prefix4 >= 2221 && prefix4 <= 2720;
    }
    final low = int.parse(pan.padRight(4, '0'));
    final high = int.parse(pan.padRight(4, '9'));
    return high >= 2221 && low <= 2720;
  }

  static bool luhn(String raw) {
    final pan = digits(raw);
    if (pan.length < 2) return false;
    var sum = 0;
    var alternate = false;
    for (var i = pan.length - 1; i >= 0; i--) {
      var n = pan.codeUnitAt(i) - 48;
      if (n < 0 || n > 9) return false;
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  static String formatPan(String raw) {
    final pan = digits(raw);
    final max = maxDigits(pan);
    final clipped = pan.length > max ? pan.substring(0, max) : pan;
    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clipped[i]);
    }
    return buffer.toString();
  }

  static String formatExpiry(String raw) {
    var pan = digits(raw);
    if (pan.length > 4) pan = pan.substring(0, 4);
    if (pan.length <= 2) return pan;
    return '${pan.substring(0, 2)}/${pan.substring(2)}';
  }

  static String normalizeHolder(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Marca completa: longitud de la marca y algoritmo de Luhn.
  static CardBrand? detectBrand(String raw) {
    final pan = digits(raw);
    final brand = brandFromPrefix(pan);
    if (brand == null || pan.length != maxDigits(pan) || !luhn(pan)) return null;
    return brand;
  }

  static String? numberError(String? value) {
    final pan = digits(value ?? '');
    if (pan.isEmpty) return 'Ingresa el número de la tarjeta.';
    if (!prefixCanBeBrand(pan)) {
      return 'No reconocemos la marca. Usa Visa, Mastercard o American Express.';
    }
    final brand = brandFromPrefix(pan);
    final expected = maxDigits(pan);
    if (pan.length > expected) return 'Superaste la cantidad máxima de dígitos.';
    if (pan.length < expected) {
      if (brand == CardBrand.amex) return 'Faltan dígitos: American Express usa 15.';
      if (brand == CardBrand.visa || brand == CardBrand.mastercard) {
        return 'Faltan dígitos: Visa y Mastercard usan 16.';
      }
      return 'Completa el número de la tarjeta.';
    }
    if (brand == null) return 'No reconocemos la marca. Usa Visa, Mastercard o American Express.';
    if (!luhn(pan)) return 'El número de tarjeta no es válido.';
    return null;
  }

  static String? holderError(String? value) {
    final text = normalizeHolder(value ?? '');
    if (text.isEmpty) return 'El nombre del titular es obligatorio.';
    if (RegExp(r'[^\p{L} ]', unicode: true).hasMatch(text)) return 'Usa solo letras y espacios.';
    if (text.length > holderMax) return 'El nombre no puede superar $holderMax caracteres.';
    final words = text.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length < 2 || text.length < holderMin) return 'Ingresa el nombre y el apellido.';
    return null;
  }

  static String? expiryError(String? value, {bool rejectExpired = false}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Ingresa el vencimiento (MM/AA).';
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(text);
    if (match == null) return 'Usa el formato MM/AA.';
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return 'El mes debe estar entre 01 y 12.';
    if (!rejectExpired) return null;
    final year = 2000 + int.parse(match.group(2)!);
    final now = DemoClock.now;
    final expired = year < now.year || (year == now.year && month < now.month);
    if (expired) return 'La tarjeta está vencida.';
    return null;
  }

  static String? cvvError(String? value) {
    final code = digits(value ?? '');
    if (code.length < cvvMin || code.length > cvvMax) return 'El CVV debe tener 3 o 4 dígitos.';
    return null;
  }

  static CardDraft? draft({
    required String number,
    required String holderName,
    required String expiry,
    required CardFunding funding,
  }) {
    final pan = digits(number);
    final brand = detectBrand(pan);
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry.trim());
    if (brand == null || match == null) return null;
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return null;
    final holder = normalizeHolder(holderName);
    if (holder.isEmpty) return null;
    return CardDraft(
      brand: brand,
      last4: pan.substring(pan.length - 4),
      holderName: holder.toUpperCase(),
      expiryMonth: month,
      expiryYear: 2000 + int.parse(match.group(2)!),
      funding: funding,
    );
  }

  static PaymentStatus outcome({
    required PaymentMethod method,
    required bool forceFailure,
    String? last4,
    int? expiryMonth,
    int? expiryYear,
  }) {
    if (method != PaymentMethod.card) {
      return forceFailure ? PaymentStatus.rejected : PaymentStatus.approved;
    }
    if (forceFailure || last4 == '0002') return PaymentStatus.rejected;
    if (last4 == '0005') return PaymentStatus.processingError;
    if (expiryMonth != null && expiryYear != null) {
      final expired = expiryYear < DemoClock.now.year ||
          (expiryYear == DemoClock.now.year && expiryMonth < DemoClock.now.month);
      if (expired) return PaymentStatus.expiredCard;
    }
    return PaymentStatus.approved;
  }

  static String failureMessage(PaymentStatus status) => switch (status) {
        PaymentStatus.approved => '',
        PaymentStatus.rejected => 'El banco simulado rechazó la transacción. No se realizó ningún cargo.',
        PaymentStatus.expiredCard => 'La tarjeta está vencida. El pago simulado no se aplicó.',
        PaymentStatus.processingError => 'El procesador de demostración no pudo completar la operación. No se realizó ningún cargo.',
      };
}
