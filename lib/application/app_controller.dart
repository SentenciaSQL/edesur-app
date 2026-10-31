import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/mock/demo_clock.dart';
import '../core/network/api_client.dart';
import '../core/utils/demo_exception.dart';
import '../data/datasources/local_store.dart';
import '../data/datasources/mock_database.dart';
import '../data/repositories/mock_repositories.dart';
import '../domain/entities/entities.dart';
import '../domain/usecases/usecases.dart';

class AppController extends AsyncNotifier<DemoSnapshot> {
  late MockDatabase _db;
  late EdesurApiClient _api;
  late MockAccountRepository _account;
  late MockBillingRepository _billing;
  late MockOutageRepository _outages;
  late MockRequestRepository _requests;
  late MockNotificationRepository _notifications;
  late MockAssistantRepository _assistant;
  late MockDemoRepository _demo;
  late PayInvoiceUseCase _pay;

  @override
  Future<DemoSnapshot> build() async {
    _db = ref.read(databaseProvider);
    _api = ref.read(apiClientProvider);
    _account = MockAccountRepository(_db, _api);
    _billing = MockBillingRepository(_db);
    _outages = MockOutageRepository(_db);
    _requests = MockRequestRepository(_db);
    _notifications = MockNotificationRepository(_db);
    _assistant = MockAssistantRepository(_db);
    _demo = MockDemoRepository(_db, _api);
    _pay = PayInvoiceUseCase(_billing);
    final snapshot = await _db.load();
    _api.attachSession(snapshot.authenticated ? 'demo-session' : null);
    return snapshot;
  }

  DemoSnapshot get _current => state.requireValue;

  Future<void> _commitFromDb() async {
    state = AsyncData(_db.current);
  }

  Future<void> completeOnboarding() async {
    await _db.commit(_current.copyWith(onboardingDone: true));
    await _commitFromDb();
  }

