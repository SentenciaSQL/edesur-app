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
  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static CardBrand? detectBrand(String raw) {
    final pan = digits(raw);
    if (pan.length < 2) return null;
    if (pan.startsWith('34') || pan.startsWith('37')) {
      return pan.length == 15 ? CardBrand.amex : null;
    }
    if (pan.length != 16) return null;
    if (pan.startsWith('4')) return CardBrand.visa;
    final prefix2 = int.tryParse(pan.substring(0, 2)) ?? 0;
    if (prefix2 >= 51 && prefix2 <= 55) return CardBrand.mastercard;
    final prefix4 = int.tryParse(pan.substring(0, 4)) ?? 0;
    if (prefix4 >= 2221 && prefix4 <= 2720) return CardBrand.mastercard;
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
    return CardDraft(
      brand: brand,
      last4: pan.substring(pan.length - 4),
      holderName: holderName.trim().toUpperCase(),
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
