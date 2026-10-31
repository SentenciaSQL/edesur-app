import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/app_controller.dart';
import '../../core/billing/card_rules.dart';
import '../../core/mock/demo_clock.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/demo_exception.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import 'card_face.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        return FeatureScaffold(
          title: 'Métodos de pago',
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Solo guardamos marca, últimos cuatro dígitos, nombre, vencimiento y tipo. El número completo y el CVV no se almacenan.'),
              const SizedBox(height: 12),
              if (snapshot.cards.isEmpty)
                const EmptyState(
                  title: 'Sin tarjetas',
                  message: 'Agrega una tarjeta de prueba para usarla en los pagos simulados.',
                  icon: Icons.credit_card_off_rounded,
                )
              else
                for (final card in snapshot.cards) ...[
                  CardFace(card: card),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!card.isDefault)
                        TextButton(
                          onPressed: () => ref.read(appControllerProvider.notifier).setDefaultCard(card.id),
                          child: const Text('Hacer predeterminada'),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _remove(context, ref, snapshot, card),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              FilledButton(
                onPressed: () => _openAdd(context),
                child: const Text('Agregar tarjeta'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAdd(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCardScreen()));
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, DemoSnapshot snapshot, SavedCard card) async {
    final others = snapshot.cards.where((item) => item.id != card.id).toList();
    String? replacement;
    if (card.isDefault && others.isNotEmpty) {
      replacement = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Elige la nueva predeterminada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Vas a eliminar ${cardBrandLabel(card.brand)} •••• ${card.last4}.'),
              for (final item in others)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${cardBrandLabel(item.brand)} •••• ${item.last4}'),
                  subtitle: Text(cardFundingLabel(item.funding)),
                  onTap: () => Navigator.pop(context, item.id),
                ),
            ],
          ),
        ),
      );
      if (replacement == null || !context.mounted) return;
    }
    final confirmed = await showConfirmSheet(
      context: context,
      title: 'Eliminar tarjeta',
      message: 'Se quitará ${cardBrandLabel(card.brand)} terminada en ${card.last4}. Es un cambio local de la demostración.',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(appControllerProvider.notifier).removeCard(cardId: card.id, replacementDefaultId: replacement);
      if (context.mounted) showAppMessage(context, 'Tarjeta eliminada de este dispositivo.');
    } on DemoException catch (error) {
      if (context.mounted) showAppMessage(context, error.message, error: true);
    }
  }
}

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController(text: 'ANDRES FRIAS');
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  CardFunding _funding = CardFunding.credit;
  bool _default = false;
  CardDraft? _draft;
  bool _busy = false;

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final draft = await ref.read(appControllerProvider.notifier).prepareCard(
            number: _number.text,
            holderName: _name.text,
            expiry: _expiry.text,
            cvv: _cvv.text,
            funding: _funding,
          );
      _number.clear();
      _cvv.clear();
      if (mounted) setState(() => _draft = draft);
    } on DemoException catch (error) {
      if (mounted) showAppMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(appControllerProvider.notifier).saveCard(draft: draft, makeDefault: _default);
      if (mounted) {
        showAppMessage(context, 'Tarjeta •••• ${draft.last4} guardada. El número completo y el CVV se descartaron.');
        Navigator.pop(context);
      }
    } on DemoException catch (error) {
      if (mounted) showAppMessage(context, error.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return FeatureScaffold(
      title: 'Agregar tarjeta',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (draft == null)
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Usa solo números de prueba. Visa empieza en 4, Mastercard en 51–55 y American Express en 34 o 37.'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _number,
                    decoration: const InputDecoration(labelText: 'Número de tarjeta'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s]'))],
                    validator: (value) {
                      final format = Validators.cardNumber(value);
                      if (format != null) return format;
                      if (CardRules.detectBrand(value ?? '') == null) return 'No reconocemos la marca de este número de prueba.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Nombre del titular'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) => Validators.required(value, label: 'El nombre'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiry,
                          decoration: const InputDecoration(labelText: 'Vencimiento', hintText: 'MM/AA'),
                          validator: Validators.expiryFormat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cvv,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          obscureText: true,
                          validator: Validators.cvv,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CardFunding>(
                    initialValue: _funding,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final funding in CardFunding.values)
                        DropdownMenuItem(value: funding, child: Text(cardFundingLabel(funding))),
                    ],
                    onChanged: (value) => setState(() => _funding = value ?? _funding),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _default,
                    onChanged: (value) => setState(() => _default = value),
                    title: const Text('Establecer como predeterminada'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _busy ? null : _preview, child: Text(_busy ? 'Validando...' : 'Validar tarjeta')),
                ],
              ),
            )
          else ...[
            CardFace(
              card: SavedCard(
                id: 'preview',
                brand: draft.brand,
                funding: draft.funding,
                last4: draft.last4,
                holderName: draft.holderName,
                expiryMonth: draft.expiryMonth,
                expiryYear: draft.expiryYear,
                isDefault: _default,
              ),
            ),
            const SizedBox(height: 12),
            if (draft.isExpiredAt(DemoClock.now))
              const Text('Esta tarjeta está vencida. Se puede guardar para demostrar un pago rechazado por vencimiento.', style: TextStyle(color: AppColors.amber)),
            const SizedBox(height: 8),
            const Text('Confirmamos la simulación. Al guardar se descartan el número completo y el CVV.'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _default,
              onChanged: (value) => setState(() => _default = value),
              title: const Text('Establecer como predeterminada'),
            ),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Guardar tarjeta')),
            TextButton(onPressed: () => setState(() => _draft = null), child: const Text('Corregir datos')),
          ],
        ],
      ),
    );
  }
}
