import '../../core/mock/demo_clock.dart';
import '../../core/utils/formatters.dart';
import '../entities/entities.dart';

extension DemoSelectors on DemoSnapshot {
  ContractAccount get activeContract =>
      contracts.firstWhere((contract) => contract.id == activeContractId);

  List<Invoice> invoicesOf(String contractId) {
    final items = invoices.where((invoice) => invoice.contractId == contractId).toList();
    items.sort((a, b) => b.periodStart.compareTo(a.periodStart));
    return items;
  }

  List<Invoice> get activeInvoices => invoicesOf(activeContractId);

  Invoice? invoiceById(String id) {
    for (final invoice in invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }

  Invoice? payableInvoiceOf(String contractId) {
    final open = invoicesOf(contractId).where((invoice) => invoice.status != InvoiceStatus.paid).toList();
    if (open.isEmpty) return null;
    open.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return open.first;
  }

  Invoice? get payableInvoice => payableInvoiceOf(activeContractId);

  double balanceOf(String contractId) {
    return invoicesOf(contractId)
        .where((invoice) => invoice.status != InvoiceStatus.paid)
        .fold<double>(0, (sum, invoice) => sum + invoice.total);
  }

  double get activeBalance => balanceOf(activeContractId);

  List<ConsumptionMonth> consumptionOf(String contractId) {
    final items = consumption.where((item) => item.contractId == contractId).toList();
    items.sort((a, b) => a.month.compareTo(b.month));
    return items;
  }

  List<ConsumptionMonth> get activeConsumption => consumptionOf(activeContractId);

  ConsumptionMonth? get currentConsumption {
    final items = activeConsumption;
    if (items.isEmpty) return null;
    return items.last;
  }

  ConsumptionMonth? get previousConsumption {
    final items = activeConsumption;
    if (items.length < 2) return null;
    return items[items.length - 2];
  }

  int get unreadCount => notifications.where((item) => !item.read).length;

  List<OutageReport> outagesOf(String contractId) {
    final items = outages.where((item) => item.contractId == contractId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<ServiceRequest> requestsOf(String contractId) {
    final items = requests.where((item) => item.contractId == contractId).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  PaymentReceipt? receiptById(String id) {
    for (final receipt in receipts) {
      if (receipt.id == id) return receipt;
    }
    return null;
  }

  OutageReport? outageById(String id) {
    for (final report in outages) {
      if (report.id == id) return report;
    }
    return null;
  }

  ServiceRequest? requestById(String id) {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  bool get supplyInterrupted => activeContract.serviceStatus == ServiceStatus.interrupted;

  OutageReport? get openOutage {
    for (final report in outagesOf(activeContractId)) {
      if (report.status != OutageStatus.resolved) return report;
    }
    return null;
  }
}

class WeekBucket {
  const WeekBucket({required this.label, required this.kwh, required this.start});
  final String label;
  final double kwh;
  final DateTime start;
}

List<WeekBucket> lastWeeks(List<ConsumptionMonth> months, {int count = 8}) {
  final days = <(DateTime, double)>[];
  for (final month in months) {
    for (var i = 0; i < month.daily.length; i++) {
      days.add((DateTime(month.month.year, month.month.month, i + 1), month.daily[i]));
    }
  }
  if (days.isEmpty) return const [];
  final end = days.last.$1;
  final start = end.subtract(Duration(days: count * 7 - 1));
  final buckets = <WeekBucket>[];
  for (var w = 0; w < count; w++) {
    final from = DateTime(start.year, start.month, start.day).add(Duration(days: w * 7));
    final to = from.add(const Duration(days: 6));
    var total = 0.0;
    for (final day in days) {
      if (!day.$1.isBefore(from) && !day.$1.isAfter(to)) total += day.$2;
    }
    buckets.add(WeekBucket(
      label: '${from.day}/${from.month}',
      kwh: round2(total),
      start: from,
    ));
  }
  return buckets;
}

String relativeUpdate(DateTime moment) {
  final now = DemoClock.now;
  final delta = now.difference(moment);
  if (delta.inMinutes.abs() < 1) return 'Hace un momento';
  if (delta.inMinutes.abs() < 60) return 'Hace ${delta.inMinutes.abs()} min';
  if (delta.inHours.abs() < 24) return 'Hace ${delta.inHours.abs()} h';
  return formatDateTime(moment);
}
