# Evidencias sugeridas — Demo App Cliente (Alfin Banco)

> **Schema actualizado (C4.9):** Se verificaron las 34 columnas de `solicitudes_credito` en Supabase.
> El fallback silencioso fue eliminado: ahora la solicitud se guarda completa o falla con error visible.

Guía para capturas de pantalla y exposición oral. Orden recomendado para una presentación de 8–12 minutos.

---

## 0. Splash — Verificación de sesión

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Logo Alfin, "Alfin Banco", "Verificando sesión..." con spinner |
| **Qué explicar** | Punto de entrada; verifica sesión Supabase, timeout de 5 min e internet; si todo ok va directo al Dashboard; si expiró o no hay sesión va al Login |

---

## 1. Login

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Logo Alfin, título "Alfin Banco", campos DNI y contraseña, botón "Ingresar", enlace "¿No tienes cuenta? Regístrate", texto modo demostración, posible banner de conexión requerida |
| **Qué explicar** | Punto de entrada tras splash; credenciales de ejemplo; muestra banner si no hay internet; en producción validaría contra el core bancario |

---

## 2. Registro

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Formulario completo (DNI, nombres, apellidos, teléfono, correo, contraseñas, términos), botón “Crear cuenta” |
| **Qué explicar** | Validaciones locales (8 dígitos DNI, 9 teléfono, email, contraseña ≥ 6); alta simulada sin backend |

---

## 3. Dashboard

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Saludo “Hola, Diego”, botón Transferencias y Pagos, tarjetas ahorro y crédito, bottom navigation |
| **Qué explicar** | Hub principal del Home Banking; acceso rápido a productos y operaciones |

---

## 4. Cuentas / Ahorros

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Número de cuenta, CCI, saldo disponible y contable, botones estado de cuenta y Transferir |
| **Qué explicar** | Detalle del producto de ahorros; en fase backend vendría del API de cuentas |

---

## 5. Últimos movimientos

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Lista en Dashboard o en pantalla Cuentas (depósitos/retiros con montos y fechas) |
| **Qué explicar** | Trazabilidad de operaciones; categorías y referencias mock |

---

## 6. Créditos

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Préstamo personal, monto pendiente, cuota mensual, TEA, barra de progreso, botón “Pagar cuota” |
| **Qué explicar** | Vista consolidada del crédito activo del cliente |

---

## 7. Cronograma de pagos

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Lista de cuotas con chips Pagado / Pendiente / Vencido |
| **Qué explicar** | Seguimiento de obligaciones; estados visuales para mora y pagos al día |

---

## 8. Transferencias — formulario

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Selector de tipo (Transferencia / Crédito / Servicio), cuenta origen, destino, monto, descripción |
| **Qué explicar** | Un solo flujo para varios tipos de operación; validación antes de continuar |

---

## 9. Resumen de operación

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Card con tipo, origen, destino, monto, descripción y botón “Confirmar operación” |
| **Qué explicar** | Paso de confirmación obligatorio (doble factor en producción) |

---

## 10. Operación exitosa

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Ícono de éxito, número `ALF-OP-XXXX`, fecha, monto, tipo, estado, destino, "Operación registrada correctamente.", botones "Nueva operación" y "Volver al inicio" |
| **Qué explicar** | Comprobante simulado con persistencia en Supabase; se insertó en `clientes_operaciones`, `clientes_movimientos` y se actualizó `clientes_cuentas` |

## 10b. Validación de saldo insuficiente

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Ingresar un monto mayor al saldo disponible → error "Saldo insuficiente para realizar la operación." en el campo monto |
| **Qué explicar** | Validación desde el saldo real cargado de Supabase; en producción se consultaría el core bancario |

## 10c. Saldo actualizado post-operación

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Volver al Dashboard después de una operación exitosa → saldo actualizado; ir a Cuentas → nuevo movimiento arriba |
| **Qué explicar** | Al navegar, los ViewModels se crean frescos y cargan desde Supabase; el nuevo saldo y movimiento se reflejan automáticamente |

---

## 10d. Historial de operaciones

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Pantalla "Mis operaciones" con lista de transferencias/pagos realizados; pull-to-refresh; estado vacío si no hay operaciones |
| **Qué explicar** | Consulta `clientes_operaciones` en Supabase filtrada por `cliente_id = auth.uid()`; ordenado por fecha descendente |

## 10e. Comprobante de operación

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Tocar una operación → pantalla "Comprobante" con N° operación, estado, fecha, tipo, origen, destino, descripción, monto, botones "Volver al inicio" y "Nueva operación" |
| **Qué explicar** | Detalle completo de la operación leído desde Supabase; reemplaza el comprobante local simulado de fases anteriores |

## 11. Perfil de usuario

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Nombre, DNI censurado, correo, teléfono, dirección, tipo de cliente, sección seguridad |
| **Qué explicar** | Datos de identificación; opciones de seguridad en modo demostración |

