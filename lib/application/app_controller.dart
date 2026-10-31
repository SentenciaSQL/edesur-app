import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/billing/card_rules.dart';
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
  late PayInvoicesUseCase _pay;
  bool _paying = false;

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
    _pay = PayInvoicesUseCase(_billing);
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

  Future<void> updateAlias({required String contractId, required String alias}) async {
    await _account.updateAlias(contractId: contractId, alias: alias);
    await _commitFromDb();
  }

  ContractLookup lookupContract({
    required String number,
    required String cedula,
    required String holderName,
  }) {
    return const LinkContractUseCase().lookup(
      snapshot: _current,
      number: number,
      cedula: cedula,
      holderName: holderName,
    );
  }

  Future<void> linkContract({
    required ContractAccount contract,
    required List<Invoice> invoices,
    required List<ConsumptionMonth> months,
    required String alias,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await _account.linkContract(contract: contract, invoices: invoices, months: months, alias: alias);
    await _commitFromDb();
  }

  Future<void> unlinkContract(String contractId) async {
    const UnlinkContractUseCase().check(_current, contractId);
    await _account.unlinkContract(contractId);
    await _commitFromDb();
  }

  Future<CardDraft> prepareCard({
    required String number,
    required String holderName,
    required String expiry,
    required String cvv,
    required CardFunding funding,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const AddCardUseCase().prepare(
      number: number,
      holderName: holderName,
      expiry: expiry,
      cvv: cvv,
      funding: funding,
    );
  }

  Future<void> saveCard({
    required CardDraft draft,
    required bool makeDefault,
  }) async {
    final id = 'card-${_current.cardSequence}';
    await _account.addCard(SavedCard(
      id: id,
      brand: draft.brand,
      funding: draft.funding,
      last4: draft.last4,
      holderName: draft.holderName,
      expiryMonth: draft.expiryMonth,
      expiryYear: draft.expiryYear,
      isDefault: makeDefault || _current.cards.isEmpty,
    ));
    await _commitFromDb();
  }

  Future<void> removeCard({required String cardId, String? replacementDefaultId}) async {
    await _account.removeCard(cardId: cardId, replacementDefaultId: replacementDefaultId);
    await _commitFromDb();
  }

  Future<void> setDefaultCard(String cardId) async {
    await _account.setDefaultCard(cardId);
    await _commitFromDb();
  }

  Future<PaymentTransaction> payInvoices({
    required List<String> invoiceIds,
    required PaymentMethod method,
    String? cardNumber,
    String? expiry,
    String? holderName,
    String? savedCardId,
    bool forceFailure = false,
  }) async {
    if (_paying) {
      throw DemoException('Ya hay un pago simulado en proceso.');
    }
    _paying = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      SavedCard? saved;
      if (savedCardId != null) {
        for (final card in _current.cards) {
          if (card.id == savedCardId) saved = card;
        }
        if (saved == null) throw DemoException('No encontramos la tarjeta seleccionada.');
      }
      final transaction = await _pay.execute(
        snapshot: _current,
        invoiceIds: invoiceIds,
        method: method,
        forceFailure: forceFailure,
        cardNumber: cardNumber,
        expiry: expiry,
        holderName: holderName,
        savedCard: saved,
      );
      await _commitFromDb();
      return transaction;
    } finally {
      _paying = false;
    }
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

  Future<void> applyPortfolio(PortfolioPreset portfolio) async {
    await _demo.applyPortfolio(portfolio);
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
