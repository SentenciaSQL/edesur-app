import '../../core/billing/card_rules.dart';
import '../../core/constants/app_constants.dart';
import '../../core/mock/mock_seed.dart';
import '../../core/utils/demo_exception.dart';
import '../entities/entities.dart';
import '../logic/selectors.dart';
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

class ContractLookup {
  const ContractLookup({required this.result, this.supply});
  final LinkLookupResult result;
  final SupplyBundle? supply;
}

class LinkContractUseCase {
  const LinkContractUseCase();

  ContractLookup lookup({
    required DemoSnapshot snapshot,
    required String number,
    required String cedula,
  }) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    final linked = snapshot.contracts.any((contract) => contract.number.replaceAll(RegExp(r'\D'), '') == digits);
    if (linked) return const ContractLookup(result: LinkLookupResult.alreadyLinked);
    final supply = MockSeed.lookupSupply(digits);
    if (supply == null) return const ContractLookup(result: LinkLookupResult.missing);
    if (!supply.contract.isOwnedBy(cedula)) return const ContractLookup(result: LinkLookupResult.holderMismatch);
    return ContractLookup(result: LinkLookupResult.found, supply: supply);
  }
}

class UnlinkContractUseCase {
  const UnlinkContractUseCase();

  void check(DemoSnapshot snapshot, String contractId) {
    ContractAccount? contract;
    for (final item in snapshot.contracts) {
      if (item.id == contractId) contract = item;
    }
    if (contract == null) throw DemoException('No encontramos ese contrato.');
    if (contract.isOwnedBy(snapshot.user.cedula)) {
      throw DemoException(AppConstants.cannotUnlinkOwnContract);
    }
  }
}

class PayInvoicesUseCase {
  PayInvoicesUseCase(this._billing);
  final BillingRepository _billing;

  Future<PaymentTransaction> execute({
    required DemoSnapshot snapshot,
    required List<String> invoiceIds,
    required PaymentMethod method,
    required bool forceFailure,
    String? cardNumber,
    String? expiry,
    String? holderName,
    SavedCard? savedCard,
  }) {
    final unique = invoiceIds.toSet().toList();
    if (unique.isEmpty) throw DemoException('Selecciona al menos un contrato con balance pendiente.');
    final invoices = <Invoice>[];
    for (final id in unique) {
      final invoice = snapshot.invoiceById(id);
      if (invoice == null) throw DemoException('No encontramos una de las facturas seleccionadas.');
      if (invoice.status == InvoiceStatus.paid || invoice.total <= 0) {
        throw DemoException('Una de las facturas ya no tiene balance pendiente.');
      }
      invoices.add(invoice);
    }
    final total = invoices.fold<double>(0, (sum, invoice) => sum + invoice.total);
    if (total <= 0) throw DemoException('El total a pagar debe ser mayor que cero.');

    String? last4 = savedCard?.last4;
    int? month = savedCard?.expiryMonth;
    int? year = savedCard?.expiryYear;
    var brand = savedCard?.brand;
    var holder = savedCard?.holderName;
    if (method == PaymentMethod.card && savedCard == null) {
      final draft = CardRules.draft(
        number: cardNumber ?? '',
        holderName: holderName ?? '',
        expiry: expiry ?? '',
        funding: CardFunding.credit,
      );
      if (draft == null) throw DemoException('Revisa el número, la marca y el vencimiento de la tarjeta de prueba.');
      last4 = draft.last4;
      month = draft.expiryMonth;
      year = draft.expiryYear;
      brand = draft.brand;
      holder = draft.holderName;
    }
    final status = CardRules.outcome(
      method: method,
      forceFailure: forceFailure,
      last4: last4,
      expiryMonth: month,
      expiryYear: year,
    );
    return _billing.settle(
      invoiceIds: unique,
      method: method,
      status: status,
      cardBrand: brand,
      cardLast4: last4,
      cardHolder: holder,
      message: status == PaymentStatus.approved ? null : CardRules.failureMessage(status),
    );
  }
}

class AddCardUseCase {
  const AddCardUseCase();

  CardDraft prepare({
    required String number,
    required String holderName,
    required String expiry,
    required String cvv,
    required CardFunding funding,
  }) {
    final numberError = CardRules.numberError(number);
    if (numberError != null) throw DemoException(numberError);
    final holderError = CardRules.holderError(holderName);
    if (holderError != null) throw DemoException(holderError);
    final expiryError = CardRules.expiryError(expiry, rejectExpired: true);
    if (expiryError != null) throw DemoException(expiryError);
    final cvvError = CardRules.cvvError(cvv);
    if (cvvError != null) throw DemoException(cvvError);
    final draft = CardRules.draft(number: number, holderName: holderName, expiry: expiry, funding: funding);
    if (draft == null) {
      throw DemoException('Usa un número de prueba Visa, Mastercard o American Express.');
    }
    return draft;
  }
}
