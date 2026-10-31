class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/auth/login';
  static const register = '/auth/registro';
  static const recover = '/auth/recuperar';
  static const verify = '/auth/verificar';
  static const home = '/app/inicio';
  static const invoices = '/app/facturas';
  static const outages = '/app/averias';
  static const requests = '/app/solicitudes';
  static const account = '/app/cuenta';
  static const consumption = '/consumo';
  static const reportOutage = '/reportar-averia';
  static const map = '/mapa';
  static const assistant = '/asistente';
  static const notifications = '/notificaciones';
  static const offices = '/oficinas';
  static const personal = '/cuenta/datos';
  static const contracts = '/cuenta/contratos';
  static const security = '/cuenta/seguridad';
  static const preferences = '/cuenta/preferencias';
  static const faq = '/cuenta/preguntas';
  static const contact = '/cuenta/contacto';
  static const demo = '/cuenta/demostracion';

  static String invoice(String id) => '/facturas/$id';
  static String pay(String id) => '/pagar/$id';
  static String receipt(String id) => '/comprobante/$id';
  static String outage(String id) => '/averias/$id';
  static String request(String id) => '/solicitudes/$id';
  static String requestForm(String type) => '/tramite/$type';
  static String notification(String id) => '/notificaciones/$id';
  static String office(String id) => '/oficinas/$id';
}
