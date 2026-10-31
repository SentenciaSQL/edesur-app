import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../domain/entities/entities.dart';

String serviceStatusLabel(ServiceStatus status) => switch (status) {
      ServiceStatus.active => 'Activo',
      ServiceStatus.interrupted => 'Interrumpido',
      ServiceStatus.suspended => 'Suspendido',
    };

Color serviceStatusColor(ServiceStatus status) => switch (status) {
      ServiceStatus.active => AppColors.green,
      ServiceStatus.interrupted => AppColors.red,
      ServiceStatus.suspended => AppColors.amber,
    };

String invoiceStatusLabel(InvoiceStatus status) => switch (status) {
      InvoiceStatus.paid => 'Pagada',
      InvoiceStatus.pending => 'Pendiente',
      InvoiceStatus.overdue => 'Vencida',
    };

Color invoiceStatusColor(InvoiceStatus status) => switch (status) {
      InvoiceStatus.paid => AppColors.green,
      InvoiceStatus.pending => AppColors.navy,
      InvoiceStatus.overdue => AppColors.red,
    };

String paymentMethodLabel(PaymentMethod method) => switch (method) {
      PaymentMethod.card => 'Tarjeta de crédito o débito',
      PaymentMethod.transfer => 'Transferencia simulada',
      PaymentMethod.paymentPoint => 'Punto de pago',
    };

String cardBrandLabel(CardBrand brand) => switch (brand) {
      CardBrand.visa => 'Visa',
      CardBrand.mastercard => 'Mastercard',
      CardBrand.amex => 'American Express',
    };

String cardFundingLabel(CardFunding funding) => switch (funding) {
      CardFunding.credit => 'Crédito',
      CardFunding.debit => 'Débito',
    };

String paymentStatusLabel(PaymentStatus status) => switch (status) {
      PaymentStatus.approved => 'Aprobado',
      PaymentStatus.rejected => 'Rechazado',
      PaymentStatus.expiredCard => 'Tarjeta vencida',
      PaymentStatus.processingError => 'Error de procesamiento',
    };

Color paymentStatusColor(PaymentStatus status) => switch (status) {
      PaymentStatus.approved => AppColors.green,
      PaymentStatus.rejected => AppColors.red,
      PaymentStatus.expiredCard => AppColors.amber,
      PaymentStatus.processingError => AppColors.red,
    };

String portfolioLabel(PortfolioPreset preset) => switch (preset) {
      PortfolioPreset.mixed => 'Propios y de terceros',
      PortfolioPreset.singleOwn => 'Un solo contrato propio',
      PortfolioPreset.severalOwn => 'Varios contratos propios',
      PortfolioPreset.ownAndThird => 'Propios con contratos de terceros',
      PortfolioPreset.thirdOnly => 'Solo contratos de terceros',
    };

String portfolioDescription(PortfolioPreset preset) => switch (preset) {
      PortfolioPreset.mixed =>
        'Andrés es titular de casa, apartamento y local, y también tiene vinculados contratos de Rosa, Luis y Pedro.',
      PortfolioPreset.singleOwn => 'Solo queda la casa principal, con factura pendiente.',
      PortfolioPreset.severalOwn => 'Tres contratos a nombre de Andrés: pendiente, sin deuda y vencido.',
      PortfolioPreset.ownAndThird => 'La casa y el local propios, más la casa de mamá y el inquilino.',
      PortfolioPreset.thirdOnly => 'Ningún contrato está a nombre de Andrés. Todos se pueden desvincular.',
    };

String outageTypeLabel(OutageType type) => switch (type) {
      OutageType.noPower => 'No tengo electricidad',
      OutageType.frequentInterruptions => 'Interrupciones frecuentes',
      OutageType.lowVoltage => 'Bajo voltaje',
      OutageType.highVoltage => 'Alto voltaje',
      OutageType.fluctuations => 'Fluctuaciones eléctricas',
      OutageType.downedWires => 'Cables eléctricos caídos',
      OutageType.damagedPole => 'Postes averiados',
      OutageType.other => 'Otra incidencia',
    };

IconData outageTypeIcon(OutageType type) => switch (type) {
      OutageType.noPower => Icons.power_off_rounded,
      OutageType.frequentInterruptions => Icons.bolt_rounded,
      OutageType.lowVoltage => Icons.trending_down_rounded,
      OutageType.highVoltage => Icons.trending_up_rounded,
      OutageType.fluctuations => Icons.ssid_chart_rounded,
      OutageType.downedWires => Icons.cable_rounded,
      OutageType.damagedPole => Icons.vertical_align_bottom_rounded,
      OutageType.other => Icons.report_rounded,
    };

