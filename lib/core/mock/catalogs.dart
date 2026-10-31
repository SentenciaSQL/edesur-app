import '../../domain/entities/entities.dart';
import '../../domain/logic/selectors.dart';
import '../constants/app_constants.dart';
import '../utils/formatters.dart';

enum FieldKind { text, multiline, phone, email, number, select }

class RequestFieldDef {
  const RequestFieldDef({
    required this.key,
    required this.label,
    required this.kind,
    this.hint,
    this.options = const [],
    this.required = true,
  });

  final String key;
  final String label;
  final FieldKind kind;
  final String? hint;
  final List<String> options;
  final bool required;
}

class RequestDefinition {
  const RequestDefinition({
    required this.type,
    required this.summary,
    required this.description,
    required this.requirements,
    required this.fields,
  });

  final RequestType type;
  final String summary;
  final String description;
  final List<String> requirements;
  final List<RequestFieldDef> fields;
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class AssistantReply {
  const AssistantReply({required this.text, this.actions = const []});
  final String text;
  final List<ChatAction> actions;
}

const savingsTips = <(String, String)>[
  ('Desconecta lo que no usas', 'Los cargadores y equipos encendidos sin uso siguen consumiendo energía.'),
  ('Prefiere bombillas LED', 'Sustituir focos incandescentes reduce el consumo de iluminación de forma inmediata.'),
  ('Evita el modo de espera', 'Apaga el televisor, el módem y los equipos de cocina cuando no los necesites.'),
  ('Revisa los aires acondicionados', 'Un grado más alto en el termostato y un filtro limpio bajan el consumo en los meses de calor.'),
];

class Catalogs {
  static const offices = <OfficeLocation>[
    OfficeLocation(
      id: 'of-este',
      name: 'Centro de Atención Demostración — Sede Este',
      address: 'Calle Demostración No. 100, Urbanización Ejemplo',
      sector: 'Santo Domingo Este',
      schedule: 'Lunes a viernes 8:00 a.m. – 5:00 p.m. · Sábados 8:00 a.m. – 12:00 p.m.',
      phone: '(809) 555-0101',
      services: ['Pagos', 'Contratos', 'Certificaciones', 'Reclamaciones'],
      directions:
          'Desde la avenida principal de demostración, continúa 400 metros y gira a la derecha en la calle Ejemplo. El centro ocupa la planta baja del edificio ficticio Norte.',
      mapX: 0.68,
      mapY: 0.42,
    ),
    OfficeLocation(
      id: 'of-alcarrizos',
      name: 'Estafeta Demostración — Los Alcarrizos',
      address: 'Avenida Demostración No. 45',
      sector: 'Los Alcarrizos',
      schedule: 'Lunes a viernes 8:00 a.m. – 4:00 p.m.',
      phone: '(809) 555-0102',
      services: ['Pagos', 'Duplicado de factura', 'Reportes'],
      directions:
          'Indicación simulada: sobre la avenida de demostración, frente a la plaza ficticia del Este. Estacionamiento de visita en el lateral del local.',
      mapX: 0.40,
      mapY: 0.30,
    ),
    OfficeLocation(
      id: 'of-sancristobal',
      name: 'Oficina Demostración — San Cristóbal',
      address: 'Calle Ejemplo No. 12',
      sector: 'San Cristóbal',
      schedule: 'Lunes a viernes 8:00 a.m. – 5:00 p.m.',
      phone: '(809) 555-0103',
      services: ['Contratos comerciales', 'Inspecciones', 'Reclamos'],
      directions:
          'Indicación simulada: a dos cuadras del parque de demostración, edificio de una planta identificado con el rótulo de prototipo.',
      mapX: 0.34,
      mapY: 0.55,
    ),
    OfficeLocation(
      id: 'of-bani',
      name: 'Punto de Atención Demostración — Baní',
      address: 'Calle Ficticia No. 8',
      sector: 'Baní',
      schedule: 'Lunes a viernes 8:30 a.m. – 4:30 p.m.',
      phone: '(809) 555-0104',
      services: ['Pagos', 'Certificación de pago'],
      directions:
          'Indicación simulada: entrada por la calle Ficticia, local 2. No corresponde a una oficina real.',
      mapX: 0.30,
      mapY: 0.70,
    ),
    OfficeLocation(
      id: 'of-barahona',
      name: 'Centro Demostración — Barahona',
      address: 'Avenida Prototipo No. 3',
      sector: 'Barahona',
      schedule: 'Lunes a viernes 8:00 a.m. – 4:00 p.m.',
      phone: '(809) 555-0105',
      services: ['Pagos', 'Nuevos suministros', 'Averías'],
      directions:
          'Indicación simulada: sobre la avenida Prototipo, frente a la plaza cívica de demostración. Acceso peatonal por la acera norte.',
      mapX: 0.22,
      mapY: 0.84,
    ),
  ];

