# Fase C4.8 — Pago de cuota del crédito

## Objetivo
Permitir que el cliente pague la siguiente cuota pendiente de un crédito activo desde App Clientes, cerrando el flujo principal de crédito: Solicitud → seguimiento → desembolso → crédito activo → cronograma → pago de cuota.

## Schema real de `clientes_cronograma_pagos`

| Columna | Tipo | Uso en pago |
|---------|------|-------------|
| `id` | bigint / uuid | Identificador único para UPDATE |
| `cliente_id` | uuid | Filtro de seguridad |
| `credito_id` | uuid | Relación con crédito |
| `numero_cuota` | int | Número de cuota |
| `fecha_vencimiento` | timestamptz | Fecha de vencimiento |
| `monto` | numeric | Monto total de la cuota (usado para el débito) |
| `estado` | text | Valores: 'pendiente', 'pagado', 'vencido' |
| `fecha_pago` | timestamptz | Fecha real de pago (nulleable) |
| `created_at` | timestamptz | Auditoría |

**NO existen**: `cuota`, `capital`, `interes`, `saldo`, `fecha_pago_real`, `numero_operacion`

## Schema real de `clientes_creditos`

`monto_pendiente` se reduce por el monto total de la cuota (columna `capital` no existe en cronograma).

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/app/repository/credit_payment_repository.dart` | Lógica de pago: validación, actualización de cronograma, crédito, débito, movimiento, operación |
| `lib/app/viewmodel/credit_payment_viewmodel.dart` | Estado del formulario: carga de cuota pendiente, selección de cuenta, validación, confirmación |
| `lib/app/view/credits/credit_payment_screen.dart` | UI de pago: resumen crédito, detalle cuota, dropdown cuentas, confirmación, éxito |
| `docs/FASE_C4_8_PAGO_CUOTA_CREDITO.md` | Este documento |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/model/payment_schedule_model.dart` | Eliminados campos `fechaPagoReal`, `numeroOperacion` (no existen en schema real); parseo robusto de estados en minúscula |
| `lib/app/model/credit_model.dart` | Campos usando schema real: `progreso_pago`, `monto_original`, `proxima_fecha_pago`; eliminados `cuotasPagadas`, `totalCuotas`; agregado `isActive` |
| `lib/app/repository/credit_payment_repository.dart` | Flujo reordenado con rollback (snapshot → debit → movement → operation → cuota → crédito); solo columnas reales (`progreso_pago`, `monto_pendiente`, `estado`, `activo`); reduce `monto_pendiente` por `installment.amount` |
| `lib/app/viewmodel/credit_payment_viewmodel.dart` | Manejo de mensajes de error específicos según el error |
| `lib/app/view/credits/credit_payment_screen.dart` | Labels corregidos (N° de cuota, Fecha de vencimiento, Monto) |
| `lib/app/viewmodel/credits_viewmodel.dart` | Nuevo método `reload()` |
| `lib/app/view/credits/credits_screen.dart` | Botón "Pagar cuota" condicional; navega a `CreditPaymentScreen` |
| `lib/app/navigation/app_routes.dart` | Ruta `/credits/payment` |
| `lib/app/navigation/app_navigation.dart` | `onGenerateRoute` para `CreditModel` |

## Flujo de pago (orden corregido)

1. **Cliente entra a Créditos** — ve crédito activo, cronograma, botón "Pagar cuota" si hay cuotas pendientes
2. **Toca "Pagar cuota"** — navega a `CreditPaymentScreen` con el `CreditModel`
3. **Carga datos** — `CreditPaymentViewModel.loadData()` obtiene cronograma, selecciona primera cuota `status == pending`, carga cuentas
4. **Selecciona cuenta origen** — toca cuenta de la lista
5. **Confirma pago** — `AlertDialog` con resumen
6. **Ejecución en `CreditPaymentRepository`**:

   a. **Validar estado actual**: re-consulta la cuota por `id` para verificar que siga `'pendiente'`
   b. **Validar saldo**: `availableBalance >= installment.amount`
   c. **Snapshot**: guarda valores originales de cuenta, movimiento, operación y crédito para rollback
   d. **Debitar cuenta**: reducir `saldo`, `saldo_disponible`, `saldo_contable`
   e. **Insertar movimiento**: `es_abono = false`, categoría 'Pago de crédito'
   f. **Insertar operación**: `tipo_operacion = 'PAGO_CUOTA_CREDITO'`
   g. **Actualizar cronograma**: `estado = 'pagado'`, `fecha_pago = now()`
   h. **Actualizar crédito**: `monto_pendiente -= installment.amount`, recalcular `progreso_pago`, si `monto_pendiente <= 0` → `estado = 'CANCELADO'`, `activo = false`; si hay siguiente cuota pendiente → actualizar `proxima_fecha_pago`

   Si falla cualquier paso entre d y h, se ejecuta rollback automático restaurando valores del snapshot.

7. **Vuelve a Créditos** — `CreditsViewModel.reload()` recarga todo: cuota aparece pagada, monto pendiente reducido

## Detección de la siguiente cuota pendiente

```dart
final schedule = await _creditsRepository.getPaymentSchedule(creditoId: id);
final pending = schedule.where((s) => s.status == PaymentInstallmentStatus.pending);
nextInstallment = pending.isNotEmpty ? pending.first : null;
```

