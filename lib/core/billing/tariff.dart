import '../utils/formatters.dart';

class TariffLine {
  const TariffLine({
    required this.label,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  final String label;
  final double quantity;
  final double rate;
  final double amount;
}

class TariffQuote {
  const TariffQuote({
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.tariffName,
  });

  final List<TariffLine> lines;
  final double subtotal;
  final double tax;
  final double total;
  final String tariffName;
}

/// Tarifas ficticias, etiquetadas como simulación. No reproducen el pliego
/// tarifario vigente de la Superintendencia de Electricidad.
class DemoTariff {
  static const residentialName = 'BTS1 · Baja tensión residencial (demo)';
  static const commercialName = 'BTD · Baja tensión con demanda (demo)';

  static TariffQuote residential(double kwh) {
    const bands = <(double, double, String)>[
      (200, 6.85, 'Energía 0–200 kWh'),
      (100, 8.55, 'Energía 201–300 kWh'),
      (400, 12.35, 'Energía 301–700 kWh'),
      (1000000, 14.10, 'Energía sobre 700 kWh'),
    ];
    final lines = <TariffLine>[
      const TariffLine(label: 'Cargo fijo por suministro', quantity: 1, rate: 185, amount: 185),
    ];
    var left = kwh;
    for (final band in bands) {
      if (left <= 0) break;
      final qty = left < band.$1 ? left : band.$1;
      lines.add(TariffLine(
        label: band.$3,
        quantity: qty,
        rate: band.$2,
        amount: round2(qty * band.$2),
      ));
      left -= qty;
    }
    lines.add(const TariffLine(
      label: 'Alumbrado público',
      quantity: 1,
      rate: 96.50,
      amount: 96.50,
    ));
    return _finish(lines, residentialName, exemptLabel: 'Alumbrado público');
  }

  static TariffQuote commercial(double kwh) {
    final energy = round2(kwh * 11.40);
    final lines = <TariffLine>[
      const TariffLine(label: 'Cargo fijo por suministro', quantity: 1, rate: 450, amount: 450),
      TariffLine(label: 'Energía', quantity: kwh, rate: 11.40, amount: energy),
      const TariffLine(label: 'Cargo por demanda (demo)', quantity: 1, rate: 320, amount: 320),
    ];
    return _finish(lines, commercialName);
  }

  static TariffQuote _finish(List<TariffLine> lines, String name, {String? exemptLabel}) {
    final subtotal = round2(lines.fold<double>(0, (sum, line) => sum + line.amount));
    final taxable = round2(lines
        .where((line) => line.label != exemptLabel)
        .fold<double>(0, (sum, line) => sum + line.amount));
    final tax = round2(taxable * 0.18);
    return TariffQuote(
      lines: lines,
      subtotal: subtotal,
      tax: tax,
      total: round2(subtotal + tax),
      tariffName: name,
    );
  }
}
