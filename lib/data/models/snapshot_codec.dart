import 'dart:convert';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/entities.dart';

class SnapshotCodec {
  static String encode(DemoSnapshot snapshot) => jsonEncode(_snapshot(snapshot));

  static DemoSnapshot decode(String raw) {
    final json = jsonDecode(raw);
    if (json is! Map) {
      throw const FormatException('La instantánea de demostración no es válida.');
    }
    final map = Map<String, dynamic>.from(json);
    if (map['schema'] != AppConstants.schemaVersion) {
      throw const FormatException('La versión de los datos de demostración cambió.');
    }
    return _readSnapshot(map);
  }

  static Map<String, dynamic> _snapshot(DemoSnapshot s) => {
        'schema': AppConstants.schemaVersion,
        'user': _user(s.user),
        'password': s.password,
        'authenticated': s.authenticated,
        'onboardingDone': s.onboardingDone,
        'contracts': s.contracts.map(_contract).toList(),
        'activeContractId': s.activeContractId,
        'invoices': s.invoices.map(_invoice).toList(),
        'consumption': s.consumption.map(_month).toList(),
        'outages': s.outages.map(_outage).toList(),
        'requests': s.requests.map(_request).toList(),
        'notifications': s.notifications.map(_notification).toList(),
        'announcements': s.announcements.map(_announcement).toList(),
        'mapIncidents': s.mapIncidents.map(_incident).toList(),
        'receipts': s.receipts.map(_receipt).toList(),
        'transactions': s.transactions.map(_transaction).toList(),
        'cards': s.cards.map(_card).toList(),
        'messages': s.messages.map(_message).toList(),
        'prefs': _prefs(s.prefs),
        'scenario': s.scenario.name,
        'reportSequence': s.reportSequence,
        'requestSequence': s.requestSequence,
        'receiptSequence': s.receiptSequence,
        'transactionSequence': s.transactionSequence,
        'cardSequence': s.cardSequence,
        'portfolio': s.portfolio.name,
        'lastUpdated': s.lastUpdated.toIso8601String(),
        'lastAccess': s.lastAccess?.toIso8601String(),
      };

  static DemoSnapshot _readSnapshot(Map<String, dynamic> map) {
    return DemoSnapshot(
      user: _readUser(_map(map['user'])),
      password: map['password'] as String,
      authenticated: map['authenticated'] as bool,
      onboardingDone: map['onboardingDone'] as bool,
      contracts: _list(map['contracts']).map((item) => _readContract(_map(item))).toList(),
      activeContractId: map['activeContractId'] as String,
      invoices: _list(map['invoices']).map((item) => _readInvoice(_map(item))).toList(),
      consumption: _list(map['consumption']).map((item) => _readMonth(_map(item))).toList(),
      outages: _list(map['outages']).map((item) => _readOutage(_map(item))).toList(),
      requests: _list(map['requests']).map((item) => _readRequest(_map(item))).toList(),
      notifications: _list(map['notifications']).map((item) => _readNotification(_map(item))).toList(),
      announcements: _list(map['announcements']).map((item) => _readAnnouncement(_map(item))).toList(),
      mapIncidents: _list(map['mapIncidents']).map((item) => _readIncident(_map(item))).toList(),
      receipts: _list(map['receipts']).map((item) => _readReceipt(_map(item))).toList(),
      transactions: _list(map['transactions']).map((item) => _readTransaction(_map(item))).toList(),
      cards: _list(map['cards']).map((item) => _readCard(_map(item))).toList(),
      messages: _list(map['messages']).map((item) => _readMessage(_map(item))).toList(),
      prefs: _readPrefs(_map(map['prefs'])),
      scenario: _enum(DemoScenario.values, map['scenario']),
      reportSequence: _int(map['reportSequence']),
      requestSequence: _int(map['requestSequence']),
      receiptSequence: _int(map['receiptSequence']),
      transactionSequence: _int(map['transactionSequence']),
      cardSequence: _int(map['cardSequence']),
      portfolio: _enum(PortfolioPreset.values, map['portfolio']),
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      lastAccess: map['lastAccess'] == null ? null : DateTime.parse(map['lastAccess'] as String),
    );
  }

