import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/demo_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.card;
  bool _forceFailure = false;
  bool _processing = false;
  String? _error;
  String? _receiptId;
  final _form = GlobalKey<FormState>();
  final _card = TextEditingController(text: '4111 1111 1111 1111');
  final _name = TextEditingController(text: 'ANDRES FRIAS');
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');

  @override
  void dispose() {
    _card.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _pay(Invoice invoice) async {
    if (_method == PaymentMethod.card && !_form.currentState!.validate()) return;
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Confirmar pago simulado',
      message: 'Se aplicará ${formatMoney(invoice.total)} con ${paymentMethodLabel(_method)}. No saldrá dinero de ninguna cuenta.',
      confirmLabel: 'Pagar ${formatMoney(invoice.total)}',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final receipt = await ref.read(appControllerProvider.notifier).payInvoice(
            invoiceId: invoice.id,
            method: _method,
            cardNumber: _card.text,
            forceFailure: _forceFailure,
          );
      if (mounted) {
        setState(() {
          _processing = false;
          _receiptId = receipt.id;
        });
      }
    } on DemoException catch (error) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 18),
                Text('Procesando pago simulado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                SizedBox(height: 8),
                Text('Validando el método, contactando el banco de demostración y aplicando el pago.', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
    if (_receiptId != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 84),
                const SizedBox(height: 12),
                const Text('Pago exitoso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                const SizedBox(height: 8),
                const Text('Generamos un comprobante ficticio. No hubo una transacción real.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.push(Routes.receipt(_receiptId!)), child: const Text('Ver comprobante')),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => context.go(Routes.home), child: const Text('Ir al inicio')),
              ],
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado del pago')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cancel_rounded, color: AppColors.red, size: 84),
                const SizedBox(height: 12),
                const Text('Pago rechazado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => setState(() => _error = null), child: const Text('Intentar de nuevo')),
              ],
            ),
          ),
        ),
      );
    }

    return SnapshotBody(
      builder: (context, snapshot) {
        final invoice = snapshot.invoiceById(widget.invoiceId);
        if (invoice == null || invoice.status == InvoiceStatus.paid) {
          return FeatureScaffold(
            title: 'Pagar',
            body: EmptyState(
              title: invoice == null ? 'Factura no disponible' : 'Esta factura ya está pagada',
              message: 'Elige otra factura del historial.',
            ),
          );
        }
        return FeatureScaffold(
          title: 'Pagar factura',
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.number, style: const TextStyle(color: AppColors.muted)),
                      Text(formatMoney(invoice.total), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                      Text('Vence ${formatDate(invoice.dueDate)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                RadioGroup<PaymentMethod>(
                  groupValue: _method,
                  onChanged: (value) => setState(() => _method = value ?? _method),
                  child: Column(
                    children: [
                      for (final method in PaymentMethod.values)
                        RadioListTile<PaymentMethod>(
                          value: method,
                          title: Text(paymentMethodLabel(method)),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                if (_method == PaymentMethod.card) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _card,
                    decoration: const InputDecoration(labelText: 'Número de tarjeta'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s]'))],
                    validator: Validators.cardNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre en la tarjeta'), validator: (v) => Validators.required(v, label: 'El nombre')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _expiry, decoration: const InputDecoration(labelText: 'Vence', hintText: 'MM/AA'), validator: Validators.expiry)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _cvv, decoration: const InputDecoration(labelText: 'CVV'), obscureText: true, validator: Validators.cvv)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Éxito: 4111 1111 1111 1111. Rechazo: termina en 0002.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
                if (_method == PaymentMethod.transfer)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Se generará una referencia de transferencia simulada. No se conecta a un banco.'),
                  ),
                if (_method == PaymentMethod.paymentPoint)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Se generará un código para un punto de pago ficticio. El botón de confirmar simula que ya fue recibido.'),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _forceFailure,
                  onChanged: (value) => setState(() => _forceFailure = value),
                  title: const Text('Forzar rechazo (demostración)'),
                ),
                const SizedBox(height: 8),
                FilledButton(onPressed: () => _pay(invoice), child: const Text('Continuar')),
              ],
            ),
          ),
        );
      },
    );
  }
}
