import '../../domain/entities/entities.dart';
import '../billing/tariff.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';
import 'demo_clock.dart';

class MockSeed {
  static DemoSnapshot build(DemoScenario scenario, {PortfolioPreset portfolio = PortfolioPreset.mixed}) {
    final base = _base();
    final shaped = switch (scenario) {
      DemoScenario.normal => base,
      DemoScenario.interruption => _interruption(base),
      DemoScenario.overdue => _overdue(base),
      DemoScenario.outageInProgress => _outageInProgress(base),
    };
    return _limitPortfolio(shaped, portfolio);
  }

  static SupplyBundle? lookupSupply(String number) {
    final normalized = number.trim();
    for (final contract in _linkable()) {
      if (contract.number == normalized) {
        final history = _history(contract);
        return SupplyBundle(contract, history.invoices, history.months);
      }
    }
    return null;
  }

  static DemoSnapshot _base() {
    final contracts = _contracts();
    final invoices = <Invoice>[];
    final consumption = <ConsumptionMonth>[];
    for (final contract in contracts) {
      final built = _history(contract);
      invoices.addAll(built.invoices);
      consumption.addAll(built.months);
    }

    final october = invoices.firstWhere((invoice) => invoice.id == 'inv-c1-202610');
    final messages = [
      ChatMessage(
        id: 'msg-welcome',
        fromUser: false,
        text:
            'Hola, Andrés. Soy el asistente de EDESUR. Puedo orientarte con la información de demostración de tus contratos, facturas y reportes.',
        at: DemoClock.now.subtract(const Duration(minutes: 5)),
      ),
    ];

    return DemoSnapshot(
      user: const UserProfile(
        name: AppConstants.demoHolder,
        cedula: AppConstants.demoCedula,
        email: AppConstants.demoEmail,
        phone: '809-555-0142',
        clientType: 'Residencial',
      ),
      password: AppConstants.demoPassword,
      authenticated: false,
      onboardingDone: false,
      contracts: contracts,
      activeContractId: 'c1',
      invoices: invoices,
      consumption: consumption,
      outages: _outages(),
      requests: _requests(),
      notifications: _notifications(october),
      announcements: _announcements(),
      mapIncidents: _incidents(),
      receipts: const [],
      transactions: const [],
      cards: _cards(),
      messages: messages,
      prefs: const NotificationPrefs(
        invoiceAlerts: true,
        dueReminders: true,
        outageAlerts: true,
        requestUpdates: true,
        announcements: true,
        emailChannel: true,
        smsChannel: false,
        biometricEnabled: false,
      ),
      scenario: DemoScenario.normal,
      reportSequence: 1402,
      requestSequence: 510,
      receiptSequence: 40,
      transactionSequence: 80,
      cardSequence: 3,
      portfolio: PortfolioPreset.mixed,
      lastUpdated: DemoClock.now,
    );
  }

  static List<SavedCard> _cards() {
    return const [
      SavedCard(
        id: 'card-1',
        brand: CardBrand.visa,
        funding: CardFunding.credit,
        last4: '1111',
        holderName: 'ANDRES FRIAS',
        expiryMonth: 12,
        expiryYear: 2028,
        isDefault: true,
      ),
      SavedCard(
        id: 'card-2',
        brand: CardBrand.mastercard,
        funding: CardFunding.debit,
        last4: '4444',
        holderName: 'ANDRES FRIAS',
        expiryMonth: 8,
        expiryYear: 2027,
        isDefault: false,
      ),
    ];
  }

