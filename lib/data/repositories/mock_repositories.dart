import '../../core/constants/app_constants.dart';
import '../../core/mock/catalogs.dart';
import '../../core/mock/demo_clock.dart';
import '../../core/mock/mock_seed.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/demo_exception.dart';
import '../../core/utils/formatters.dart';
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

  @override
  Future<DemoSnapshot> updateAlias({required String contractId, required String alias}) {
    final exists = _db.current.contracts.any((contract) => contract.id == contractId);
    if (!exists) throw DemoException('No encontramos ese contrato.');
    final contracts = [
      for (final contract in _db.current.contracts)
        if (contract.id == contractId) contract.copyWith(alias: alias.trim()) else contract,
    ];
    return _db.commit(_db.current.copyWith(contracts: contracts));
  }

  @override
  Future<DemoSnapshot> linkContract({
    required ContractAccount contract,
    required List<Invoice> invoices,
    required List<ConsumptionMonth> months,
    required String alias,
  }) {
    final current = _db.current;
    if (current.contracts.any((item) => item.id == contract.id || item.number == contract.number)) {
      throw DemoException('Este contrato ya está vinculado a tu cuenta.');
    }
    final linked = contract.copyWith(alias: alias.trim());
    return _db.commit(current.copyWith(
      contracts: [...current.contracts, linked],
      invoices: [...current.invoices, ...invoices],
      consumption: [...current.consumption, ...months],
      activeContractId: current.contracts.isEmpty ? linked.id : current.activeContractId,
    ));
  }

  @override
  Future<DemoSnapshot> unlinkContract(String contractId) {
    final current = _db.current;
    ContractAccount? contract;
    for (final item in current.contracts) {
      if (item.id == contractId) contract = item;
    }
    if (contract == null) throw DemoException('No encontramos ese contrato.');
    if (contract.isOwnedBy(current.user.cedula)) {
      throw DemoException(AppConstants.cannotUnlinkOwnContract);
    }
    final contracts = current.contracts.where((item) => item.id != contractId).toList();
    final active = current.activeContractId == contractId
        ? (contracts.isEmpty ? '' : contracts.first.id)
        : current.activeContractId;
    return _db.commit(current.copyWith(
      contracts: contracts,
      activeContractId: active,
      invoices: current.invoices.where((invoice) => invoice.contractId != contractId).toList(),
      consumption: current.consumption.where((month) => month.contractId != contractId).toList(),
      outages: current.outages.where((report) => report.contractId != contractId).toList(),
      requests: current.requests.where((request) => request.contractId != contractId).toList(),
    ));
  }

  @override
  Future<DemoSnapshot> addCard(SavedCard card) {
    final current = _db.current;
    final makeDefault = current.cards.isEmpty || card.isDefault;
    final existing = [
      for (final item in current.cards) item.copyWith(isDefault: makeDefault ? false : item.isDefault),
    ];
    final saved = card.copyWith(isDefault: makeDefault);
    return _db.commit(current.copyWith(cards: [...existing, saved], cardSequence: current.cardSequence + 1));
  }

  @override
  Future<DemoSnapshot> removeCard({required String cardId, String? replacementDefaultId}) {
    final current = _db.current;
    SavedCard? card;
    for (final item in current.cards) {
      if (item.id == cardId) card = item;
    }
    if (card == null) throw DemoException('No encontramos esa tarjeta.');
    final others = current.cards.where((item) => item.id != cardId).toList();
    if (card.isDefault && others.isNotEmpty) {
      if (replacementDefaultId == null || !others.any((item) => item.id == replacementDefaultId)) {
        throw DemoException('Elige otra tarjeta como predeterminada antes de eliminar esta.');
      }
    }
    final cards = [
      for (final item in others) item.copyWith(isDefault: item.id == replacementDefaultId || (!card.isDefault && item.isDefault)),
    ];
    return _db.commit(current.copyWith(cards: cards));
  }

  @override
  Future<DemoSnapshot> setDefaultCard(String cardId) {
    final current = _db.current;
    if (!current.cards.any((card) => card.id == cardId)) {
      throw DemoException('No encontramos esa tarjeta.');
    }
    final cards = [for (final card in current.cards) card.copyWith(isDefault: card.id == cardId)];
    return _db.commit(current.copyWith(cards: cards));
  }
}

class MockBillingRepository implements BillingRepository {
  MockBillingRepository(this._db);
  final MockDatabase _db;

