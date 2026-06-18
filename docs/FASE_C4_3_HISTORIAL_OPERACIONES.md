# Fase C4.3 — Historial de operaciones y comprobante

## Objetivo

Permitir que el cliente vea el historial de operaciones realizadas (transferencias, pagos) y el detalle/comprobante de cada una, consumiendo datos desde `clientes_operaciones` en Supabase.

## Tabla usada

| Tabla | Operación | Propósito |
|-------|-----------|-----------|
| `clientes_operaciones` | SELECT | Listar historial y mostrar detalle de cada operación |

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/app/model/operation_model.dart` | Modelo `OperationModel` con `fromSupabase()` |
| `lib/app/viewmodel/operations_viewmodel.dart` | ViewModel con `loadOperations()`, `refresh()` |
| `lib/app/view/operations/operations_screen.dart` | Pantalla de historial con lista, pull-to-refresh, vacío, error |
| `lib/app/view/operations/operation_detail_screen.dart` | Pantalla de comprobante con detalle completo |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/repository/operations_repository.dart` | +`getOperations()` con filtro por `cliente_id = auth.uid()` |
| `lib/app/navigation/app_routes.dart` | +`operations`, +`operationDetail` rutas |
| `lib/app/navigation/app_navigation.dart` | +imports, +routes para OperationsScreen y OperationDetailScreen |
| `lib/app/view/home/dashboard_screen.dart` | +Tarjeta "Mis operaciones" |
| `lib/app/view/profile/profile_screen.dart` | +"Historial de operaciones" en sección de Historial |

## Flujo de datos

```
OperationsScreen.initState()
  → OperationsViewModel.loadOperations()
    → OperationsRepository.getOperations()
      → clientes_operaciones.select().eq('cliente_id', auth.uid()).order('fecha', desc)
      → List<OperationModel>
```

## Pantallas

### OperationsScreen ("Mis operaciones")

- **Loading**: `CircularProgressIndicator` centrado
- **Vacío**: Ícono + "Aún no tienes operaciones registradas." + subtítulo
- **Error**: Mensaje + botón "Reintentar"
- **Lista**: Tarjetas con tipo, número de operación, fecha, destino, monto y badge de estado
- **Pull-to-refresh**: `RefreshIndicator` para recargar
- Cada tarjeta navega a `OperationDetailScreen`

### OperationDetailScreen ("Comprobante")

- Recibe `OperationModel` por argumentos
- Muestra: N° operación, estado, fecha, tipo, cuenta origen, cuenta destino, descripción, monto
- Texto: "Operación registrada correctamente."
- Botón: "Volver al inicio"
- Botón: "Nueva operación"

## Acceso desde la app

1. Dashboard → tarjeta "Mis operaciones" (morada, igual que Mis solicitudes)
2. Perfil → sección "Historial" → "Historial de operaciones"

## Logs agregados

| Log | Punto |
|-----|-------|
| `[OPERATIONS] loading operations` | Inicio de carga |
| `[OPERATIONS] operations found=N` | Resultado de consulta |
| `[OPERATIONS] error=...` | Error en consulta |
| `[OPERATIONS] inserting operation` | Al crear operación desde C4.2 |

## Pruebas realizadas

1. Login → Dashboard → Mis operaciones → lista con operación de C4.2
2. Pull-to-refresh funciona
3. Tocar operación → Comprobante con todos los datos
4. Volver al inicio desde comprobante
5. Nueva transferencia → volver a Mis operaciones → aparece arriba
6. Cuentas refleja nuevo movimiento y saldo
7. Mis Solicitudes, Créditos y Perfil siguen funcionando
8. flutter analyze: 0 issues
9. flutter build apk --debug: exitoso

## Pendiente para C4.4

- Historial con paginación (cargar más)
- Filtros por tipo de operación y rango de fechas
- Descarga de comprobante en PDF
