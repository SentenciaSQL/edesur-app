import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _Page(
      icon: Icons.home_rounded,
      title: 'Gestiona tu servicio eléctrico desde cualquier lugar',
      body: 'Consulta tu contrato, el estado del suministro y los avisos de tu circuito en un solo lugar.',
    ),
    _Page(
      icon: Icons.receipt_long_rounded,
      title: 'Consulta y paga tus facturas fácilmente',
      body: 'Revisa el consumo, el detalle de los cargos y simula el pago sin salir de la aplicación.',
    ),
    _Page(
      icon: Icons.bolt_rounded,
      title: 'Reporta averías y mantente informado sobre tu servicio',
      body: 'Da seguimiento a tus reportes y consulta interrupciones programadas de tu sector.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(appControllerProvider.notifier).completeOnboarding();
    if (mounted) context.go(Routes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('Omitir')),
            ),
            const EdesurLogo(height: 54),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 148,
                          height: 148,
                          decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
                          child: Icon(page.icon, size: 72, color: AppColors.orange),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.navyDeep,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, height: 1.45, fontSize: 16),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.orange : AppColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: FilledButton(
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
                  }
                },
                child: Text(last ? 'Comenzar' : 'Continuar'),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Prototipo demostrativo', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page {
  const _Page({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}