  Future<void> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    const SignInUseCase().check(_current, email, password);
    _api.attachSession('demo-session');
    await _db.commit(_current.copyWith(authenticated: true, lastAccess: DemoClock.now));
    await _commitFromDb();
  }

  Future<void> signInDemo() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _api.attachSession('demo-session');
    await _db.commit(_current.copyWith(
      authenticated: true,
      onboardingDone: true,
      lastAccess: DemoClock.now,
    ));
    await _commitFromDb();
  }

  Future<void> signInBiometric() async {
    if (!_current.prefs.biometricEnabled) {
      throw DemoException('Activa la biometría simulada en Seguridad.');
    }
    await signInDemo();
  }

  Future<void> register({
    required String name,
    required String cedula,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _api.attachSession('demo-session');
    await _db.commit(_current.copyWith(
      user: _current.user.copyWith(name: name, cedula: cedula, email: email, phone: phone),
      password: password,
      authenticated: true,
      onboardingDone: true,
      lastAccess: DemoClock.now,
    ));
    await _commitFromDb();
  }

  Future<void> verifyIdentity({
    required String cedula,
    required String contractNumber,
    required String otp,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    const VerifyIdentityUseCase().check(
      snapshot: _current,
      cedula: cedula,
      contractNumber: contractNumber,
      otp: otp,
    );
  }

  Future<void> resetPassword({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.trim().toLowerCase() != _current.user.email.toLowerCase()) {
      throw DemoException('No encontramos esa cuenta de demostración.');
    }
    await _db.commit(_current.copyWith(password: password));
    await _commitFromDb();
  }

  Future<void> signOut() async {
    _api.attachSession(null);
    await _db.commit(_current.copyWith(authenticated: false));
    await _commitFromDb();
  }

  Future<void> selectContract(String id) async {
    await _account.selectContract(id);
    await _commitFromDb();
  }

  Future<void> updateProfile(UserProfile user) async {
    await _account.updateProfile(user);
    await _commitFromDb();
  }

  Future<void> updateContractAddress({
    required String contractId,
    required String address,
    required String sector,
  }) async {
    await _account.updateContractAddress(contractId: contractId, address: address, sector: sector);
    await _commitFromDb();
  }

  Future<void> changePassword(String current, String next) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (current != _current.password) {
      throw DemoException('La contraseña actual no coincide.');
    }
    await _account.updatePassword(next);
    await _commitFromDb();
  }

  Future<void> updatePrefs(NotificationPrefs prefs) async {
    await _account.updatePrefs(prefs);
    await _commitFromDb();
  }

  Future<void> refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await _db.commit(_current);
    await _commitFromDb();
  }

  Future<PaymentReceipt> payInvoice({
    required String invoiceId,
    required PaymentMethod method,
    String? cardNumber,
    bool forceFailure = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final receipt = await _pay.execute(
      snapshot: _current,
      invoiceId: invoiceId,
      method: method,
      cardNumber: cardNumber,
      forceFailure: forceFailure,
    );
    await _commitFromDb();
    return receipt;
  }

  Future<OutageReport> submitOutage({
    required OutageType type,
    required String description,
    required String address,
    required String sector,
    required String reference,
    required double latitude,
    required double longitude,
    required double mapX,
    required double mapY,
    required bool demoPhoto,
    String? photoBase64,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final snapshot = _current;
    final sequence = snapshot.reportSequence + 1;
    final createdAt = DemoClock.now;
    final report = OutageReport(
      id: 'out-$sequence',
      number: 'RPT-2026-${sequence.toString().padLeft(4, '0')}',
      contractId: snapshot.activeContractId,
      type: type,
      description: description,
      address: address,
      sector: sector,
      reference: reference,
      latitude: latitude,
      longitude: longitude,
      mapX: mapX,
      mapY: mapY,
      demoPhoto: demoPhoto,
      photoBase64: photoBase64,
      createdAt: createdAt,
      status: OutageStatus.reported,
      history: [
        StatusEvent(
          title: 'Reportada',
          detail: 'El reporte de demostración quedó registrado en este dispositivo.',
          at: createdAt,
        ),
      ],
    );
    final saved = await _outages.create(report);
    await _commitFromDb();
    return saved;
  }

  Future<void> advanceOutage(String id) async {
    await _outages.advance(id);
    await _commitFromDb();
  }

  Future<ServiceRequest> submitRequest({
    required RequestType type,
    required String summary,
    required Map<String, String> details,
    required List<String> attachments,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final snapshot = _current;
    final sequence = snapshot.requestSequence + 1;
    final createdAt = DemoClock.now;
    final request = ServiceRequest(
      id: 'req-$sequence',
      number: 'SOL-2026-${sequence.toString().padLeft(4, '0')}',
      contractId: snapshot.activeContractId,
      type: type,
      summary: summary,
      details: details,
      attachments: attachments,
      createdAt: createdAt,
      status: RequestStatus.submitted,
      history: [
        StatusEvent(
          title: 'Enviada',
          detail: 'Trámite simulado. No se envió a un sistema externo.',
          at: createdAt,
        ),
      ],
    );
    final saved = await _requests.create(request);
    await _commitFromDb();
    return saved;
  }

  Future<void> advanceRequest(String id) async {
    await _requests.advance(id);
    await _commitFromDb();
  }

  Future<void> markNotificationRead(String id) async {
    await _notifications.markRead(id);
    await _commitFromDb();
  }

  Future<void> markAllNotificationsRead() async {
    await _notifications.markAllRead();
    await _commitFromDb();
  }

  Future<void> sendAssistantMessage(String text) async {
    await _assistant.send(text);
    await _commitFromDb();
  }

  Future<void> applyScenario(DemoScenario scenario) async {
    await _demo.applyScenario(scenario, keepAccount: true);
    await _commitFromDb();
  }

  Future<void> resetDemoData() async {
    await _demo.applyScenario(DemoScenario.normal, keepAccount: false);
    await _commitFromDb();
  }

  Future<void> restoreInitial() async {
    await _demo.restoreInitial();
    await _commitFromDb();
  }
}

final databaseProvider = Provider<MockDatabase>((ref) {
  return MockDatabase(ref.watch(localStoreProvider));
});

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final apiClientProvider = Provider<EdesurApiClient>((ref) => EdesurApiClient());

final appControllerProvider = AsyncNotifierProvider<AppController, DemoSnapshot>(AppController.new);
