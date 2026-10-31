import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import 'outage_map_view.dart';

class OutagesScreen extends ConsumerWidget {
  const OutagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final reports = snapshot.outages;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(child: FilledButton(onPressed: () => context.push(Routes.reportOutage), child: const Text('Reportar avería'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () => context.push(Routes.map), child: const Text('Ver mapa'))),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: reports.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return AppCard(
                    onTap: () => context.push(Routes.outage(report.id)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(outageTypeIcon(report.type), color: AppColors.orangeDark),
                            const SizedBox(width: 8),
                            Expanded(child: Text(report.number, style: const TextStyle(fontWeight: FontWeight.w700))),
                            StatusPill(label: outageStatusLabel(report.status), color: outageStatusColor(report.status)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(outageTypeLabel(report.type), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${report.sector} · ${formatDateTime(report.createdAt)}', style: const TextStyle(color: AppColors.muted)),
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

class ReportOutageScreen extends ConsumerStatefulWidget {
  const ReportOutageScreen({super.key});

  @override
  ConsumerState<ReportOutageScreen> createState() => _ReportOutageScreenState();
}

class _ReportOutageScreenState extends ConsumerState<ReportOutageScreen> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _sector = TextEditingController();
  final _reference = TextEditingController();
  OutageType _type = OutageType.noPower;
  bool _demoPhoto = false;
  String? _photoBase64;
  bool _loading = false;
  bool _ready = false;

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _sector.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _prefill() {
    if (_ready) return;
    final contract = ref.read(appControllerProvider).value?.activeContract;
    if (contract == null) return;
    _address.text = contract.address;
    _sector.text = contract.sector;
    _ready = true;
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 45);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 350000) {
        if (mounted) showAppMessage(context, 'La imagen es muy grande para la demostración. Usa la foto de ejemplo.', error: true);
        return;
      }
      setState(() {
        _photoBase64 = base64Encode(bytes);
        _demoPhoto = false;
      });
    } catch (_) {
      if (mounted) showAppMessage(context, 'No se pudo abrir la cámara o la galería. Puedes usar la fotografía de demostración.', error: true);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final contract = ref.read(appControllerProvider).requireValue.activeContract;
    setState(() => _loading = true);
    await runDemoAction(context, () async {
      final report = await ref.read(appControllerProvider.notifier).submitOutage(
            type: _type,
            description: _description.text.trim(),
            address: _address.text.trim(),
            sector: _sector.text.trim(),
            reference: _reference.text.trim(),
            latitude: contract.latitude,
            longitude: contract.longitude,
            mapX: contract.mapX,
            mapY: contract.mapY,
            demoPhoto: _demoPhoto,
            photoBase64: _photoBase64,
          );
      if (mounted) context.pushReplacement(Routes.outage(report.id));
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    _prefill();
    return FeatureScaffold(
      title: 'Reportar avería',
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Tipo de incidencia', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in OutageType.values)
                  ChoiceChip(
                    label: Text(outageTypeLabel(type)),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _description, maxLines: 4, decoration: const InputDecoration(labelText: 'Descripción'), validator: (v) => Validators.minLength(v, 12, label: 'La descripción')),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Dirección'), validator: (v) => Validators.required(v, label: 'La dirección')),
            const SizedBox(height: 12),
            TextFormField(controller: _sector, decoration: const InputDecoration(labelText: 'Sector'), validator: (v) => Validators.required(v, label: 'El sector')),
            const SizedBox(height: 12),
            TextFormField(controller: _reference, decoration: const InputDecoration(labelText: 'Referencia de ubicación'), validator: (v) => Validators.required(v, label: 'La referencia')),
            const SizedBox(height: 12),
            const Text('La ubicación del suministro se toma del contrato de demostración. No se usa GPS ni un mapa externo.'),
            const SizedBox(height: 12),
            if (_demoPhoto) Image.asset(AppConstants.demoPhotoAsset, height: 160, fit: BoxFit.cover),
            if (_photoBase64 != null) Image.memory(base64Decode(_photoBase64!), height: 160, fit: BoxFit.cover),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: () => _pick(ImageSource.gallery), child: const Text('Galería')),
                OutlinedButton(onPressed: () => _pick(ImageSource.camera), child: const Text('Cámara')),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _demoPhoto = true;
                    _photoBase64 = null;
                  }),
                  child: const Text('Foto de demostración'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Enviando...' : 'Enviar reporte')),
          ],
        ),
      ),
    );
  }
}

class OutageDetailScreen extends ConsumerWidget {
  const OutageDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final report = snapshot.outageById(id);
        if (report == null) {
          return const FeatureScaffold(title: 'Avería', body: EmptyState(title: 'Reporte no encontrado', message: 'Puede haber cambiado al cargar un escenario.'));
        }
        return FeatureScaffold(
          title: report.number,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(label: outageStatusLabel(report.status), color: outageStatusColor(report.status)),
                    const SizedBox(height: 8),
                    Text(outageTypeLabel(report.type), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    const SizedBox(height: 8),
                    Text(report.description),
                    const Divider(height: 24),
                    InfoLine(label: 'Creado', value: formatDateTime(report.createdAt)),
                    InfoLine(label: 'Dirección', value: report.address),
                    InfoLine(label: 'Sector', value: report.sector),
                    InfoLine(label: 'Referencia', value: report.reference),
                    InfoLine(label: 'Ubicación', value: '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)} (demo)'),
                  ],
                ),
              ),
              if (report.demoPhoto || report.photoBase64 != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: report.demoPhoto
                      ? Image.asset(AppConstants.demoPhotoAsset, height: 180, width: double.infinity, fit: BoxFit.cover)
                      : Image.memory(Uint8List.fromList(base64Decode(report.photoBase64!)), height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),
              const SectionHeader(title: 'Historial'),
              const SizedBox(height: 8),
              for (final event in report.history) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                      Text(formatDateTime(event.at), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(event.detail),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (nextOutageStatus(report.status) != null)
                OutlinedButton(
                  onPressed: () => runDemoAction(context, () => ref.read(appControllerProvider.notifier).advanceOutage(report.id)),
                  child: Text('Avanzar a ${outageStatusLabel(nextOutageStatus(report.status)!)} (demo)'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class OutageMapScreen extends ConsumerWidget {
  const OutageMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        return FeatureScaffold(
          title: 'Mapa de interrupciones',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Mapa esquemático de demostración. No usa Google Maps ni una API Key. Las posiciones no son georreferenciadas.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              OutageMapView(snapshot: snapshot),
            ],
          ),
        );
      },
    );
  }
}
