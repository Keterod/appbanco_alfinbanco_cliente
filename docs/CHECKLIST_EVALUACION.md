# Checklist de evaluación — App Cliente / Home Banking (Alfin Banco)

**Proyecto:** `banco_alfinbanco_cliente`  
**Versión:** mock/local demostrativa  
**Fecha de referencia:** entrega final

| # | Requisito | Estado | Evidencia / pantalla | Observación |
|---|-----------|--------|----------------------|-------------|
| 1 | Branding Alfin Banco | ✅ Cumple | Login, Registro, todas las pantallas | Paleta `#FA4616`, `#8F1A95`, `#73058A`; logo en `assets/images/alfin_logo.png`; `AppTheme` Material 3 |
| 2 | Splash con verificación de sesión | ✅ Cumple | `SplashScreen` (`/`) | Verifica sesión Supabase, timeout de 5 min e internet |
| 3 | Login | ✅ Cumple | `LoginScreen` (`/login`) | Email+password, loading, demo mode fallback, banner no-internet |
| 4 | Registro | ✅ Cumple | `RegisterScreen` (`/register`) | Validaciones locales; retorno a login tras éxito |
| 5 | Sesión temporal 5 min | ✅ Cumple | `SessionTimeoutManager` | Guarda timestamp, expira tras 5 min de inactividad |
| 6 | Logout con limpieza | ✅ Cumple | Dashboard + Perfil | signOut Supabase + clearActivity de sesión temporal |
| 7 | Dashboard con saldo | ✅ Cumple | `DashboardScreen` (`/dashboard`) | Saludo, tarjeta ahorros con saldo S/ |
| 8 | Últimos movimientos | ✅ Cumple | Dashboard — sección movimientos | 3 movimientos mock en `HomeViewModel` |
| 9 | Módulo Ahorros / Cuentas | ✅ Cumple | `AccountsScreen` (`/accounts`) | Tab Cuentas + tarjeta desde Dashboard |
| 10 | Estado de cuenta mock | ✅ Cumple | Cuentas — botón “Ver estado de cuenta” | SnackBar: modo demostración |
| 11 | Módulo Créditos | ✅ Cumple | `CreditsScreen` (`/credits`) | Tab Créditos + tarjeta desde Dashboard |
| 12 | Cronograma de pagos | ✅ Cumple | Créditos — lista de cuotas | Estados: Pagado / Pendiente / Vencido |
| 13 | Pago de cuota mock | ✅ Cumple | Créditos — “Pagar cuota” | Navega a Transferencias con tipo pago crédito |
| 14 | Mis Solicitudes | ✅ Cumple | `RequestsScreen` (`/requests`) | Solicitudes reales desde Supabase vía puente DNI |
| 15 | Pull-to-refresh en solicitudes | ✅ Cumple | `RequestsScreen` | `RefreshIndicator` + SnackBar en fallo; mantiene datos anteriores |
| 16 | Detalle individual de solicitud | ✅ Cumple | `RequestDetailScreen` (`/requests/detail`) | Expediente, estado, fecha, monto, plazo, cuota, elegibilidad, pre-evaluación, cronograma completo |
| 17 | Cronograma completo en detalle | ✅ Cumple | `RequestDetailScreen` | Tarjetas compactas con # cuota, fecha, capital, interés, cuota, saldo |
| 18 | Contactar asesor | ✅ Cumple | `RequestDetailScreen` — botón | `AlertDialog` con mensaje simulado y número de expediente |
| 19 | Badges de estado con colores suaves | ✅ Cumple | `RequestsScreen` + `RequestDetailScreen` | 8 estados: enviada, pendiente, evaluación, observada, aprobada, rechazada, desembolsada, desconocido |
| 20 | Estado vacío mejorado | ✅ Cumple | `RequestsScreen` | Ícono, título, subtítulo informativo, soporta pull-to-refresh |
| 21 | Transferencias y pagos | ✅ Cumple | `TransfersScreen` (`/transfers`) | Tipos: transferencia, pago crédito, pago servicio |
| 22 | Resumen y confirmación de operación | ✅ Cumple | Transferencias — pasos resumen + confirmar | Validación monto, destino y saldo suficiente |
| 23 | Operaciones persistentes en Supabase | ✅ Cumple | Transferencias + Dashboard + Cuentas | Inserta en `clientes_operaciones`, `clientes_movimientos` y actualiza `clientes_cuentas` |
| 24 | Validación de saldo insuficiente | ✅ Cumple | Transferencias — formulario | Error "Saldo insuficiente para realizar la operación." |
| 25 | Refresco de saldo post-operación | ✅ Cumple | Dashboard + Cuentas | Nuevo saldo y movimiento visibles al regresar |
| 26 | Perfil de usuario | ✅ Cumple | `ProfileScreen` (`/profile`) | Datos, DNI censurado, tipo cliente |
| 27 | Historial de operaciones | ✅ Cumple | `OperationsScreen` (`/operations`) | Lista con pull-to-refresh, vacío, error |
| 28 | Comprobante de operación | ✅ Cumple | `OperationDetailScreen` (`/operations/detail`) | Detalle completo con N° operación, fecha, monto, origen, destino |
| 29 | Acceso desde Dashboard y Perfil | ✅ Cumple | Dashboard + Perfil | Tarjeta "Mis operaciones" e "Historial de operaciones" |
| 30 | Cierre de sesión | ✅ Cumple | Dashboard (AppBar) y Perfil | signOut Supabase + clearActivity + pushReplacementNamed |
| 31 | Navegación funcional | ✅ Cumple | Bottom nav + rutas nombradas | Inicio, Cuentas, Créditos, Perfil, Operaciones; links entre módulos |
| 32 | Arquitectura MVVM | ✅ Cumple | `lib/app/model`, `viewmodel`, `view` | `ChangeNotifier` + `ListenableBuilder` |
| 33 | Datos desde Supabase | ✅ Cumple | Repositorios | Cuentas, movimientos, créditos, perfil, solicitudes, operaciones desde Supabase |
| 34 | Carga de todas las cuentas propias | ✅ Cumple | `AccountsScreen` + `TransfersScreen` | Lista de cuentas con badge "Principal", dropdowns para transferencia |
| 35 | Transferencia entre cuentas propias | ✅ Cumple | `TransfersScreen` + `TransfersViewModel` | Dropdown origen/destino, validación origen≠destino, débito+crédito |
| 36 | Validación origen y destino | ✅ Cumple | Transferencias — formulario | "Selecciona una cuenta origen", "Selecciona una cuenta destino", "La cuenta destino debe ser diferente" |
| 37 | Saldo restante en resumen | ✅ Cumple | Transferencias — paso resumen | Muestra saldo restante aproximado de la cuenta origen |
| 38 | Movimientos débito y abono para transferencia propia | ✅ Cumple | `clientes_movimientos` | "Transferencia enviada a cuenta..." y "Transferencia recibida desde cuenta..." |
| 39 | Refresco de ambas cuentas post-transferencia | ✅ Cumple | Cuentas + Dashboard | Saldo origen baja, saldo destino sube, suma total se mantiene |
| 40 | `flutter analyze` sin issues | ✅ Cumple | Terminal / CI local | 0 issues |
| 41 | APK debug generado | ✅ Cumple | `build/app/outputs/flutter-apk/app-debug.apk` | `flutter build apk --debug` |

## Resumen de cumplimiento

| Métrica | Valor |
|---------|-------|
| Requisitos evaluados | 41 |
| Cumplidos | 41 |
| Pendientes (esta entrega) | 0 |

## Fuera de alcance (fase backend)

- Autenticación y registro en servidor
- Sincronización de saldos y movimientos reales
- Transferencias con autorización bancaria
- Notificaciones push
- RPC transaccional en backend (operación + movimiento + saldo atómico)
