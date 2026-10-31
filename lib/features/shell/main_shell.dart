import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SimulatedBanner(),
          if (shell.currentIndex != 0)
            Material(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        const ['Inicio', 'Facturas', 'Averías', 'Solicitudes', 'Mi cuenta'][shell.currentIndex],
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navyDeep),
                      ),
                    ),
                    const AssistantButton(),
                  ],
                ),
              ),
            ),
          Expanded(child: shell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Facturas'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Averías'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Solicitudes'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Mi cuenta'),
        ],
      ),
    );
  }
}
