# EDESUR Móvil

Prototipo demostrativo de una aplicación Flutter para clientes de EDESUR Dominicana. Recorre el autoservicio de un suministro eléctrico: consulta del estado, contratos, facturas, pagos, consumo, averías, trámites y atención.

Todas las operaciones ocurren en el dispositivo. Los contratos, facturas, tarjetas, averías, solicitudes, notificaciones y respuestas del asistente son datos ficticios. La aplicación no se conecta a los sistemas internos de EDESUR y no envía información a un banco ni a un servicio comercial.

## Características

- **Dashboard y estado del suministro.** Saldo, consumo reciente, estado del servicio y comunicados del contrato activo.
- **Gestión de varios contratos.** La cuenta de demostración puede tener suministros propios y de terceros. El contrato activo cambia facturas, consumo y solicitudes.
- **Vinculación y eliminación según titularidad.** Se puede agregar un suministro de demostración y quitar un contrato de un tercero. Un contrato en el que el usuario figura como titular no se elimina desde la aplicación.
- **Facturación.** Listado con filtro por año y estado, detalle de la factura y PDF de demostración.
- **Pagos individuales.** Una factura pendiente se paga con una tarjeta de crédito o débito. La aplicación simula el procesamiento y muestra el comprobante.
- **Pagos múltiples.** Se eligen una o varias facturas, se calcula el total y una sola tarjeta cubre toda la operación. El resultado es una transacción y un comprobante consolidado.
- **Tarjetas de crédito y débito.** Alta, selección, predeterminada y eliminación. Las marcas contempladas son Visa, Mastercard y American Express.
- **Historial de pagos.** Cada registro muestra marca, tipo, terminación, fecha y hora, número de transacción, contratos, importe en RD$ y estado.
- **Consumo y analítica.** Series diaria, semanal, mensual y de 12 meses, con la estimación identificada como simulación.
- **Reportes y seguimiento de averías.** Registro con tipo, descripción, referencia y fotografía opcional, más el avance de estado para la presentación.
- **Interrupciones.** Mapa esquemático local y avisos del escenario de demostración. No usa un proveedor de mapas ni una API key.
- **Solicitudes y trámites.** Catálogo local, formulario, número de solicitud y seguimiento.
- **Asistente virtual simulado.** Responde con un catálogo incluido en la aplicación. No usa OpenAI, Claude ni otro proveedor.
- **Centro de notificaciones.** Avisos locales de facturas, pagos, averías y solicitudes, con preferencias de la cuenta.
- **Centros de atención.** Directorio de oficinas ficticias, marcadas como demostración, y los teléfonos publicados en el sitio de EDESUR.
- **Modo demostración.** Escenarios de servicio y carteras de contratos, con restauración del estado inicial.
- **Navegación.** Barra inferior con Inicio, Facturas, Averías, Solicitudes y Mi cuenta. El icono de cuadrícula del inicio abre accesos a contratos, agregar contrato, métodos de pago, historial, solicitudes, oficinas, asistente y preguntas frecuentes.

## Métodos de pago

Los únicos métodos de pago de la aplicación son:

- Tarjeta de crédito.
- Tarjeta de débito.

Al pagar se muestran las tarjetas registradas, con marca, tipo, últimos cuatro dígitos, titular e indicador de predeterminada. Se puede cambiar la tarjeta, abrir la gestión de métodos de pago o agregar una tarjeta y volver al pago. Si no hay tarjetas, el pago muestra un estado vacío con **Agregar tarjeta**.

El pago de varias facturas usa una sola tarjeta para toda la transacción. Los importes se muestran en pesos dominicanos (RD$).

El procesamiento es simulado. No se realiza ninguna transacción bancaria real. Una tarjeta guardada con vencimiento `01/26` produce el estado de tarjeta vencida. Al escribir otra tarjeta de prueba, la terminación `0002` simula un rechazo y la terminación `0005` un error del procesador. También existe el interruptor **Forzar rechazo** en la confirmación.

