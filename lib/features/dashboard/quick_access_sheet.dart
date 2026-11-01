import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';

class QuickAccessButton extends StatelessWidget {
  const QuickAccessButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Accesos rápidos',
      onPressed: () => showQuickAccessSheet(context),
      icon: const Icon(Icons.grid_view_rounded, color: AppColors.navy),
    );
  }
}

void showQuickAccessSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: const SingleChildScrollView(child: QuickAccessSheet()),
      );
    },
  );
}

class QuickAccessSheet extends StatelessWidget {
  const QuickAccessSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accesos rápidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navyDeep),
          ),
          const SizedBox(height: 14),
          const _PayOnlineTile(),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 118,
            ),
            itemBuilder: (context, index) => _QuickTile(item: _items[index]),
          ),
        ],
      ),
    );
  }
}

class _PayOnlineTile extends StatelessWidget {
  const _PayOnlineTile();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orange,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context, Routes.multiPay),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                child: const Icon(Icons.payments_rounded, color: AppColors.orangeDark, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pago en Línea',
                      style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Paga uno o varios contratos con tarjeta',
                      style: TextStyle(color: AppColors.white, fontSize: 13, height: 1.2),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem({required this.icon, required this.label, required this.route, this.switchTab = false});

  final IconData icon;
  final String label;
  final String route;
  final bool switchTab;
}

const _items = [
  _QuickItem(icon: Icons.description_outlined, label: 'Mis contratos', route: Routes.contracts),
  _QuickItem(icon: Icons.add_circle_outline, label: 'Agregar contrato', route: Routes.addContract),
  _QuickItem(icon: Icons.credit_card_outlined, label: 'Métodos de pago', route: Routes.paymentMethods),
  _QuickItem(icon: Icons.receipt_long_outlined, label: 'Historial de pagos', route: Routes.paymentHistory),
  _QuickItem(icon: Icons.assignment_outlined, label: 'Nueva solicitud', route: Routes.requests, switchTab: true),
  _QuickItem(icon: Icons.location_on_outlined, label: 'Oficinas y centros de atención', route: Routes.offices),
  _QuickItem(icon: Icons.support_agent_rounded, label: 'Asistente virtual', route: Routes.assistant),
  _QuickItem(icon: Icons.help_outline_rounded, label: 'Preguntas frecuentes', route: Routes.faq),
];

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context, item.route, switchTab: item.switchTab),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
                child: Icon(item.icon, color: AppColors.navy, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.15, fontWeight: FontWeight.w600, color: AppColors.navyDeep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _open(BuildContext context, String route, {bool switchTab = false}) {
  final router = GoRouter.of(context);
  Navigator.pop(context);
  if (switchTab) {
    router.go(route);
  } else {
    router.push(route);
  }
}
