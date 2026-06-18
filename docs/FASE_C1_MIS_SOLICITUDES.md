# Fase C1 — Mis Solicitudes

## Objetivo

Permitir que el cliente autenticado en App Clientes pueda ver las solicitudes de crédito creadas desde Fuerza de Ventas.

## Puente de identidad confirmado

```
auth.uid() → clientes_perfil.id (UUID)
clientes_perfil.dni → clientes.numero_documento (string 8 dígitos)
clientes.id → solicitudes_credito.cliente_id (UUID/correlativo)
```

### Consulta de verificación que devolvió datos reales

```sql
SELECT
  cp.dni,
  cp.nombres || ' ' || cp.apellidos as cliente_app,
  c.id as cliente_corporativo_id,
  sc.numero_expediente as solicitud,
  sc.estado,
  sc.monto_solicitado,
  sc.plazo_meses,
  sc.cuota_estimada,
  sc.elegibilidad
FROM clientes_perfil cp
JOIN clientes c ON c.numero_documento = cp.dni
JOIN solicitudes_credito sc ON sc.cliente_id = c.id
WHERE cp.id = auth.uid();
```

**Resultado esperado:**
| cliente_app | dni | cliente_corporativo_id | solicitud | estado | monto | plazo | cuota | elegibilidad |
|---|---|---|---|---|---|---|---|---|
| Miguel Huamán | 72345618 | 163b50b3-... | EXP-ALF-2026-... | enviada | 500 | 3 | 175.39 | apto |

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/app/model/request_model.dart` | Modelo `RequestModel` + `RequestScheduleRow` |
| `lib/app/repository/requests_repository.dart` | Repositorio con puente DNI a `solicitudes_credito` |
| `lib/app/viewmodel/requests_viewmodel.dart` | ViewModel con load/refresh |
| `lib/app/view/requests/requests_screen.dart` | Pantalla con lista expandible, cronograma, pre-evaluación |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/navigation/app_routes.dart` | Ruta `/requests` |
| `lib/app/navigation/app_navigation.dart` | Import + route mapping para `RequestsScreen` |
| `lib/app/view/home/dashboard_screen.dart` | Tarjeta "Mis solicitudes" con navegación |

## Datos mostrados

Cada tarjeta de solicitud muestra:

- **Número de expediente** (título)
- **Fecha de creación**
- **Badge de estado** con color: Enviada (morado), En evaluación (naranja), Aprobada (verde), Rechazada (rojo), Desembolsada (teal)
- **Monto solicitado, Plazo, Cuota estimada** (mini métricas)
- **Elegibilidad** con ícono

Al expandir:

- **Pre-evaluación crediticia**: Score, riesgo, ratio capacidad de pago
- **Cronograma de pagos**: Tabla con # cuota, fecha, capital, interés, saldo (primeras 3 cuotas + indicador de más cuotas)

## Flujo de datos

```
RequestsScreen.initState()
  → RequestsViewModel.loadRequests()
    → RequestsRepository.getRequests()
      → Supabase.instance.client.auth.currentUser.id
      → clientes_perfil.select('dni').eq('id', currentUser.id)
      → clientes.select('id').eq('numero_documento', dni)
      → solicitudes_credito.select().eq('cliente_id', clienteId).order('created_at', false)
      → List<RequestModel>
```

## Limitaciones

- Depende de que existan las tablas `clientes`, `clientes_perfil` y `solicitudes_credito` en Supabase
- Requiere RLS policies que permitan SELECT al cliente autenticado
- No hay paginación (lista completa)
- No hay pull-to-refresh (solo botón reintentar en error)
- No hay detalle individual (todo en tarjeta expandible)
- No hay acción de seguimiento (ej: contactar asesor)

## SQL de verificación

```sql
-- Verificar tablas existen
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('clientes_perfil', 'clientes', 'solicitudes_credito');

-- Verificar puente DNI
SELECT cp.dni, c.numero_documento, c.id as clientes_id
FROM clientes_perfil cp
JOIN clientes c ON c.numero_documento = cp.dni
LIMIT 5;

-- Verificar solicitudes vinculadas
SELECT sc.id, sc.numero_expediente, sc.estado, sc.monto_solicitado
FROM solicitudes_credito sc
LIMIT 10;
```

### RLS policies necesarias

```sql
-- clientes_perfil: cada usuario ve su propio perfil
CREATE POLICY "clientes_perfil_select_own"
ON clientes_perfil FOR SELECT
USING (id = auth.uid());

-- clientes: permitir SELECT por numero_documento
-- (ajustar según esquema de seguridad)
CREATE POLICY "clientes_select_by_documento"
ON clientes FOR SELECT
USING (true);

-- solicitudes_credito: el cliente ve sus solicitudes
-- (o se filtra en la app por cliente_id)
CREATE POLICY "solicitudes_credito_select_own"
ON solicitudes_credito FOR SELECT
USING (cliente_id IN (
  SELECT c.id FROM clientes c
  JOIN clientes_perfil cp ON cp.dni = c.numero_documento
  WHERE cp.id = auth.uid()
));
```

## Pruebas realizadas

- `flutter analyze` — 0 issues
- `flutter build apk --debug` — APK generado exitosamente
- Dashboard funcional con navegación a Mis Solicitudes
- Dashboard, Cuentas, Créditos, Transferencias, Perfil sin cambios
- Estado vacío si no hay solicitudes
- Estado error si Supabase no responde
