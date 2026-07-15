# Fase C4.9 — Soporte para 30 casos de crédito empresarial

## Objetivo

Garantizar que la App Clientes pueda probar manualmente cualquiera de los 30 casos de crédito empresarial desde el lado del cliente, sin depender de un asesor o DNI específico.

## Schema real verificado

Se verificaron en Supabase las siguientes columnas de `solicitudes_credito`:

| Columna | Tipo | Uso |
|---------|------|-----|
| `numero_expediente` | text | Identificador único del expediente |
| `cliente_id` | uuid | FK a `clientes.id` — representa al solicitante del caso |
| `created_by_auth_id` | uuid | FK a `auth.users.id` — usuario logueado que registró la solicitud |
| `monto_solicitado` | numeric | Monto solicitado por el cliente |
| `plazo_meses` | int | Plazo en meses |
| `cuota_estimada` | numeric | Cuota calculada |
| `cronograma_json` | jsonb | Cronograma preliminar generado |
| `score_pre_evaluacion` | int | Score de la pre-evaluación |
| `elegibilidad` | text | APTO / OBSERVADO / NO APTO |
| `ratio_capacidad_pago` | numeric | Ratio cuota / capacidad |
| `riesgo_asignado` | text | Bajo / Medio / Alto |
| `motivo_pre_evaluacion` | text | Motivo de la pre-evaluación |
| `estado` | text | enviado, recibido_comite, en_evaluacion, aprobado, condicionado, rechazado, desembolsado |
| `tipo_negocio` | text | Comercio, Servicios, Producción, Agropecuario |
| `nombre_negocio` | text | Nombre del negocio |
| `antiguedad_negocio_meses` | int | Antigüedad del negocio |
| `ingresos_estimados` | numeric | Ingresos mensuales |
| `gastos_mensuales` | numeric | Gastos mensuales |
| `destino_credito` | text | Capital de trabajo, maquinaria, etc. |
| `garantia` | text | Sin garantía, Aval, Hipotecaria, Prendaria |
| `tea_referencial` | numeric | TEA calculada |
| `seguro_desgravamen` | text | Sí / No |
| `estado_buro` | text | NORMAL, CPP, DEFICIENTE, DUDOSO, PERDIDA |
| `entidades_deuda` | int | Entidades con deuda |
| `deuda_total` | numeric | Deuda total |
| `dias_mayor_mora` | int | Días de mayor mora |
| `en_lista_inhabilitados` | bool | Si está en lista de inhabilitados |
| `solicitante_documento` | text | DNI del solicitante |
| `solicitante_nombre` | text | Nombre del solicitante |
| `solicitante_telefono` | text | Teléfono del solicitante |
| `canal` | text | 'cliente' para solicitudes desde App Clientes |
| `created_at` | timestamptz | Fecha de creación |
| `updated_at` | timestamptz | Fecha de actualización |
| `monto_aprobado` | numeric | Monto aprobado (para condicionado) |
| `motivo_rechazo` | text | Motivo de rechazo |
| `fecha_decision` | timestamptz | Fecha de decisión |
| `fecha_desembolso` | timestamptz | Fecha de desembolso |
| `observacion_evaluador` | text | Observaciones del evaluador |

## Modelo de datos

- `solicitudes_credito.cliente_id` → `clientes.id`: identifica al **solicitante** del caso (persona natural o negocio que pide el crédito).
- `solicitudes_credito.created_by_auth_id` → `auth.users.id`: identifica al **usuario logueado** que registró la solicitud en la demo.
- Esto permite que un asesor (ej. Miguel Huamán) registre casos con DNI de otros solicitantes y luego los vea en Mis Solicitudes.

## Cambios realizados

### 1. Fallback silencioso eliminado

**Antes:** `submitRequest()` tenía 3 niveles de intentos:
1. Insert completo con todos los campos
2. Si falla, insert con campos mínimos
3. Si falla, insert con campos super-mínimos

Esto ocultaba errores de schema y permisos, guardando solicitudes incompletas sin notificar al usuario.

**Ahora:** Un solo insert con todos los campos. Si falla, el error se propaga y se muestra al usuario:
> "No se pudo registrar la solicitud. Verifique la conexión, permisos o configuración de Supabase."

