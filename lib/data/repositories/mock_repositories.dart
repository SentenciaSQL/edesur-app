import '../../core/mock/catalogs.dart';
import '../../core/mock/demo_clock.dart';
import '../../core/mock/mock_seed.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/demo_exception.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../shared/labels.dart';
import '../datasources/mock_database.dart';

class MockAccountRepository implements AccountRepository {
  MockAccountRepository(this._db, this._api);
  final MockDatabase _db;
  final EdesurApiClient _api;

  @override
  Future<DemoSnapshot> updateProfile(UserProfile user) {
    _api.attachSession(_db.current.authenticated ? 'demo-session' : null);
    return _db.commit(_db.current.copyWith(user: user));
  }

  @override
  Future<DemoSnapshot> updatePassword(String password) {
    return _db.commit(_db.current.copyWith(password: password));
  }

  @override
  Future<DemoSnapshot> updatePrefs(NotificationPrefs prefs) {
    return _db.commit(_db.current.copyWith(prefs: prefs));
  }

  @override
  Future<DemoSnapshot> selectContract(String contractId) {
    final exists = _db.current.contracts.any((contract) => contract.id == contractId);
    if (!exists) throw DemoException('No encontramos ese contrato en la demostración.');
    return _db.commit(_db.current.copyWith(activeContractId: contractId));
  }

  @override
  Future<DemoSnapshot> updateContractAddress({
    required String contractId,
    required String address,
    required String sector,
  }) {
    final contracts = [
      for (final contract in _db.current.contracts)
        if (contract.id == contractId) contract.copyWith(address: address, sector: sector) else contract,
    ];
    return _db.commit(_db.current.copyWith(contracts: contracts));
  }
}

class MockBillingRepository implements BillingRepository {
  MockBillingRepository(this._db);
  final MockDatabase _db;

  @override
  Future<PaymentReceipt> registerPayment({
    required String invoiceId,
    required PaymentMethod method,
    String? cardLast4,
  }) async {
    final snapshot = _db.current;
    final index = snapshot.invoices.indexWhere((invoice) => invoice.id == invoiceId);
    if (index < 0) throw DemoException('No encontramos la factura.');
    final invoice = snapshot.invoices[index];
    final contract = snapshot.contracts.firstWhere((item) => item.id == invoice.contractId);
    final sequence = snapshot.receiptSequence + 1;
    final reference = switch (method) {
      PaymentMethod.card => 'TARJ-${cardLast4 ?? '0000'}-${sequence.toString().padLeft(4, '0')}',
      PaymentMethod.transfer => 'TRF-DEMO-$sequence',
      PaymentMethod.paymentPoint => 'PAG-DEMO-$sequence',
    };
    final receipt = PaymentReceipt(
      id: 'rcp-$sequence',
      number: 'CP-2026-${sequence.toString().padLeft(5, '0')}',
      invoiceId: invoice.id,
      invoiceNumber: invoice.number,
      contractNumber: contract.number,
      amount: invoice.total,
      method: method,
      paidAt: DemoClock.now,
      reference: reference,
      authorization: 'AUTH-DEMO-${900000 + sequence}',
    );
    final invoices = [...snapshot.invoices];
    invoices[index] = invoice.copyWith(
      status: InvoiceStatus.paid,
      paidAt: DemoClock.now,
      receiptId: receipt.id,
    );
    final notification = AppNotification(
      id: 'nt-pay-$sequence',
      kind: NotificationKind.paymentDone,
      title: 'Pago realizado',
      body: 'Se aplicó ${receipt.number} a la factura ${invoice.number}. Comprobante de demostración.',
      createdAt: DemoClock.now,
      read: false,
      route: '/comprobante/${receipt.id}',
    );
    await _db.commit(snapshot.copyWith(
      invoices: invoices,
      receipts: [receipt, ...snapshot.receipts],
      notifications: [notification, ...snapshot.notifications],
      receiptSequence: sequence,
    ));
    return receipt;
  }
}

class MockOutageRepository implements OutageRepository {
  MockOutageRepository(this._db);
  final MockDatabase _db;

  @override
  Future<OutageReport> create(OutageReport report) async {
    final snapshot = _db.current;
    final notification = AppNotification(
      id: 'nt-${report.id}',
      kind: NotificationKind.reportReceived,
      title: 'Reporte recibido',
      body: 'Registramos ${report.number}. El seguimiento de esta demostración queda en tu dispositivo.',
      createdAt: report.createdAt,
      read: false,
      route: '/averias/${report.id}',
    );
    await _db.commit(snapshot.copyWith(
      outages: [report, ...snapshot.outages],
      notifications: [notification, ...snapshot.notifications],
      reportSequence: snapshot.reportSequence + 1,
      mapIncidents: [
        MapIncident(
          id: 'map-${report.id}',
          title: report.number,
          sector: report.sector,
          circuit: snapshot.contracts.firstWhere((c) => c.id == report.contractId).circuit,
          kind: 'Reportada',
          status: 'Reportada',
          x: report.mapX,
          y: report.mapY,
          detail: report.description,
          critical: report.type == OutageType.noPower || report.type == OutageType.downedWires,
        ),
        ...snapshot.mapIncidents,
      ],
    ));
    return report;
  }

