import '../../core/constants/app_constants.dart';
import '../../core/utils/demo_exception.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

class SignInUseCase {
  const SignInUseCase();

  void check(DemoSnapshot snapshot, String email, String password) {
    final matchesEmail = email.trim().toLowerCase() == snapshot.user.email.toLowerCase();
    final matchesPassword = password == snapshot.password;
    if (!matchesEmail || !matchesPassword) {
      throw DemoException(
        'Correo o contraseña incorrectos. La cuenta de demostración es ${snapshot.user.email}.',
      );
    }
  }
}

class VerifyIdentityUseCase {
  const VerifyIdentityUseCase();

  void check({
    required DemoSnapshot snapshot,
    required String cedula,
    required String contractNumber,
    required String otp,
  }) {
    if (otp.trim() != AppConstants.demoOtp) {
      throw DemoException('El código no es válido. En la demostración usa ${AppConstants.demoOtp}.');
    }
    final cedulaOk = cedula.trim() == snapshot.user.cedula;
    final contractOk = snapshot.contracts.any((contract) => contract.number == contractNumber.trim());
    if (!cedulaOk || !contractOk) {
      throw DemoException(
        'No pudimos validar la identidad. Usa la cédula ${snapshot.user.cedula} y uno de los contratos de demostración.',
      );
    }
  }
}

class PayInvoiceUseCase {
  PayInvoiceUseCase(this._billing);
  final BillingRepository _billing;

  Future<PaymentReceipt> execute({
    required DemoSnapshot snapshot,
    required String invoiceId,
    required PaymentMethod method,
    String? cardNumber,
    bool forceFailure = false,
  }) {
    final invoice = snapshot.invoiceById(invoiceId);
    if (invoice == null) throw DemoException('No encontramos la factura.');
    if (invoice.status == InvoiceStatus.paid) {
      throw DemoException('Esta factura ya está pagada.');
    }
    final digits = (cardNumber ?? '').replaceAll(RegExp(r'\D'), '');
    final rejected = forceFailure || (method == PaymentMethod.card && digits.endsWith('0002'));
    if (rejected) {
      throw DemoException('El banco simulado rechazó la transacción. No se realizó ningún cargo.');
    }
    final last4 = digits.length >= 4 ? digits.substring(digits.length - 4) : null;
    return _billing.registerPayment(invoiceId: invoiceId, method: method, cardLast4: last4);
  }
}

extension _Lookup on DemoSnapshot {
  Invoice? invoiceById(String id) {
    for (final invoice in invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }
}
