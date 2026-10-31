enum ServiceStatus { active, interrupted, suspended }

enum InvoiceStatus { paid, pending, overdue }

enum PaymentMethod { card, transfer, paymentPoint }

enum CardBrand { visa, mastercard, amex }

enum CardFunding { credit, debit }

enum PaymentStatus { approved, rejected, expiredCard, processingError }

enum PortfolioPreset { mixed, singleOwn, severalOwn, ownAndThird, thirdOnly }

enum LinkLookupResult { found, missing, alreadyLinked, holderMismatch }

enum OutageType {
  noPower,
  frequentInterruptions,
  lowVoltage,
  highVoltage,
  fluctuations,
  downedWires,
  damagedPole,
  other,
}

enum OutageStatus { reported, received, inReview, crewAssigned, inProgress, resolved }

enum RequestType {
  newSupply,
  changeHolder,
  reconnection,
  meterReview,
  technicalInspection,
  paymentCertificate,
  contractCertificate,
  invoiceDuplicate,
  updatePersonalData,
  billingComplaint,
}

enum RequestStatus { submitted, received, inReview, inProgress, completed, rejected }

enum NotificationKind {
  invoiceReady,
  dueReminder,
  paymentDone,
  reportReceived,
  outageUpdate,
  plannedOutage,
  announcement,
  requestUpdate,
}

enum DemoScenario { normal, interruption, overdue, outageInProgress }

enum AssistantLink {
  pay,
  invoices,
  consumption,
  reportOutage,
  requests,
  offices,
  contact,
  notifications,
  map,
  contracts,
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.cedula,
    required this.email,
    required this.phone,
    required this.clientType,
  });

  final String name;
  final String cedula;
  final String email;
  final String phone;
  final String clientType;

  UserProfile copyWith({
    String? name,
    String? cedula,
    String? email,
    String? phone,
    String? clientType,
  }) {
    return UserProfile(
      name: name ?? this.name,
      cedula: cedula ?? this.cedula,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      clientType: clientType ?? this.clientType,
    );
  }
}

class ContractAccount {
  const ContractAccount({
    required this.id,
    required this.number,
    required this.holderName,
    required this.cedula,
    required this.address,
    required this.sector,
    required this.municipality,
    this.province = '',
    required this.clientType,
    required this.tariffCode,
    required this.tariffName,
    required this.circuit,
    required this.meter,
    required this.serviceStatus,
    required this.since,
    required this.commercial,
    required this.mapX,
    required this.mapY,
    required this.latitude,
    required this.longitude,
    this.alias = '',
  });

  final String id;
  final String number;
  final String alias;
  final String holderName;
  final String cedula;
  final String address;
  final String sector;
  final String municipality;
  final String province;
  final String clientType;
  final String tariffCode;
  final String tariffName;
  final String circuit;
  final String meter;
  final ServiceStatus serviceStatus;
  final DateTime since;
  final bool commercial;
  final double mapX;
  final double mapY;
  final double latitude;
  final double longitude;

  String get displayName => alias.trim().isEmpty ? number : alias.trim();

  bool isOwnedBy(String cedula) {
    final own = cedula.replaceAll(RegExp(r'\D'), '');
    final holder = this.cedula.replaceAll(RegExp(r'\D'), '');
    return own.isNotEmpty && own == holder;
  }

