import '../billing/card_rules.dart';
import 'cedula_rules.dart';

class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _cedula = RegExp(r'^\d{3}-\d{7}-\d$');

  static String? required(String? value, {String label = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio.';
    return null;
  }

  static String? email(String? value) {
    final empty = required(value, label: 'El correo');
    if (empty != null) return empty;
    if (!_email.hasMatch(value!.trim())) return 'Ingresa un correo válido.';
    return null;
  }

  static String? password(String? value) {
    final empty = required(value, label: 'La contraseña');
    if (empty != null) return empty;
    final text = value!.trim();
    if (text.length < 8) return 'Usa al menos 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(text) || !RegExp(r'\d').hasMatch(text)) {
      return 'Incluye al menos una letra y un número.';
    }
    return null;
  }

  static String? match(String? value, String other, {String label = 'La confirmación'}) {
    if (value != other) return '$label no coincide.';
    return null;
  }

  static String? cedula(String? value) {
    final empty = required(value, label: 'La cédula');
    if (empty != null) return empty;
    if (!_cedula.hasMatch(value!.trim())) {
      return 'Usa el formato 000-0000000-0.';
    }
    return null;
  }

  static String? contractNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 7) return 'El número de contrato debe contener exactamente 7 dígitos';
    return null;
  }

  static String? holderCedula(String? value) {
    final digits = CedulaRules.digits(value ?? '');
    if (digits.isEmpty) return 'Ingresa la cédula del titular.';
    if (digits.length != 11) return 'Completa la cédula con el formato 000-0000000-0.';
    if (!CedulaRules.hasValidCheckDigit(digits)) return 'El dígito verificador de la cédula no es válido.';
    return null;
  }

  static String? phone(String? value) {
    final empty = required(value, label: 'El teléfono');
    if (empty != null) return empty;
    final digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Ingresa un teléfono válido.';
    return null;
  }

  static String? minLength(String? value, int min, {String label = 'La descripción'}) {
    final empty = required(value, label: label);
    if (empty != null) return empty;
    if (value!.trim().length < min) return '$label debe tener al menos $min caracteres.';
    return null;
  }

  static String? cardNumber(String? value) => CardRules.numberError(value);

  static String? cardHolder(String? value) => CardRules.holderError(value);

  static String? expiryFormat(String? value) => CardRules.expiryError(value);

  static String? expiry(String? value) => CardRules.expiryError(value, rejectExpired: true);

  static String? cvv(String? value) => CardRules.cvvError(value);

  static String? otp(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return 'El código tiene 6 dígitos.';
    return null;
  }
}
