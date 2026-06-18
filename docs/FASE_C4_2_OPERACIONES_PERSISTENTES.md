# Fase C4.2 — Operaciones persistentes y actualización de saldo

## Objetivo

Implementar persistencia en Supabase para las operaciones de transferencia y pago simuladas. Cuando el cliente confirma una operación, se inserta en tres tablas de forma coordinada:

1. `clientes_operaciones` — registro de la operación
2. `clientes_movimientos` — movimiento contable
3. `clientes_cuentas` — actualización de saldo

## Tablas usadas

| Tabla | Operación | Columnas relevantes |
|-------|-----------|---------------------|
| `clientes_operaciones` | INSERT | `cliente_id`, `cuenta_origen`, `cuenta_destino`, `monto`, `descripcion`, `numero_operacion`, `fecha`, `estado`, `tipo_operacion` |
| `clientes_movimientos` | INSERT | `cliente_id`, `fecha`, `monto`, `es_abono`, `descripcion`, `categoria`, `referencia` |
| `clientes_cuentas` | UPDATE | `saldo`, `saldo_disponible`, `saldo_contable` |

## Flujo de operación

```
TransfersViewModel.confirmOperation()
  │
  ├── 1. Validar fondos: amount <= _availableBalance
  │     Si falla → "Saldo insuficiente para realizar la operación."
  │
  ├── 2. Insertar en clientes_operaciones (vía OperationsRepository.createOperation)
  │     → Obtiene numero_operacion (ALF-OP-{timestamp})
  │
  ├── 3. Insertar en clientes_movimientos (vía AccountsRepository.insertMovement)
  │     → es_abono = false (débito)
  │     → categoria según tipo:
  │       - transferencia → 'Transferencia'
  │       - pagoCredito → 'Pago de crédito'
  │       - pagoServicio → 'Servicios'
  │     → referencia = numero_operacion
  │
  ├── 4. Actualizar saldo en clientes_cuentas (vía AccountsRepository.updateBalance)
  │     → saldo = saldo - monto
  │     → saldo_disponible = saldo_disponible - monto
  │     → saldo_contable = saldo_contable - monto
  │     → Filtra por cliente_id = auth.uid() AND es_principal = true
  │
  └── 5. Mostrar pantalla de éxito
        → N° operación, fecha, monto, tipo, estado, destino
        → "Operación registrada correctamente."
```

## Validación de fondos

- Se carga el saldo real desde `clientes_cuentas` al iniciar el formulario.
- En `validateForContinue()` se valida que `amount <= availableBalance`.
- Si no hay saldo suficiente, se muestra el error en el campo monto.
- Dato simulado: en producción la validación debe hacerse contra el core bancario real.

## Refresco de datos post-operación

- Al volver al Dashboard o Cuentas, se crean nuevos ViewModels (vía `pushReplacementNamed`) que cargan datos frescos desde Supabase.
- El nuevo saldo y movimiento aparecen automáticamente.

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/repository/accounts_repository.dart` | +`getCurrentBalance()`, +`insertMovement()`, +`updateBalance()` |
| `lib/app/viewmodel/transfers_viewmodel.dart` | +`_availableBalance`, +`_balanceLoaded`, +`_operationCategory`; mod `_loadOriginAccount()` para cargar saldo; mod `validateForContinue()` para validar fondos; mod `confirmOperation()` para flujo completo (operación→movimiento→saldo) |
| `lib/app/view/transfers/transfers_screen.dart` | +"Operación registrada correctamente." en pantalla de éxito; +tipo de operación en resumen |

## Logs agregados

| Log | Punto |
|-----|-------|
| `[TRANSFERS] loading real account` | Al cargar cuenta origen |
| `[TRANSFERS] balance=...` | Saldo cargado |
| `[TRANSFERS] validating funds` | Antes de validar saldo |
| `[TRANSFERS] inserting operation` | Antes de insertar en clientes_operaciones |
| `[TRANSFERS] inserting movement` | Antes de insertar en clientes_movimientos |
| `[TRANSFERS] updating balance` | Antes de actualizar clientes_cuentas |
| `[TRANSFERS] operation completed numero=...` | Operación exitosa |
| `[TRANSFERS] error=...` | Error en cualquier paso |

## Limitación — Sin transacción backend

Los tres pasos (operación → movimiento → saldo) se ejecutan desde el cliente Flutter de forma secuencial, no como una transacción atómica. Si falla el paso 3 o 4 después de que el paso 2 ya se completó, la base de datos queda en estado inconsistente.

**En producción**, estos tres pasos deben ejecutarse como una sola función RPC en PostgreSQL:

```sql
CREATE OR REPLACE FUNCTION ejecutar_operacion(
  p_cliente_id UUID,
  p_cuenta_origen TEXT,
  p_cuenta_destino TEXT,
  p_monto NUMERIC,
  p_descripcion TEXT,
  p_tipo_operacion TEXT
) RETURNS JSON AS $$
DECLARE
  v_numero_operacion TEXT;
  v_saldo_actual NUMERIC;