## Reglas de negocio

- Un contrato que se vincula desde **Agregar contrato** tiene exactamente 7 dígitos.
- La cédula dominicana usa el formato `000-0000000-0`. El último dígito se valida como dígito verificador.
- Un usuario puede vincular varios contratos.
- El usuario no puede eliminar un contrato en el que figura como titular. El mensaje es: «No puedes eliminar este contrato porque figuras como su titular. Para gestionar la titularidad del suministro, debes realizar el trámite correspondiente con EDESUR.»
- Un contrato de un tercero que ya está vinculado sí se puede quitar de la cuenta.
- Una factura se puede pagar sola o junto con otras, en una única operación.
- El pago múltiple usa una sola tarjeta para todas las facturas de esa transacción.
- Una tarjeta guardada conserva marca, tipo (crédito o débito), últimos cuatro dígitos, nombre del titular y vencimiento. El número completo y el CVV no se almacenan ni se envían.

La cuenta de Andrés que abre la demostración conserva los números de contrato con los que fue armado el escenario, de 10 dígitos. Esos registros no pasan por el formulario de vinculación. Los suministros que se agregan después, y el catálogo **Ver contratos disponibles para demostración**, usan 7 dígitos.

## Tecnologías

- Flutter y Dart, con Material 3.
- Riverpod 3 para el estado de la aplicación (`appControllerProvider`).
- GoRouter para la navegación.
- SharedPreferences para conservar la sesión de demostración en el dispositivo.
- fl_chart para los gráficos de consumo.
- pdf y printing para los comprobantes de demostración.
- image_picker para la fotografía opcional de una avería.
- share_plus y path_provider para compartir archivos locales.
- url_launcher para teléfonos y correo publicados.
- intl para fechas y la localización en español.
- Dio queda declarado en `EdesurApiClient` como cliente HTTP de una integración futura. El prototipo no ejecuta esas solicitudes.
- Tipografía Poppins, incluida en la aplicación. Los colores salen de la identidad pública de edesur.com.do: naranja `#FD6B0D`, azul marino `#083367` y `#0F1D41`, rojo `#DC052D`.

El identificador de la aplicación es `com.indra.vmo.sgc.edesur` en Android, iOS y Linux.

## Arquitectura

```
lib/
  core/          tema, rutas, constantes, reloj de demostración, semilla y reglas de tarjeta, cédula y tarifa
  domain/        entidades, selectores, contratos de repositorio y casos de uso
  data/          almacenamiento local, codec del snapshot y repositorios mock
  application/   controlador Riverpod que expone los casos de uso a las pantallas
  features/      pantallas por módulo
  shared/        etiquetas y componentes reutilizables
```

Las pantallas no leen el JSON de demostración. Piden la operación al controlador, el caso de uso aplica la regla y el repositorio mock actualiza el snapshot. `EdesurApiClient` deja preparados la URL, los tiempos de espera y el encabezado de sesión para sustituir después las implementaciones mock. El mapa vive en `OutageMapView` y se puede reemplazar más adelante por un mapa con servicio externo.

## Instalación

Requiere Flutter compatible con el SDK de Dart declarado en `pubspec.yaml` (`>=3.8.0 <4.0.0`).

```bash
git clone https://github.com/SentenciaSQL/edesur-app.git
cd edesur-app
flutter pub get
```

Ejecutar en el dispositivo o emulador disponible:

```bash
flutter run
```

En el navegador:

```bash
flutter run -d chrome
```

Generar el APK de depuración, firmado con la configuración debug del proyecto:

```bash
flutter build apk --debug
```

El archivo queda en `build/app/outputs/flutter-apk/app-debug.apk`.

Ejecutar en Android, con un emulador o un teléfono conectado:

```bash
flutter run -d android
```

Ejecutar en iOS, desde macOS, con simulador o dispositivo y los certificados de desarrollo de Xcode:

```bash
flutter run -d ios
```

## Modo demostración

