import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/app_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/common.dart';

class RegisterDraft {
  const RegisterDraft({
    required this.name,
    required this.cedula,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String name;
  final String cedula;
  final String email;
  final String phone;
  final String password;
}

class RecoveryDraft {
  const RecoveryDraft(this.email);
  final String email;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await runDemoAction(context, () async {
      await ref.read(appControllerProvider.notifier).signIn(_email.text, _password.text);
      if (mounted) context.go(Routes.home);
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _demo() async {
    setState(() => _loading = true);
    await runDemoAction(context, () async {
      await ref.read(appControllerProvider.notifier).signInDemo();
      if (mounted) context.go(Routes.home);
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).value;
    final email = snapshot?.user.email ?? AppConstants.demoEmail;
    final password = snapshot?.password ?? AppConstants.demoPassword;
    final biometric = snapshot?.prefs.biometricEnabled ?? false;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            const EdesurLogo(height: 64),
            const SizedBox(height: 20),
            Text('Bienvenido', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
            const SizedBox(height: 6),
            const Text('Ingresa para gestionar tu servicio eléctrico.', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Ingresa la contraseña.' : null,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.push(Routes.recover), child: const Text('Recuperar contraseña')),
            ),
            FilledButton(
              onPressed: _loading ? null : _signIn,
              child: Text(_loading ? 'Ingresando...' : 'Iniciar sesión'),
            ),
            if (biometric) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => runDemoAction(context, () async {
                          await ref.read(appControllerProvider.notifier).signInBiometric();
                          if (context.mounted) context.go(Routes.home);
                        }),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Entrar con biometría (simulado)'),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _loading ? null : () => context.push(Routes.register), child: const Text('Crear cuenta')),
            const SizedBox(height: 16),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('o')), Expanded(child: Divider())]),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _loading ? null : _demo,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
              child: const Text('Entrar en modo demostración'),
            ),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.tint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Credenciales de demostración', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
                  const SizedBox(height: 6),
                  Text('Correo: $email'),
                  Text('Contraseña: $password'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _email.text = email;
                      _password.text = password;
                    },
                    child: const Text('Rellenar credenciales'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Prototipo demostrativo. No valida contra los sistemas de EDESUR.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cedula = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _cedula.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Crear cuenta',
      showBanner: false,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('La cuenta queda guardada solo en este dispositivo y se asocia a los suministros de demostración.'),
            const SizedBox(height: 16),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo'), validator: (v) => Validators.required(v, label: 'El nombre')),
            const SizedBox(height: 12),
            TextFormField(controller: _cedula, decoration: const InputDecoration(labelText: 'Cédula', hintText: '000-0000000-0'), validator: Validators.cedula),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Correo'), validator: Validators.email),
            const SizedBox(height: 12),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Teléfono'), validator: Validators.phone),
            const SizedBox(height: 12),
            TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña'), validator: Validators.password),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
              validator: (value) => Validators.match(value, _password.text, label: 'La confirmación'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (value) => setState(() => _accepted = value ?? false),
              title: const Text('Acepto las condiciones de uso del prototipo'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (!_accepted) {
                  showAppMessage(context, 'Debes aceptar las condiciones del prototipo.', error: true);
                  return;
                }
                if (!_form.currentState!.validate()) return;
                context.push(
                  Routes.verify,
                  extra: RegisterDraft(
                    name: _name.text.trim(),
                    cedula: _cedula.text.trim(),
                    email: _email.text.trim(),
                    phone: _phone.text.trim(),
                    password: _password.text,
                  ),
                );
              },
              child: const Text('Continuar a verificación'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Recuperar contraseña',
      showBanner: false,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Te enviaremos un código simulado. En esta demostración el código siempre es 123456.'),
            const SizedBox(height: 16),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Correo'), validator: Validators.email),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                context.push(Routes.verify, extra: RecoveryDraft(_email.text.trim()));
              },
              child: const Text('Enviar código'),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, this.extra});
  final Object? extra;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _form = GlobalKey<FormState>();
  final _cedula = TextEditingController();
  final _contract = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  bool get _isRecovery => widget.extra is RecoveryDraft;
  bool get _isRegister => widget.extra is RegisterDraft;

  @override
  void initState() {
    super.initState();
    final draft = widget.extra;
    if (draft is RegisterDraft) {
      _cedula.text = draft.cedula;
    }
  }

  @override
  void dispose() {
    _cedula.dispose();
    _contract.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final notifier = ref.read(appControllerProvider.notifier);
    await runDemoAction(context, () async {
      await notifier.verifyIdentity(cedula: _cedula.text, contractNumber: _contract.text, otp: _otp.text);
      final extra = widget.extra;
      if (extra is RegisterDraft) {
        await notifier.register(
          name: extra.name,
          cedula: extra.cedula,
          email: extra.email,
          phone: extra.phone,
          password: extra.password,
        );
        if (mounted) context.go(Routes.home);
      } else if (extra is RecoveryDraft) {
        await notifier.resetPassword(email: extra.email, password: _password.text);
        if (mounted) {
          showAppMessage(context, 'Contraseña de demostración actualizada.');
          context.go(Routes.login);
        }
      } else if (mounted) {
        showAppMessage(context, 'Identidad verificada en la demostración.');
        context.pop();
      }
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Verificación de identidad',
      showBanner: false,
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Compara la cédula y el contrato con los datos de demostración. El código simulado es 123456.'),
            const SizedBox(height: 16),
            TextFormField(controller: _cedula, decoration: const InputDecoration(labelText: 'Cédula', hintText: '001-0000000-0'), validator: Validators.cedula),
            const SizedBox(height: 12),
            TextFormField(controller: _contract, decoration: const InputDecoration(labelText: 'Número de contrato', hintText: '1002345678'), validator: (v) => Validators.required(v, label: 'El contrato')),
            const SizedBox(height: 12),
            TextFormField(controller: _otp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Código de verificación', hintText: '123456'), validator: Validators.otp),
            if (_isRecovery) ...[
              const SizedBox(height: 12),
              TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Nueva contraseña'), validator: Validators.password),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                validator: (value) => Validators.match(value, _password.text),
              ),
            ],
            if (_isRegister) ...[
              const SizedBox(height: 12),
              const Text('Al verificar, se creará la cuenta de demostración y entrarás a la aplicación.'),
            ],
            const SizedBox(height: 18),
            FilledButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Verificando...' : 'Verificar')),
          ],
        ),
      ),
    );
  }
}
