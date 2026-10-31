import '../mock/demo_clock.dart';

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

  static String? cardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    final amex = digits.startsWith('34') || digits.startsWith('37');
    if (amex && digits.length != 15) return 'American Express usa 15 dígitos en esta demostración.';
    if (!amex && digits.length != 16) return 'La tarjeta debe tener 16 dígitos.';
    return null;
  }

  static String? expiryFormat(String? value) {
    final text = (value ?? '').trim();
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(text);
    if (match == null) return 'Usa el formato MM/AA.';
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return 'El mes no es válido.';
    return null;
  }

  static String? expiry(String? value) {
    final format = expiryFormat(value);
    if (format != null) return format;
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value!.trim())!;
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final now = DemoClock.now;
    final expired = year < now.year || (year == now.year && month < now.month);
    if (expired) return 'La tarjeta está vencida.';
    return null;
  }

  static String? cvv(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3 || digits.length > 4) return 'CVV inválido.';
    return null;
  }

  static String? otp(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) return 'El código tiene 6 dígitos.';
    return null;
  }
}