  static const faqs = <FaqItem>[
    FaqItem(
      question: '¿Cómo pago mi factura en este prototipo?',
      answer:
          'Desde Inicio o Facturas elige Pagar ahora. Puedes simular tarjeta, transferencia o punto de pago. La tarjeta 4111 1111 1111 1111 produce un pago exitoso. La terminada en 0002 simula un rechazo. No se procesa ningún cargo real.',
    ),
    FaqItem(
      question: '¿Qué significa que la información es simulada?',
      answer:
          'Contratos, consumos, facturas, averías, solicitudes y oficinas viven en este dispositivo. Sirven para presentar la experiencia. No consultan los sistemas comerciales de EDESUR.',
    ),
    FaqItem(
      question: '¿Cómo reporto una avería?',
      answer:
          'En Averías elige Reportar. Indica el tipo de incidencia, describe lo ocurrido, confirma el sector y, si quieres, adjunta una fotografía. Recibirás un número de reporte y podrás avanzar su estado con la acción de demostración.',
    ),
    FaqItem(
      question: '¿Puedo tener varios contratos?',
      answer:
          'Sí. La cuenta de demostración incluye tres suministros. Cámbialos desde Inicio o desde Mi cuenta para ver facturas, consumo y solicitudes de cada uno.',
    ),
    FaqItem(
      question: '¿La estimación de facturación es oficial?',
      answer:
          'No. La estimación usa una tarifa ficticia y el consumo de demostración. No constituye una factura ni un compromiso de cobro.',
    ),
    FaqItem(
      question: '¿Dónde están las oficinas?',
      answer:
          'El directorio de centros de atención es ficticio y está rotulado como demostración. Los teléfonos 555 no corresponden a locales reales. Los canales publicados en edesur.com.do se muestran aparte en Contacto.',
    ),
    FaqItem(
      question: '¿Cómo restauro la presentación?',
      answer:
          'En Mi cuenta abre Modo demostración. Desde ahí puedes cargar servicio normal, interrupción, factura vencida o avería en proceso, y también restablecer los datos.',
    ),
    FaqItem(
      question: '¿El asistente usa inteligencia artificial externa?',
      answer:
          'No. Responde con un catálogo local y con los datos de demostración cargados en el dispositivo. No se envía información a OpenAI, Claude ni a ningún otro proveedor.',
    ),
  ];

