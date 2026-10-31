import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/app_controller.dart';
import '../../core/mock/catalogs.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../../shared/widgets/common.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SnapshotBody(
      builder: (context, snapshot) {
        final contract = snapshot.activeContractOrNull;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.navy,
                    child: Text(firstName(snapshot.user.name).substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(snapshot.user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.navyDeep)),
                        Text(snapshot.user.email, style: const TextStyle(color: AppColors.muted)),
                        Text(contract == null ? 'Sin contrato vinculado' : 'Contrato ${contract.number}', style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _tile(context, Icons.swap_horiz, 'Cambiar contrato', () => showContractSwitcher(context, ref)),
            _tile(context, Icons.badge_outlined, 'Datos personales', () => context.push(Routes.personal)),
            _tile(context, Icons.home_work_outlined, 'Contratos', () => context.push(Routes.contracts)),
            _tile(context, Icons.credit_card_outlined, 'Métodos de pago', () => context.push(Routes.paymentMethods)),
            _tile(context, Icons.receipt_outlined, 'Historial de pagos', () => context.push(Routes.paymentHistory)),
            _tile(context, Icons.notifications_outlined, 'Preferencias de notificación', () => context.push(Routes.preferences)),
            _tile(context, Icons.lock_outline, 'Seguridad', () => context.push(Routes.security)),
            _tile(context, Icons.help_outline, 'Preguntas frecuentes', () => context.push(Routes.faq)),
            _tile(context, Icons.store_mall_directory_outlined, 'Centros de atención', () => context.push(Routes.offices)),
            _tile(context, Icons.call_outlined, 'Canales de contacto', () => context.push(Routes.contact)),
            _tile(context, Icons.support_agent, 'Asistente', () => context.push(Routes.assistant)),
            _tile(context, Icons.tune, 'Modo demostración', () => context.push(Routes.demo)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final ok = await showConfirmSheet(context: context, title: 'Cerrar sesión', message: 'Volverás a la pantalla de acceso. Los datos de demostración se conservan en el dispositivo.');
                if (!ok || !context.mounted) return;
                await ref.read(appControllerProvider.notifier).signOut();
                if (context.mounted) context.go(Routes.login);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.navy),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class PersonalDataScreen extends ConsumerStatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  ConsumerState<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends ConsumerState<PersonalDataScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  bool _ready = false;

  @override
  void dispose() {
    if (_ready) {
      _name.dispose();
      _phone.dispose();
      _email.dispose();
    }
    super.dispose();
  }

  void _init(UserProfile user) {
    if (_ready) return;
    _name = TextEditingController(text: user.name);
    _phone = TextEditingController(text: user.phone);
    _email = TextEditingController(text: user.email);
    _ready = true;
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotBody(
      builder: (context, snapshot) {
        _init(snapshot.user);
        final contract = snapshot.activeContractOrNull;
        return FeatureScaffold(
          title: 'Datos personales',
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => Validators.required(v, label: 'El nombre')),
                const SizedBox(height: 12),
                TextFormField(initialValue: snapshot.user.cedula, decoration: const InputDecoration(labelText: 'Cédula'), readOnly: true),
                const SizedBox(height: 12),
                TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Correo'), validator: Validators.email),
                const SizedBox(height: 12),
                TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Teléfono'), validator: Validators.phone),
                const SizedBox(height: 12),
                const Text('La cédula se modifica solo con el trámite de actualización. El cambio de contacto es local.', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suministro activo', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(contract == null ? 'No hay un contrato vinculado.' : contract.address),
                      if (contract != null) ...[
                        Text(contract.sector),
                        Text('Contrato ${contract.number} · ${contract.clientType}'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (!_form.currentState!.validate()) return;
                    await runDemoAction(context, () async {
                      await ref.read(appControllerProvider.notifier).updateProfile(
                            snapshot.user.copyWith(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim()),
                          );
                      if (context.mounted) showAppMessage(context, 'Datos de contacto actualizados en este dispositivo.');
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).value;
    return FeatureScaffold(
      title: 'Seguridad',
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (snapshot?.lastAccess != null) Text('Último acceso de demostración: ${formatDateTime(snapshot!.lastAccess!)}'),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Biometría simulada'),
              subtitle: const Text('Muestra un acceso biométrico en el inicio. No usa el sensor del dispositivo.'),
              value: snapshot?.prefs.biometricEnabled ?? false,
              onChanged: snapshot == null
                  ? null
                  : (value) => ref.read(appControllerProvider.notifier).updatePrefs(snapshot.prefs.copyWith(biometricEnabled: value)),
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _current, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña actual'), validator: (v) => Validators.required(v, label: 'La contraseña actual')),
            const SizedBox(height: 12),
            TextFormField(controller: _next, obscureText: true, decoration: const InputDecoration(labelText: 'Nueva contraseña'), validator: Validators.password),
            const SizedBox(height: 12),
            TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar'), validator: (v) => Validators.match(v, _next.text)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                await runDemoAction(context, () async {
                  await ref.read(appControllerProvider.notifier).changePassword(_current.text, _next.text);
                  if (context.mounted) showAppMessage(context, 'Contraseña de demostración actualizada.');
                });
              },
              child: const Text('Cambiar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appControllerProvider).value?.prefs;
    if (prefs == null) return const LoadingView();
    return FeatureScaffold(
      title: 'Notificaciones',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Estas preferencias solo afectan la demostración local. No hay notificaciones push reales.'),
          _switch(ref, prefs, 'Facturas disponibles', prefs.invoiceAlerts, (p, v) => p.copyWith(invoiceAlerts: v)),
          _switch(ref, prefs, 'Recordatorios de vencimiento', prefs.dueReminders, (p, v) => p.copyWith(dueReminders: v)),
          _switch(ref, prefs, 'Averías e interrupciones', prefs.outageAlerts, (p, v) => p.copyWith(outageAlerts: v)),
          _switch(ref, prefs, 'Solicitudes', prefs.requestUpdates, (p, v) => p.copyWith(requestUpdates: v)),
          _switch(ref, prefs, 'Comunicados', prefs.announcements, (p, v) => p.copyWith(announcements: v)),
          _switch(ref, prefs, 'Canal de correo', prefs.emailChannel, (p, v) => p.copyWith(emailChannel: v)),
          _switch(ref, prefs, 'Canal de SMS', prefs.smsChannel, (p, v) => p.copyWith(smsChannel: v)),
        ],
      ),
    );
  }

  Widget _switch(WidgetRef ref, NotificationPrefs prefs, String label, bool value, NotificationPrefs Function(NotificationPrefs, bool) update) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (next) => ref.read(appControllerProvider.notifier).updatePrefs(update(prefs, next)),
    );
  }
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Preguntas frecuentes',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in Catalogs.faqs)
            Card(
              child: ExpansionTile(
                title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(item.answer)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Contacto',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Canales publicados en edesur.com.do', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
          const SizedBox(height: 8),
          _channel(context, 'Centro de atención telefónica', '809-683-9393', Uri.parse('tel:8096839393')),
          _channel(context, 'Teléfono', '(809) 683-9292', Uri.parse('tel:8096839292')),
          _channel(context, 'Correo', 'info@edesur.com.do', Uri.parse('mailto:info@edesur.com.do')),
          _channel(context, 'Emergencias', '911', Uri.parse('tel:911')),
          const SizedBox(height: 16),
          const Text('Oficinas de la demostración', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('El directorio interno usa direcciones ficticias. No son sucursales reales.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => context.push(Routes.offices), child: const Text('Ver centros de atención')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => context.push(Routes.assistant), child: const Text('Hablar con el asistente')),
        ],
      ),
    );
  }

  Widget _channel(BuildContext context, String label, String value, Uri uri) {
    return AppCard(
      onTap: () async {
        final launched = await launchUrl(uri);
        if (!launched && context.mounted) showAppMessage(context, value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
        ],
      ),
    );
  }
}

