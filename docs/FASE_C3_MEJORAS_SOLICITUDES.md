# Fase C3 — Mejoras a Mis Solicitudes

## Objetivo

Mejorar la experiencia de la pantalla Mis Solicitudes con pull-to-refresh, pantalla detalle individual, cronograma completo, contacto con asesor, badges de estado con colores suaves y estado vacío mejorado.

## Cambios realizados

### Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/app/view/requests/request_detail_screen.dart` | Pantalla detalle individual de solicitud |

### Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `lib/app/viewmodel/requests_viewmodel.dart` | Añadido flag `isRefreshing`, `refresh()` ahora retorna `bool` |
| `lib/app/view/requests/requests_screen.dart` | Pull-to-refresh, navegación a detalle, badges suaves, empty state mejorado |
| `lib/app/navigation/app_routes.dart` | Nueva constante `requestDetail = '/requests/detail'` |
| `lib/app/navigation/app_navigation.dart` | Import + `onGenerateRoute` para `RequestDetailScreen` |

## 1. Pull-to-refresh

- `RefreshIndicator` envuelve el `ListView` en `RequestsScreen`
- Llama a `_viewModel.refresh()` que retorna `bool`
- Si el refresh falla, se mantienen los datos anteriores y se muestra un `SnackBar` flotante discreto
- `_viewModel.isRefreshing` evita que el indicador de carga inicial aparezca durante el refresh
- El estado vacío también incluye `RefreshIndicator` para permitir pull-to-refresh

### Flujo

```
Usuario hace pull hacia abajo
  → RefreshIndicator.onRefresh()
    → _viewModel.refresh()
      → isRefreshing = true
      → notifyListeners
      → _repository.getRequests()
      → Si éxito: requests = result, errorMessage = null
      → isRefreshing = false
      → notifyListeners
      → Retorna true
      → Si fallo: mantiene requests anterior, isRefreshing = false, retorna false
    → Si false: ScaffoldMessenger.showSnackBar("No se pudo actualizar")
```

## 2. Pantalla detalle individual

`RequestDetailScreen` es un `StatefulWidget` que recibe `RequestModel` como parámetro.

### Datos mostrados

- **AppBar**: Número de expediente
- **Sección 1 — Encabezado**: Número de expediente, badge de estado grande, fecha de creación
- **Sección 2 — Detalles del crédito**: Monto solicitado, plazo, cuota estimada, elegibilidad con ícono
- **Sección 3 — Pre-evaluación crediticia**: Score, riesgo, ratio capacidad de pago (solo si existen)
- **Sección 4 — Cronograma de pagos**: Todas las cuotas en tarjetas compactas
- **Botón**: "Contactar asesor" al final

### Navegación

```dart
Navigator.of(context).pushNamed(AppRoutes.requestDetail, arguments: req);
```

La ruta se maneja en `onGenerateRoute` de `AppNavigation`:

```dart
if (settings.name == AppRoutes.requestDetail) {
  final request = settings.arguments as RequestModel;
  return MaterialPageRoute<void>(
    builder: (_) => RequestDetailScreen(request: request),
    settings: settings,
  );
}
```

## 3. Cronograma completo

En la pantalla detalle se muestran **todas** las cuotas del cronograma, no solo las primeras 3.

Cada cuota se muestra en una tarjeta compacta (`_CuotaCard`) con:

| Campo | Formato |
|-------|---------|
| Número de cuota | Círculo numerado con fondo morado |
| Fecha | Formato `dd mmm aaaa` |
| Capital | `S/ xx,xxx.xx` |
| Interés | `S/ xx,xxx.xx` |
| Cuota | `S/ xx,xxx.xx` (destacado en negrita) |
| Saldo | `S/ xx,xxx.xx` |

Las tarjetas usan diseño de filas para evitar overflow horizontal en móvil.

## 4. Contactar asesor

Botón `ElevatedButton.icon` al final de la pantalla detalle con ícono `headset_mic_outlined`.

Al tocar:

```dart
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: 'Contactar asesor',
    content: 'Un asesor se comunicará contigo para revisar esta solicitud.'
             'Expediente: EXP-ALF-...',
    actions: [TextButton('Entendido')],
  ),
);
```

No se implementa WhatsApp real ni chat real. Es una acción simulada.

## 5. Badges de estado con colores suaves

| Estado | Color de texto | Fondo |
|--------|---------------|-------|
| enviada | `blue.shade700` | `blue.shade50` |
| pendiente | `blue.shade700` | `blue.shade50` |
| en evaluación | `amber.shade800` | `amber.shade50` |
| observada | `orange.shade800` | `orange.shade50` |
| aprobada | `green.shade700` | `green.shade50` |
| desembolsada | `green.shade700` | `green.shade50` |
| rechazada | `red.shade700` | `red.shade50` |
| desconocido | `grey.shade700` | `grey.shade50` |

Los badges usan `Container` con `BorderRadius.circular(12)` (card) o `BorderRadius.circular(16)` (detalle) en lugar de `Chip` para mejor control visual.

## 6. Estado vacío mejorado

Cuando no hay solicitudes:

- **Ícono**: `Icons.assignment_outlined` (tamaño 72, gris claro)
- **Título**: "Aún no tienes solicitudes registradas"
- **Subtítulo**: "Cuando un asesor registre una solicitud de crédito, aparecerá aquí."
- **Soporta pull-to-refresh**: El estado vacío también está envuelto en `RefreshIndicator`

## Verificación

| Comando | Resultado |
|---------|-----------|
| `flutter analyze` | 0 issues |
| `flutter build apk --debug` | APK generado exitosamente |

## Limitaciones

- `DemoClientData` sigue siendo la fuente de datos mock para cuentas, créditos y movimientos
- Solo `solicitudes_credito` está conectada a Supabase real
- "Contactar asesor" es simulado (AlertDialog), no hay envío real de notificación
- No hay paginación en la lista de solicitudes