  static const requests = <RequestDefinition>[
    RequestDefinition(
      type: RequestType.newSupply,
      summary: 'Pide un suministro nuevo para una dirección de demostración.',
      description:
          'Inicia el trámite simulado de un nuevo contrato residencial o comercial. En la operación real este paso se integraría con el sistema comercial.',
      requirements: [
        'Cédula del solicitante',
        'Dirección del inmueble',
        'Teléfono de contacto',
        'Croquis o referencia de ubicación',
      ],
      fields: [
        RequestFieldDef(key: 'nombre', label: 'Nombre del solicitante', kind: FieldKind.text),
        RequestFieldDef(key: 'cedula', label: 'Cédula', kind: FieldKind.text, hint: '000-0000000-0'),
        RequestFieldDef(key: 'telefono', label: 'Teléfono', kind: FieldKind.phone),
        RequestFieldDef(key: 'direccion', label: 'Dirección del inmueble', kind: FieldKind.text),
        RequestFieldDef(key: 'sector', label: 'Sector', kind: FieldKind.text),
        RequestFieldDef(
          key: 'uso',
          label: 'Tipo de uso',
          kind: FieldKind.select,
          options: ['Residencial', 'Comercial'],
        ),
      ],
    ),
    RequestDefinition(
      type: RequestType.changeHolder,
      summary: 'Transfiere el contrato a otro titular de forma simulada.',
      description: 'Registra los datos del nuevo titular. El prototipo no modifica un registro civil ni un contrato real.',
      requirements: ['Contrato actual', 'Cédula del nuevo titular', 'Teléfono de contacto'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'titular', label: 'Nuevo titular', kind: FieldKind.text),
        RequestFieldDef(key: 'cedula', label: 'Cédula del nuevo titular', kind: FieldKind.text),
        RequestFieldDef(key: 'telefono', label: 'Teléfono', kind: FieldKind.phone),
      ],
    ),
    RequestDefinition(
      type: RequestType.reconnection,
      summary: 'Solicita la reconexión simulada de un suministro.',
      description: 'Úsalo para mostrar el trámite cuando el servicio aparece suspendido en un escenario.',
      requirements: ['Contrato', 'Motivo de la solicitud', 'Teléfono para coordinar la visita'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'motivo', label: 'Motivo', kind: FieldKind.multiline),
        RequestFieldDef(key: 'telefono', label: 'Teléfono', kind: FieldKind.phone),
      ],
    ),
    RequestDefinition(
      type: RequestType.meterReview,
      summary: 'Pide una revisión del medidor asociado al contrato.',
      description: 'Genera una orden simulada de revisión. No se despacha una brigada real.',
      requirements: ['Número de contrato', 'Motivo de la revisión', 'Disponibilidad de acceso al medidor'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'motivo', label: 'Motivo', kind: FieldKind.multiline),
        RequestFieldDef(
          key: 'acceso',
          label: 'Acceso al medidor',
          kind: FieldKind.select,
          options: ['Disponible en horario laboral', 'Requiere coordinación'],
        ),
      ],
    ),
    RequestDefinition(
      type: RequestType.technicalInspection,
      summary: 'Solicita una inspección técnica del suministro.',
      description: 'Describe la condición que quieres que revise el equipo técnico en la demostración.',
      requirements: ['Descripción del hallazgo', 'Referencia de ubicación'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'detalle', label: 'Qué debe inspeccionarse', kind: FieldKind.multiline),
        RequestFieldDef(key: 'referencia', label: 'Referencia de ubicación', kind: FieldKind.text),
      ],
    ),
    RequestDefinition(
      type: RequestType.paymentCertificate,
      summary: 'Emite una constancia simulada de los pagos del contrato.',
      description: 'El documento de salida es de demostración y no tiene validez ante terceros.',
      requirements: ['Contrato', 'Período que deseas certificar', 'Finalidad de la constancia'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'periodo', label: 'Período', kind: FieldKind.text, hint: 'Ej. 2026'),
        RequestFieldDef(key: 'finalidad', label: 'Finalidad', kind: FieldKind.text),
      ],
    ),
    RequestDefinition(
      type: RequestType.contractCertificate,
      summary: 'Solicita una certificación simulada del contrato vigente.',
      description: 'Confirma el suministro de demostración y el uso declarado de la constancia.',
      requirements: ['Contrato', 'Finalidad'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'finalidad', label: 'Finalidad', kind: FieldKind.text),
      ],
    ),
    RequestDefinition(
      type: RequestType.invoiceDuplicate,
      summary: 'Pide el duplicado de una factura de demostración.',
      description: 'Puedes indicar el período. El duplicado se representa con la factura ya cargada en la app.',
      requirements: ['Contrato', 'Período facturado'],
      fields: [
        RequestFieldDef(key: 'contrato', label: 'Número de contrato', kind: FieldKind.text),
        RequestFieldDef(key: 'periodo', label: 'Período facturado', kind: FieldKind.text, hint: 'Ej. Octubre 2026'),
      ],
    ),
    RequestDefinition(
      type: RequestType.updatePersonalData,
      summary: 'Actualiza teléfono, correo o dirección de correspondencia.',
      description: 'El cambio queda guardado en este dispositivo como parte de la demostración.',
      requirements: ['Teléfono', 'Correo', 'Dirección de correspondencia'],
      fields: [
        RequestFieldDef(key: 'telefono', label: 'Teléfono', kind: FieldKind.phone),
        RequestFieldDef(key: 'correo', label: 'Correo', kind: FieldKind.email),
        RequestFieldDef(key: 'direccion', label: 'Dirección de correspondencia', kind: FieldKind.text),
      ],
    ),
    RequestDefinition(
      type: RequestType.billingComplaint,
      summary: 'Registra un reclamo simulado sobre una factura.',
      description: 'Describe la diferencia que quieres mostrar. El reclamo recibe un número de seguimiento local.',
      requirements: ['Número de factura', 'Motivo', 'Detalle del reclamo'],
      fields: [
        RequestFieldDef(key: 'factura', label: 'Número de factura', kind: FieldKind.text),
        RequestFieldDef(
          key: 'motivo',
          label: 'Motivo',
          kind: FieldKind.select,
          options: ['Consumo elevado', 'Cargo no reconocido', 'Lectura del medidor', 'Otro'],
        ),
        RequestFieldDef(key: 'detalle', label: 'Detalle', kind: FieldKind.multiline),
      ],
    ),
  ];

  static RequestDefinition definition(RequestType type) =>
      requests.firstWhere((item) => item.type == type);

  static OfficeLocation? office(String id) {
    for (final item in offices) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class AssistantEngine {
  AssistantReply reply(String question, DemoSnapshot snapshot) {
    final q = normalizeText(question);
    final contract = snapshot.activeContractOrNull;
    if (contract == null) {
      return const AssistantReply(
        text: 'No tienes contratos vinculados en esta demostración. Puedes agregar uno desde Contratos.',
        actions: [ChatAction(label: 'Ver contratos', link: AssistantLink.contracts)],
      );
    }
    final invoice = snapshot.payableInvoice;
    final balance = snapshot.activeBalance;
    final current = snapshot.currentConsumption;
    final previous = snapshot.previousConsumption;

    if (_has(q, ['hola', 'buenos', 'buenas', 'saludo'])) {
      return AssistantReply(
        text:
            'Hola, ${firstName(snapshot.user.name)}. Soy el asistente de demostración de EDESUR. Puedo orientarte sobre tu balance, facturas, averías y solicitudes con la información simulada de esta cuenta.',
      );
    }

    if (_has(q, ['cuanto debo', 'cuanto pago', 'balance', 'deuda', 'pendiente'])) {
      if (invoice == null || balance <= 0) {
        return const AssistantReply(
          text: 'Tu contrato de demostración está al día. No tienes balance pendiente en este momento.',
          actions: [ChatAction(label: 'Ver facturas', link: AssistantLink.invoices)],
        );
      }
      return AssistantReply(
        text:
            'El balance pendiente del contrato ${contract.number} es ${formatMoney(balance)}. Corresponde a la factura ${invoice.number} de ${formatMonthYear(invoice.periodStart)} y vence el ${formatDate(invoice.dueDate)}.',
        actions: const [
          ChatAction(label: 'Pagar ahora', link: AssistantLink.pay),
          ChatAction(label: 'Ver factura', link: AssistantLink.invoices),
        ],
      );
    }

    if (_has(q, ['vence', 'vencimiento', 'fecha limite', 'hasta cuando'])) {
      if (invoice == null) {
        return const AssistantReply(
          text: 'No tienes una factura abierta. La próxima factura de demostración aparecerá cuando cambies el escenario o restaures los datos.',
        );
      }
      final state = invoice.status == InvoiceStatus.overdue ? 'Ya está vencida.' : 'Aún está dentro de fecha.';
      return AssistantReply(
        text: 'La factura ${invoice.number} vence el ${formatDate(invoice.dueDate)}. $state',
        actions: const [ChatAction(label: 'Pagar ahora', link: AssistantLink.pay)],
      );
    }

    if (_has(q, ['averia', 'reporte', 'sin luz', 'no tengo', 'interrup'])) {
      final open = snapshot.openOutage;
      final extra = open == null
          ? 'Ahora mismo no tienes un reporte abierto en el contrato ${contract.number}.'
          : 'Tienes el reporte ${open.number} en estado de seguimiento.';
      return AssistantReply(
        text:
            'Para reportar una avería entra a Averías, elige el tipo de incidencia y confirma la dirección. $extra Todo el seguimiento de este prototipo es local.',
        actions: const [
          ChatAction(label: 'Reportar avería', link: AssistantLink.reportOutage),
          ChatAction(label: 'Ver mapa', link: AssistantLink.map),
        ],
      );
    }

    if (_has(q, ['nuevo servicio', 'nuevo suministro', 'solicitar', 'tramite', 'solicitud'])) {
      return const AssistantReply(
        text:
            'En Solicitudes encontrarás el catálogo de trámites: nuevo suministro, cambio de titular, reconexión, revisión del medidor, certificaciones y reclamos. Cada envío genera un número de solicitud simulado.',
        actions: [ChatAction(label: 'Ver trámites', link: AssistantLink.requests)],
      );
    }

    if (_has(q, ['aumento', 'subio', 'consumo', 'porque'])) {
      if (current != null && previous != null) {
        final delta = percentChange(current.kwh, previous.kwh);
        final direction = delta > 0 ? 'subió' : 'bajó';
        return AssistantReply(
          text:
              'En ${formatMonthYear(current.month)} el consumo fue ${formatKwh(current.kwh)}. $direction ${formatPercent(delta.abs(), signed: false)} frente a ${formatMonthYear(previous.month)}. En los meses de calor el aire acondicionado suele explicar la mayor parte de la variación. Esta lectura es ficticia.',
          actions: const [ChatAction(label: 'Ver consumo', link: AssistantLink.consumption)],
        );
      }
      return const AssistantReply(
        text: 'Puedes revisar la comparación de períodos en el módulo de consumo.',
        actions: [ChatAction(label: 'Ver consumo', link: AssistantLink.consumption)],
      );
    }

    if (_has(q, ['ahorr', 'consejo', 'reducir', 'bajar la factura'])) {
      return const AssistantReply(
        text:
            'Cuatro hábitos con efecto visible: desconectar equipos que no usas, cambiar a bombillas LED, evitar el modo de espera y revisar la temperatura de los aires acondicionados. El módulo de consumo los muestra junto a tu gráfico.',
        actions: [ChatAction(label: 'Ver recomendaciones', link: AssistantLink.consumption)],
      );
    }

    if (_has(q, ['donde pagar', 'punto de pago', 'pagar mi factura', 'como pago', 'oficina'])) {
      return AssistantReply(
        text:
            'En el prototipo puedes simular el pago con tarjeta, transferencia o un código de punto de pago. El centro de atención publicado es ${AppConstants.publishedCallCenter}. Las oficinas del directorio son ficticias y están marcadas como demostración.',
        actions: const [
          ChatAction(label: 'Pagar ahora', link: AssistantLink.pay),
          ChatAction(label: 'Ver oficinas demo', link: AssistantLink.offices),
          ChatAction(label: 'Contacto', link: AssistantLink.contact),
        ],
      );
    }

    if (_has(q, ['contrato', 'nic', 'suministro'])) {
      return AssistantReply(
        text:
            'Estás viendo el contrato ${contract.number} en ${contract.sector}. La tarifa de demostración es ${contract.tariffCode} y el circuito es ${contract.circuit}. Puedes cambiar de suministro si la cuenta tiene varias propiedades.',
        actions: const [ChatAction(label: 'Mis contratos', link: AssistantLink.contracts)],
      );
    }

    return const AssistantReply(
      text:
          'Puedo ayudarte con el balance, la fecha de vencimiento, el reporte de averías, los trámites y el ahorro de energía. Elige una pregunta sugerida o escríbela con tus palabras. Mis respuestas salen de un catálogo local.',
      actions: [
        ChatAction(label: 'Ver facturas', link: AssistantLink.invoices),
        ChatAction(label: 'Reportar avería', link: AssistantLink.reportOutage),
      ],
    );
  }

  bool _has(String text, List<String> keys) => keys.any(text.contains);
}

const assistantSuggestions = <String>[
  '¿Cuánto debo de electricidad?',
  '¿Cuándo vence mi factura?',
  '¿Cómo puedo reportar una avería?',
  '¿Cómo puedo solicitar un nuevo servicio?',
  '¿Por qué aumentó mi consumo?',
  '¿Cómo puedo ahorrar electricidad?',
  '¿Dónde puedo pagar mi factura?',
];
