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

### Contratos de la cuenta

Andrés es titular de la casa principal `1002345678` (pendiente), el apartamento `1008876543` (sin deuda) y el local `1005520198` (vencido). También tiene vinculados contratos de terceros: Rosa Frías `1004411223`, Luis Peña `1007788990` y Pedro Gómez `1006655443`. Esos se pueden desvincular. Los propios no.

Para agregar otro suministro el número tiene 7 dígitos y la cédula debe cumplir el formato `000-0000000-0` con dígito verificador. En Agregar contrato, **Ver contratos disponibles para demostración** lista los datos. Por ejemplo, `1045821` con cédula `001-3758602-0` (Carmen Díaz) se puede vincular. `4829103`, `5190042` y `6733188` ya están en la cuenta. `0000000` no existe. Si el número existe y la cédula es de otro titular, la verificación no coincide.

En Modo demostración se puede cargar un solo contrato propio, varios propios, propios con terceros o solo terceros.

### Tarjetas de prueba

La cuenta ya tiene una Visa crédito •••• 1111 y una Mastercard débito •••• 4444. Al agregar una tarjeta el formulario agrupa el número de cuatro en cuatro, detecta Visa, Mastercard o American Express, aplica el algoritmo de Luhn y exige un CVV de 3 o 4 dígitos. Solo se guardan la marca, los últimos cuatro dígitos, el nombre, el vencimiento y el tipo. El número completo y el CVV se descartan y no se envían.

En **Agregar tarjeta** y al escribir otra tarjeta en el pago no se acepta un vencimiento anterior al 31/10/2026. El mensaje aparece debajo del campo.

- Éxito: `4111 1111 1111 1111` o Mastercard `5555 5555 5555 4444`
- American Express: `3714 4963 5398 431`, con CVV de 3 o 4 dígitos
- Rechazo: `4111 1131 1111 0002`
- Error de procesamiento: `4111 1161 1111 0005`
- Vencida: `01/26` se rechaza en el formulario

La fecha de referencia de la presentación es el **31/10/2026**. Los vencimientos se calculan contra esa fecha para que el escenario no cambie el día de la demo.

### Pagos simulados

- Tarjeta exitosa: `4111 1111 1111 1111`, vencimiento futuro, CVV `123` o `1234`.
- Tarjeta rechazada: `4111 1131 1111 0002`.
- También existe el interruptor **Forzar rechazo** en la confirmación.
- No se procesa ningún cargo real.

## Qué se puede recorrer

- Splash, onboarding, inicio de sesión, registro, recuperación y verificación de identidad.
- Inicio con suministro, balance, consumo, estado del servicio, accesos y comunicados. El icono de cuadrícula del encabezado abre accesos a contratos, pagos, solicitudes, oficinas, asistente y preguntas frecuentes.
- Facturas con filtro por año y estado, detalle, PDF de demostración y pago simulado.
- Consumo diario, semanal, mensual y de 12 meses, con estimación identificada como simulación.
- Reporte de averías, fotografía, seguimiento y avance de estado para la presentación.
- Mapa esquemático local, sin API Key.
- Catálogo de trámites, formularios, número de solicitud y seguimiento.
- Asistente con catálogo local. No usa OpenAI, Claude ni otro proveedor.
- Notificaciones locales, varios contratos, preferencias, seguridad y centros de atención ficticios.
- Modo demostración: servicio normal, interrupción, factura vencida, avería en proceso y carteras de contratos.
- Pago de uno o varios contratos, historial y métodos de pago guardados sin número completo ni CVV.

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