---

## 12. Mis Solicitudes — Pull-to-refresh

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Lista de solicitudes, hacer pull hacia abajo, ver indicador de refresh, SnackBar si falla |
| **Qué explicar** | Los datos se mantienen si falla el refresh; el RefreshIndicator permite actualización manual |

---

## 13. Mis Solicitudes — Pantalla detalle

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Tocar una solicitud → pantalla detalle con expediente, badge grande, métricas, pre-evaluación, cronograma completo, botón Contactar asesor |
| **Qué explicar** | Vista individual con toda la información de la solicitud; las cuotas se muestran en tarjetas compactas para evitar overflow horizontal |

---

## 14. Contactar asesor

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Botón "Contactar asesor" al final del detalle → AlertDialog con mensaje y número de expediente |
| **Qué explicar** | Acción simulada; en producción enviaría una notificación al asesor asignado |

---

## 10f. Transferencia entre cuentas propias

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Transferencias → seleccionar tipo "Transferencia" → dropdown origen (0011-0456-7890123456, S/ 10,000.00) → dropdown destino (0022-0789-1234567890) → monto S/ 100 → Continuar → Resumen con saldo restante S/ 9,900.00 → Confirmar → "Transferencia entre cuentas realizada" con N° operación, origen, destino, monto |
| **Qué explicar** | Flujo completo: dropdowns con saldo disponible, validación origen≠destino, 5 pasos en Supabase (1 op + 2 mov + 2 actualizaciones saldo); al regresar a Cuentas se ven ambas cuentas actualizadas |

## 10g. CuentasScreen con múltiples cuentas

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Pantalla Cuentas con 2 tarjetas: "Cuenta de ahorros" con badge "Principal" y "Cuenta sueldo" sin badge; cada una con número, CCI, saldo disponible, saldo contable; movimientos debajo |
| **Qué explicar** | `getAccounts()` consulta todas las cuentas del cliente; badge "Principal" cuando `es_principal = true`; sección de movimientos se mantiene igual |

## 10h. Validación de transferencia propia

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Intentar transferir sin seleccionar origen → "Selecciona una cuenta origen."; sin destino → "Selecciona una cuenta destino."; mismo origen y destino → "La cuenta destino debe ser diferente."; monto mayor al saldo → "Saldo insuficiente para realizar la transferencia." |
| **Qué explicar** | Validaciones en `validateForContinue()`; cada mensaje específico según el error |

---

## 10i. Solicitar crédito empresarial — paso 1: Datos del negocio

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Dashboard → tarjeta "Solicitar crédito empresarial" → formulario paso 1: tipo negocio (Comercio), nombre (Bodega Miguel), antigüedad (48), ingresos (2200), gastos (900) |
| **Qué explicar** | Stepper de 3 pasos con indicador visual; validaciones en cada campo; al abrir el formulario, los datos del usuario logueado (nombre, DNI, teléfono) se cargan automáticamente desde `clientes_perfil` |

## 10i-bis. Autocarga de datos del solicitante

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Al abrir Solicitar crédito empresarial: nombre, DNI y teléfono ya aparecen llenos con los datos de Miguel. Burbuja azul informativa: "Datos del usuario cargados. Puede editarlos para probar otro caso." Botón "Restaurar mis datos" visible |
| **Qué explicar** | La app consulta `clientes_perfil` con `auth.uid()`; los campos son editables para probar otros DNI; el botón restaurar vuelve a cargar los datos originales |

## 10j. Solicitar crédito empresarial — paso 2: Datos del crédito

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Paso 2: monto (1000), plazo (12), destino, garantía (sin garantía), seguro (No) |
| **Qué explicar** | Al avanzar, se ejecutan los cálculos: TEA 43.92%, TEM, cuota estimada ~S/ 100.95 |

## 10k. Solicitar crédito empresarial — paso 3: Confirmar

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Preview completa: datos del negocio, datos del crédito, resultados (TEA, cuota, total, capacidad, ratio), badge de pre-evaluación APTO (verde) con score 85 y riesgo Bajo, botón "Enviar solicitud" |
| **Qué explicar** | Pre-evaluación: ratio cuota/capacidad ~4.9% → APTO porque <= 40%; al enviar se genera expediente y se inserta en `solicitudes_credito` |

## 10l. Solicitud enviada — éxito

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Pantalla de éxito: "Solicitud enviada correctamente", N° expediente EXP-ALF-2026-..., estado Enviado, botones "Ver Mis Solicitudes" y "Volver al inicio" |
| **Qué explicar** | La solicitud nace con estado "enviado"; al tocar "Ver Mis Solicitudes" aparece arriba en la lista porque consulta la misma tabla |

---

