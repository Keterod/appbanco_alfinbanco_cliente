# Fase C4.4 — Transferencia entre cuentas propias

## Objetivo

Implementar transferencia entre cuentas propias para que el cliente pueda elegir una cuenta origen y una cuenta destino propias, y pasar dinero entre ambas.

## Cuentas de prueba en Supabase

Tabla `clientes_cuentas` para `auth_user_id = 9566e399-21b6-4f4f-bb30-b133e4c2deb0`:

| Número de cuenta | Tipo | es_principal |
|------------------|------|-------------|
| 0011-0456-7890123456 | Cuenta de ahorros | true |
| 0022-0789-1234567890 | Cuenta sueldo | false |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/model/account_model.dart` | +`isPrincipal` field |
| `lib/app/repository/accounts_repository.dart` | +`getAccounts()`, +`debitAccount()`, +`creditAccount()` |
| `lib/app/viewmodel/accounts_viewmodel.dart` | +`accounts` list, carga todas las cuentas |
| `lib/app/view/accounts/accounts_screen.dart` | Muestra múltiples cuentas como tarjetas con badge "Principal" |
| `lib/app/viewmodel/transfers_viewmodel.dart` | +`userAccounts`, +`selectedOrigin/Destination`, +validación origen≠destino, +flujo TRANSFERENCIA_PROPIA |
| `lib/app/view/transfers/transfers_screen.dart` | Dropdowns origen/destino para Transferencia, resumen con saldo restante, pantalla de éxito específica |

## Cómo se cargan las cuentas

`AccountsRepository.getAccounts()` → consulta `clientes_cuentas` con `cliente_id = auth.uid()`, ordena por `es_principal desc, numero_cuenta asc`, retorna `List<AccountModel>`. Tanto `AccountsViewModel` como `TransfersViewModel` llaman este método.

Logs: `[ACCOUNTS] loading user accounts`, `[ACCOUNTS] accounts found=N`

## Cómo funciona la transferencia entre cuentas propias

### Formulario
- **Tipo TRANSFERENCIA**: al seleccionar "Transferencia" se muestran 2 dropdowns.
- **Dropdown origen**: lista todas las cuentas con tipo, número y saldo disponible.
- **Dropdown destino**: lista todas las cuentas excluyendo la cuenta origen seleccionada.
- El saldo disponible mostrado en el resumen corresponde a la cuenta origen.

### Validaciones
- Origen obligatorio → "Selecciona una cuenta origen."
- Destino obligatorio → "Selecciona una cuenta destino."
- Origen = destino → "La cuenta destino debe ser diferente."
- Monto > 0 → "Ingrese un monto mayor a 0"
- Monto > saldo → "Saldo insuficiente para realizar la transferencia."

### Confirmación
Secuencia de 5 pasos dentro de `TransfersViewModel.confirmOperation()`:

1. **Insertar operación** → `clientes_operaciones` con `tipo_operacion = 'TRANSFERENCIA_PROPIA'`
2. **Insertar movimiento débito** → `clientes_movimientos` con `descripcion = 'Transferencia enviada a cuenta {destino}'`
3. **Insertar movimiento abono** → `clientes_movimientos` con `descripcion = 'Transferencia recibida desde cuenta {origen}'`
4. **Debitar cuenta origen** → `AccountsRepository.debitAccount()` lee saldos actuales, resta el monto y actualiza
5. **Acreditar cuenta destino** → `AccountsRepository.creditAccount()` lee saldos actuales, suma el monto y actualiza

### Pantalla de éxito
- Título: "Transferencia entre cuentas realizada"
- Datos: N° operación, fecha, monto, tipo (TRANSFERENCIA_PROPIA), estado, cuenta origen, cuenta destino
- Botones: "Nueva operación", "Volver al inicio"

### Refresco
- Dashboard: al volver, muestra saldos actualizados (ambas cuentas)
- Cuentas: lista de cuentas con valores actualizados
- Mis operaciones: la transferencia aparece como tipo `TRANSFERENCIA_PROPIA`
- Comprobante: muestra origen y destino con tipo de cuenta

## Persistencia

### debitAccount(accountNumber, amount)
1. Lee saldo, saldo_disponible, saldo_contable de la cuenta
2. Resta amount de cada uno
3. Actualiza en `clientes_cuentas` filtrando por `cliente_id = auth.uid()` y `numero_cuenta`

### creditAccount(accountNumber, amount)
1. Lee saldo, saldo_disponible, saldo_contable de la cuenta
2. Suma amount a cada uno
3. Actualiza en `clientes_cuentas` filtrando por `cliente_id = auth.uid()` y `numero_cuenta`

## Resultados de verificación

| Comando | Resultado |
|---------|-----------|
| `flutter analyze` | 0 issues ✅ |
| `flutter build apk --debug` | APK generado ✅ |

## SQL/RLS (documentación)

Permisos necesarios en Supabase:
```sql
grant select, update on table public.clientes_cuentas to authenticated;
grant select, insert on table public.clientes_movimientos to authenticated;
grant select, insert on table public.clientes_operaciones to authenticated;
```

Policies necesarias:
- `clientes_cuentas`: SELECT y UPDATE donde `cliente_id = auth.uid()`
- `clientes_movimientos`: SELECT e INSERT donde `cliente_id = auth.uid()`
- `clientes_operaciones`: SELECT e INSERT donde `cliente_id = auth.uid()`

## Próxima fase (C4.5 — Pago de servicio Luz)

Implementar pago de servicio de luz con:
- Selección de cuenta origen
- Selección de servicio (Luz del Sur)
- Ingreso de código de suministro
- Consulta de monto a pagar
- Confirmación y persistencia (débito, sin crédito)
