import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/mock/demo_clock.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/entities.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';

class DemoModeScreen extends ConsumerWidget {
  const DemoModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appControllerProvider).value;
    return FeatureScaffold(
      title: 'Modo demostración',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Carga un escenario coherente para la presentación. Los datos operativos se reemplazan. La sesión se mantiene, salvo cuando restauras el estado inicial.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 8),
          Text('Fecha de referencia: ${formatDateTime(DemoClock.now)}', style: const TextStyle(color: AppColors.muted)),
          if (snapshot != null) ...[
            const SizedBox(height: 6),
            Text('Escenario actual: ${scenarioLabel(snapshot.scenario)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
          ],
          const SizedBox(height: 16),
          const Text('Cartera de contratos', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
          const SizedBox(height: 6),
          const Text('Cambia cuántos contratos propios y de terceros tiene la cuenta. Se restablecen las facturas y los pagos de la sesión, y vuelve el historial de tarjetas de demostración. Las tarjetas guardadas se conservan.'),
          const SizedBox(height: 10),
          for (final preset in PortfolioPreset.values) ...[
            AppCard(
              color: snapshot?.portfolio == preset ? AppColors.orangeSoft : AppColors.white,
              onTap: () async {
                await ref.read(appControllerProvider.notifier).applyPortfolio(preset);
                if (context.mounted) {
                  showAppMessage(context, 'Cartera cargada: ${portfolioLabel(preset)}.');
                  context.go(Routes.contracts);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(portfolioLabel(preset), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                  const SizedBox(height: 4),
                  Text(portfolioDescription(preset)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          const Text('Estado del servicio', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
          const SizedBox(height: 10),
          for (final scenario in DemoScenario.values) ...[
            AppCard(
              color: snapshot?.scenario == scenario ? AppColors.orangeSoft : AppColors.white,
              onTap: () async {
                await ref.read(appControllerProvider.notifier).applyScenario(scenario);
                if (context.mounted) {
                  showAppMessage(context, 'Escenario cargado: ${scenarioLabel(scenario)}.');
                  context.go(Routes.home);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scenarioLabel(scenario), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                  const SizedBox(height: 4),
                  Text(scenarioDescription(scenario)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: () async {
              await ref.read(appControllerProvider.notifier).resetDemoData();
              if (context.mounted) showAppMessage(context, 'Datos de demostración restablecidos.');
            },
            child: const Text('Restablecer datos de demostración'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final ok = await showConfirmSheet(
                context: context,
                title: 'Restaurar estado inicial',
                message: 'Se borran los cambios, se cierra la sesión y vuelves al inicio de la presentación.',
                confirmLabel: 'Restaurar',
              );
              if (!ok || !context.mounted) return;
              await ref.read(appControllerProvider.notifier).restoreInitial();
              if (context.mounted) context.go(Routes.splash);
            },
            child: const Text('Restaurar estado inicial'),
          ),
        ],
      ),
    );
  }
}
