import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../shared/labels.dart';
import 'card_face.dart';

class PaymentSubmission {
  const PaymentSubmission({
    required this.method,
    required this.forceFailure,
    this.savedCardId,
    this.cardNumber,
    this.expiry,
    this.holderName,
  });

  final PaymentMethod method;
  final bool forceFailure;
  final String? savedCardId;
  final String? cardNumber;
  final String? expiry;
  final String? holderName;
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
  PaymentMethod _method = PaymentMethod.card;
  bool _forceFailure = false;
  bool _newCard = false;
  String? _savedId;
  final _card = TextEditingController();
  final _name = TextEditingController(text: 'ANDRES FRIAS');
  final _expiry = TextEditingController(text: '12/28');
  final _cvv = TextEditingController(text: '123');

  @override
  void initState() {
    super.initState();
    _savedId = _defaultId;
    _newCard = widget.cards.isEmpty;
  }

  String? get _defaultId {
    for (final card in widget.cards) {
      if (card.isDefault) return card.id;
    }
    return widget.cards.isEmpty ? null : widget.cards.first.id;
  }

  @override
  void dispose() {
    _card.dispose();
    _name.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  void _submit() {
    if (_method == PaymentMethod.card && _newCard && !_form.currentState!.validate()) return;
    if (_method == PaymentMethod.card && !_newCard && _savedId == null) return;
    widget.onSubmit(PaymentSubmission(
      method: _method,
      forceFailure: _forceFailure,
      savedCardId: _method == PaymentMethod.card && !_newCard ? _savedId : null,
      cardNumber: _newCard ? _card.text : null,
      expiry: _newCard ? _expiry.text : null,
      holderName: _newCard ? _name.text : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Método de pago', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          RadioGroup<PaymentMethod>(
            groupValue: _method,
            onChanged: (value) => setState(() => _method = value ?? _method),
            child: Column(
              children: [
                for (final method in PaymentMethod.values)
                  RadioListTile<PaymentMethod>(
                    value: method,
                    title: Text(paymentMethodLabel(method)),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          if (_method == PaymentMethod.card) ...[
            if (widget.cards.isNotEmpty) ...[
              const SizedBox(height: 8),
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
              TextButton(
                onPressed: () => setState(() => _newCard = true),
                child: Text(_newCard ? 'Usando otra tarjeta de prueba' : 'Usar otra tarjeta de prueba'),
              ),
            ],
            if (_newCard) ...[
              TextFormField(
                controller: _card,
                decoration: const InputDecoration(labelText: 'Número de tarjeta de prueba'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s]'))],
                validator: Validators.cardNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre en la tarjeta'),
                validator: (value) => Validators.required(value, label: 'El nombre'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiry,
                      decoration: const InputDecoration(labelText: 'Vence', hintText: 'MM/AA'),
                      validator: Validators.expiry,
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
              const SizedBox(height: 8),
              const Text(
                'El número y el CVV solo se usan en esta simulación y no se guardan. Éxito: 4111 1111 1111 1111. Rechazo: termina en 0002. Error: termina en 0005. Vencida: 01/26.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ],
          if (_method == PaymentMethod.transfer)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Se generará una referencia de transferencia simulada. No se conecta a un banco.'),
            ),
          if (_method == PaymentMethod.paymentPoint)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Se simula que un punto de pago ficticio ya recibió el dinero.'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _forceFailure,
            onChanged: (value) => setState(() => _forceFailure = value),
            title: const Text('Forzar rechazo (demostración)'),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: const Text('Continuar')),
        ],
      ),
    );
  }
}
