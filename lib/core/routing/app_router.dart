import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../features/assistant/assistant_screen.dart';
import '../../features/authentication/auth_screens.dart';
import '../../features/billing/billing_screens.dart';
import '../../features/consumption/consumption_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/demo/demo_mode_screen.dart';
import '../../features/notifications/notification_screens.dart';
import '../../features/offices/office_screens.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/outages/outage_screens.dart';
import '../../features/payments/payment_screen.dart';
import '../../features/profile/profile_screens.dart';
import '../../features/requests/request_screens.dart';
import '../../features/shell/main_shell.dart';
import 'routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(appControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final async = ref.read(appControllerProvider);
      final location = state.matchedLocation;
      if (async.isLoading || async.hasError) {
        return location == Routes.splash ? null : Routes.splash;
      }
      final snapshot = async.requireValue;
      final auth = location.startsWith('/auth');
      final intro = location == Routes.splash || location == Routes.onboarding;
      final inApp = !auth && !intro;
      if (!snapshot.authenticated && inApp) return Routes.login;
      if (snapshot.authenticated && auth) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.splash),
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.recover, builder: (_, _) => const RecoverScreen()),
      GoRoute(
        path: Routes.verify,
        builder: (_, state) => VerifyScreen(extra: state.extra),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.invoices, builder: (_, _) => const InvoicesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.outages, builder: (_, _) => const OutagesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.requests, builder: (_, _) => const RequestsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen())]),
        ],
      ),
      GoRoute(path: '/facturas/:id', builder: (_, state) => InvoiceDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/pagar/:id', builder: (_, state) => PaymentScreen(invoiceId: state.pathParameters['id']!)),
      GoRoute(path: '/comprobante/:id', builder: (_, state) => ReceiptScreen(id: state.pathParameters['id']!)),
      GoRoute(path: Routes.consumption, builder: (_, _) => const ConsumptionScreen()),
      GoRoute(path: Routes.reportOutage, builder: (_, _) => const ReportOutageScreen()),
      GoRoute(path: '/averias/:id', builder: (_, state) => OutageDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: Routes.map, builder: (_, _) => const OutageMapScreen()),
      GoRoute(path: '/tramite/:type', builder: (_, state) => RequestFormScreen(typeName: state.pathParameters['type']!)),
      GoRoute(path: '/solicitudes/:id', builder: (_, state) => RequestDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: Routes.assistant, builder: (_, _) => const AssistantScreen()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/notificaciones/:id', builder: (_, state) => NotificationDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: Routes.offices, builder: (_, _) => const OfficesScreen()),
      GoRoute(path: '/oficinas/:id', builder: (_, state) => OfficeDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: Routes.personal, builder: (_, _) => const PersonalDataScreen()),
      GoRoute(path: Routes.contracts, builder: (_, _) => const ContractsScreen()),
      GoRoute(path: Routes.security, builder: (_, _) => const SecurityScreen()),
      GoRoute(path: Routes.preferences, builder: (_, _) => const PreferencesScreen()),
      GoRoute(path: Routes.faq, builder: (_, _) => const FaqScreen()),
      GoRoute(path: Routes.contact, builder: (_, _) => const ContactScreen()),
      GoRoute(path: Routes.demo, builder: (_, _) => const DemoModeScreen()),
    ],
  );
});
