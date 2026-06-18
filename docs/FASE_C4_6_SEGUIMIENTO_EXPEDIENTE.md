# Fase C4.6 — Seguimiento visual del expediente por estados

## Objetivo

Mejorar la pantalla Mis Solicitudes y el detalle del expediente para que el cliente pueda hacer seguimiento visual del estado de su solicitud de crédito empresarial mediante una línea de tiempo, card de decisión y dashboard informativo.

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/model/request_model.dart` | +8 campos opcionales (observacionEvaluador, motivoRechazo, montoAprobado, fechaDecision, fechaDesembolso, canal, asesorAsignado, prioridad, updatedAt); +status helpers (normalizedStatus, statusLabel, statusDescription, statusStepIndex, isRejected, isApproved, isDisbursed, isConditioned, hasDecision, hasUpdate); +métodos estáticos |
| `lib/app/view/requests/request_detail_screen.dart` | +Timeline vertical de 5 pasos con iconos (completado/actual/pendiente); +Card "Resultado de evaluación" con mensaje según estado; +Card "Aún no hay decisión final" para estados sin decisión; +badge de "Tu expediente tiene una actualización" |
| `lib/app/view/requests/requests_screen.dart` | +Subtítulo con descripción del estado; +indicador "Paso X de 5"; +fecha de última actualización; +colores actualizados para nuevos estados |
| `lib/app/viewmodel/home_viewmodel.dart` | +Carga de solicitudes desde RequestsRepository; +getters evaluationCount, approvedCount, rejectedCount, pendingCount, latestRequest |
| `lib/app/view/home/dashboard_screen.dart` | +Sección "Estado de tus expedientes" con último expediente, badge de estado, chips con conteos (En evaluación, Aprobados, Rechazados) |

## Archivos creados

| Archivo |
|---------|
| `docs/FASE_C4_6_SEGUIMIENTO_EXPEDIENTE.md` |

## Cómo se calcula el paso del expediente

`RequestModel.statusStepIndex` mapea el estado a un índice 0-4:

| Estado | Step | Timeline |
|--------|------|----------|
| enviado | 0 | Solicitud enviada |
| recibido_comite | 1 | Recibido por comité |
| en_evaluacion | 2 | En evaluación |
| aprobado/condicionado/rechazado | 3 | Decisión |
| desembolsado | 4 | Desembolso |

## Cómo funciona el timeline

Se muestra en `RequestDetailScreen._buildTimeline()`:
- **Completado** (step < current): icono check_circle, color primario
- **Actual** (step == current): icono radio_button_checked, color secondary + descripción
- **Pendiente** (step > current): icono radio_button_unchecked, gris
- **No aplica** (step 4, rechazado): icono not_interested, gris, texto "No aplica"

Cada step tiene título y descripción. Si el estado es rechazado y hay motivo_rechazo, se muestra debajo.

## Cómo funciona la card de decisión

`_buildDecisionCard()` muestra según estado:
- **aprobado**: "Tu crédito fue aprobado y se encuentra pendiente de desembolso."
- **condicionado**: "El comité aprobó un monto o condición diferente al solicitado."
- **rechazado**: muestra motivo_rechazo o mensaje genérico
- **desembolsado**: "Tu crédito ya fue desembolsado." + fecha

Si no hay decisión aún, muestra `_buildNoDecisionCard()` con "Aún no hay decisión final." + "Te avisaremos cuando tu expediente cambie de estado."

## Cómo se ve en Dashboard

Sección "Estado de tus expedientes" que aparece si hay solicitudes cargadas:
- Último expediente con badge de estado y paso actual
- 3 chips con conteos: En evaluación, Aprobados, Rechazados
- Al tocar, navega a Mis Solicitudes

## Resultados de verificación

| Comando | Resultado |
|---------|-----------|
| `flutter analyze` | 0 issues ✅ |
| `flutter build apk --debug` | APK generado ✅ |

## SQL opcional (columnas nuevas)

Si faltan columnas en `solicitudes_credito`:

```sql
alter table public.solicitudes_credito
add column if not exists observacion_evaluador text,
add column if not exists motivo_rechazo text,
add column if not exists monto_aprobado numeric,
add column if not exists fecha_decision timestamptz,
add column if not exists fecha_desembolso timestamptz,
add column if not exists canal text,
add column if not exists asesor_asignado text,
add column if not exists prioridad text,
add column if not exists updated_at timestamptz default now();
```

## Próxima fase (C4.7 — Crédito desembolsado / crédito activo)

- Solicitud aprobada → reflejar como crédito activo en `clientes_creditos`
- Opción de pago de cuota desde transferencias