En el acceso se puede entrar con **Entrar en modo demostración**, sin registro. También sirven estas credenciales:

| Campo | Valor |
| --- | --- |
| Nombre | Andrés Frías |
| Correo | andres.frias@demo.edesur.com.do |
| Contraseña | Demo2026 |
| Cédula | 001-0000000-0 |
| Contrato principal | 1002345678 |
| Código de verificación | 123456 |

Andrés es titular de la casa `1002345678` (pendiente), el apartamento `1008876543` (sin deuda) y el local `1005520198` (vencido). Tiene vinculados contratos de terceros: Rosa Frías `1004411223`, Luis Peña `1007788990` y Pedro Gómez `1006655443`. Esos se pueden desvincular. Los propios no.

El historial ya incluye pagos con tarjeta: un crédito aprobado, un débito aprobado, un pago múltiple aprobado, un rechazo (`•••• 0002`), una tarjeta vencida (`•••• 8431`, vencimiento `01/26`) y un error de procesamiento (`•••• 0005`). Esas operaciones no liquidan las facturas que siguen pendientes.

Para agregar otro suministro, el número tiene 7 dígitos y la cédula debe cumplir `000-0000000-0` con dígito verificador. En Agregar contrato, **Ver contratos disponibles para demostración** lista los datos. Por ejemplo, `1045821` con cédula `001-3758602-0` (Carmen Díaz) se puede vincular. `4829103`, `5190042` y `6733188` ya están en la cartera mixta. `0000000` no existe. Si el número existe y la cédula es de otro titular, la verificación no coincide.

La cuenta empieza con una Visa crédito `•••• 1111` (predeterminada), una Mastercard débito `•••• 4444` y una American Express crédito `•••• 8431` vencida el `01/26`. Al agregar una tarjeta, el formulario agrupa el número, detecta la marca, aplica Luhn y acepta un CVV de 3 o 4 dígitos. No se acepta un vencimiento anterior al 31/10/2026. El número completo y el CVV se descartan.

Tarjetas de prueba que se pueden escribir durante el pago, sin guardarlas:

- Éxito: `4111 1111 1111 1111` o Mastercard `5555 5555 5555 4444`, vencimiento futuro, CVV `123` o `1234`.
- American Express: `3714 4963 5398 431`.
- Rechazo: `4111 1131 1111 0002`.
- Error de procesamiento: `4111 1161 1111 0005`.
- Vencida: `01/26` se rechaza en el formulario. La American Express ya guardada permite ver ese resultado al pagarla.

La fecha de referencia de la presentación es el **31/10/2026**. Los vencimientos se calculan contra esa fecha.

En **Mi cuenta > Modo demostración** se puede cargar servicio normal, interrupción, factura vencida o avería en proceso, y una cartera de un solo contrato propio, varios propios, propios con terceros, solo terceros o la cartera mixta. **Restablecer datos de demostración** vuelve a la semilla de Andrés y mantiene la sesión. **Restaurar estado inicial** vuelve a la semilla, cierra la sesión y descarta los cambios locales. Esos cambios, mientras tanto, se guardan en el dispositivo con SharedPreferences.

## Limitaciones

- No hay integración con una API de EDESUR.
- No hay backend real. El estado vive en el dispositivo.
- No se procesan pagos reales.
- No se envían solicitudes, averías ni trámites a EDESUR.
- No se utilizan datos personales reales. Los nombres, cédulas, contratos, teléfonos de clientes y direcciones son ficticios.
- El mapa, las notificaciones y el asistente usan información simulada.
- Las oficinas del directorio son ficticias. Los teléfonos `809-683-9393` y `(809) 683-9292`, y el correo `info@edesur.com.do`, se muestran porque están publicados en el sitio de EDESUR.

## Estado del proyecto

EDESUR Móvil es un prototipo funcional de presentación. La separación entre pantallas, casos de uso y repositorios deja el lugar para conectar más adelante los servicios corporativos de EDESUR, sustituyendo las implementaciones mock sin rehacer la interfaz.
