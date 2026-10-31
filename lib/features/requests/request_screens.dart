import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/mock/catalogs.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'Trámites'), Tab(text: 'Mis solicitudes')],
            labelColor: AppColors.orangeDark,
            indicatorColor: AppColors.orange,
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    for (final item in Catalogs.requests) ...[
                      AppCard(
                        onTap: () => context.push(Routes.requestForm(item.type.name)),
                        child: Row(
                          children: [
                            Icon(requestTypeIcon(item.type), color: AppColors.navy),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(requestTypeLabel(item.type), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                                  Text(item.summary, style: const TextStyle(color: AppColors.muted)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
                SnapshotBody(
                  builder: (context, snapshot) {
                    final items = snapshot.requests;
                    if (items.isEmpty) {
                      return const EmptyState(title: 'Sin solicitudes', message: 'Cuando envíes un trámite aparecerá aquí.');
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final request = items[index];
                        return AppCard(
                          onTap: () => context.push(Routes.request(request.id)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(request.number, style: const TextStyle(fontWeight: FontWeight.w700))),
                                  StatusPill(label: requestStatusLabel(request.status), color: requestStatusColor(request.status)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(requestTypeLabel(request.type)),
                              Text(formatDate(request.createdAt), style: const TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RequestFormScreen extends ConsumerStatefulWidget {
  const RequestFormScreen({super.key, required this.typeName});
  final String typeName;

  @override
  ConsumerState<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends ConsumerState<RequestFormScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _attachments = <String>[];
  bool _loading = false;
  bool _ready = false;

  RequestType get _type => RequestType.values.firstWhere((item) => item.name == widget.typeName);

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prepare(RequestDefinition definition) {
    if (_ready) return;
    final snapshot = ref.read(appControllerProvider).value;
    for (final field in definition.fields) {
      final controller = TextEditingController();
      if (snapshot != null && field.key == 'contrato') controller.text = snapshot.activeContractOrNull?.number ?? '';
      if (snapshot != null && field.key == 'nombre') controller.text = snapshot.user.name;
      if (snapshot != null && field.key == 'cedula') controller.text = snapshot.user.cedula;
      if (snapshot != null && field.key == 'telefono') controller.text = snapshot.user.phone;
      if (snapshot != null && field.key == 'correo') controller.text = snapshot.user.email;
      _controllers[field.key] = controller;
    }
    _ready = true;
  }

  Future<void> _submit(RequestDefinition definition) async {
    if (!_form.currentState!.validate()) return;
    final ok = await showConfirmSheet(
      context: context,
      title: 'Enviar solicitud simulada',
      message: 'Se generará un número de seguimiento local. No se enviará a EDESUR.',
      confirmLabel: 'Enviar',
    );
    if (!ok || !mounted) return;
    setState(() => _loading = true);
    final details = {
      for (final field in definition.fields) field.label: _controllers[field.key]!.text.trim(),
    };
    await runDemoAction(context, () async {
      final request = await ref.read(appControllerProvider.notifier).submitRequest(
            type: definition.type,
            summary: definition.summary,
            details: details,
            attachments: List<String>.from(_attachments),
          );
      if (mounted) context.pushReplacement(Routes.request(request.id));
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final definition = Catalogs.definition(_type);
    _prepare(definition);
    return FeatureScaffold(
      title: requestTypeLabel(definition.type),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(definition.description),
            const SizedBox(height: 12),
            const Text('Requisitos', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final item in definition.requirements) Text('• $item'),
            const SizedBox(height: 16),
            for (final field in definition.fields) ...[
              if (field.kind == FieldKind.select)
                DropdownButtonFormField<String>(
                  initialValue: _controllers[field.key]!.text.isEmpty ? null : _controllers[field.key]!.text,
                  decoration: InputDecoration(labelText: field.label),
                  items: [for (final option in field.options) DropdownMenuItem(value: option, child: Text(option))],
                  onChanged: (value) => _controllers[field.key]!.text = value ?? '',
                  validator: (value) => Validators.required(value ?? _controllers[field.key]!.text, label: field.label),
                )
              else
                TextFormField(
                  controller: _controllers[field.key],
                  maxLines: field.kind == FieldKind.multiline ? 4 : 1,
                  keyboardType: field.kind == FieldKind.phone
                      ? TextInputType.phone
                      : field.kind == FieldKind.email
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                  decoration: InputDecoration(labelText: field.label, hintText: field.hint),
                  validator: (value) {
                    if (field.kind == FieldKind.email) return Validators.email(value);
                    if (field.kind == FieldKind.phone) return Validators.phone(value);
                    if (field.kind == FieldKind.multiline) return Validators.minLength(value, 8, label: field.label);
                    return Validators.required(value, label: field.label);
                  },
                ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              children: [
                for (final name in _attachments) Chip(label: Text(name)),
              ],
            ),
            OutlinedButton(
              onPressed: () => setState(() => _attachments.add('documento-demostracion-${_attachments.length + 1}.pdf')),
              child: const Text('Adjuntar documento de demostración'),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loading ? null : () => _submit(definition), child: Text(_loading ? 'Enviando...' : 'Enviar solicitud')),
          ],
        ),
      ),
    );
  }
}

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final request = snapshot.requestById(id);
        if (request == null) {
          return const FeatureScaffold(title: 'Solicitud', body: EmptyState(title: 'Solicitud no encontrada', message: 'Vuelve al catálogo.'));
        }
        return FeatureScaffold(
          title: request.number,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(label: requestStatusLabel(request.status), color: requestStatusColor(request.status)),
                    const SizedBox(height: 8),
                    Text(requestTypeLabel(request.type), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                    const SizedBox(height: 6),
                    Text(request.summary),
                    const Divider(height: 24),
                    InfoLine(label: 'Creada', value: formatDateTime(request.createdAt)),
                    for (final entry in request.details.entries) InfoLine(label: entry.key, value: entry.value),
                    if (request.attachments.isNotEmpty) InfoLine(label: 'Adjuntos', value: request.attachments.join(', ')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SectionHeader(title: 'Seguimiento'),
              const SizedBox(height: 8),
              for (final event in request.history) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(formatDateTime(event.at), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      Text(event.detail),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (nextRequestStatus(request.status) != null)
                OutlinedButton(
                  onPressed: () => runDemoAction(context, () => ref.read(appControllerProvider.notifier).advanceRequest(request.id)),
                  child: Text('Avanzar a ${requestStatusLabel(nextRequestStatus(request.status)!)} (demo)'),
                ),
            ],
          ),
        );
      },
    );
  }
}