## 10m. Timeline del expediente en detalle

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Detalle de solicitud → sección "Seguimiento del expediente" con 5 pasos verticales: Solicitud enviada (check ✅), Recibido por comité (check ✅), En evaluación (círculo relleno = actual), Decisión (círculo vacío = pendiente), Desembolso (círculo vacío = pendiente) |
| **Qué explicar** | Mapeo estado→paso: enviado→paso1, recibido_comite→paso2, en_evaluacion→paso3, decisión→paso4, desembolso→paso5; cada paso tiene icono distinto según completado/actual/pendiente |

## 10n. Card de resultado de evaluación

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Para solicitud aprobada: "Resultado de evaluación" → badge verde "Aprobado" + monto aprobado + "Tu crédito fue aprobado y se encuentra pendiente de desembolso."; para rechazado: badge rojo "Rechazado" + motivo + mensaje |
| **Qué explicar** | La card solo aparece si el estado tiene decisión (aprobado/condicionado/rechazado/desembolsado). Si no, muestra "Aún no hay decisión final." + "Te avisaremos cuando tu expediente cambie de estado." |

## 10o. Lista de solicitudes mejorada

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Cada tarjeta en Mis Solicitudes muestra: expediente, monto · plazo, badge de estado, descripción corta "Tu solicitud fue registrada correctamente...", "Paso 1 de 5", fecha de última actualización |
| **Qué explicar** | Subtítulo usa `statusDescription` del modelo; paso se calcula con `statusStepIndex`; `updatedAt` muestra última modificación si existe |

## 10q. Pago de cuota — Formulario y confirmación

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Créditos → tocar "Pagar cuota" → card crédito (nombre, monto pendiente, cuota mensual) → card "Siguiente cuota" (# cuota, fecha, cuota, capital, interés, saldo posterior) → dropdown cuentas origen con saldo → "Confirmar pago" → AlertDialog confirmación (crédito, cuota, cuenta origen, monto) → pantalla éxito con "Pago registrado correctamente", N° operación, fecha, cuota, monto, botones "Ver créditos" y "Ver operaciones" |
| **Qué explicar** | Flujo completo: selecciona la siguiente cuota pendiente del cronograma, elige cuenta origen con saldo suficiente, confirma; se debita la cuenta, inserta movimiento y operación PAGO_CUOTA_CREDITO, marca cuota Pagado, reduce monto pendiente del crédito; si era la última cuota, el crédito pasa a CANCELADO |

## 10r. Crédito actualizado post-pago

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Volver a Créditos después del pago → cuota aparece "Pagado", monto pendiente reducido, progreso actualizado; si era la última cuota → botón "Pagar cuota" desaparece, muestra "Crédito al día" |
| **Qué explicar** | El ViewModel recarga datos al regresar; la cuota se lee desde Supabase con estado Pagado; el crédito refleja el nuevo monto pendiente y progreso |

## 10s. Saldo actualizado post-pago de cuota

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Ir a Cuentas → saldo de la cuenta origen reducido por el monto de la cuota pagada; movimiento "Pago de cuota X del crédito Y" visible; ir a Mis operaciones → operación con tipo PAGO_CUOTA_CREDITO visible |
| **Qué explicar** | El débito, movimiento y operación se insertan en Supabase de forma secuencial; los ViewModels cargan los datos frescos al navegar |

## 10t. Validación de saldo insuficiente en pago de cuota

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Seleccionar cuenta origen con saldo menor a la cuota → intentar pagar → error "Saldo insuficiente para pagar la cuota." en card roja |
| **Qué explicar** | Validación desde el saldo disponible real de la cuenta; se compara con el monto total de la cuota antes de ejecutar el débito |

## 10u. Validación de cuota ya pagada (re-query)

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Pagar una cuota → volver a intentar pagar la misma cuota (simulado recargando) → error "La cuota ya fue pagada." |
| **Qué explicar** | Antes de ejecutar el pago, el repositorio vuelve a consultar la cuota por `id` para verificar que siga en estado `'pendiente'`. Si otro proceso o intento previo ya la pagó, se rechaza con mensaje claro |

---

## 10p. Dashboard — Estado de tus expedientes

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Sección en Dashboard debajo de Mis Operaciones: título "Estado de tus expedientes", último expediente con badge y paso, 3 chips: En evaluación (0), Aprobados (0), Rechazados (0). Al tocar va a Mis Solicitudes |
| **Qué explicar** | Datos cargados desde `RequestsRepository.getRequests()` en el HomeViewModel; conteos con filtros por estado (evaluationCount, approvedCount, rejectedCount) |

## 15. Cierre de sesión

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Botón cerrar sesión en Perfil o icono en Dashboard → pantalla Login |
| **Qué explicar** | Fin de sesión; en producción invalidaría token y limpiaría datos sensibles |

---

## Tips para la exposición

- Usar un solo dispositivo o emulador con tema claro.
- Nombrar siempre **Alfin Banco** y **modo demostración** al hablar de datos ficticios.
- Cerrar con roadmap: Supabase/API, persistencia, notificaciones (ver `README.md`).
