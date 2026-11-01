import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/demo_exception.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import 'payment_form.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _processing = false;
  PaymentTransaction? _result;

  Future<void> _pay(Invoice invoice, PaymentSubmission submission) async {
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Confirmar pago simulado',
      message: 'Se aplicará ${formatMoney(invoice.total)} con ${submission.summary}. No saldrá dinero de ninguna cuenta.',
      confirmLabel: 'Pagar ${formatMoney(invoice.total)}',
    );
    if (!confirmed || !mounted) return;
    setState(() => _processing = true);
    try {
      final transaction = await ref.read(appControllerProvider.notifier).payInvoices(
            invoiceIds: [invoice.id],
            method: submission.method,
            cardNumber: submission.cardNumber,
            expiry: submission.expiry,
            holderName: submission.holderName,
            savedCardId: submission.savedCardId,
            cardFunding: submission.funding,
            forceFailure: submission.forceFailure,
          );
      if (mounted) setState(() => _result = transaction);
    } on DemoException catch (error) {
      if (mounted) {
        showAppMessage(context, error.message, error: true);
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) return const _ProcessingView(multiple: false);
    final result = _result;
    if (result != null) {
      return _PaymentResult(
        transaction: result,
        onRetry: result.approved ? null : () => setState(() => _result = null),
      );
    }
    return SnapshotBody(
      builder: (context, snapshot) {
        final invoice = snapshot.invoiceById(widget.invoiceId);
        ContractAccount? contract;
        if (invoice != null) {
          for (final item in snapshot.contracts) {
            if (item.id == invoice.contractId) contract = item;
          }
        }
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
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract?.displayName ?? 'Contrato', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    if (contract != null) Text('${contract.number} · ${contract.holderName}'),
                    const SizedBox(height: 8),
                    InfoLine(label: 'Factura', value: invoice.number),
                    InfoLine(label: 'Importe', value: formatMoney(invoice.total)),
                    InfoLine(label: 'Vence', value: formatDate(invoice.dueDate)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SimulatedPaymentForm(
                cards: snapshot.cards,
                onSubmit: (submission) => _pay(invoice, submission),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.multiple});
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                multiple ? 'Procesando un solo pago para varios contratos' : 'Procesando pago simulado',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Validando la tarjeta y aplicando la operación en este dispositivo. No hay conexión con un banco.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentResult extends StatelessWidget {
  const _PaymentResult({required this.transaction, this.onRetry});
  final PaymentTransaction transaction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final approved = transaction.approved;
    final icon = approved ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final color = approved ? AppColors.green : AppColors.red;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 84),
              const SizedBox(height: 12),
              Text(paymentStatusLabel(transaction.status), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
              const SizedBox(height: 8),
              Text(
                transaction.message ?? 'Generamos un comprobante ficticio. No hubo una transacción real.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(transaction.number, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => context.push(Routes.transaction(transaction.id)), child: const Text('Ver comprobante')),
              const SizedBox(height: 8),
              if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Intentar de nuevo')),
              OutlinedButton(onPressed: () => context.go(Routes.home), child: const Text('Ir al inicio')),
            ],
          ),
        ),
      ),
    );
  }
}
