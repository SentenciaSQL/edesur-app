import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/billing/tariff.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/widgets/common.dart';
import '../consumption/consumption_charts.dart';
import '../../core/mock/catalogs.dart';

class ConsumptionScreen extends ConsumerStatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  ConsumerState<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends ConsumerState<ConsumptionScreen> {
  int _view = 2;

  @override
  Widget build(BuildContext context) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final months = snapshot.activeConsumption;
        if (months.isEmpty) {
          return const FeatureScaffold(title: 'Consumo', body: EmptyState(title: 'Sin datos', message: 'No hay consumo para este contrato.'));
        }
        final current = months.last;
        final previous = months.length > 1 ? months[months.length - 2] : null;
        final average = months.fold<double>(0, (sum, item) => sum + item.kwh) / months.length;
        final delta = previous == null ? 0.0 : percentChange(current.kwh, previous.kwh);
        final slope = trendSlope([for (final month in months) month.kwh]);
        final quote = snapshot.activeContract.commercial ? DemoTariff.commercial(current.kwh) : DemoTariff.residential(current.kwh);
        final high = current.kwh > average * 1.08;
        final weeks = lastWeeks(months);
        return FeatureScaffold(
          title: 'Consumo',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Diario')),
                  ButtonSegment(value: 1, label: Text('Semanal')),
                  ButtonSegment(value: 2, label: Text('Mensual')),
                  ButtonSegment(value: 3, label: Text('12 meses')),
                ],
                selected: {_view},
                onSelectionChanged: (value) => setState(() => _view = value.first),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatMonthYear(current.month), style: const TextStyle(color: AppColors.muted)),
                    Text(formatKwh(current.kwh), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    if (previous != null)
                      Text('${formatPercent(delta)} frente a ${formatMonthYear(previous.month)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (_view == 0) DailyLine(values: current.daily),
                    if (_view == 1)
                      MonthlyBars(
                        labels: [for (final week in weeks) week.label],
                        values: [for (final week in weeks) week.kwh],
                      ),
                    if (_view == 2 || _view == 3)
                      MonthlyBars(
                        labels: [for (final month in months) formatMonthShort(month.month)],
                        values: [for (final month in months) month.kwh],
                        height: 220,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Stat(title: 'Promedio', value: formatKwh(average))),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(title: 'Tendencia', value: slope >= 0.8 ? 'Al alza' : slope <= -0.8 ? 'A la baja' : 'Estable')),
                ],
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimación de facturación', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    const SizedBox(height: 6),
                    Text(formatMoney(quote.total), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                      'Estimación simulada con datos ficticios y una tarifa de demostración. No constituye una factura.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (high) ...[
                const SizedBox(height: 10),
                const AppCard(
                  color: AppColors.amberSoft,
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.amber),
                      SizedBox(width: 10),
                      Expanded(child: Text('Tu consumo del período está por encima del promedio de los últimos meses.')),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const SectionHeader(title: 'Recomendaciones de ahorro'),
              const SizedBox(height: 8),
              for (final tip in savingsTips) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tip.$1, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                      const SizedBox(height: 4),
                      Text(tip.$2),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
        ],
      ),
    );
  }
}
