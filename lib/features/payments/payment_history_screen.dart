import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/logic/selectors.dart';
import '../billing/invoice_pdf.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final items = snapshot.transactionsNewestFirst;
        return FeatureScaffold(
          title: 'Historial de pagos',
          body: items.isEmpty
              ? const EmptyState(
                  title: 'Sin pagos todavía',
                  message: 'Cuando simules un pago individual o de varios contratos, la operación aparecerá aquí.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final names = item.lines.map((line) => line.alias.isEmpty ? line.contractNumber : line.alias).join(', ');
                    return AppCard(
                      onTap: () => context.push(Routes.transaction(item.id)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.number, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep))),
                              StatusPill(label: paymentStatusLabel(item.status), color: paymentStatusColor(item.status)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(item.lines.length > 1 ? 'Pago múltiple · ${item.lines.length} contratos' : 'Pago individual'),
                          Text(names),
                          Text(formatDateTime(item.paidAt), style: const TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 6),
                          Text(formatMoney(item.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (item.cardLast4 != null)
                            Text('${cardBrandLabel(item.cardBrand!)} •••• ${item.cardLast4}', style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final transaction = snapshot.transactionById(id);
        if (transaction == null) {
          return const FeatureScaffold(
            title: 'Comprobante',
            body: EmptyState(title: 'Operación no encontrada', message: 'Este pago no está en el historial de demostración.'),
          );
        }
        final method = transaction.cardLast4 == null
            ? paymentMethodLabel(transaction.method)
            : '${cardBrandLabel(transaction.cardBrand!)} •••• ${transaction.cardLast4}';
        return FeatureScaffold(
          title: transaction.number,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  children: [
                    InfoLine(label: 'Transacción', value: transaction.number),
                    InfoLine(label: 'Fecha', value: formatDateTime(transaction.paidAt)),
                    InfoLine(label: 'Método', value: method),
                    if (transaction.cardHolder != null) InfoLine(label: 'Titular de la tarjeta', value: transaction.cardHolder!),
                    InfoLine(label: 'Contratos', value: '${transaction.lines.length}'),
                    InfoLine(label: 'Estado', value: paymentStatusLabel(transaction.status)),
                    InfoLine(label: 'Total', value: formatMoney(transaction.total)),
                  ],
                ),
              ),
              if (transaction.message != null) ...[
                const SizedBox(height: 10),
                Text(transaction.message!, style: const TextStyle(color: AppColors.red)),
              ],
              const SizedBox(height: 16),
              const SectionHeader(title: 'Detalle por contrato'),
              const SizedBox(height: 8),
              for (final line in transaction.lines) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.alias.isEmpty ? line.contractNumber : line.alias, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                      Text('${line.contractNumber} · ${line.holderName}'),
                      Text(line.address, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 6),
                      InfoLine(label: 'Factura', value: line.invoiceNumber),
                      InfoLine(label: 'Importe', value: formatMoney(line.amount)),
                      if (line.receiptId != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push(Routes.receipt(line.receiptId!)),
                            child: const Text('Comprobante individual'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const Text('Comprobante ficticio de una sola operación. No representa un cargo real.', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final bytes = Uint8List.fromList(await InvoicePdf.transaction(transaction));
                  await Printing.sharePdf(bytes: bytes, filename: '${transaction.number}.pdf');
                },
                child: const Text('Compartir comprobante consolidado'),
              ),
            ],
          ),
        );
      },
    );
  }
}