  ContractAccount copyWith({
    ServiceStatus? serviceStatus,
    String? address,
    String? sector,
    String? alias,
  }) {
    return ContractAccount(
      id: id,
      number: number,
      alias: alias ?? this.alias,
      holderName: holderName,
      cedula: cedula,
      address: address ?? this.address,
      sector: sector ?? this.sector,
      municipality: municipality,
      province: province,
      clientType: clientType,
      tariffCode: tariffCode,
      tariffName: tariffName,
      circuit: circuit,
      meter: meter,
      serviceStatus: serviceStatus ?? this.serviceStatus,
      since: since,
      commercial: commercial,
      mapX: mapX,
      mapY: mapY,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class InvoiceLine {
  const InvoiceLine({
    required this.label,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  final String label;
  final double quantity;
  final double rate;
  final double amount;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.contractId,
    required this.periodStart,
    required this.periodEnd,
    required this.issueDate,
    required this.dueDate,
    required this.previousReading,
    required this.currentReading,
    required this.kwh,
    required this.tariffName,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paidAt,
    this.receiptId,
  });

  final String id;
  final String number;
  final String contractId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime issueDate;
  final DateTime dueDate;
  final double previousReading;
  final double currentReading;
  final double kwh;
  final String tariffName;
  final List<InvoiceLine> lines;
  final double subtotal;
  final double tax;
  final double total;
  final InvoiceStatus status;
  final DateTime? paidAt;
  final String? receiptId;

  Invoice copyWith({
    InvoiceStatus? status,
    DateTime? dueDate,
    DateTime? paidAt,
    String? receiptId,
    bool clearPayment = false,
  }) {
    return Invoice(
      id: id,
      number: number,
      contractId: contractId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      issueDate: issueDate,
      dueDate: dueDate ?? this.dueDate,
      previousReading: previousReading,
      currentReading: currentReading,
      kwh: kwh,
      tariffName: tariffName,
      lines: lines,
      subtotal: subtotal,
      tax: tax,
      total: total,
      status: status ?? this.status,
      paidAt: clearPayment ? null : paidAt ?? this.paidAt,
      receiptId: clearPayment ? null : receiptId ?? this.receiptId,
    );
  }
}

class ConsumptionMonth {
  const ConsumptionMonth({
    required this.contractId,
    required this.month,
    required this.kwh,
    required this.daily,
  });

  final String contractId;
  final DateTime month;
  final double kwh;
  final List<double> daily;
}

class StatusEvent {
  const StatusEvent({required this.title, required this.detail, required this.at});

  final String title;
  final String detail;
  final DateTime at;
}

class OutageReport {
  const OutageReport({
    required this.id,
    required this.number,
    required this.contractId,
    required this.type,
    required this.description,
    required this.address,
    required this.sector,
    required this.reference,
    required this.latitude,
    required this.longitude,
    required this.mapX,
    required this.mapY,
    required this.demoPhoto,
    required this.createdAt,
    required this.status,
    required this.history,
    this.photoBase64,
  });

  final String id;
  final String number;
  final String contractId;
  final OutageType type;
  final String description;
  final String address;
  final String sector;
  final String reference;
  final double latitude;
  final double longitude;
  final double mapX;
  final double mapY;
  final bool demoPhoto;
  final String? photoBase64;
  final DateTime createdAt;
  final OutageStatus status;
  final List<StatusEvent> history;

  OutageReport copyWith({OutageStatus? status, List<StatusEvent>? history}) {
    return OutageReport(
      id: id,
      number: number,
      contractId: contractId,
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
      status: status ?? this.status,
      history: history ?? this.history,
    );
  }
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.number,
    required this.contractId,
    required this.type,
    required this.summary,
    required this.details,
    required this.attachments,
    required this.createdAt,
    required this.status,
    required this.history,
  });

  final String id;
  final String number;
  final String contractId;
  final RequestType type;
  final String summary;
  final Map<String, String> details;
  final List<String> attachments;
  final DateTime createdAt;
  final RequestStatus status;
  final List<StatusEvent> history;

  ServiceRequest copyWith({RequestStatus? status, List<StatusEvent>? history}) {
    return ServiceRequest(
      id: id,
      number: number,
      contractId: contractId,
      type: type,
      summary: summary,
      details: details,
      attachments: attachments,
      createdAt: createdAt,
      status: status ?? this.status,
      history: history ?? this.history,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.route,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? route;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
      route: route,
    );
  }
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.date,
    required this.critical,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final DateTime date;
  final bool critical;
}

class MapIncident {
  const MapIncident({
    required this.id,
    required this.title,
    required this.sector,
    required this.circuit,
    required this.kind,
    required this.status,
    required this.x,
    required this.y,
    required this.detail,
    required this.critical,
  });

