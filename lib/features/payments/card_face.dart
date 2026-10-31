import 'package:flutter/material.dart';

import '../../core/mock/demo_clock.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/entities.dart';
import '../../shared/labels.dart';

class CardFace extends StatelessWidget {
  const CardFace({super.key, required this.card, this.selected = false, this.onTap});

  final SavedCard card;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = switch (card.brand) {
      CardBrand.visa => const [Color(0xFF0F1D41), Color(0xFF083367)],
      CardBrand.mastercard => const [Color(0xFF3D1218), Color(0xFFB42318)],
      CardBrand.amex => const [Color(0xFF0E3B2E), Color(0xFF1C7C45)],
    };
    final expired = card.isExpiredAt(DemoClock.now);
    final face = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: selected ? Border.all(color: AppColors.orange, width: 3) : null,
        boxShadow: const [BoxShadow(color: Color(0x240F1D41), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(cardBrandLabel(card.brand), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Text(cardFundingLabel(card.funding), style: const TextStyle(color: Colors.white70)),
              if (card.isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
                  child: const Text('Predeterminada', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          Text('••••  ••••  ••••  ${card.last4}', style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text(card.holderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              Text(
                '${card.expiryMonth.toString().padLeft(2, '0')}/${(card.expiryYear % 100).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          if (expired) ...[
            const SizedBox(height: 8),
            const Text('Vencida en la demostración', style: TextStyle(color: Color(0xFFFFE08A), fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
    if (onTap == null) return face;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: face));
  }
}