BEGIN
  -- 1. Validar saldo
  SELECT saldo INTO v_saldo_actual
  FROM clientes_cuentas
  WHERE cliente_id = p_cliente_id AND es_principal = true
  FOR UPDATE;

  IF v_saldo_actual < p_monto THEN
    RAISE EXCEPTION 'Saldo insuficiente';
  END IF;

  -- 2. Insertar operación
  v_numero_operacion := 'ALF-OP-' || EXTRACT(EPOCH FROM now())::BIGINT::TEXT;

  INSERT INTO clientes_operaciones
    (cliente_id, cuenta_origen, cuenta_destino, monto, descripcion,
     numero_operacion, fecha, estado, tipo_operacion)
  VALUES
    (p_cliente_id, p_cuenta_origen, p_cuenta_destino, p_monto, p_descripcion,
     v_numero_operacion, now(), 'Completada', p_tipo_operacion);

  -- 3. Insertar movimiento
  INSERT INTO clientes_movimientos
    (cliente_id, fecha, monto, es_abono, descripcion, categoria, referencia)
  VALUES
    (p_cliente_id, now(), p_monto, false, p_descripcion, p_tipo_operacion, v_numero_operacion);

  -- 4. Actualizar saldo
  UPDATE clientes_cuentas
  SET saldo = saldo - p_monto,
      saldo_disponible = saldo_disponible - p_monto,
      saldo_contable = saldo_contable - p_monto
  WHERE cliente_id = p_cliente_id AND es_principal = true;

  RETURN json_build_object(
    'success', true,
    'numero_operacion', v_numero_operacion
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## RLS policies requeridas

```sql
grant select, insert on table public.clientes_operaciones to authenticated;
grant select, insert on table public.clientes_movimientos to authenticated;
grant select, update on table public.clientes_cuentas to authenticated;

create policy if not exists operaciones_select_own on public.clientes_operaciones
  for select to authenticated
  using (cliente_id = auth.uid());

create policy if not exists operaciones_insert_own on public.clientes_operaciones
  for insert to authenticated
  with check (cliente_id = auth.uid());

create policy if not exists movimientos_select_own on public.clientes_movimientos
  for select to authenticated
  using (cliente_id = auth.uid());

create policy if not exists movimientos_insert_own on public.clientes_movimientos
  for insert to authenticated
  with check (cliente_id = auth.uid());

create policy if not exists cuentas_update_own on public.clientes_cuentas
  for update to authenticated
  using (cliente_id = auth.uid())
  with check (cliente_id = auth.uid());
```

## Pruebas realizadas

1. Login con miguel@alfin.demo / 123456
2. Ir a Cuentas → saldo inicial S/ 2,450.80
3. Ir a Transferencias → hacer transferencia de S/ 50.00 → confirmar
4. Pantalla de éxito con número de operación
5. Volver al Dashboard → saldo actualizado S/ 2,400.80
6. Ir a Cuentas → nuevo movimiento arriba
7. Verificar en Supabase:
   - clientes_operaciones: 1 registro nuevo
   - clientes_movimientos: 1 registro nuevo (monto 50, es_abono false)
   - clientes_cuentas: saldo bajó de 2450.80 a 2400.80
8. Probar operación con monto > saldo → "Saldo insuficiente"
9. flutter analyze: 0 issues
10. flutter build apk --debug: exitoso

## Pendiente para C4.3

- RPC transaccional en backend (reemplazar los 3 pasos del cliente)
- Manejo de límite diario de operaciones
- Historial completo de operaciones con paginación
- SQLite / caché offline