### 2. Creación de cliente mejorada

`findOrCreateClientByDni()` ahora intenta guardar:
- `numero_documento`
- `nombres` (nombre completo del solicitante)
- `telefono`
- `tipo_cliente` = 'microempresa'
- `created_at`

Si las columnas `nombres` o `telefono` no existen en la tabla `clientes`, el insert continúa con los campos disponibles (manejo seguro en creación de cliente, no en la solicitud principal).

### 3. Logs claros

```
[LOAN_REQUEST] insert request payload={...}
[LOAN_REQUEST] insert failed=<error>
[LOAN_REQUEST] request not created
```

### 4. Autocarga de datos del usuario logueado

Al abrir "Solicitar crédito empresarial":

1. Se consulta `clientes_perfil` usando `auth.uid()` para obtener DNI, nombres, apellidos y teléfono.
2. Si hay perfil, los campos se precargan automáticamente.
3. Se muestra mensaje informativo: *"Datos del usuario cargados. Puede editarlos para probar otro caso."*
4. Si no hay perfil: *"Complete los datos del solicitante manualmente."*

**Editabilidad**: los campos NO están bloqueados. El usuario puede cambiar DNI, nombre o teléfono para probar los 30 casos.

**created_by_auth_id** siempre guarda al usuario logueado, independientemente del DNI que se ingrese.

**solicitante_documento** guarda el DNI ingresado en el formulario (puede ser distinto del usuario logueado).

Existe un botón **"Restaurar mis datos"** que recarga los datos originales del usuario logueado.

### Pruebas manuales de autocarga

**Caso A — Login con Miguel:**
1. Login como Miguel.
2. Ir a Solicitar crédito empresarial.
3. Verificar que nombre, DNI y teléfono de Miguel aparecen precargados.

**Caso B — Cambiar DNI para otro caso:**
1. Cambiar DNI por 40118120.
2. Enviar solicitud.
3. Verificar que `solicitante_documento` = 40118120 en Supabase.
4. Verificar que `created_by_auth_id` sigue siendo el auth.uid de Miguel.

**Caso C — Restaurar datos:**
1. Tocar "Restaurar mis datos".
2. Verificar que vuelve a cargar DNI/nombre/teléfono de Miguel.

## Archivos modificados

- `lib/app/repository/client_loan_request_repository.dart` — Eliminación del fallback silencioso + getCurrentLoggedApplicant()
- `lib/app/viewmodel/client_loan_request_viewmodel.dart` — loadCurrentLoggedApplicant(), restoreApplicantData()
- `lib/app/view/loan_request/client_loan_request_screen.dart` — Init con autocarga, info banner, botón restaurar
- `docs/RESUMEN_TECNICO.md` — Limitación actualizada
- `docs/CHECKLIST_EVALUACION.md` — Items 69-72 agregados
- `docs/PENDIENTES_TECNICOS.md` — Sección C4.9 agregada
- `docs/EVIDENCIAS_DEMO.md` — Nota de schema actualizado
- `docs/FASE_C4_9_SOPORTE_30_CASOS_CREDITO.md` — Este documento (actualizado)

## Pruebas representativas desde App Clientes

La app puede probar los siguientes casos configurando los campos del formulario:

| Caso | Configuración |
|------|--------------|
| Aprobado sin seguro | Ingresos altos, gastos bajos, buró NORMAL, ratio ≤ 0.40, seguro NO |
| Aprobado con seguro | Ingresos altos, gastos bajos, buró NORMAL, ratio ≤ 0.40, seguro SÍ |
| Monto alto | S/ 50,000+ con ingresos y capacidad suficientes |
| Condicionado | Se marca en backend como estado=condicionado con monto_aprobado menor |
| Rechazado por inhabilitado | Marcar "En lista de inhabilitados" = Sí |
| Rechazado por capacidad | Ingresos < gastos o capacidad disponible ≤ 0 |
| Rechazado por buró DUDOSO con mora | Buró = DUDOSO, días mora ≥ 90 |
| Rechazado por buró PERDIDA | Buró = PERDIDA |
| Observado por CPP | Buró = CPP, cualquier ratio |
| Observado por DEFICIENTE | Buró = DEFICIENTE, cualquier ratio |
