import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _start();
  }

  Future<void> _start() async {
    try {
      await Future.wait([
        ref.read(appControllerProvider.future),
        Future<void>.delayed(const Duration(milliseconds: 1700)),
      ]);
      if (!mounted) return;
      final snapshot = ref.read(appControllerProvider).value;
      if (snapshot == null) return;
      if (snapshot.authenticated) {
        context.go(Routes.home);
      } else if (!snapshot.onboardingDone) {
        context.go(Routes.onboarding);
      } else {
        context.go(Routes.login);
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'No pudimos preparar la demostración.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EdesurLogo(height: 92),
                  const SizedBox(height: 18),
                  const Text(
                    'Móvil',
                    style: TextStyle(
                      color: AppColors.navyDeep,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_error == null)
                    const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.4))
                  else ...[
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        setState(() => _error = null);
                        ref.invalidate(appControllerProvider);
                        _start();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