  @override
  Future<OutageReport> advance(String id) async {
    final snapshot = _db.current;
    final index = snapshot.outages.indexWhere((item) => item.id == id);
    if (index < 0) throw DemoException('No encontramos el reporte.');
    final current = snapshot.outages[index];
    final next = nextOutageStatus(current.status);
    if (next == null) throw DemoException('Este reporte ya está resuelto.');
    final event = StatusEvent(
      title: outageStatusLabel(next),
      detail: 'Avance de demostración aplicado manualmente para la presentación.',
      at: DemoClock.now.add(Duration(minutes: current.history.length * 12)),
    );
    final updated = current.copyWith(status: next, history: [...current.history, event]);
    final outages = [...snapshot.outages]..[index] = updated;
    final notification = AppNotification(
      id: 'nt-adv-${current.id}-${next.name}',
      kind: NotificationKind.outageUpdate,
      title: 'Actualización de avería',
      body: '${current.number} pasó a ${outageStatusLabel(next)}.',
      createdAt: event.at,
      read: false,
      route: '/averias/${current.id}',
    );
    await _db.commit(snapshot.copyWith(
      outages: outages,
      notifications: [notification, ...snapshot.notifications],
    ));
    return updated;
  }
}

class MockRequestRepository implements RequestRepository {
  MockRequestRepository(this._db);
  final MockDatabase _db;

  @override
  Future<ServiceRequest> create(ServiceRequest request) async {
    final snapshot = _db.current;
    final notification = AppNotification(
      id: 'nt-${request.id}',
      kind: NotificationKind.requestUpdate,
      title: 'Solicitud recibida',
      body: '${request.number} quedó registrada. El trámite es simulado.',
      createdAt: request.createdAt,
      read: false,
      route: '/solicitudes/${request.id}',
    );
    await _db.commit(snapshot.copyWith(
      requests: [request, ...snapshot.requests],
      notifications: [notification, ...snapshot.notifications],
      requestSequence: snapshot.requestSequence + 1,
    ));
    return request;
  }

  @override
  Future<ServiceRequest> advance(String id) async {
    final snapshot = _db.current;
    final index = snapshot.requests.indexWhere((item) => item.id == id);
    if (index < 0) throw DemoException('No encontramos la solicitud.');
    final current = snapshot.requests[index];
    final next = nextRequestStatus(current.status);
    if (next == null) throw DemoException('Esta solicitud ya no admite más avances.');
    final event = StatusEvent(
      title: requestStatusLabel(next),
      detail: 'El backoffice de demostración actualizó el trámite.',
      at: DemoClock.now.add(Duration(minutes: current.history.length * 20)),
    );
    final updated = current.copyWith(status: next, history: [...current.history, event]);
    final requests = [...snapshot.requests]..[index] = updated;
    await _db.commit(snapshot.copyWith(
      requests: requests,
      notifications: [
        AppNotification(
          id: 'nt-req-${current.id}-${next.name}',
          kind: NotificationKind.requestUpdate,
          title: 'Actualización de solicitud',
          body: '${current.number} pasó a ${requestStatusLabel(next)}.',
          createdAt: event.at,
          read: false,
          route: '/solicitudes/${current.id}',
        ),
        ...snapshot.notifications,
      ],
    ));
    return updated;
  }
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this._db);
  final MockDatabase _db;

  @override
  Future<void> markRead(String id) async {
    final snapshot = _db.current;
    final notifications = [
      for (final item in snapshot.notifications)
        if (item.id == id) item.copyWith(read: true) else item,
    ];
    await _db.commit(snapshot.copyWith(notifications: notifications));
  }

  @override
  Future<void> markAllRead() async {
    final snapshot = _db.current;
    await _db.commit(snapshot.copyWith(
      notifications: [for (final item in snapshot.notifications) item.copyWith(read: true)],
    ));
  }
}

class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository(this._db);
  final MockDatabase _db;
  final AssistantEngine _engine = AssistantEngine();

  @override
  Future<List<ChatMessage>> send(String text) async {
    final snapshot = _db.current;
    final reply = _engine.reply(text, snapshot);
    final now = DemoClock.now.add(Duration(seconds: snapshot.messages.length));
    final user = ChatMessage(
      id: 'msg-u-${snapshot.messages.length + 1}',
      fromUser: true,
      text: text.trim(),
      at: now,
    );
    final bot = ChatMessage(
      id: 'msg-b-${snapshot.messages.length + 2}',
      fromUser: false,
      text: reply.text,
      at: now.add(const Duration(seconds: 1)),
      actions: reply.actions,
    );
    final messages = [...snapshot.messages, user, bot];
    final trimmed = messages.length > 40 ? messages.sublist(messages.length - 40) : messages;
    await _db.commit(snapshot.copyWith(messages: trimmed));
    return [user, bot];
  }
}

class MockDemoRepository implements DemoControlsRepository {
  MockDemoRepository(this._db, this._api);
  final MockDatabase _db;
  final EdesurApiClient _api;

  @override
  Future<DemoSnapshot> applyScenario(DemoScenario scenario, {required bool keepAccount}) async {
    final current = _db.current;
    final seeded = MockSeed.build(scenario);
    final next = keepAccount
        ? seeded.copyWith(
            user: current.user,
            password: current.password,
            authenticated: current.authenticated,
            onboardingDone: true,
            prefs: current.prefs,
            lastAccess: current.lastAccess,
            activeContractId: current.activeContractId,
          )
        : seeded.copyWith(authenticated: current.authenticated, onboardingDone: true);
    final saved = await _db.commit(next);
    _api.attachSession(saved.authenticated ? 'demo-session' : null);
    return saved;
  }

  @override
  Future<DemoSnapshot> restoreInitial() async {
    _api.attachSession(null);
    final seeded = MockSeed.build(DemoScenario.normal);
    return _db.commit(seeded.copyWith(authenticated: false, onboardingDone: false, clearLastAccess: true));
  }
}