  @override
  Future<PaymentTransaction> settle({
    required List<String> invoiceIds,
    required PaymentMethod method,
    required PaymentStatus status,
    CardBrand? cardBrand,
    String? cardLast4,
    String? cardHolder,
    CardFunding? cardFunding,
    String? message,
  }) async {
    final snapshot = _db.current;
    final selected = <Invoice>[];
    for (final id in invoiceIds) {
      Invoice? invoice;
      for (final item in snapshot.invoices) {
        if (item.id == id) invoice = item;
      }
      if (invoice == null) throw DemoException('No encontramos la factura.');
      if (invoice.status == InvoiceStatus.paid) {
        throw DemoException('La factura ${invoice.number} ya está pagada.');
      }
      selected.add(invoice);
    }
    final now = DemoClock.now;
    final txSequence = snapshot.transactionSequence + 1;
    final txId = 'tx-$txSequence';
    var receiptSequence = snapshot.receiptSequence;
    final receipts = <PaymentReceipt>[];
    final lines = <PaymentLine>[];
    final invoices = [...snapshot.invoices];
    final approved = status == PaymentStatus.approved;
    for (final invoice in selected) {
      final contract = snapshot.contracts.firstWhere((item) => item.id == invoice.contractId);
      String? receiptId;
      if (approved) {
        receiptSequence += 1;
        receiptId = 'rcp-$receiptSequence';
        final reference = 'TARJ-${cardLast4 ?? '0000'}-${receiptSequence.toString().padLeft(4, '0')}';
        receipts.add(PaymentReceipt(
          id: receiptId,
          number: 'CP-2026-${receiptSequence.toString().padLeft(5, '0')}',
          invoiceId: invoice.id,
          invoiceNumber: invoice.number,
          contractNumber: contract.number,
          amount: invoice.total,
          method: method,
          paidAt: now,
          reference: reference,
          authorization: 'AUTH-DEMO-${900000 + receiptSequence}',
          transactionId: txId,
          cardBrand: cardBrand,
          cardLast4: cardLast4,
          cardFunding: cardFunding,
        ));
        final index = invoices.indexWhere((item) => item.id == invoice.id);
        invoices[index] = invoice.copyWith(status: InvoiceStatus.paid, paidAt: now, receiptId: receiptId);
      }
      lines.add(PaymentLine(
        contractId: contract.id,
        contractNumber: contract.number,
        alias: contract.alias,
        holderName: contract.holderName,
        address: contract.address,
        invoiceId: invoice.id,
        invoiceNumber: invoice.number,
        amount: invoice.total,
        receiptId: receiptId,
      ));
    }
    final total = round2(lines.fold<double>(0, (sum, line) => sum + line.amount));
    final transaction = PaymentTransaction(
      id: txId,
      number: 'TX-2026-${txSequence.toString().padLeft(5, '0')}',
      paidAt: now,
      method: method,
      status: status,
      total: total,
      lines: lines,
      cardBrand: cardBrand,
      cardLast4: cardLast4,
      cardHolder: cardHolder,
      cardFunding: cardFunding,
      message: message,
    );
    final notification = approved
        ? AppNotification(
            id: 'nt-pay-$txSequence',
            kind: NotificationKind.paymentDone,
            title: lines.length > 1 ? 'Pago múltiple realizado' : 'Pago realizado',
            body: lines.length > 1
                ? 'Se aplicó ${transaction.number} a ${lines.length} contratos. Comprobante simulado.'
                : 'Se aplicó ${transaction.number} a la factura ${lines.first.invoiceNumber}. Comprobante de demostración.',
            createdAt: now,
            read: false,
            route: '/transaccion/$txId',
          )
        : null;
    await _db.commit(snapshot.copyWith(
      invoices: invoices,
      receipts: [...receipts, ...snapshot.receipts],
      transactions: [transaction, ...snapshot.transactions],
      notifications: notification == null ? snapshot.notifications : [notification, ...snapshot.notifications],
      receiptSequence: receiptSequence,
      transactionSequence: txSequence,
    ));
    return transaction;
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
    final seeded = MockSeed.build(
      scenario,
      portfolio: keepAccount ? current.portfolio : PortfolioPreset.mixed,
    );
    final active = seeded.contracts.any((contract) => contract.id == current.activeContractId)
        ? current.activeContractId
        : seeded.activeContractId;
    final next = keepAccount
        ? seeded.copyWith(
            user: current.user,
            password: current.password,
            authenticated: current.authenticated,
            onboardingDone: true,
            prefs: current.prefs,
            lastAccess: current.lastAccess,
            cards: current.cards,
            cardSequence: current.cardSequence,
            activeContractId: active,
          )
        : seeded.copyWith(authenticated: current.authenticated, onboardingDone: true);
    final saved = await _db.commit(next);
    _api.attachSession(saved.authenticated ? 'demo-session' : null);
    return saved;
  }

  @override
  Future<DemoSnapshot> applyPortfolio(PortfolioPreset portfolio) async {
    final current = _db.current;
    final seeded = MockSeed.build(current.scenario, portfolio: portfolio);
    final saved = await _db.commit(seeded.copyWith(
      user: current.user,
      password: current.password,
      authenticated: current.authenticated,
      onboardingDone: true,
      prefs: current.prefs,
      lastAccess: current.lastAccess,
      cards: current.cards,
      cardSequence: current.cardSequence,
    ));
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
