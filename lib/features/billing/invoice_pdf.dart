import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../shared/labels.dart';

class InvoicePdf {
  static Future<List<int>> build({
    required Invoice invoice,
    required ContractAccount contract,
    required UserProfile user,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('EDESUR MÓVIL', style: pw.TextStyle(fontSize: 22, color: PdfColor.fromInt(0xFFFD6B0D), fontWeight: pw.FontWeight.bold)),
          pw.Text('Comprobante de demostración', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Text('Este documento es ficticio. No tiene validez fiscal ni comercial.', style: pw.TextStyle(color: PdfColors.red)),
          pw.SizedBox(height: 16),
          pw.Text('Factura ${invoice.number}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text('Cliente: ${user.name}'),
          pw.Text('Cédula: ${user.cedula}'),
          pw.Text('Contrato: ${contract.number}'),
          pw.Text('Dirección: ${contract.address}, ${contract.sector}'),
          pw.Text('Circuito: ${contract.circuit} · Medidor: ${contract.meter}'),
          pw.Text('Período: ${formatDate(invoice.periodStart)} – ${formatDate(invoice.periodEnd)}'),
          pw.Text('Emisión: ${formatDate(invoice.issueDate)} · Vence: ${formatDate(invoice.dueDate)}'),
          pw.Text('Estado: ${invoiceStatusLabel(invoice.status)}'),
          pw.SizedBox(height: 12),
          pw.Text('Lectura anterior: ${invoice.previousReading.toStringAsFixed(0)}'),
          pw.Text('Lectura actual: ${invoice.currentReading.toStringAsFixed(0)}'),
          pw.Text('Consumo: ${formatKwh(invoice.kwh)}'),
          pw.Text('Tarifa aplicada: ${invoice.tariffName}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['Concepto', 'Cantidad', 'Tarifa', 'Monto'],
            data: [
              for (final line in invoice.lines)
                [line.label, line.quantity.toStringAsFixed(2), formatMoney(line.rate), formatMoney(line.amount)],
              ['Subtotal', '', '', formatMoney(invoice.subtotal)],
              ['ITBIS 18% (simulado)', '', '', formatMoney(invoice.tax)],
              ['Total', '', '', formatMoney(invoice.total)],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('Generado por el prototipo EDESUR Móvil el ${formatDateTime(invoice.issueDate)}.'),
        ],
      ),
    );
    return doc.save();
  }

  static Future<List<int>> receipt(PaymentReceipt receipt) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('COMPROBANTE DE PAGO', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF083367))),
            pw.SizedBox(height: 8),
            pw.Text('Documento ficticio. No representa una transacción real.'),
            pw.SizedBox(height: 16),
            pw.Text('Número: ${receipt.number}'),
            pw.Text('Factura: ${receipt.invoiceNumber}'),
            pw.Text('Contrato: ${receipt.contractNumber}'),
            pw.Text('Método: ${paymentMethodLabel(receipt.method)}'),
            pw.Text('Referencia: ${receipt.reference}'),
            pw.Text('Autorización: ${receipt.authorization}'),
            pw.Text('Fecha: ${formatDateTime(receipt.paidAt)}'),
            pw.SizedBox(height: 12),
            pw.Text('Monto: ${formatMoney(receipt.amount)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
