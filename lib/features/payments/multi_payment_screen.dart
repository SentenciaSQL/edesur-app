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

class MultiPaymentScreen extends ConsumerStatefulWidget {
  const MultiPaymentScreen({super.key});

  @override
  ConsumerState<MultiPaymentScreen> createState() => _MultiPaymentScreenState();
}

class _MultiPaymentScreenState extends ConsumerState<MultiPaymentScreen> {
  final _selected = <String>{};
  int _step = 0;
  bool _processing = false;
  PaymentTransaction? _result;

  List<_Payable> _rows(DemoSnapshot snapshot) {
    return [
      for (final contract in snapshot.contracts)
        _Payable(contract, snapshot.payableInvoiceOf(contract.id), snapshot.balanceOf(contract.id)),
    ];
  }

  void _selectOpen(DemoSnapshot snapshot) {
    setState(() {
      _selected
        ..clear()
        ..addAll(_rows(snapshot).where((row) => row.invoice != null).map((row) => row.invoice!.id));
    });
  }

  Future<void> _pay(PaymentSubmission submission) async {
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Confirmar pago simulado',
      message: 'Una sola operación cubrirá ${_selected.length} factura${_selected.length == 1 ? '' : 's'}. No saldrá dinero de ninguna cuenta.',
      confirmLabel: 'Pagar ahora',
    );
    if (!confirmed || !mounted) return;
    setState(() => _processing = true);
    try {
      final transaction = await ref.read(appControllerProvider.notifier).payInvoices(
            invoiceIds: _selected.toList(),
            method: submission.method,
            cardNumber: submission.cardNumber,
            expiry: submission.expiry,
            holderName: submission.holderName,
            savedCardId: submission.savedCardId,
            forceFailure: submission.forceFailure,
          );
      if (mounted) {
        setState(() {
          _result = transaction;
          _processing = false;
        });
      }
    } on DemoException catch (error) {
      if (mounted) {
        setState(() => _processing = false);
        showAppMessage(context, error.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_processing) {
      return const Scaffold(
        body: Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 18),
          Text('Procesando un solo pago para varios contratos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ]))),
      );
    }
    final result = _result;
    if (result != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(result.approved ? Icons.check_circle_rounded : Icons.cancel_rounded, color: result.approved ? AppColors.green : AppColors.red, size: 84),
                const SizedBox(height: 12),
                Text(paymentStatusLabel(result.status), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(result.message ?? 'El pago simulado agrupó las facturas en una sola operación.', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('${result.number} · ${formatMoney(result.total)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.push(Routes.transaction(result.id)), child: const Text('Ver comprobante consolidado')),
                const SizedBox(height: 8),
                if (!result.approved)
                  TextButton(onPressed: () => setState(() => _result = null), child: const Text('Intentar de nuevo')),
                OutlinedButton(onPressed: () => context.go(Routes.home), child: const Text('Ir al inicio')),
              ],
            ),
          ),
        ),
      );
    }
    return SnapshotBody(
      builder: (context, snapshot) {
        final rows = _rows(snapshot);
        final chosen = rows.where((row) => row.invoice != null && _selected.contains(row.invoice!.id)).toList();
        final total = chosen.fold<double>(0, (sum, row) => sum + row.balance);
        return FeatureScaffold(
          title: _step == 0 ? 'Pagar contratos' : _step == 1 ? 'Resumen' : 'Método de pago',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_step == 0) ...[
                const Text('Elige uno o varios contratos con balance. Los que están al día no entran en el total.'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _selectOpen(snapshot), child: const Text('Con balance'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => setState(_selected.clear), child: const Text('Quitar todos'))),
                  ],
                ),
                const SizedBox(height: 12),
                for (final row in rows) ...[
                  _ContractPayTile(
                    row: row,
                    selected: row.invoice != null && _selected.contains(row.invoice!.id),
                    onChanged: row.invoice == null
                        ? null
                        : (value) => setState(() {
                              if (value) {
                                _selected.add(row.invoice!.id);
                              } else {
                                _selected.remove(row.invoice!.id);
                              }
                            }),
                    onDetail: row.invoice == null ? null : () => context.push(Routes.invoice(row.invoice!.id)),
                  ),
                  const SizedBox(height: 10),
                ],
                AppCard(
                  child: Row(
                    children: [
                      Expanded(child: Text('${chosen.length} contrato${chosen.length == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(formatMoney(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: chosen.isEmpty || total <= 0 ? null : () => setState(() => _step = 1),
                  child: const Text('Ver resumen'),
                ),
              ],
              if (_step == 1) ...[
                Text('${chosen.length} contratos seleccionados', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.navyDeep)),
                const SizedBox(height: 12),
                for (final row in chosen) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(row.contract.displayName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep))),
                            IconButton(
                              tooltip: 'Quitar',
                              onPressed: () => setState(() {
                                _selected.remove(row.invoice!.id);
                                if (_selected.isEmpty) _step = 0;
                              }),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        Text('${row.contract.number} · ${row.contract.holderName}'),
                        Text(row.contract.address, style: const TextStyle(color: AppColors.muted)),
                        const SizedBox(height: 6),
                        InfoLine(label: 'Factura', value: row.invoice!.number),
                        InfoLine(label: 'Estado', value: invoiceStatusLabel(row.invoice!.status)),
                        InfoLine(label: 'Subtotal', value: formatMoney(row.balance)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                AppCard(
                  color: AppColors.navyDeep,
                  child: Row(
                    children: [
                      const Expanded(child: Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                      Text(formatMoney(total), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: chosen.isEmpty || total <= 0 ? null : () => setState(() => _step = 2),
                  child: const Text('Elegir método de pago'),
                ),
                TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Volver a la selección')),
              ],
              if (_step == 2) ...[
                Text('Total ${formatMoney(total)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                const SizedBox(height: 6),
                Text('Una tarjeta, transferencia o punto de pago cubre las ${chosen.length} facturas.'),
                const SizedBox(height: 16),
                SimulatedPaymentForm(cards: snapshot.cards, onSubmit: _pay),
                TextButton(onPressed: () => setState(() => _step = 1), child: const Text('Volver al resumen')),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Payable {
  const _Payable(this.contract, this.invoice, this.balance);
  final ContractAccount contract;
  final Invoice? invoice;
  final double balance;
}

class _ContractPayTile extends StatelessWidget {
  const _ContractPayTile({required this.row, required this.selected, required this.onChanged, required this.onDetail});
  final _Payable row;
  final bool selected;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    final open = row.invoice != null && row.balance > 0;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: open && selected, onChanged: open ? (value) => onChanged?.call(value ?? false) : null),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.contract.displayName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                Text('${row.contract.number} · ${row.contract.holderName}'),
                Text(row.contract.address, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 4),
                Text(open ? formatMoney(row.balance) : 'Sin deuda', style: TextStyle(fontWeight: FontWeight.w700, color: open ? AppColors.navy : AppColors.green)),
                if (row.invoice != null) Text(invoiceStatusLabel(row.invoice!.status), style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          if (onDetail != null) IconButton(tooltip: 'Ver factura', onPressed: onDetail, icon: const Icon(Icons.receipt_long_outlined)),
        ],
      ),
    );
  }
}
