# Evidencias sugeridas — Demo App Cliente (Alfin Banco)

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
