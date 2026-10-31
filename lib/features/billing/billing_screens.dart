import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import 'invoice_pdf.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _year = 'Todos';
  String _status = 'Todas';

  @override
  Widget build(BuildContext context) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final all = snapshot.activeInvoices;
        final years = <String>{'Todos', for (final invoice in all) '${invoice.periodStart.year}'}.toList();
        final filtered = all.where((invoice) {
          final yearOk = _year == 'Todos' || '${invoice.periodStart.year}' == _year;
          final statusOk = _status == 'Todas' || invoiceStatusLabel(invoice.status) == _status;
          return yearOk && statusOk;
        }).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _Filter(label: _year, values: years, onChanged: (value) => setState(() => _year = value))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Filter(
                      label: _status,
                      values: const ['Todas', 'Pagada', 'Pendiente', 'Vencida'],
                      onChanged: (value) => setState(() => _status = value),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(title: 'Sin facturas', message: 'No hay facturas con ese filtro.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final invoice = filtered[index];
                        return AppCard(
                          onTap: () => context.push(Routes.invoice(invoice.id)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(invoice.number, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep))),
                                  StatusPill(label: invoiceStatusLabel(invoice.status), color: invoiceStatusColor(invoice.status)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(formatMonthYear(invoice.periodStart)),
                              Text('Emisión ${formatDate(invoice.issueDate)} · Vence ${formatDate(invoice.dueDate)}', style: const TextStyle(color: AppColors.muted)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(formatKwh(invoice.kwh), style: const TextStyle(color: AppColors.navy)),
                                  const Spacer(),
                                  Text(formatMoney(invoice.total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, required this.values, required this.onChanged});
  final String label;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: label,
      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      items: [for (final value in values) DropdownMenuItem(value: value, child: Text(value))],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final invoice = snapshot.invoiceById(id);
        if (invoice == null) {
          return const FeatureScaffold(title: 'Factura', body: EmptyState(title: 'Factura no encontrada', message: 'Vuelve al listado.'));
        }
        final contract = snapshot.contracts.firstWhere((item) => item.id == invoice.contractId);
        return FeatureScaffold(
          title: invoice.number,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(formatMoney(invoice.total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.navyDeep))),
                        StatusPill(label: invoiceStatusLabel(invoice.status), color: invoiceStatusColor(invoice.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InfoLine(label: 'Cliente', value: snapshot.user.name),
                    InfoLine(label: 'Cédula', value: snapshot.user.cedula),
                    InfoLine(label: 'Contrato', value: contract.number),
                    InfoLine(label: 'Dirección', value: contract.address),
                    InfoLine(label: 'Período', value: '${formatDate(invoice.periodStart)} – ${formatDate(invoice.periodEnd)}'),
                    InfoLine(label: 'Emisión', value: formatDate(invoice.issueDate)),
                    InfoLine(label: 'Vencimiento', value: formatDate(invoice.dueDate)),
                    InfoLine(label: 'Lectura anterior', value: invoice.previousReading.toStringAsFixed(0)),
                    InfoLine(label: 'Lectura actual', value: invoice.currentReading.toStringAsFixed(0)),
                    InfoLine(label: 'Consumo', value: formatKwh(invoice.kwh)),
                    InfoLine(label: 'Tarifa', value: invoice.tariffName),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conceptos facturados', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    const SizedBox(height: 8),
                    for (final line in invoice.lines) InfoLine(label: line.label, value: formatMoney(line.amount)),
                    const Divider(),
                    InfoLine(label: 'Subtotal', value: formatMoney(invoice.subtotal)),
                    InfoLine(label: 'ITBIS 18% (simulado)', value: formatMoney(invoice.tax)),
                    InfoLine(label: 'Total a pagar', value: formatMoney(invoice.total)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tarifa y impuestos de demostración. No reproducen el pliego tarifario vigente.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          bottom: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (invoice.status != InvoiceStatus.paid)
                    FilledButton(onPressed: () => context.push(Routes.pay(invoice.id)), child: const Text('Pagar factura')),
                  if (invoice.receiptId != null)
                    FilledButton(onPressed: () => context.push(Routes.receipt(invoice.receiptId!)), child: const Text('Ver comprobante')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _share(context, invoice, contract, snapshot.user),
                          child: const Text('Descargar PDF'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _share(context, invoice, contract, snapshot.user, preview: false),
                          child: const Text('Compartir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _share(BuildContext context, Invoice invoice, ContractAccount contract, UserProfile user, {bool preview = true}) async {
    final bytes = Uint8List.fromList(await InvoicePdf.build(invoice: invoice, contract: contract, user: user));
    if (preview) {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: '${invoice.number}.pdf');
    } else {
      await Printing.sharePdf(bytes: bytes, filename: '${invoice.number}.pdf');
    }
  }
}

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final receipt = snapshot.receiptById(id);
        if (receipt == null) {
          return const FeatureScaffold(title: 'Comprobante', body: EmptyState(title: 'Sin comprobante', message: 'Este pago no está en la demostración.'));
        }
        return FeatureScaffold(
          title: receipt.number,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.green, size: 64),
              const SizedBox(height: 8),
              const Center(child: Text('Pago simulado aplicado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18))),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    InfoLine(label: 'Comprobante', value: receipt.number),
                    InfoLine(label: 'Factura', value: receipt.invoiceNumber),
                    InfoLine(label: 'Contrato', value: receipt.contractNumber),
                    InfoLine(label: 'Método', value: paymentMethodLabel(receipt.method)),
                    InfoLine(label: 'Referencia', value: receipt.reference),
                    InfoLine(label: 'Autorización', value: receipt.authorization),
                    InfoLine(label: 'Fecha', value: formatDateTime(receipt.paidAt)),
                    InfoLine(label: 'Monto', value: formatMoney(receipt.amount)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Comprobante ficticio. No se realizó una transacción real.', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final bytes = Uint8List.fromList(await InvoicePdf.receipt(receipt));
                  await Printing.sharePdf(bytes: bytes, filename: '${receipt.number}.pdf');
                },
                child: const Text('Compartir PDF'),
              ),
            ],
          ),
        );
      },
    );
  }
}
