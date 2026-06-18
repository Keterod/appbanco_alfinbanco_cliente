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
| 15 | Transferencias y pagos | ✅ Cumple | `TransfersScreen` (`/transfers`) | Tipos: transferencia, pago crédito, pago servicio |
| 16 | Resumen y confirmación de operación | ✅ Cumple | Transferencias — pasos resumen + confirmar | Validación monto y destino |
| 17 | Perfil de usuario | ✅ Cumple | `ProfileScreen` (`/profile`) | Datos, DNI censurado, tipo cliente |
| 18 | Cierre de sesión | ✅ Cumple | Dashboard (AppBar) y Perfil | signOut Supabase + clearActivity + pushReplacementNamed |
| 19 | Navegación funcional | ✅ Cumple | Bottom nav + rutas nombradas | Inicio, Cuentas, Créditos, Perfil; links entre módulos; ahora con splash inicial |
| 20 | Arquitectura MVVM | ✅ Cumple | `lib/app/model`, `viewmodel`, `view` | `ChangeNotifier` + `ListenableBuilder` |
| 21 | Datos hardcodeados/mock | ✅ Cumple | ViewModels | Sin API ni persistencia (excepto shared_preferences para sesión) |
| 22 | `flutter analyze` sin issues | ✅ Cumple | Terminal / CI local | 0 issues |
| 23 | APK debug generado | ✅ Cumple | `build/app/outputs/flutter-apk/app-debug.apk` | `flutter build apk --debug` |

## Resumen de cumplimiento

| Métrica | Valor |
|---------|-------|
| Requisitos evaluados | 23 |
| Cumplidos | 23 |
| Pendientes (esta entrega) | 0 |

## Fuera de alcance (fase backend)

- Autenticación y registro en servidor
- Sincronización de saldos y movimientos reales
- Transferencias con autorización bancaria
- Persistencia y notificaciones