  static Map<String, dynamic> _user(UserProfile u) => {
        'name': u.name,
        'cedula': u.cedula,
        'email': u.email,
        'phone': u.phone,
        'clientType': u.clientType,
      };

  static UserProfile _readUser(Map<String, dynamic> m) => UserProfile(
        name: m['name'] as String,
        cedula: m['cedula'] as String,
        email: m['email'] as String,
        phone: m['phone'] as String,
        clientType: m['clientType'] as String,
      );

  static Map<String, dynamic> _contract(ContractAccount c) => {
        'id': c.id,
        'number': c.number,
        'holderName': c.holderName,
        'cedula': c.cedula,
        'address': c.address,
        'sector': c.sector,
        'municipality': c.municipality,
        'province': c.province,
        'clientType': c.clientType,
        'tariffCode': c.tariffCode,
        'tariffName': c.tariffName,
        'circuit': c.circuit,
        'meter': c.meter,
        'serviceStatus': c.serviceStatus.name,
        'since': c.since.toIso8601String(),
        'commercial': c.commercial,
        'mapX': c.mapX,
        'mapY': c.mapY,
        'latitude': c.latitude,
        'longitude': c.longitude,
        'alias': c.alias,
      };

  static ContractAccount _readContract(Map<String, dynamic> m) => ContractAccount(
        id: m['id'] as String,
        number: m['number'] as String,
        holderName: m['holderName'] as String,
        cedula: m['cedula'] as String,
        address: m['address'] as String,
        sector: m['sector'] as String,
        municipality: m['municipality'] as String,
        province: m['province'] as String? ?? '',
        clientType: m['clientType'] as String,
        tariffCode: m['tariffCode'] as String,
        tariffName: m['tariffName'] as String,
        circuit: m['circuit'] as String,
        meter: m['meter'] as String,
        serviceStatus: _enum(ServiceStatus.values, m['serviceStatus']),
        since: DateTime.parse(m['since'] as String),
        commercial: m['commercial'] as bool,
        mapX: _double(m['mapX']),
        mapY: _double(m['mapY']),
        latitude: _double(m['latitude']),
        longitude: _double(m['longitude']),
        alias: m['alias'] as String? ?? '',
      );

  static Map<String, dynamic> _invoice(Invoice i) => {
        'id': i.id,
        'number': i.number,
        'contractId': i.contractId,
        'periodStart': i.periodStart.toIso8601String(),
        'periodEnd': i.periodEnd.toIso8601String(),
        'issueDate': i.issueDate.toIso8601String(),
        'dueDate': i.dueDate.toIso8601String(),
        'previousReading': i.previousReading,
        'currentReading': i.currentReading,
        'kwh': i.kwh,
        'tariffName': i.tariffName,
        'lines': i.lines
            .map((line) => {
                  'label': line.label,
                  'quantity': line.quantity,
                  'rate': line.rate,
                  'amount': line.amount,
                })
            .toList(),
        'subtotal': i.subtotal,
        'tax': i.tax,
        'total': i.total,
        'status': i.status.name,
        'paidAt': i.paidAt?.toIso8601String(),
        'receiptId': i.receiptId,
      };

  static Invoice _readInvoice(Map<String, dynamic> m) => Invoice(
        id: m['id'] as String,
        number: m['number'] as String,
        contractId: m['contractId'] as String,
        periodStart: DateTime.parse(m['periodStart'] as String),
        periodEnd: DateTime.parse(m['periodEnd'] as String),
        issueDate: DateTime.parse(m['issueDate'] as String),
        dueDate: DateTime.parse(m['dueDate'] as String),
        previousReading: _double(m['previousReading']),
        currentReading: _double(m['currentReading']),
        kwh: _double(m['kwh']),
        tariffName: m['tariffName'] as String,
        lines: _list(m['lines']).map((item) {
          final line = _map(item);
          return InvoiceLine(
            label: line['label'] as String,
            quantity: _double(line['quantity']),
            rate: _double(line['rate']),
            amount: _double(line['amount']),
          );
        }).toList(),
        subtotal: _double(m['subtotal']),
        tax: _double(m['tax']),
        total: _double(m['total']),
        status: _enum(InvoiceStatus.values, m['status']),
        paidAt: m['paidAt'] == null ? null : DateTime.parse(m['paidAt'] as String),
        receiptId: m['receiptId'] as String?,
      );