El repositorio ordena por `numero_cuota` ascendente. `PaymentInstallmentStatus.pending` se normaliza desde cualquier variante: `'pendiente'`, `'Pendiente'`, `'PENDING'` → todas resuelven a `pending`.

## Validación de saldo

```dart
final available = originAccount.availableBalance ?? originAccount.balance;
if (available < cuotaMonto) {
  throw StateError('Saldo insuficiente para pagar la cuota.');
}
```

Usa `saldo_disponible` si existe, o `saldo` como fallback.

## Actualización de cronograma (solo columnas reales)

```sql
update clientes_cronograma_pagos
set estado = 'pagado', fecha_pago = now()
where id = ? and cliente_id = ?
```

No se actualizan `fecha_pago_real` ni `numero_operacion` porque no existen.

## Actualización de crédito

`monto_pendiente` se reduce por el monto total de la cuota (`installment.amount`), no por capital (columna no disponible en schema real).

```dart
final newPending = (oldMontoPendiente - cuotaMonto).clamp(0, double.infinity);
final newProgress = (montoOriginal - newPending) / montoOriginal;
```

Columnas reales actualizadas:

| Columna | Valor |
|---------|-------|
| `monto_pendiente` | `oldValue - installment.amount` (clamp a 0) |
| `progreso_pago` | `(montoOriginal - newPending) / montoOriginal` (0.0–1.0) |
| `estado` | `'CANCELADO'` si newPending <= 0, sino `'ACTIVO'` |
| `activo` | `false` si cancelado, `true` si activo |
| `proxima_fecha_pago` | Fecha de vencimiento de la siguiente cuota pendiente (si existe y se puede consultar) |
| `fecha_proximo_pago` | Igual que `proxima_fecha_pago` (para compatibilidad) |

No se usan `cuotas_pagadas`, `total_cuotas`, `progreso` porque no existen en schema real.

## Registro de movimiento y operación

**Movimiento** (`clientes_movimientos`):
- `monto` = monto total de la cuota
- `es_abono` = false
- `categoria` = 'Pago de crédito'
- `referencia` = número de operación

**Operación** (`clientes_operaciones`):
- `cuenta_destino` = 'Crédito Alfin'
- `tipo_operacion` = 'PAGO_CUOTA_CREDITO'
- `numero_operacion` = `ALF-CUOTA-{timestamp}`

## Rollback automático

Antes de ejecutar pasos destructivos, se toma snapshot de:

- `clientes_cuentas`: saldo, saldo_disponible, saldo_contable originales
- `clientes_cronograma_pagos`: estado, fecha_pago originales
- `clientes_creditos`: monto_pendiente, progreso_pago, estado, activo, proxima_fecha_pago originales

Si falla cualquier paso entre débito y actualización de crédito:

1. Restaurar saldo de cuenta a valores originales
2. Eliminar movimiento insertado (por `id`)
3. Eliminar operación insertada (por `id`)
4. Restaurar cuota a `estado = 'pendiente'` y `fecha_pago` original
5. Restaurar crédito a valores originales

Cada rollback es independiente (try/catch individual) para maximizar chances de recuperación.

## Manejo de errores

| Condición | Mensaje |
|-----------|---------|
| Cuota ya pagada (re-query) | "La cuota ya fue pagada." |
| Saldo insuficiente | "Saldo insuficiente para pagar la cuota." |
| Error general | "No se pudo registrar el pago." |

## Logs de depuración

```
[CREDIT_PAYMENT] validating installment status
[CREDIT_PAYMENT] validating account balance
[CREDIT_PAYMENT] update installment
[CREDIT_PAYMENT] update credit
[CREDIT_PAYMENT] debit account
[CREDIT_PAYMENT] insert movement
[CREDIT_PAYMENT] insert operation
[CREDIT_PAYMENT] payment completed numero=...
[CREDIT_PAYMENT] error=...
```

## Schema real de `clientes_creditos`

| Columna | Tipo | Uso en pago |
|---------|------|-------------|
| `id` | uuid | Identificador |
| `cliente_id` | uuid | Filtro de seguridad |
| `nombre_producto` / `producto` | text | Nombre del crédito |
| `monto_original` | numeric | Para calcular progreso |
| `monto_pendiente` | numeric | Se reduce por el monto de la cuota |
| `cuota_mensual` | numeric | Cuota mensual del crédito |
| `proxima_fecha_pago` o `fecha_proximo_pago` | timestamptz | Siguiente fecha de pago |
| `tea_referencial` / `tea` | numeric | Tasa de interés |
| `progreso_pago` | numeric | Progreso (0.0–1.0) |
| `estado` | text | `'ACTIVO'` o `'CANCELADO'` |
| `activo` | bool | `true` si activo |

**NO existen**: `progreso`, `cuotas_pagadas`, `total_cuotas`

No requiere cambios en `clientes_cronograma_pagos` — se usa schema real existente.

## Permisos recomendados

```sql
grant select, update on table public.clientes_creditos to authenticated;
grant select, update on table public.clientes_cronograma_pagos to authenticated;
grant select, update on table public.clientes_cuentas to authenticated;
grant select, insert on table public.clientes_movimientos to authenticated;
grant select, insert on table public.clientes_operaciones to authenticated;
```

## Próximos pasos

- C4.9 — Pago de Luz, Metas de ahorro, Depósito
- C5 — RPC transaccional, paginación, filtros, PDF, SQLite offline, notificaciones, biometría, tests, Core/FastAPI