  final String id;
  final String title;
  final String sector;
  final String circuit;
  final String kind;
  final String status;
  final double x;
  final double y;
  final String detail;
  final bool critical;
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.number,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.contractNumber,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.reference,
    required this.authorization,
    this.transactionId,
    this.cardBrand,
    this.cardLast4,
  });

  final String id;
  final String number;
  final String invoiceId;
  final String invoiceNumber;
  final String contractNumber;
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final String reference;
  final String authorization;
  final String? transactionId;
  final CardBrand? cardBrand;
  final String? cardLast4;
}

class SavedCard {
  const SavedCard({
    required this.id,
    required this.brand,
    required this.funding,
    required this.last4,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
  });

  final String id;
  final CardBrand brand;
  final CardFunding funding;
  final String last4;
  final String holderName;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;

  bool isExpiredAt(DateTime moment) {
    return expiryYear < moment.year || (expiryYear == moment.year && expiryMonth < moment.month);
  }

  SavedCard copyWith({bool? isDefault}) {
    return SavedCard(
      id: id,
      brand: brand,
      funding: funding,
      last4: last4,
      holderName: holderName,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PaymentLine {
  const PaymentLine({
    required this.contractId,
    required this.contractNumber,
    required this.alias,
    required this.holderName,
    required this.address,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
    this.receiptId,
  });

  final String contractId;
  final String contractNumber;
  final String alias;
  final String holderName;
  final String address;
  final String invoiceId;
  final String invoiceNumber;
  final double amount;
  final String? receiptId;
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.number,
    required this.paidAt,
    required this.method,
    required this.status,
    required this.total,
    required this.lines,
    this.cardBrand,
    this.cardLast4,
    this.cardHolder,
    this.message,
  });

  final String id;
  final String number;
  final DateTime paidAt;
  final PaymentMethod method;
  final PaymentStatus status;
  final double total;
  final List<PaymentLine> lines;
  final CardBrand? cardBrand;
  final String? cardLast4;
  final String? cardHolder;
  final String? message;

  bool get approved => status == PaymentStatus.approved;
}

class ChatAction {
  const ChatAction({required this.label, required this.link});

  final String label;
  final AssistantLink link;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    required this.at,
    this.actions = const [],
  });

  final String id;
  final bool fromUser;
  final String text;
  final DateTime at;
  final List<ChatAction> actions;
}

class NotificationPrefs {
  const NotificationPrefs({
    required this.invoiceAlerts,
    required this.dueReminders,
    required this.outageAlerts,
    required this.requestUpdates,
    required this.announcements,
    required this.emailChannel,
    required this.smsChannel,
    required this.biometricEnabled,
  });

  final bool invoiceAlerts;
  final bool dueReminders;
  final bool outageAlerts;
  final bool requestUpdates;
  final bool announcements;
  final bool emailChannel;
  final bool smsChannel;
  final bool biometricEnabled;

  NotificationPrefs copyWith({
    bool? invoiceAlerts,
    bool? dueReminders,
    bool? outageAlerts,
    bool? requestUpdates,
    bool? announcements,
    bool? emailChannel,
    bool? smsChannel,
    bool? biometricEnabled,
  }) {
    return NotificationPrefs(
      invoiceAlerts: invoiceAlerts ?? this.invoiceAlerts,
      dueReminders: dueReminders ?? this.dueReminders,
      outageAlerts: outageAlerts ?? this.outageAlerts,
      requestUpdates: requestUpdates ?? this.requestUpdates,
      announcements: announcements ?? this.announcements,
      emailChannel: emailChannel ?? this.emailChannel,
      smsChannel: smsChannel ?? this.smsChannel,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class OfficeLocation {
  const OfficeLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.sector,
    required this.schedule,
    required this.phone,
    required this.services,
    required this.directions,
    required this.mapX,
    required this.mapY,
  });

  final String id;
  final String name;
  final String address;
  final String sector;
  final String schedule;
  final String phone;
  final List<String> services;
  final String directions;
  final double mapX;
  final double mapY;
}

class DemoSnapshot {
  const DemoSnapshot({
    required this.user,
    required this.password,
    required this.authenticated,
    required this.onboardingDone,
    required this.contracts,
    required this.activeContractId,
    required this.invoices,
    required this.consumption,
    required this.outages,
    required this.requests,
    required this.notifications,
    required this.announcements,
    required this.mapIncidents,
    required this.receipts,
    required this.transactions,
    required this.cards,
    required this.messages,
    required this.prefs,
    required this.scenario,
    required this.reportSequence,
    required this.requestSequence,
    required this.receiptSequence,
    required this.transactionSequence,
    required this.cardSequence,
    required this.portfolio,
    required this.lastUpdated,
    this.lastAccess,
  });