  static Map<String, dynamic> _month(ConsumptionMonth m) => {
        'contractId': m.contractId,
        'month': m.month.toIso8601String(),
        'kwh': m.kwh,
        'daily': m.daily,
      };

  static ConsumptionMonth _readMonth(Map<String, dynamic> m) => ConsumptionMonth(
        contractId: m['contractId'] as String,
        month: DateTime.parse(m['month'] as String),
        kwh: _double(m['kwh']),
        daily: _list(m['daily']).map(_double).toList(),
      );

  static Map<String, dynamic> _event(StatusEvent e) => {
        'title': e.title,
        'detail': e.detail,
        'at': e.at.toIso8601String(),
      };

  static StatusEvent _readEvent(Map<String, dynamic> m) => StatusEvent(
        title: m['title'] as String,
        detail: m['detail'] as String,
        at: DateTime.parse(m['at'] as String),
      );

  static Map<String, dynamic> _outage(OutageReport o) => {
        'id': o.id,
        'number': o.number,
        'contractId': o.contractId,
        'type': o.type.name,
        'description': o.description,
        'address': o.address,
        'sector': o.sector,
        'reference': o.reference,
        'latitude': o.latitude,
        'longitude': o.longitude,
        'mapX': o.mapX,
        'mapY': o.mapY,
        'demoPhoto': o.demoPhoto,
        'photoBase64': o.photoBase64,
        'createdAt': o.createdAt.toIso8601String(),
        'status': o.status.name,
        'history': o.history.map(_event).toList(),
      };

