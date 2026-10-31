import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/demo_exception.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../labels.dart';
import '../../core/routing/routes.dart';

class EdesurLogo extends StatelessWidget {
  const EdesurLogo({super.key, this.height = 72});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppConstants.logoAsset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Edesur Dominicana',
    );
  }
}

class AssistantButton extends StatelessWidget {
  const AssistantButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Asistente',
      onPressed: () => context.push(Routes.assistant),
      icon: const Icon(Icons.support_agent_rounded, color: AppColors.navy),
    );
  }
}

class EdesurMark extends StatelessWidget {
  const EdesurMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppConstants.markAsset, width: size, height: size, fit: BoxFit.contain);
  }
}

class SimulatedBanner extends StatelessWidget {
  const SimulatedBanner({super.key, this.tappable = true});
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      width: double.infinity,
      color: AppColors.navyDeep,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: const Text(
        'Prototipo · información y operaciones simuladas',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
    if (!tappable) return banner;
    return GestureDetector(
      onTap: () => context.push(Routes.demo),
      child: banner,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x140F1D41), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: card),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined, this.action});
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppColors.navy),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Cargando información de demostración...'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.showBanner = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: Column(
        children: [
          if (showBanner) const SimulatedBanner(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: bottom,
    );
  }
}

void showAppMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.red : AppColors.navyDeep,
    ),
  );
}

Future<bool> showConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

Future<void> showContractSwitcher(BuildContext context, WidgetRef ref) {
  final snapshot = ref.read(appControllerProvider).requireValue;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tus contratos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Cambia de suministro para ver facturas, consumo y trámites de cada propiedad de demostración.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            for (final contract in snapshot.contracts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  contract.id == snapshot.activeContractId ? Icons.check_circle : Icons.home_work_outlined,
                  color: contract.id == snapshot.activeContractId ? AppColors.orange : AppColors.navy,
                ),
                title: Text(contract.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${contract.number} · ${contract.sector}'),
                trailing: StatusPill(
                  label: serviceStatusLabel(contract.serviceStatus),
                  color: serviceStatusColor(contract.serviceStatus),
                ),
                onTap: () async {
                  await ref.read(appControllerProvider.notifier).selectContract(contract.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      );
    },
  );
}

class SnapshotBody extends ConsumerWidget {
  const SnapshotBody({super.key, required this.builder});
  final Widget Function(BuildContext context, DemoSnapshot snapshot) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appControllerProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (error, _) => EmptyState(
        title: 'No pudimos abrir la demostración',
        message: '$error',
        icon: Icons.error_outline,
      ),
      data: (snapshot) => builder(context, snapshot),
    );
  }
}

Future<void> runDemoAction(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on DemoException catch (error) {
    if (context.mounted) showAppMessage(context, error.message, error: true);
  } catch (error) {
    if (context.mounted) showAppMessage(context, 'No se pudo completar la acción de demostración.', error: true);
  }
}

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.orangeSoft, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.orangeDark, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyDeep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: AppColors.muted))),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

String moneyOrZero(double value) => formatMoney(value);