  final UserProfile user;
  final String password;
  final bool authenticated;
  final bool onboardingDone;
  final List<ContractAccount> contracts;
  final String activeContractId;
  final List<Invoice> invoices;
  final List<ConsumptionMonth> consumption;
  final List<OutageReport> outages;
  final List<ServiceRequest> requests;
  final List<AppNotification> notifications;
  final List<Announcement> announcements;
  final List<MapIncident> mapIncidents;
  final List<PaymentReceipt> receipts;
  final List<PaymentTransaction> transactions;
  final List<SavedCard> cards;
  final List<ChatMessage> messages;
  final NotificationPrefs prefs;
  final DemoScenario scenario;
  final int reportSequence;
  final int requestSequence;
  final int receiptSequence;
  final int transactionSequence;
  final int cardSequence;
  final PortfolioPreset portfolio;
  final DateTime lastUpdated;
  final DateTime? lastAccess;

  DemoSnapshot copyWith({
    UserProfile? user,
    String? password,
    bool? authenticated,
    bool? onboardingDone,
    List<ContractAccount>? contracts,
    String? activeContractId,
    List<Invoice>? invoices,
    List<ConsumptionMonth>? consumption,
    List<OutageReport>? outages,
    List<ServiceRequest>? requests,
    List<AppNotification>? notifications,
    List<Announcement>? announcements,
    List<MapIncident>? mapIncidents,
    List<PaymentReceipt>? receipts,
    List<PaymentTransaction>? transactions,
    List<SavedCard>? cards,
    List<ChatMessage>? messages,
    NotificationPrefs? prefs,
    DemoScenario? scenario,
    int? reportSequence,
    int? requestSequence,
    int? receiptSequence,
    int? transactionSequence,
    int? cardSequence,
    PortfolioPreset? portfolio,
    DateTime? lastUpdated,
    DateTime? lastAccess,
    bool clearLastAccess = false,
  }) {
    return DemoSnapshot(
      user: user ?? this.user,
      password: password ?? this.password,
      authenticated: authenticated ?? this.authenticated,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      contracts: contracts ?? this.contracts,
      activeContractId: activeContractId ?? this.activeContractId,
      invoices: invoices ?? this.invoices,
      consumption: consumption ?? this.consumption,
      outages: outages ?? this.outages,
      requests: requests ?? this.requests,
      notifications: notifications ?? this.notifications,
      announcements: announcements ?? this.announcements,
      mapIncidents: mapIncidents ?? this.mapIncidents,
      receipts: receipts ?? this.receipts,
      transactions: transactions ?? this.transactions,
      cards: cards ?? this.cards,
      messages: messages ?? this.messages,
      prefs: prefs ?? this.prefs,
      scenario: scenario ?? this.scenario,
      reportSequence: reportSequence ?? this.reportSequence,
      requestSequence: requestSequence ?? this.requestSequence,
      receiptSequence: receiptSequence ?? this.receiptSequence,
      transactionSequence: transactionSequence ?? this.transactionSequence,
      cardSequence: cardSequence ?? this.cardSequence,
      portfolio: portfolio ?? this.portfolio,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastAccess: clearLastAccess ? null : lastAccess ?? this.lastAccess,
    );
  }
}
