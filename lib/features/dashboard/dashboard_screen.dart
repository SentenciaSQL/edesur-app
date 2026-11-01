import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/mock/demo_clock.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import '../consumption/consumption_charts.dart';
import 'quick_access_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        if (snapshot.contracts.isEmpty) {
          return EmptyState(
            title: 'Sin contratos vinculados',
            message: 'Agrega un suministro de demostración para ver el balance, el consumo y el estado del servicio.',
            action: FilledButton(onPressed: () => context.push(Routes.addContract), child: const Text('Agregar contrato')),
          );
        }
        final contract = snapshot.activeContract;
        final invoice = snapshot.payableInvoice;
        final balance = snapshot.activeBalance;
        final current = snapshot.currentConsumption;
        final previous = snapshot.previousConsumption;
        final months = snapshot.activeConsumption;
        final visible = months.length > 6 ? months.sublist(months.length - 6) : months;
        final delta = current != null && previous != null ? percentChange(current.kwh, previous.kwh) : 0.0;
        final down = delta <= 0;
        return RefreshIndicator(
          onRefresh: () => ref.read(appControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  const EdesurLogo(height: 36),
                  const Spacer(),
                  const QuickAccessButton(),
                  const AssistantButton(),
                  _Bell(count: snapshot.unreadCount),
                ],
              ),
              const SizedBox(height: 16),
              Text(greetingFor(DemoClock.now), style: const TextStyle(color: AppColors.muted)),
              Text(
                firstName(snapshot.user.name),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navyDeep),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => showContractSwitcher(context, ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Tu suministro', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                        ),
                        StatusPill(label: serviceStatusLabel(contract.serviceStatus), color: serviceStatusColor(contract.serviceStatus)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(snapshot.user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    if (contract.alias.trim().isNotEmpty)
                      Text(contract.alias.trim(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    Text('Contrato ${contract.number}', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(contract.address, style: const TextStyle(color: AppColors.ink)),
                    Text('${contract.sector} · ${contract.clientType}', style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Meta(icon: Icons.account_tree_outlined, text: 'Circuito ${contract.circuit}'),
                        _Meta(icon: Icons.sell_outlined, text: contract.tariffCode),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                color: balance <= 0 ? AppColors.white : (invoice?.status == InvoiceStatus.overdue ? AppColors.redSoft : AppColors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(balance <= 0 ? 'Estás al día' : 'Balance pendiente', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(formatMoney(balance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    if (invoice != null) ...[
                      const SizedBox(height: 4),
                      Text('Última factura ${invoice.number} · ${formatMonthYear(invoice.periodStart)}'),
                      Text('Fecha límite ${formatDate(invoice.dueDate)} · ${invoiceStatusLabel(invoice.status)}'),
                    ] else
                      const Text('No tienes facturas abiertas en este contrato.'),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: invoice == null ? null : () => context.push(Routes.pay(invoice.id)),
                      child: const Text('Pagar ahora'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: () => context.push(Routes.multiPay), child: const Text('Pagar varios contratos')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Consumo eléctrico'),
                    const SizedBox(height: 8),
                    Text(current == null ? '—' : formatKwh(current.kwh), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    if (previous != null)
                      Row(
                        children: [
                          Icon(down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: down ? AppColors.green : AppColors.red, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${formatPercent(delta)} vs ${formatMonthYear(previous.month)}',
                            style: TextStyle(color: down ? AppColors.green : AppColors.red, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    MonthlyBars(
                      labels: [for (final month in visible) formatMonthShort(month.month)],
                      values: [for (final month in visible) month.kwh],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: () => context.push(Routes.consumption), child: const Text('Ver análisis')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SupplyCard(snapshot: snapshot),
              const SizedBox(height: 16),
              const SectionHeader(title: 'Accesos rápidos'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.92,
                children: [
                  QuickAction(
                    icon: Icons.payments_outlined,
                    label: 'Pagar factura',
                    onTap: () {
                      if (invoice == null) {
                        showAppMessage(context, 'No tienes balance pendiente.');
                      } else {
                        context.push(Routes.pay(invoice.id));
                      }
                    },
                  ),
                  QuickAction(icon: Icons.report_gmailerrorred_rounded, label: 'Reportar avería', onTap: () => context.push(Routes.reportOutage)),
                  QuickAction(icon: Icons.insights_rounded, label: 'Consultar consumo', onTap: () => context.push(Routes.consumption)),
                  QuickAction(icon: Icons.receipt_long_outlined, label: 'Historial de facturas', onTap: () => context.go(Routes.invoices)),
                  QuickAction(icon: Icons.assignment_outlined, label: 'Nueva solicitud', onTap: () => context.go(Routes.requests)),
                  QuickAction(icon: Icons.support_agent_rounded, label: 'Contactar soporte', onTap: () => context.push(Routes.contact)),
                ],
              ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Comunicaciones'),
              const SizedBox(height: 10),
              for (final item in snapshot.announcements) ...[
                AppCard(
                  color: item.critical ? AppColors.redSoft : AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.critical ? Icons.warning_amber_rounded : Icons.campaign_outlined, color: item.critical ? AppColors.red : AppColors.orangeDark),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.category, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600))),
                          Text(formatDate(item.date), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                      const SizedBox(height: 4),
                      Text(item.body, style: const TextStyle(height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push(Routes.notifications),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_none_rounded, color: AppColors.navy),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.navy),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.snapshot});
  final DemoSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final contract = snapshot.activeContract;
    final open = snapshot.openOutage;
    final interrupted = contract.serviceStatus == ServiceStatus.interrupted;
    final title = interrupted
        ? 'Interrupción en tu circuito'
        : open != null
            ? 'Avería en seguimiento'
            : 'Servicio normal';
    final subtitle = interrupted
        ? 'Hay una interrupción simulada en ${contract.circuit}.'
        : open != null
            ? '${open.number} · ${outageStatusLabel(open.status)}'
            : 'Sin interrupciones reportadas en tu circuito.';
    final color = interrupted ? AppColors.red : open != null ? AppColors.amber : AppColors.green;
    return AppCard(
      onTap: interrupted || open != null ? () => context.push(Routes.map) : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(interrupted ? Icons.power_off_rounded : Icons.check_circle_outline, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                Text(subtitle),
                Text('Actualizado ${formatDateTime(snapshot.lastUpdated)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