  static List<ContractAccount> _contracts() {
    return [
      ContractAccount(
        id: 'c1',
        number: '1002345678',
        holderName: AppConstants.demoHolder,
        cedula: AppConstants.demoCedula,
        address: 'Calle Demostración No. 42, Urbanización Los Prados Demo',
        sector: 'Santo Domingo Este',
        municipality: 'Santo Domingo Este',
        clientType: 'Residencial',
        tariffCode: 'BTS1',
        tariffName: DemoTariff.residentialName,
        circuit: 'SDE-14',
        meter: 'MTR-884210',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2019, 3, 12),
        commercial: false,
        mapX: 0.68,
        mapY: 0.42,
        latitude: 18.4891,
        longitude: -69.8570,
        alias: 'Casa principal',
      ),
      ContractAccount(
        id: 'c2',
        number: '1008876543',
        holderName: AppConstants.demoHolder,
        cedula: AppConstants.demoCedula,
        address: 'Avenida Ejemplo No. 118, Residencial Demo del Este',
        sector: 'Los Alcarrizos',
        municipality: 'Los Alcarrizos',
        clientType: 'Residencial',
        tariffCode: 'BTS1',
        tariffName: DemoTariff.residentialName,
        circuit: 'LAC-07',
        meter: 'MTR-771043',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2021, 8, 4),
        commercial: false,
        mapX: 0.40,
        mapY: 0.30,
        latitude: 18.5160,
        longitude: -70.0040,
        alias: 'Apartamento',
      ),
      ContractAccount(
        id: 'c3',
        number: '1005520198',
        holderName: AppConstants.demoHolder,
        cedula: AppConstants.demoCedula,
        address: 'Calle Comercial Demo No. 9, Zona Industrial Demo',
        sector: 'San Cristóbal',
        municipality: 'San Cristóbal',
        clientType: 'Comercial',
        tariffCode: 'BTD',
        tariffName: DemoTariff.commercialName,
        circuit: 'SCR-03',
        meter: 'MTR-650918',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2016, 1, 19),
        commercial: true,
        mapX: 0.34,
        mapY: 0.55,
        latitude: 18.4160,
        longitude: -70.1090,
        alias: 'Local comercial',
      ),
      ContractAccount(
        id: 'c4',
        number: '1004411223',
        holderName: 'Rosa Frías',
        cedula: '001-1234567-8',
        address: 'Calle Familiar Demo No. 15, Urbanización Demostración',
        sector: 'Los Mina',
        municipality: 'Santo Domingo Este',
        clientType: 'Residencial',
        tariffCode: 'BTS1',
        tariffName: DemoTariff.residentialName,
        circuit: 'LMN-02',
        meter: 'MTR-441122',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2014, 6, 2),
        commercial: false,
        mapX: 0.74,
        mapY: 0.36,
        latitude: 18.4750,
        longitude: -69.8300,
        alias: 'Casa de mamá',
      ),
      ContractAccount(
        id: 'c5',
        number: '1007788990',
        holderName: 'Luis Peña',
        cedula: '402-0001111-2',
        address: 'Apartamento Demo 3B, Edificio Ejemplo',
        sector: 'Gazcue',
        municipality: 'Distrito Nacional',
        clientType: 'Residencial',
        tariffCode: 'BTS1',
        tariffName: DemoTariff.residentialName,
        circuit: 'DNX-11',
        meter: 'MTR-778899',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2022, 2, 11),
        commercial: false,
        mapX: 0.52,
        mapY: 0.48,
        latitude: 18.4700,
        longitude: -69.9010,
        alias: 'Inquilino',
      ),
      ContractAccount(
        id: 'c6',
        number: '1006655443',
        holderName: 'Pedro Gómez',
        cedula: '001-5554443-3',
        address: 'Calle del Mercado Demo No. 4',
        sector: 'Baní',
        municipality: 'Baní',
        clientType: 'Comercial',
        tariffCode: 'BTD',
        tariffName: DemoTariff.commercialName,
        circuit: 'BAN-05',
        meter: 'MTR-665544',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2018, 11, 9),
        commercial: true,
        mapX: 0.28,
        mapY: 0.62,
        latitude: 18.2790,
        longitude: -70.3310,
        alias: 'Colmado del primo',
      ),
    ];
  }

  static List<ContractAccount> _linkable() {
    return [
      ContractAccount(
        id: 'c7',
        number: '1009900112',
        holderName: 'Carmen Díaz',
        cedula: '001-9988776-6',
        address: 'Camino de la Finca Demo Km 2',
        sector: 'Guerra',
        municipality: 'Guerra',
        clientType: 'Residencial',
        tariffCode: 'BTS1',
        tariffName: DemoTariff.residentialName,
        circuit: 'GUE-01',
        meter: 'MTR-990011',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2020, 4, 18),
        commercial: false,
        mapX: 0.80,
        mapY: 0.58,
        latitude: 18.5550,
        longitude: -69.7000,
        alias: '',
      ),
      ContractAccount(
        id: 'c8',
        number: '1003300221',
        holderName: 'Ana Pérez',
        cedula: '001-2223334-5',
        address: 'Residencial Ejemplo, Apartamento 2A',
        sector: 'Boca Chica',
        municipality: 'Boca Chica',
        clientType: 'Residencial',
        tariffCode: 'BTS1',
        tariffName: DemoTariff.residentialName,
        circuit: 'BCH-04',
        meter: 'MTR-330022',
        serviceStatus: ServiceStatus.active,
        since: DateTime(2023, 1, 7),
        commercial: false,
        mapX: 0.86,
        mapY: 0.50,
        latitude: 18.4530,
        longitude: -69.6060,
        alias: '',
      ),
    ];
  }

  static DemoSnapshot _limitPortfolio(DemoSnapshot snapshot, PortfolioPreset portfolio) {
    const ids = {
      PortfolioPreset.mixed: {'c1', 'c2', 'c3', 'c4', 'c5', 'c6'},
      PortfolioPreset.singleOwn: {'c1'},
      PortfolioPreset.severalOwn: {'c1', 'c2', 'c3'},
      PortfolioPreset.ownAndThird: {'c1', 'c3', 'c4', 'c5'},
      PortfolioPreset.thirdOnly: {'c4', 'c5', 'c6'},
    };
    final allowed = ids[portfolio]!;
    final contracts = snapshot.contracts.where((contract) => allowed.contains(contract.id)).toList();
    final active = allowed.contains(snapshot.activeContractId)
        ? snapshot.activeContractId
        : (contracts.isEmpty ? '' : contracts.first.id);
    return snapshot.copyWith(
      contracts: contracts,
      activeContractId: active,
      invoices: snapshot.invoices.where((invoice) => allowed.contains(invoice.contractId)).toList(),
      consumption: snapshot.consumption.where((month) => allowed.contains(month.contractId)).toList(),
      outages: snapshot.outages.where((report) => allowed.contains(report.contractId)).toList(),
      requests: snapshot.requests.where((request) => allowed.contains(request.contractId)).toList(),
      portfolio: portfolio,
      transactions: const [],
      receipts: const [],
    );
  }

  static _History _history(ContractAccount contract) {
    const series = <String, List<double>>{
      'c1': [420, 455, 398, 372, 410, 476, 530, 568, 610, 642, 588, 541],
      'c2': [260, 280, 250, 240, 255, 300, 340, 360, 390, 410, 370, 340],
      'c3': [2000, 2100, 2050, 1980, 2140, 2300, 2420, 2510, 2480, 2390, 2280, 2210],
      'c4': [180, 190, 175, 168, 185, 210, 230, 240, 255, 248, 220, 205],
      'c5': [140, 150, 130, 128, 135, 160, 175, 180, 190, 185, 170, 160],
      'c6': [900, 940, 910, 880, 960, 1020, 1100, 1080, 1040, 990, 970, 1010],
      'c7': [300, 320, 290, 280, 310, 340, 360, 380, 400, 390, 360, 330],
      'c8': [200, 210, 190, 185, 200, 220, 240, 250, 260, 255, 230, 215],
    };
    const starts = {
      'c1': 14820.0,
      'c2': 8020.0,
      'c3': 54000.0,
      'c4': 4100.0,
      'c5': 9900.0,
      'c6': 22000.0,
      'c7': 1500.0,
      'c8': 3300.0,
    };
    final values = series[contract.id]!;
    var reading = starts[contract.id]!;
    final invoices = <Invoice>[];
    final months = <ConsumptionMonth>[];
    for (var index = 0; index < 12; index++) {
      final month = DateTime(2025, 11 + index, 1);
      final kwh = values[index];
      final previous = reading;
      reading = round2(reading + kwh);
      final quote = contract.commercial ? DemoTariff.commercial(kwh) : DemoTariff.residential(kwh);
      final periodStart = DateTime(month.year, month.month, 1);
      final periodEnd = DateTime(month.year, month.month + 1, 0);
      final isCurrent = month.year == 2026 && month.month == 10;
      final issue = isCurrent ? DateTime(2026, 10, 31) : DateTime(month.year, month.month + 1, 2);
      var due = issue.add(const Duration(days: 18));
      InvoiceStatus status;
      DateTime? paidAt;
      final openBill = switch (contract.id) {
        'c2' || 'c5' => 'paid',
        'c3' || 'c6' => 'overdue',
        _ => 'pending',
      };
      if (openBill == 'overdue' && isCurrent) {
        due = DateTime(2026, 10, contract.id == 'c6' ? 10 : 15);
        status = InvoiceStatus.overdue;
      } else if (openBill == 'paid' && isCurrent) {
        status = InvoiceStatus.paid;
        paidAt = DateTime(2026, 10, 31, 8, 10);
      } else if (isCurrent) {
        status = InvoiceStatus.pending;
      } else {
        status = InvoiceStatus.paid;
        paidAt = issue.add(const Duration(days: 6, hours: 11));
      }
      final suffix = contract.number.substring(contract.number.length - 4);
      final stamp = '${month.year}${month.month.toString().padLeft(2, '0')}';
      invoices.add(Invoice(
        id: 'inv-${contract.id}-$stamp',
        number: 'F-$suffix-$stamp',
        contractId: contract.id,
        periodStart: periodStart,
        periodEnd: periodEnd,
        issueDate: issue,
        dueDate: due,
        previousReading: previous,
        currentReading: reading,
        kwh: kwh,
        tariffName: quote.tariffName,
        lines: [
          for (final line in quote.lines)
            InvoiceLine(label: line.label, quantity: line.quantity, rate: line.rate, amount: line.amount),
        ],
        subtotal: quote.subtotal,
        tax: quote.tax,
        total: quote.total,
        status: status,
        paidAt: paidAt,
      ));
      months.add(ConsumptionMonth(
        contractId: contract.id,
        month: periodStart,
        kwh: kwh,
        daily: splitDaily(periodStart, kwh, contract.number.codeUnitAt(contract.number.length - 1) + index),
      ));
    }
    return _History(invoices, months);
  }

  static List<OutageReport> _outages() {
    return [
      OutageReport(
        id: 'out-1',
        number: 'RPT-2026-0841',
        contractId: 'c1',
        type: OutageType.lowVoltage,
        description:
            'Durante la noche las luces quedaban tenues en la sala y el aire acondicionado se apagaba solo. La incidencia ya fue corregida en la demostración.',
        address: 'Calle Demostración No. 42, Urbanización Los Prados Demo',
        sector: 'Santo Domingo Este',
        reference: 'Frente al parque de demostración',
        latitude: 18.4891,
        longitude: -69.8570,
        mapX: 0.68,
        mapY: 0.42,
        demoPhoto: false,
        createdAt: DateTime(2026, 8, 12, 21, 15),
        status: OutageStatus.resolved,
        history: [
          StatusEvent(
            title: 'Reportada',
            detail: 'El cliente registró bajo voltaje desde la aplicación.',
            at: DateTime(2026, 8, 12, 21, 15),
          ),
          StatusEvent(
            title: 'En revisión',
            detail: 'El centro de operaciones asoció el caso al circuito SDE-14.',
            at: DateTime(2026, 8, 13, 8, 40),
          ),
          StatusEvent(
            title: 'Resuelta',
            detail: 'Se normalizó el nivel de tensión en el tramo de demostración.',
            at: DateTime(2026, 8, 13, 16, 5),
          ),
        ],
      ),
      OutageReport(
        id: 'out-2',
        number: 'RPT-2026-0912',
        contractId: 'c1',
        type: OutageType.frequentInterruptions,
        description: 'El suministro se iba y volvía varias veces en la tarde. Caso histórico de la cuenta.',
        address: 'Calle Demostración No. 42, Urbanización Los Prados Demo',
        sector: 'Santo Domingo Este',
        reference: 'Poste de la esquina de demostración',
        latitude: 18.4884,
        longitude: -69.8582,
        mapX: 0.66,
        mapY: 0.44,
        demoPhoto: false,
        createdAt: DateTime(2026, 6, 2, 15, 20),
        status: OutageStatus.resolved,
        history: [
          StatusEvent(
            title: 'Reportada',
            detail: 'Se registraron interrupciones breves y repetidas.',
            at: DateTime(2026, 6, 2, 15, 20),
          ),
          StatusEvent(
            title: 'Resuelta',
            detail: 'Se reemplazó un conectador en la red de demostración.',
            at: DateTime(2026, 6, 3, 11, 0),
          ),
        ],
      ),
      OutageReport(
        id: 'out-3',
        number: 'RPT-2026-1104',
        contractId: 'c2',
        type: OutageType.fluctuations,
        description: 'Las lámparas parpadean al encender la bomba de agua del residencial de demostración.',
        address: 'Avenida Ejemplo No. 118, Residencial Demo del Este',
        sector: 'Los Alcarrizos',
        reference: 'Entrada principal del residencial',
        latitude: 18.5160,
        longitude: -70.0040,
        mapX: 0.40,
        mapY: 0.30,
        demoPhoto: true,
        createdAt: DateTime(2026, 10, 20, 18, 45),
        status: OutageStatus.inReview,
        history: [
          StatusEvent(
            title: 'Reportada',
            detail: 'El reporte ingresó con fotografía de demostración.',
            at: DateTime(2026, 10, 20, 18, 45),
          ),
          StatusEvent(
            title: 'Recibida',
            detail: 'El centro de atención confirmó la recepción.',
            at: DateTime(2026, 10, 20, 19, 10),
          ),
          StatusEvent(
            title: 'En revisión',
            detail: 'Se analiza el circuito LAC-07 junto con otros avisos del sector.',
            at: DateTime(2026, 10, 21, 9, 30),
          ),
        ],
      ),
      OutageReport(
        id: 'out-4',
        number: 'RPT-2026-1020',
        contractId: 'c3',
        type: OutageType.downedWires,
        description:
            'Un cable de baja tensión de la zona industrial de demostración quedó a baja altura después de la lluvia. La brigada ya está asignada.',
        address: 'Calle Comercial Demo No. 9, Zona Industrial Demo',
        sector: 'San Cristóbal',
        reference: 'Esquina con la calle Ficticia',
        latitude: 18.4160,
        longitude: -70.1090,
        mapX: 0.34,
        mapY: 0.55,
        demoPhoto: false,
        createdAt: DateTime(2026, 10, 28, 7, 50),
        status: OutageStatus.crewAssigned,
        history: [
          StatusEvent(
            title: 'Reportada',
            detail: 'Se reportó un cable a baja altura. Se pidió no acercarse.',
            at: DateTime(2026, 10, 28, 7, 50),
          ),
          StatusEvent(
            title: 'Brigada asignada',
            detail: 'La brigada demo SCR-2 tiene el caso en ruta.',
            at: DateTime(2026, 10, 28, 9, 15),
          ),
        ],
      ),
      OutageReport(
        id: 'out-5',
        number: 'RPT-2026-0777',
        contractId: 'c1',
        type: OutageType.noPower,
        description: 'El suministro se fue por completo durante la mañana y volvió el mismo día.',
        address: 'Calle Demostración No. 42, Urbanización Los Prados Demo',
        sector: 'Santo Domingo Este',
        reference: 'Interior de la vivienda de demostración',
        latitude: 18.4891,
        longitude: -69.8570,
        mapX: 0.68,
        mapY: 0.42,
        demoPhoto: false,
        createdAt: DateTime(2026, 3, 15, 9, 5),
        status: OutageStatus.resolved,
        history: [
          StatusEvent(
            title: 'Reportada',
            detail: 'Sin servicio en todo el inmueble.',
            at: DateTime(2026, 3, 15, 9, 5),
          ),
          StatusEvent(
            title: 'En proceso',
            detail: 'Se aisló una falla en el ramal de demostración.',
            at: DateTime(2026, 3, 15, 10, 40),
          ),
          StatusEvent(
            title: 'Resuelta',
            detail: 'Servicio restablecido a las 12:10 p.m.',
            at: DateTime(2026, 3, 15, 12, 10),
          ),
        ],
      ),
    ];
  }

  static List<ServiceRequest> _requests() {
    return [
      ServiceRequest(
        id: 'req-1',
        number: 'SOL-2026-0142',
        contractId: 'c1',
        type: RequestType.paymentCertificate,
        summary: 'Certificación de pago para un trámite de demostración.',
        details: const {
          'Contrato': '1002345678',
          'Período': '2026',
          'Finalidad': 'Trámite bancario de demostración',
        },
        attachments: const ['documento-demostracion.pdf'],
        createdAt: DateTime(2026, 9, 4, 10, 20),
        status: RequestStatus.completed,
        history: [
          StatusEvent(title: 'Enviada', detail: 'Solicitud registrada.', at: DateTime(2026, 9, 4, 10, 20)),
          StatusEvent(
            title: 'Completada',
            detail: 'Constancia de demostración disponible en el seguimiento.',
            at: DateTime(2026, 9, 6, 15, 0),
          ),
        ],
      ),
      ServiceRequest(
        id: 'req-2',
        number: 'SOL-2026-0208',
        contractId: 'c1',
        type: RequestType.invoiceDuplicate,
        summary: 'Duplicado de la factura de septiembre 2026.',
        details: const {
          'Contrato': '1002345678',
          'Período': 'Septiembre 2026',
        },
        attachments: const [],
        createdAt: DateTime(2026, 10, 18, 11, 5),
        status: RequestStatus.inProgress,
        history: [
          StatusEvent(title: 'Enviada', detail: 'Se solicitó el duplicado.', at: DateTime(2026, 10, 18, 11, 5)),
          StatusEvent(title: 'Recibida', detail: 'El backoffice de demostración tomó el caso.', at: DateTime(2026, 10, 18, 14, 40)),
          StatusEvent(title: 'En proceso', detail: 'Se prepara la copia de la factura.', at: DateTime(2026, 10, 20, 9, 0)),
        ],
      ),
      ServiceRequest(
        id: 'req-3',
        number: 'SOL-2026-0116',
        contractId: 'c1',
        type: RequestType.updatePersonalData,
        summary: 'Actualización del teléfono de contacto.',
        details: const {
          'Teléfono': '809-555-0142',
          'Correo': AppConstants.demoEmail,
          'Dirección': 'Calle Demostración No. 42',
        },
        attachments: const [],
        createdAt: DateTime(2026, 7, 22, 16, 12),
        status: RequestStatus.completed,
        history: [
          StatusEvent(title: 'Enviada', detail: 'Cambio de datos enviado.', at: DateTime(2026, 7, 22, 16, 12)),
          StatusEvent(title: 'Completada', detail: 'Datos de contacto actualizados en la demostración.', at: DateTime(2026, 7, 23, 9, 30)),
        ],
      ),
      ServiceRequest(
        id: 'req-4',
        number: 'SOL-2026-0233',
        contractId: 'c2',
        type: RequestType.meterReview,
        summary: 'Revisión del medidor del residencial en Los Alcarrizos.',
        details: const {
          'Contrato': '1008876543',
          'Motivo': 'El consumo no coincide con la ocupación de la vivienda de demostración.',
          'Acceso': 'Disponible en horario laboral',
        },
        attachments: const ['foto-medidor-demo.jpg'],
        createdAt: DateTime(2026, 10, 25, 13, 18),
        status: RequestStatus.received,
        history: [
          StatusEvent(title: 'Enviada', detail: 'Solicitud creada desde la app.', at: DateTime(2026, 10, 25, 13, 18)),
          StatusEvent(title: 'Recibida', detail: 'Quedó en la cola de revisiones de demostración.', at: DateTime(2026, 10, 25, 15, 2)),
        ],
      ),
      ServiceRequest(
        id: 'req-5',
        number: 'SOL-2026-0094',
        contractId: 'c3',
        type: RequestType.billingComplaint,
        summary: 'Reclamo por el cargo de demanda de agosto 2026.',
        details: const {
          'Factura': 'F-0198-202608',
          'Motivo': 'Cargo no reconocido',
          'Detalle': 'El local de demostración estuvo cerrado una semana y el cargo de demanda se mantuvo.',
        },
        attachments: const [],
        createdAt: DateTime(2026, 10, 11, 9, 48),
        status: RequestStatus.inReview,
        history: [
          StatusEvent(title: 'Enviada', detail: 'Reclamo registrado.', at: DateTime(2026, 10, 11, 9, 48)),
          StatusEvent(title: 'En revisión', detail: 'Facturación de demostración compara la lectura del medidor.', at: DateTime(2026, 10, 14, 11, 20)),
        ],
      ),
    ];
  }

  static List<AppNotification> _notifications(Invoice october) {
    return [
      AppNotification(
        id: 'nt-1',
        kind: NotificationKind.invoiceReady,
        title: 'Factura de octubre disponible',
        body: 'La factura ${october.number} de ${formatMoney(october.total)} ya puede consultarse. Vence el ${formatDate(october.dueDate)}.',
        createdAt: DateTime(2026, 10, 31, 8, 5),
        read: false,
        route: '/facturas/${october.id}',
      ),
      AppNotification(
        id: 'nt-2',
        kind: NotificationKind.dueReminder,
        title: 'Recordatorio de vencimiento',
        body: 'Tu factura de octubre vence el ${formatDate(october.dueDate)}. Puedes simular el pago desde la app.',
        createdAt: DateTime(2026, 10, 31, 8, 6),
        read: false,
        route: '/facturas/${october.id}',
      ),
      AppNotification(
        id: 'nt-3',
        kind: NotificationKind.paymentDone,
        title: 'Pago de septiembre registrado',
        body: 'El pago de la factura F-5678-202609 quedó aplicado en el historial de demostración.',
        createdAt: DateTime(2026, 10, 16, 11, 24),
        read: true,
        route: '/facturas/inv-c1-202609',
      ),
      AppNotification(
        id: 'nt-4',
        kind: NotificationKind.reportReceived,
        title: 'Reporte recibido',
        body: 'El reporte RPT-2026-0841 de bajo voltaje fue recibido y luego resuelto.',
        createdAt: DateTime(2026, 8, 12, 21, 16),
        read: true,
        route: '/averias/out-1',
      ),
      AppNotification(
        id: 'nt-5',
        kind: NotificationKind.outageUpdate,
        title: 'Avería resuelta',
        body: 'El caso RPT-2026-0841 en Santo Domingo Este pasó a resuelto.',
        createdAt: DateTime(2026, 8, 13, 16, 6),
        read: true,
        route: '/averias/out-1',
      ),
      AppNotification(
        id: 'nt-6',
        kind: NotificationKind.plannedOutage,
        title: 'Mantenimiento programado',
        body: 'El circuito SDE-14 tendrá mantenimiento el 05/11/2026, de 8:00 a.m. a 12:00 p.m.',
        createdAt: DateTime(2026, 10, 28, 9, 0),
        read: false,
        route: '/mapa',
      ),
      AppNotification(
        id: 'nt-7',
        kind: NotificationKind.announcement,
        title: 'Campaña de ahorro energético',
        body: 'Apaga lo que no uses y ajusta los aires acondicionados. Revisa las recomendaciones del módulo de consumo.',
        createdAt: DateTime(2026, 10, 22, 8, 0),
        read: false,
        route: '/consumo',
      ),
      AppNotification(
        id: 'nt-8',
        kind: NotificationKind.requestUpdate,
        title: 'Solicitud en proceso',
        body: 'El duplicado SOL-2026-0208 sigue en proceso en el backoffice de demostración.',
        createdAt: DateTime(2026, 10, 20, 9, 5),
        read: true,
        route: '/solicitudes/req-2',
      ),
      AppNotification(
        id: 'nt-9',
        kind: NotificationKind.plannedOutage,
        title: 'Interrupción en un circuito vecino',
        body: 'El circuito LAC-02, fuera de tus contratos, tiene una ventana programada el 02/11/2026. Es un aviso informativo.',
        createdAt: DateTime(2026, 10, 27, 17, 40),
        read: true,
        route: '/mapa',
      ),
    ];
  }

  static List<Announcement> _announcements() {
    return [
      Announcement(
        id: 'an-1',
        title: 'Mantenimiento programado en SDE-14',
        body:
            'El miércoles 05/11/2026, de 8:00 a.m. a 12:00 p.m., el circuito SDE-14 podría interrumpirse en la Urbanización Los Prados Demo.',
        category: 'Mantenimiento',
        date: DateTime(2026, 10, 28),
        critical: false,
      ),
      Announcement(
        id: 'an-2',
        title: 'Tu factura de octubre ya está disponible',
        body: 'Revísala y, si quieres, simula el pago antes del 18/11/2026. No se realizará ningún cargo real.',
        category: 'Facturación',
        date: DateTime(2026, 10, 31),
        critical: false,
      ),
      Announcement(
        id: 'an-3',
        title: 'Campaña: apaga lo que no usas',
        body: 'Pequeños cambios en iluminación y climatización reducen el consumo en los meses de calor.',
        category: 'Comunicado',
        date: DateTime(2026, 10, 22),
        critical: false,
      ),
    ];
  }

  static List<MapIncident> _incidents() {
    return const [
      MapIncident(
        id: 'map-1',
        title: 'Mantenimiento programado',
        sector: 'Santo Domingo Este',
        circuit: 'SDE-14',
        kind: 'Programada',
        status: '05/11/2026 · 8:00 a.m. a 12:00 p.m.',
        x: 0.70,
        y: 0.38,
        detail: 'Ventana de mantenimiento en el circuito del contrato principal. El servicio puede interrumpirse durante esas horas.',
        critical: false,
      ),
      MapIncident(
        id: 'map-2',
        title: 'Fluctuaciones reportadas',
        sector: 'Los Alcarrizos',
        circuit: 'LAC-07',
        kind: 'Reportada',
        status: 'En revisión',
        x: 0.42,
        y: 0.28,
        detail: 'Reporte RPT-2026-1104 asociado al segundo contrato de la cuenta de demostración.',
        critical: false,
      ),
      MapIncident(
        id: 'map-3',
        title: 'Cable a baja altura',
        sector: 'San Cristóbal',
        circuit: 'SCR-03',
        kind: 'Avería',
        status: 'Brigada asignada',
        x: 0.32,
        y: 0.52,
        detail: 'Reporte RPT-2026-1020. La información geográfica es esquemática.',
        critical: true,
      ),
    ];
  }

  static DemoSnapshot _overdue(DemoSnapshot base) {
    final invoices = [
      for (final invoice in base.invoices)
        if (invoice.id == 'inv-c1-202610')
          invoice.copyWith(
            dueDate: DateTime(2026, 10, 12),
            status: InvoiceStatus.overdue,
            clearPayment: true,
          )
        else
          invoice,
    ];
    final notifications = [
      AppNotification(
        id: 'nt-overdue',
        kind: NotificationKind.dueReminder,
        title: 'Factura vencida',
        body: 'La factura de octubre del contrato 1002345678 está vencida en este escenario de demostración.',
        createdAt: DateTime(2026, 10, 31, 8, 2),
        read: false,
        route: '/facturas/inv-c1-202610',
      ),
      ...base.notifications,
    ];
    final announcements = [
      Announcement(
        id: 'an-overdue',
        title: 'Tienes una factura vencida',
        body: 'El balance del contrato principal aparece vencido para esta parte de la presentación.',
        category: 'Facturación',
        date: DateTime(2026, 10, 31),
        critical: true,
      ),
      ...base.announcements,
    ];
    return base.copyWith(
      invoices: invoices,
      notifications: notifications,
      announcements: announcements,
      scenario: DemoScenario.overdue,
      messages: _greeting(base, 'En este escenario la factura de octubre está vencida.'),
    );
  }

  static DemoSnapshot _interruption(DemoSnapshot base) {
    final contracts = [
      for (final contract in base.contracts)
        if (contract.id == 'c1') contract.copyWith(serviceStatus: ServiceStatus.interrupted) else contract,
    ];
    final outage = OutageReport(
      id: 'out-live',
      number: 'RPT-2026-1401',
      contractId: 'c1',
      type: OutageType.noPower,
      description: 'Escenario de presentación: el circuito SDE-14 está fuera de servicio en Santo Domingo Este.',
      address: 'Calle Demostración No. 42, Urbanización Los Prados Demo',
      sector: 'Santo Domingo Este',
      reference: 'Todo el sector de demostración',
      latitude: 18.4891,
      longitude: -69.8570,
      mapX: 0.68,
      mapY: 0.42,
      demoPhoto: false,
      createdAt: DateTime(2026, 10, 31, 6, 40),
      status: OutageStatus.inProgress,
      history: [
        StatusEvent(
          title: 'Reportada',
          detail: 'Interrupción general del circuito de demostración.',
          at: DateTime(2026, 10, 31, 6, 40),
        ),
        StatusEvent(
          title: 'En proceso',
          detail: 'Las brigadas trabajan en la red del circuito SDE-14.',
          at: DateTime(2026, 10, 31, 7, 30),
        ),
      ],
    );
    return base.copyWith(
      contracts: contracts,
      outages: [outage, ...base.outages],
      announcements: [
        Announcement(
          id: 'an-out',
          title: 'Interrupción en tu circuito',
          body: 'El circuito SDE-14 está interrumpido en este escenario. La información es simulada.',
          category: 'Interrupción',
          date: DateTime(2026, 10, 31),
          critical: true,
        ),
        ...base.announcements,
      ],
      mapIncidents: [
        const MapIncident(
          id: 'map-live',
          title: 'Interrupción del circuito',
          sector: 'Santo Domingo Este',
          circuit: 'SDE-14',
          kind: 'Interrupción',
          status: 'En proceso',
          x: 0.68,
          y: 0.42,
          detail: 'Escenario de presentación. No corresponde a un evento real de la red.',
          critical: true,
        ),
        ...base.mapIncidents,
      ],
      notifications: [
        AppNotification(
          id: 'nt-live',
          kind: NotificationKind.plannedOutage,
          title: 'Interrupción en SDE-14',
          body: 'Tu suministro de Santo Domingo Este aparece interrumpido en el escenario de demostración.',
          createdAt: DateTime(2026, 10, 31, 6, 45),
          read: false,
          route: '/averias/out-live',
        ),
        ...base.notifications,
      ],
      scenario: DemoScenario.interruption,
      messages: _greeting(base, 'En este escenario el circuito SDE-14 está interrumpido.'),
    );
  }

  static DemoSnapshot _outageInProgress(DemoSnapshot base) {
    final report = OutageReport(
      id: 'out-progress',
      number: 'RPT-2026-1390',
      contractId: 'c1',
      type: OutageType.lowVoltage,
      description: 'Las luces quedan bajas al encender el aire. Una brigada de demostración ya está en el sector.',
      address: 'Calle Demostración No. 42, Urbanización Los Prados Demo',
      sector: 'Santo Domingo Este',
      reference: 'Poste frente a la casa de demostración',
      latitude: 18.4894,
      longitude: -69.8564,
      mapX: 0.69,
      mapY: 0.40,
      demoPhoto: true,
      createdAt: DateTime(2026, 10, 30, 19, 10),
      status: OutageStatus.inProgress,
      history: [
        StatusEvent(title: 'Reportada', detail: 'Bajo voltaje registrado anoche.', at: DateTime(2026, 10, 30, 19, 10)),
        StatusEvent(title: 'Recibida', detail: 'El caso entró a la cola del circuito SDE-14.', at: DateTime(2026, 10, 30, 19, 25)),
        StatusEvent(title: 'Brigada asignada', detail: 'Brigada demo SDE-4 tomó el reporte.', at: DateTime(2026, 10, 31, 7, 50)),
        StatusEvent(title: 'En proceso', detail: 'La brigada está en el sector de demostración.', at: DateTime(2026, 10, 31, 8, 40)),
      ],
    );
    return base.copyWith(
      outages: [report, ...base.outages],
      mapIncidents: [
        const MapIncident(
          id: 'map-progress',
          title: 'Bajo voltaje en atención',
          sector: 'Santo Domingo Este',
          circuit: 'SDE-14',
          kind: 'Avería',
          status: 'En proceso',
          x: 0.69,
          y: 0.40,
          detail: 'Reporte RPT-2026-1390. Brigada de demostración en el sector.',
          critical: false,
        ),
        ...base.mapIncidents,
      ],
      notifications: [
        AppNotification(
          id: 'nt-progress',
          kind: NotificationKind.outageUpdate,
          title: 'Brigada en tu sector',
          body: 'El reporte RPT-2026-1390 está en proceso. Es un escenario de demostración.',
          createdAt: DateTime(2026, 10, 31, 8, 40),
          read: false,
          route: '/averias/out-progress',
        ),
        ...base.notifications,
      ],
      scenario: DemoScenario.outageInProgress,
      messages: _greeting(base, 'Hay una avería de bajo voltaje en proceso para tu contrato principal.'),
    );
  }

  static List<ChatMessage> _greeting(DemoSnapshot base, String extra) {
    return [
      ChatMessage(
        id: 'msg-scenario',
        fromUser: false,
        text: 'Hola, ${firstName(base.user.name)}. $extra Pregúntame por tu balance, la avería o cómo pagar.',
        at: DemoClock.now,
      ),
    ];
  }
}

class _History {
  const _History(this.invoices, this.months);
  final List<Invoice> invoices;
  final List<ConsumptionMonth> months;
}

class SupplyBundle {
  const SupplyBundle(this.contract, this.invoices, this.months);
  final ContractAccount contract;
  final List<Invoice> invoices;
  final List<ConsumptionMonth> months;
}