  static OutageReport _readOutage(Map<String, dynamic> m) => OutageReport(
        id: m['id'] as String,
        number: m['number'] as String,
        contractId: m['contractId'] as String,
        type: _enum(OutageType.values, m['type']),
        description: m['description'] as String,
        address: m['address'] as String,
        sector: m['sector'] as String,
        reference: m['reference'] as String,
        latitude: _double(m['latitude']),
        longitude: _double(m['longitude']),
        mapX: _double(m['mapX']),
        mapY: _double(m['mapY']),
        demoPhoto: m['demoPhoto'] as bool,
        photoBase64: m['photoBase64'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        status: _enum(OutageStatus.values, m['status']),
        history: _list(m['history']).map((item) => _readEvent(_map(item))).toList(),
      );

  static Map<String, dynamic> _request(ServiceRequest r) => {
        'id': r.id,
        'number': r.number,
        'contractId': r.contractId,
        'type': r.type.name,
        'summary': r.summary,
        'details': r.details,
        'attachments': r.attachments,
        'createdAt': r.createdAt.toIso8601String(),
        'status': r.status.name,
        'history': r.history.map(_event).toList(),
      };

  static ServiceRequest _readRequest(Map<String, dynamic> m) => ServiceRequest(
        id: m['id'] as String,
        number: m['number'] as String,
        contractId: m['contractId'] as String,
        type: _enum(RequestType.values, m['type']),
        summary: m['summary'] as String,
        details: Map<String, String>.from((m['details'] as Map).map((key, value) => MapEntry('$key', '$value'))),
        attachments: _list(m['attachments']).map((item) => item as String).toList(),
        createdAt: DateTime.parse(m['createdAt'] as String),
        status: _enum(RequestStatus.values, m['status']),
        history: _list(m['history']).map((item) => _readEvent(_map(item))).toList(),
      );

  static Map<String, dynamic> _notification(AppNotification n) => {
        'id': n.id,
        'kind': n.kind.name,
        'title': n.title,
        'body': n.body,
        'createdAt': n.createdAt.toIso8601String(),
        'read': n.read,
        'route': n.route,
      };

  static AppNotification _readNotification(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        kind: _enum(NotificationKind.values, m['kind']),
        title: m['title'] as String,
        body: m['body'] as String,
        createdAt: DateTime.parse(m['createdAt'] as String),
        read: m['read'] as bool,
        route: m['route'] as String?,
      );

  static Map<String, dynamic> _announcement(Announcement a) => {
        'id': a.id,
        'title': a.title,
        'body': a.body,
        'category': a.category,
        'date': a.date.toIso8601String(),
        'critical': a.critical,
      };

  static Announcement _readAnnouncement(Map<String, dynamic> m) => Announcement(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        category: m['category'] as String,
        date: DateTime.parse(m['date'] as String),
        critical: m['critical'] as bool,
      );

  static Map<String, dynamic> _incident(MapIncident i) => {
        'id': i.id,
        'title': i.title,
        'sector': i.sector,
        'circuit': i.circuit,
        'kind': i.kind,
        'status': i.status,
        'x': i.x,
        'y': i.y,
        'detail': i.detail,
        'critical': i.critical,
      };

  static MapIncident _readIncident(Map<String, dynamic> m) => MapIncident(
        id: m['id'] as String,
        title: m['title'] as String,
        sector: m['sector'] as String,
        circuit: m['circuit'] as String,
        kind: m['kind'] as String,
        status: m['status'] as String,
        x: _double(m['x']),
        y: _double(m['y']),
        detail: m['detail'] as String,
        critical: m['critical'] as bool,
      );

  static Map<String, dynamic> _receipt(PaymentReceipt r) => {
        'id': r.id,
        'number': r.number,
        'invoiceId': r.invoiceId,
        'invoiceNumber': r.invoiceNumber,
        'contractNumber': r.contractNumber,
        'amount': r.amount,
        'method': r.method.name,
        'paidAt': r.paidAt.toIso8601String(),
        'reference': r.reference,
        'authorization': r.authorization,
        'transactionId': r.transactionId,
        'cardBrand': r.cardBrand?.name,
        'cardLast4': r.cardLast4,
        'cardFunding': r.cardFunding?.name,
      };

  static PaymentReceipt _readReceipt(Map<String, dynamic> m) => PaymentReceipt(
        id: m['id'] as String,
        number: m['number'] as String,
        invoiceId: m['invoiceId'] as String,
        invoiceNumber: m['invoiceNumber'] as String,
        contractNumber: m['contractNumber'] as String,
        amount: _double(m['amount']),
        method: _enum(PaymentMethod.values, m['method']),
        paidAt: DateTime.parse(m['paidAt'] as String),
        reference: m['reference'] as String,
        authorization: m['authorization'] as String,
        transactionId: m['transactionId'] as String?,
        cardBrand: m['cardBrand'] == null ? null : _enum(CardBrand.values, m['cardBrand']),
        cardLast4: m['cardLast4'] as String?,
        cardFunding: m['cardFunding'] == null ? null : _enum(CardFunding.values, m['cardFunding']),
      );

  static Map<String, dynamic> _card(SavedCard c) => {
        'id': c.id,
        'brand': c.brand.name,
        'funding': c.funding.name,
        'last4': c.last4,
        'holderName': c.holderName,
        'expiryMonth': c.expiryMonth,
        'expiryYear': c.expiryYear,
        'isDefault': c.isDefault,
      };

  static SavedCard _readCard(Map<String, dynamic> m) => SavedCard(
        id: m['id'] as String,
        brand: _enum(CardBrand.values, m['brand']),
        funding: _enum(CardFunding.values, m['funding']),
        last4: m['last4'] as String,
        holderName: m['holderName'] as String,
        expiryMonth: _int(m['expiryMonth']),
        expiryYear: _int(m['expiryYear']),
        isDefault: m['isDefault'] as bool,
      );

  static Map<String, dynamic> _line(PaymentLine line) => {
        'contractId': line.contractId,
        'contractNumber': line.contractNumber,
        'alias': line.alias,
        'holderName': line.holderName,
        'address': line.address,
        'invoiceId': line.invoiceId,
        'invoiceNumber': line.invoiceNumber,
        'amount': line.amount,
        'receiptId': line.receiptId,
      };

  static PaymentLine _readLine(Map<String, dynamic> m) => PaymentLine(
        contractId: m['contractId'] as String,
        contractNumber: m['contractNumber'] as String,
        alias: m['alias'] as String? ?? '',
        holderName: m['holderName'] as String,
        address: m['address'] as String,
        invoiceId: m['invoiceId'] as String,
        invoiceNumber: m['invoiceNumber'] as String,
        amount: _double(m['amount']),
        receiptId: m['receiptId'] as String?,
      );

  static Map<String, dynamic> _transaction(PaymentTransaction t) => {
        'id': t.id,
        'number': t.number,
        'paidAt': t.paidAt.toIso8601String(),
        'method': t.method.name,
        'status': t.status.name,
        'total': t.total,
        'lines': t.lines.map(_line).toList(),
        'cardBrand': t.cardBrand?.name,
        'cardLast4': t.cardLast4,
        'cardHolder': t.cardHolder,
        'cardFunding': t.cardFunding?.name,
        'message': t.message,
      };

  static PaymentTransaction _readTransaction(Map<String, dynamic> m) => PaymentTransaction(
        id: m['id'] as String,
        number: m['number'] as String,
        paidAt: DateTime.parse(m['paidAt'] as String),
        method: _enum(PaymentMethod.values, m['method']),
        status: _enum(PaymentStatus.values, m['status']),
        total: _double(m['total']),
        lines: _list(m['lines']).map((item) => _readLine(_map(item))).toList(),
        cardBrand: m['cardBrand'] == null ? null : _enum(CardBrand.values, m['cardBrand']),
        cardLast4: m['cardLast4'] as String?,
        cardHolder: m['cardHolder'] as String?,
        cardFunding: m['cardFunding'] == null ? null : _enum(CardFunding.values, m['cardFunding']),
        message: m['message'] as String?,
      );

  static Map<String, dynamic> _message(ChatMessage m) => {
        'id': m.id,
        'fromUser': m.fromUser,
        'text': m.text,
        'at': m.at.toIso8601String(),
        'actions': m.actions.map((action) => {'label': action.label, 'link': action.link.name}).toList(),
      };

  static ChatMessage _readMessage(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        fromUser: m['fromUser'] as bool,
        text: m['text'] as String,
        at: DateTime.parse(m['at'] as String),
        actions: _list(m['actions']).map((item) {
          final action = _map(item);
          return ChatAction(
            label: action['label'] as String,
            link: _enum(AssistantLink.values, action['link']),
          );
        }).toList(),
      );

  static Map<String, dynamic> _prefs(NotificationPrefs p) => {
        'invoiceAlerts': p.invoiceAlerts,
        'dueReminders': p.dueReminders,
        'outageAlerts': p.outageAlerts,
        'requestUpdates': p.requestUpdates,
        'announcements': p.announcements,
        'emailChannel': p.emailChannel,
        'smsChannel': p.smsChannel,
        'biometricEnabled': p.biometricEnabled,
      };

  static NotificationPrefs _readPrefs(Map<String, dynamic> m) => NotificationPrefs(
        invoiceAlerts: m['invoiceAlerts'] as bool,
        dueReminders: m['dueReminders'] as bool,
        outageAlerts: m['outageAlerts'] as bool,
        requestUpdates: m['requestUpdates'] as bool,
        announcements: m['announcements'] as bool,
        emailChannel: m['emailChannel'] as bool,
        smsChannel: m['smsChannel'] as bool,
        biometricEnabled: m['biometricEnabled'] as bool,
      );

  static Map<String, dynamic> _map(Object? value) => Map<String, dynamic>.from(value as Map);
  static List<dynamic> _list(Object? value) => value as List<dynamic>;
  static double _double(Object? value) => (value as num).toDouble();
  static int _int(Object? value) => (value as num).toInt();

  static T _enum<T extends Enum>(List<T> values, Object? name) {
    return values.firstWhere((value) => value.name == name);
  }
}
