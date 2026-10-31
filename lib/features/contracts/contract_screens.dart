import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/mock/mock_seed.dart';
import '../../domain/usecases/usecases.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/demo_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        if (snapshot.contracts.isEmpty) {
          return FeatureScaffold(
            title: 'Contratos',
            body: EmptyState(
              title: 'Sin contratos vinculados',
              message: 'Agrega un suministro de demostración para consultar facturas y pagar.',
              action: FilledButton(onPressed: () => context.push(Routes.addContract), child: const Text('Agregar contrato')),
            ),
          );
        }
        return FeatureScaffold(
          title: 'Contratos',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final contract in snapshot.contracts) ...[
                _ContractCard(snapshot: snapshot, contract: contract),
                const SizedBox(height: 10),
              ],
              FilledButton(onPressed: () => context.push(Routes.addContract), child: const Text('Agregar contrato')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => context.push(Routes.multiPay), child: const Text('Pagar varios contratos')),
            ],
          ),
        );
      },
    );
  }
}

class _ContractCard extends ConsumerWidget {
  const _ContractCard({required this.snapshot, required this.contract});
  final DemoSnapshot snapshot;
  final ContractAccount contract;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = contract.isOwnedBy(snapshot.user.cedula);
    final balance = snapshot.balanceOf(contract.id);
    final invoice = snapshot.payableInvoiceOf(contract.id);
    final active = contract.id == snapshot.activeContractId;
    return AppCard(
      onTap: () => context.push(Routes.contract(contract.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(contract.displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
              ),
              if (active) const StatusPill(label: 'Principal', color: AppColors.orangeDark),
            ],
          ),
          const SizedBox(height: 6),
          Text('Contrato ${contract.number}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
          Text(contract.holderName),
          Text(contract.address),
          Text('${contract.sector} · ${contract.clientType}', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: owned ? 'Titular del contrato' : 'Contrato de tercero',
                color: owned ? AppColors.navy : AppColors.orangeDark,
              ),
              StatusPill(label: serviceStatusLabel(contract.serviceStatus), color: serviceStatusColor(contract.serviceStatus)),
              StatusPill(
                label: balance <= 0 ? 'Sin deuda' : formatMoney(balance),
                color: invoice?.status == InvoiceStatus.overdue ? AppColors.red : AppColors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ContractDetailScreen extends ConsumerWidget {
  const ContractDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        ContractAccount? contract;
        for (final item in snapshot.contracts) {
          if (item.id == id) contract = item;
        }
        if (contract == null) {
          return const FeatureScaffold(
            title: 'Contrato',
            body: EmptyState(title: 'Contrato no disponible', message: 'Ya no está vinculado a esta cuenta de demostración.'),
          );
        }
        final owned = contract.isOwnedBy(snapshot.user.cedula);
        final balance = snapshot.balanceOf(contract.id);
        final invoice = snapshot.payableInvoiceOf(contract.id);
        final active = contract.id == snapshot.activeContractId;
        return FeatureScaffold(
          title: contract.displayName,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  children: [
                    InfoLine(label: 'Contrato', value: contract.number),
                    InfoLine(label: 'Alias', value: contract.alias.isEmpty ? 'Sin alias' : contract.alias),
                    InfoLine(label: 'Titular', value: contract.holderName),
                    InfoLine(label: 'Cédula del titular', value: contract.cedula),
                    InfoLine(label: 'Dirección', value: contract.address),
                    InfoLine(label: 'Sector', value: contract.sector),
                    InfoLine(label: 'Tipo de cliente', value: contract.clientType),
                    InfoLine(label: 'Estado', value: serviceStatusLabel(contract.serviceStatus)),
                    InfoLine(label: 'Balance', value: balance <= 0 ? 'Sin deuda' : formatMoney(balance)),
                    InfoLine(label: 'Titularidad', value: owned ? 'Titular del contrato' : 'Contrato de tercero'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!active)
                FilledButton(
                  onPressed: () async {
                    await ref.read(appControllerProvider.notifier).selectContract(contract!.id);
                    if (context.mounted) showAppMessage(context, 'Este contrato ahora es el principal.');
                  },
                  child: const Text('Usar como principal'),
                ),
              if (invoice != null) ...[
                const SizedBox(height: 8),
                FilledButton(onPressed: () => context.push(Routes.pay(invoice.id)), child: const Text('Pagar esta factura')),
              ],
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => _alias(context, ref, contract!), child: const Text('Editar alias')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => _address(context, ref, contract!), child: const Text('Editar dirección')),
              const SizedBox(height: 8),
              if (invoice != null)
                TextButton(onPressed: () => context.push(Routes.invoice(invoice.id)), child: const Text('Ver detalle de la factura')),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _remove(context, ref, contract!, owned),
                child: Text(owned ? 'Eliminar contrato' : 'Desvincular contrato', style: TextStyle(color: owned ? AppColors.muted : AppColors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _alias(BuildContext context, WidgetRef ref, ContractAccount contract) async {
    final controller = TextEditingController(text: contract.alias);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alias del contrato'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Alias', hintText: 'Ej. Casa principal')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await ref.read(appControllerProvider.notifier).updateAlias(contractId: contract.id, alias: controller.text);
      if (context.mounted) showAppMessage(context, 'Alias actualizado en este dispositivo.');
    }
    controller.dispose();
  }

  Future<void> _address(BuildContext context, WidgetRef ref, ContractAccount contract) async {
    final address = TextEditingController(text: contract.address);
    final sector = TextEditingController(text: contract.sector);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dirección del suministro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: address, decoration: const InputDecoration(labelText: 'Dirección')),
            TextField(controller: sector, decoration: const InputDecoration(labelText: 'Sector')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      await ref.read(appControllerProvider.notifier).updateContractAddress(
            contractId: contract.id,
            address: address.text.trim(),
            sector: sector.text.trim(),
          );
      if (context.mounted) showAppMessage(context, 'Dirección de demostración actualizada.');
    }
    address.dispose();
    sector.dispose();
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, ContractAccount contract, bool owned) async {
    if (owned) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: const Text(AppConstants.cannotUnlinkOwnContract),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
        ),
      );
      return;
    }
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Desvincular contrato',
      message: 'Se quitará ${contract.displayName} de tu cuenta. El suministro de ${contract.holderName} no se cancela; solo deja de verse en esta demostración.',
      confirmLabel: 'Desvincular',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(appControllerProvider.notifier).unlinkContract(contract.id);
      if (context.mounted) {
        showAppMessage(context, 'Contrato desvinculado.');
        context.pop();
      }
    } on DemoException catch (error) {
      if (context.mounted) showAppMessage(context, error.message, error: true);
    }
  }
}

