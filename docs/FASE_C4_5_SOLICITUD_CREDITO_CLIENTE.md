# Fase C4.5 — Solicitud de Crédito Empresarial desde App Clientes

## Objetivo

Crear un flujo en App Clientes para que el cliente registre una nueva solicitud de Crédito Empresarial — Microempresa directamente desde la app, sin pasar por Fuerza de Ventas.

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/app/model/client_loan_request_model.dart` | Modelo con datos de formulario, cálculos (TEA, TEM, cuota, pre-evaluación, cronograma) |
| `lib/app/repository/client_loan_request_repository.dart` | Puente `auth.uid() → clientes_perfil.dni → clientes.id` e inserción en `solicitudes_credito` |
| `lib/app/viewmodel/client_loan_request_viewmodel.dart` | ViewModel con step navigation, validación, submit |
| `lib/app/view/loan_request/client_loan_request_screen.dart` | Formulario tipo stepper: Datos del negocio → Datos del crédito → Confirmar |
| `docs/FASE_C4_5_SOLICITUD_CREDITO_CLIENTE.md` | Documentación de la fase |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/navigation/app_routes.dart` | +`clientLoanRequest = '/loan-request'` |
| `lib/app/navigation/app_navigation.dart` | +import + ruta `ClientLoanRequestScreen` |
| `lib/app/view/home/dashboard_screen.dart` | +Tarjeta "Solicitar crédito empresarial" entre Transferencias y Mis Solicitudes |

## Cómo funciona el flujo

### Dashboard → Solicitar crédito empresarial

El Dashboard tiene una tarjeta con título "Solicitar crédito empresarial" que navega a `/loan-request`.

### Stepper de 3 pasos

1. **Datos del negocio**: tipo de negocio (dropdown), nombre, antigüedad en meses, ingresos mensuales, gastos mensuales
2. **Datos del crédito**: monto solicitado, plazo (dropdown 6/12/18/24/36), destino, garantía, seguro de desgravamen
3. **Confirmar**: preview completa con cálculos y pre-evaluación, botón "Enviar solicitud"

### Cálculos

Cuando el usuario avanza al paso 3, se ejecuta `model.compute()`:

- **TEA**: 40.92% si seguro = Sí, 43.92% si seguro = No
- **TEM**: `(1 + TEA/100)^(1/12) - 1`
- **Cuota**: `monto * TEM / (1 - (1 + TEM)^(-plazo))`
- **Total a pagar**: `cuota * plazo`

### Pre-evaluación

| Condición | Resultado | Score | Riesgo |
|-----------|-----------|-------|--------|
| ingresos <= 0 o capacidad <= 0 | NO APTO | 30 | Alto |
| ratio cuota/capacidad <= 40% | APTO | 85 | Bajo |
| ratio cuota/capacidad <= 60% | OBSERVADO | 60 | Medio |
| ratio cuota/capacidad > 60% | NO APTO | 30 | Alto |

### Cronograma

Se generan N filas (según plazo) usando sistema de amortización francés:
```
interes = saldo * TEM
capital = cuota - interes
saldo -= capital
```
La primera cuota es el próximo mes desde la fecha actual.

### Puente de identidad

`ClientLoanRequestRepository.getClienteId()`:
1. `auth.uid()` → `clientes_perfil.id` → obtener `dni`
2. `dni` → `clientes.numero_documento` → obtener `clientes.id`
3. Ese `clientes.id` se usa como `cliente_id` en `solicitudes_credito`

### Inserción en solicitudes_credito

Se insertan todos los campos disponibles. Si el insert falla por columnas faltantes, se reintenta con un conjunto mínimo de campos. Logs: `[CLIENT_LOAN] inserting request`, `[CLIENT_LOAN] request created expediente=...`.

### Pantalla de éxito

Después del envío exitoso:
- "Solicitud enviada correctamente"
- Número de expediente (ej: `EXP-ALF-2026-...`)
- Estado: Enviado
- Botones: "Ver Mis Solicitudes", "Volver al inicio"

### Mis Solicitudes

La nueva solicitud aparece automáticamente en `/requests` porque `RequestsRepository.getRequests()` consulta `solicitudes_credito` para el mismo `cliente_id`. El detalle muestra estado, monto, plazo, cuota, elegibilidad y cronograma.

## Resultados de verificación

| Comando | Resultado |
|---------|-----------|
| `flutter analyze` | 0 issues ✅ |
| `flutter build apk --debug` | APK generado ✅ |

## Próxima fase (C4.6 — Seguimiento de expediente / estados)

- Dashboard con resumen de estado actual de expedientes
- Notificaciones de cambio de estado (simulado)
- Detalle de respuesta del evaluador
