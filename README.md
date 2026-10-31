# EDESUR Móvil

Prototipo demostrativo de una aplicación de autoservicio para clientes de Edesur Dominicana. Presenta el recorrido desde el acceso hasta facturas, pagos, consumo, averías y solicitudes, con datos ficticios y sin conexión a los sistemas comerciales de EDESUR.

## Identidad visual

Los colores y el logotipo salen de los recursos públicos de [edesur.com.do](https://edesur.com.do):

- Naranja `#FD6B0D`, usado en botones y en la palabra «sur» del logotipo oficial.
- Azul marino `#083367` / `#0F1D41`, usado en la palabra «ede» y en la navegación del sitio.
- Rojo `#DC052D` para errores, interrupciones y estados críticos.
- Tipografía Poppins, la misma familia del sitio. Los archivos provienen de Google Fonts y van incluidos en la aplicación para que la interfaz se vea igual sin red y compile en web.

El logotipo es el archivo público `logo.png` del sitio. No se redibujó ni se sustituyó. El icono de la aplicación usa el isotipo público del sitio, sobre fondo blanco.

## Cómo ejecutar

```bash
flutter pub get
flutter run
```

En el navegador:

```bash
flutter run -d chrome
```

## Cuenta de demostración

| Campo | Valor |
| --- | --- |
| Nombre | Andrés Frías |
| Correo | andres.frias@demo.edesur.com.do |
| Contraseña | Demo2026 |
| Cédula | 001-0000000-0 |
| Contrato principal | 1002345678 |
| Código de verificación | 123456 |

También se puede entrar con **Entrar en modo demostración**, sin registro.

La fecha de referencia de la presentación es el **31/10/2026**. Los vencimientos se calculan contra esa fecha para que el escenario no cambie el día de la demo.

### Pagos simulados

- Tarjeta exitosa: `4111 1111 1111 1111`, vencimiento futuro, CVV `123`.
- Tarjeta rechazada: cualquier número de 16 dígitos terminado en `0002`.
- También existe el interruptor **Forzar rechazo** en la confirmación.
- No se procesa ningún cargo real.

## Qué se puede recorrer

- Splash, onboarding, inicio de sesión, registro, recuperación y verificación de identidad.
- Inicio con suministro, balance, consumo, estado del servicio, accesos y comunicados.
- Facturas con filtro por año y estado, detalle, PDF de demostración y pago simulado.
- Consumo diario, semanal, mensual y de 12 meses, con estimación identificada como simulación.
- Reporte de averías, fotografía, seguimiento y avance de estado para la presentación.
- Mapa esquemático local, sin API Key.
- Catálogo de trámites, formularios, número de solicitud y seguimiento.
- Asistente con catálogo local. No usa OpenAI, Claude ni otro proveedor.
- Notificaciones locales, varios contratos, preferencias, seguridad y centros de atención ficticios.
- Modo demostración: servicio normal, interrupción, factura vencida y avería en proceso.

Los cambios de la demostración se guardan en el dispositivo con SharedPreferences.

## Arquitectura

```
lib/
  core/        tema, rutas, utilidades, cliente Dio y datos semilla
  domain/      entidades, contratos de repositorio y casos de uso
  data/        almacenamiento local, codec y repositorios mock
  application/ controlador de estado con Riverpod
  features/    pantallas
  shared/      componentes reutilizables
```

`EdesurApiClient` deja preparado Dio (base URL, tiempos de espera y encabezado de sesión) para una integración futura. Las pantallas hablan con los casos de uso y los repositorios, no con el JSON de demostración. Para conectar los servicios reales se sustituyen las implementaciones mock sin rehacer la interfaz.

El mapa vive en `OutageMapView`. Se puede reemplazar más adelante por un mapa con servicio externo; este prototipo no requiere API Key.

## Oficinas y contacto

Las cinco oficinas del directorio son ficticias y están rotuladas como demostración. Los teléfonos `809-555-01xx` no corresponden a locales reales.

Los teléfonos `809-683-9393` y `(809) 683-9292`, y el correo `info@edesur.com.do`, se muestran como canales publicados en el sitio de EDESUR.
