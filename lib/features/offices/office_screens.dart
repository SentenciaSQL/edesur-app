import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mock/catalogs.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';

class OfficesScreen extends StatelessWidget {
  const OfficesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Centros de atención',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Directorio ficticio para la demostración. No corresponde a oficinas reales de EDESUR.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          for (final office in Catalogs.offices) ...[
            AppCard(
              onTap: () => context.push(Routes.office(office.id)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(office.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                  const SizedBox(height: 4),
                  Text(office.address),
                  Text(office.sector, style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 6),
                  Text(office.schedule, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class OfficeDetailScreen extends StatelessWidget {
  const OfficeDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final office = Catalogs.office(id);
    if (office == null) {
      return const FeatureScaffold(title: 'Oficina', body: EmptyState(title: 'Oficina no encontrada', message: 'Vuelve al directorio.'));
    }
    final digits = office.phone.replaceAll(RegExp(r'\D'), '');
    return FeatureScaffold(
      title: office.sector,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(office.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
          const SizedBox(height: 8),
          const Text('Dirección de demostración. No es un local real.', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                InfoLine(label: 'Dirección', value: office.address),
                InfoLine(label: 'Sector', value: office.sector),
                InfoLine(label: 'Horario', value: office.schedule),
                InfoLine(label: 'Teléfono', value: office.phone),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Servicios disponibles', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final service in office.services) Chip(label: Text(service))],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => launchUrl(Uri.parse('tel:$digits')),
            child: const Text('Llamar (número ficticio)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cómo llegar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(office.directions),
                      const SizedBox(height: 8),
                      const Text('Indicaciones simuladas. No abren un mapa externo.', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              );
            },
            child: const Text('Indicaciones para llegar'),
          ),
        ],
      ),
    );
  }
}