class AddContractScreen extends ConsumerStatefulWidget {
  const AddContractScreen({super.key});

  @override
  ConsumerState<AddContractScreen> createState() => _AddContractScreenState();
}

class _AddContractScreenState extends ConsumerState<AddContractScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _cedula = TextEditingController();
  final _name = TextEditingController();
  final _alias = TextEditingController();
  bool _busy = false;
  ContractLookup? _lookup;

  @override
  void dispose() {
    _number.dispose();
    _cedula.dispose();
    _name.dispose();
    _alias.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final lookup = ref.read(appControllerProvider.notifier).lookupContract(
          number: _number.text,
          cedula: _cedula.text,
          holderName: _name.text,
        );
    if (mounted) {
      setState(() {
        _busy = false;
        _lookup = lookup;
      });
    }
  }

  Future<void> _confirm(SupplyBundle? supply) async {
    if (supply == null) return;
    final contract = supply.contract;
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Vincular suministro',
      message: 'Se agregará el contrato ${contract.number} de ${contract.holderName}, en ${contract.address}. Es una vinculación simulada.',
      confirmLabel: 'Vincular',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(appControllerProvider.notifier).linkContract(
            contract: contract,
            invoices: supply.invoices,
            months: supply.months,
            alias: _alias.text,
          );
      if (mounted) {
        showAppMessage(context, 'Contrato ${contract.number} vinculado.');
        context.pop();
      }
    } on DemoException catch (error) {
      if (mounted) showAppMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = _lookup;
    final supply = lookup?.supply;
    return FeatureScaffold(
      title: 'Agregar contrato',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'La verificación es simulada. Prueba 1009900112 con cédula 001-9988776-6 y titular Carmen Díaz. Un número como 1000000000 no existe. 1002345678 ya está vinculado.',
          ),
          const SizedBox(height: 12),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _number,
                  decoration: const InputDecoration(labelText: 'Número de contrato'),
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.required(value, label: 'El número de contrato'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cedula,
                  decoration: const InputDecoration(labelText: 'Cédula del titular'),
                  validator: Validators.cedula,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre del titular'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => Validators.required(value, label: 'El nombre del titular'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _alias,
                  decoration: const InputDecoration(labelText: 'Alias', hintText: 'Opcional. Ej. Finca'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _busy ? null : _search, child: Text(_busy ? 'Verificando...' : 'Verificar suministro')),
          if (lookup != null) ...[
            const SizedBox(height: 16),
            AppCard(
              color: lookup.result == LinkLookupResult.found ? AppColors.white : AppColors.redSoft,
              child: switch (lookup.result) {
                LinkLookupResult.missing => const Text('No encontramos un suministro con ese número de contrato.'),
                LinkLookupResult.alreadyLinked => const Text('Este contrato ya está vinculado a tu cuenta.'),
                LinkLookupResult.holderMismatch => const Text('La cédula o el nombre no corresponden al titular registrado de este contrato.'),
                LinkLookupResult.found => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suministro encontrado', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                      const SizedBox(height: 8),
                      InfoLine(label: 'Contrato', value: supply!.contract.number),
                      InfoLine(label: 'Titular', value: supply.contract.holderName),
                      InfoLine(label: 'Dirección', value: supply.contract.address),
                      InfoLine(label: 'Sector', value: supply.contract.sector),
                      InfoLine(label: 'Tipo', value: supply.contract.clientType),
                      InfoLine(label: 'Estado', value: serviceStatusLabel(supply.contract.serviceStatus)),
                    ],
                  ),
              },
            ),
            if (lookup.result == LinkLookupResult.found) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: _busy ? null : () => _confirm(supply), child: const Text('Confirmar vinculación')),
            ],
          ],
        ],
      ),
    );
  }
}
