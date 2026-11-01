import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/card_formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../shared/labels.dart';
import '../../shared/widgets/common.dart';
import 'card_face.dart';

class PaymentSubmission {
  const PaymentSubmission({
    required this.summary,
    required this.forceFailure,
    this.savedCardId,
    this.cardNumber,
    this.expiry,
    this.holderName,
    this.funding,
  });

  final String summary;
  final bool forceFailure;
  final String? savedCardId;
  final String? cardNumber;
  final String? expiry;
  final String? holderName;
  final CardFunding? funding;

  PaymentMethod get method => PaymentMethod.card;
}

class SimulatedPaymentForm extends StatefulWidget {
  const SimulatedPaymentForm({super.key, required this.cards, required this.onSubmit});

  final List<SavedCard> cards;
  final ValueChanged<PaymentSubmission> onSubmit;

  @override
  State<SimulatedPaymentForm> createState() => SimulatedPaymentFormState();
}

class SimulatedPaymentFormState extends State<SimulatedPaymentForm> {
  final _form = GlobalKey<FormState>();
  bool _forceFailure = false;
  bool _newCard = false;
  String? _savedId;
  CardFunding _funding = CardFunding.credit;
  final _card = TextEditingController();
  final _name = TextEditingController(text: 'ANDRES FRIAS');
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');

  @override
  void initState() {
    super.initState();
    _savedId = _defaultId(widget.cards);
  }

  String? _defaultId(List<SavedCard> cards) {
    for (final card in cards) {
      if (card.isDefault) return card.id;
    }
    return cards.isEmpty ? null : cards.first.id;
  }

  SavedCard? get _selectedCard {
    for (final card in widget.cards) {
      if (card.id == _savedId) return card;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant SimulatedPaymentForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.cards.map((card) => card.id).toSet();
    final added = widget.cards.where((card) => !previous.contains(card.id)).toList();
    if (added.isNotEmpty) {
      _savedId = added.last.id;
      _newCard = false;
      return;
    }
    if (_savedId != null && !widget.cards.any((card) => card.id == _savedId)) {
      _savedId = _defaultId(widget.cards);
    }
  }

  @override
  void dispose() {
    _card.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  String get _summary {
    if (_newCard) {
      final digits = _card.text.replaceAll(RegExp(r'\D'), '');
      final tail = digits.length >= 4 ? digits.substring(digits.length - 4) : 'nueva';
      return '${cardFundingLabel(_funding)} · •••• $tail';
    }
    final card = _selectedCard;
    if (card == null) return 'la tarjeta seleccionada';
    return cardChargeLabel(brand: card.brand, funding: card.funding, last4: card.last4);
  }

  void _submit() {
    if (_newCard) {
      if (!_form.currentState!.validate()) return;
    } else if (_savedId == null) {
      return;
    }
    widget.onSubmit(PaymentSubmission(
      summary: _summary,
      forceFailure: _forceFailure,
      savedCardId: _newCard ? null : _savedId,
      cardNumber: _newCard ? _card.text : null,
      expiry: _newCard ? _expiry.text : null,
      holderName: _newCard ? _name.text : null,
      funding: _newCard ? _funding : _selectedCard?.funding,
    ));
  }

  Future<void> _addCard() async {
    await context.push(Routes.addCard);
  }

  @override
  Widget build(BuildContext context) {
    final hasCards = widget.cards.isNotEmpty;
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tarjeta', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'El pago simulado usa una tarjeta de crédito o débito.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          if (!hasCards)
            EmptyState(
              icon: Icons.credit_card_off_rounded,
              title: 'Sin tarjetas registradas',
              message: 'Agrega una tarjeta de crédito o débito para continuar este pago.',
              action: FilledButton(onPressed: _addCard, child: const Text('Agregar tarjeta')),
            )
          else ...[
            const Text('Toca una tarjeta para seleccionarla o cambiar la elección.'),
            const SizedBox(height: 10),
            for (final card in widget.cards) ...[
              CardFace(
                card: card,
                selected: !_newCard && _savedId == card.id,
                onTap: () => setState(() {
                  _newCard = false;
                  _savedId = card.id;
                }),
              ),
              const SizedBox(height: 10),
            ],
          ],
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (hasCards)
                OutlinedButton(onPressed: _addCard, child: const Text('Agregar tarjeta')),
              TextButton(
                onPressed: () => context.push(Routes.paymentMethods),
                child: const Text('Gestionar métodos de pago'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => setState(() => _newCard = !_newCard),
            child: Text(_newCard ? 'Volver a las tarjetas guardadas' : 'Usar otra tarjeta de prueba'),
          ),
          if (_newCard) ...[
            const SizedBox(height: 4),
            SegmentedButton<CardFunding>(
              segments: const [
                ButtonSegment(value: CardFunding.credit, label: Text('Crédito')),
                ButtonSegment(value: CardFunding.debit, label: Text('Débito')),
              ],
              selected: {_funding},
              onSelectionChanged: (value) => setState(() => _funding = value.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _card,
              decoration: const InputDecoration(labelText: 'Número de tarjeta de prueba'),
              keyboardType: TextInputType.number,
              inputFormatters: [CardNumberFormatter()],
              onChanged: (_) => setState(() {}),
              validator: Validators.cardNumber,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre en la tarjeta'),
              textCapitalization: TextCapitalization.words,
              inputFormatters: [CardHolderFormatter()],
              validator: Validators.cardHolder,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiry,
                    decoration: const InputDecoration(labelText: 'Vence', hintText: 'MM/AA'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [ExpiryFormatter()],
                    validator: Validators.expiry,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvv,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: const [CvvFormatter()],
                    validator: Validators.cvv,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'El número y el CVV solo se usan en esta simulación y no se guardan. Éxito: 4111 1111 1111 1111. Rechazo: 4111 1131 1111 0002. Error: 4111 1161 1111 0005. Un vencimiento anterior a 10/26 no se acepta. La American Express guardada con vencimiento 01/26 simula una tarjeta vencida.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _forceFailure,
            onChanged: (value) => setState(() => _forceFailure = value),
            title: const Text('Forzar rechazo (demostración)'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: hasCards || _newCard ? _submit : null,
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}