String outageStatusLabel(OutageStatus status) => switch (status) {
      OutageStatus.reported => 'Reportada',
      OutageStatus.received => 'Recibida',
      OutageStatus.inReview => 'En revisión',
      OutageStatus.crewAssigned => 'Brigada asignada',
      OutageStatus.inProgress => 'En proceso',
      OutageStatus.resolved => 'Resuelta',
    };

Color outageStatusColor(OutageStatus status) => switch (status) {
      OutageStatus.reported => AppColors.navy,
      OutageStatus.received => AppColors.navyMid,
      OutageStatus.inReview => AppColors.amber,
      OutageStatus.crewAssigned => AppColors.orangeDark,
      OutageStatus.inProgress => AppColors.orangeDark,
      OutageStatus.resolved => AppColors.green,
    };

OutageStatus? nextOutageStatus(OutageStatus status) => switch (status) {
      OutageStatus.reported => OutageStatus.received,
      OutageStatus.received => OutageStatus.inReview,
      OutageStatus.inReview => OutageStatus.crewAssigned,
      OutageStatus.crewAssigned => OutageStatus.inProgress,
      OutageStatus.inProgress => OutageStatus.resolved,
      OutageStatus.resolved => null,
    };

String requestTypeLabel(RequestType type) => switch (type) {
      RequestType.newSupply => 'Solicitud de nuevo suministro',
      RequestType.changeHolder => 'Cambio de titular',
      RequestType.reconnection => 'Reconexión del servicio',
      RequestType.meterReview => 'Revisión del medidor',
      RequestType.technicalInspection => 'Inspección técnica',
      RequestType.paymentCertificate => 'Certificación de pago',
      RequestType.contractCertificate => 'Certificación de contrato',
      RequestType.invoiceDuplicate => 'Duplicado de factura',
      RequestType.updatePersonalData => 'Actualización de datos personales',
      RequestType.billingComplaint => 'Reclamo de facturación',
    };

IconData requestTypeIcon(RequestType type) => switch (type) {
      RequestType.newSupply => Icons.add_home_rounded,
      RequestType.changeHolder => Icons.swap_horiz_rounded,
      RequestType.reconnection => Icons.power_rounded,
      RequestType.meterReview => Icons.speed_rounded,
      RequestType.technicalInspection => Icons.engineering_rounded,
      RequestType.paymentCertificate => Icons.verified_rounded,
      RequestType.contractCertificate => Icons.badge_rounded,
      RequestType.invoiceDuplicate => Icons.file_copy_rounded,
      RequestType.updatePersonalData => Icons.manage_accounts_rounded,
      RequestType.billingComplaint => Icons.feedback_rounded,
    };

String requestStatusLabel(RequestStatus status) => switch (status) {
      RequestStatus.submitted => 'Enviada',
      RequestStatus.received => 'Recibida',
      RequestStatus.inReview => 'En revisión',
      RequestStatus.inProgress => 'En proceso',
      RequestStatus.completed => 'Completada',
      RequestStatus.rejected => 'Rechazada',
    };

Color requestStatusColor(RequestStatus status) => switch (status) {
      RequestStatus.submitted => AppColors.navy,
      RequestStatus.received => AppColors.navyMid,
      RequestStatus.inReview => AppColors.amber,
      RequestStatus.inProgress => AppColors.orangeDark,
      RequestStatus.completed => AppColors.green,
      RequestStatus.rejected => AppColors.red,
    };

RequestStatus? nextRequestStatus(RequestStatus status) => switch (status) {
      RequestStatus.submitted => RequestStatus.received,
      RequestStatus.received => RequestStatus.inReview,
      RequestStatus.inReview => RequestStatus.inProgress,
      RequestStatus.inProgress => RequestStatus.completed,
      RequestStatus.completed => null,
      RequestStatus.rejected => null,
    };

String scenarioLabel(DemoScenario scenario) => switch (scenario) {
      DemoScenario.normal => 'Servicio normal',
      DemoScenario.interruption => 'Interrupción eléctrica',
      DemoScenario.overdue => 'Factura vencida',
      DemoScenario.outageInProgress => 'Avería en proceso',
    };

String scenarioDescription(DemoScenario scenario) => switch (scenario) {
      DemoScenario.normal =>
        'Suministro activo, sin interrupciones en el circuito y factura de octubre pendiente dentro de fecha.',
      DemoScenario.interruption =>
        'El circuito del contrato principal aparece interrumpido, con aviso crítico y sector afectado en el mapa.',
      DemoScenario.overdue =>
        'La factura de octubre del contrato principal está vencida y el balance se muestra en estado crítico.',
      DemoScenario.outageInProgress =>
        'Hay una avería de bajo voltaje con brigada en proceso para el contrato principal.',
    };
