# Checklist de evaluación — App Cliente / Home Banking (Alfin Banco)

**Proyecto:** `banco_alfinbanco_cliente`  
**Versión:** mock/local demostrativa  
**Fecha de referencia:** entrega final

| # | Requisito | Estado | Evidencia / pantalla | Observación |
|---|-----------|--------|----------------------|-------------|
| 1 | Branding Alfin Banco | ✅ Cumple | Login, Registro, todas las pantallas | Paleta `#FA4616`, `#8F1A95`, `#73058A`; logo en `assets/images/alfin_logo.png`; `AppTheme` Material 3 |
| 2 | Login | ✅ Cumple | `LoginScreen` (`/`) | DNI + contraseña, loading, ingreso sin servidor |
| 3 | Registro | ✅ Cumple | `RegisterScreen` (`/register`) | Validaciones locales; retorno a login tras éxito |
| 4 | Dashboard con saldo | ✅ Cumple | `DashboardScreen` (`/dashboard`) | Saludo, tarjeta ahorros con saldo S/ |
| 5 | Últimos movimientos | ✅ Cumple | Dashboard — sección movimientos | 3 movimientos mock en `HomeViewModel` |
| 6 | Módulo Ahorros / Cuentas | ✅ Cumple | `AccountsScreen` (`/accounts`) | Tab Cuentas + tarjeta desde Dashboard |
| 7 | Estado de cuenta mock | ✅ Cumple | Cuentas — botón “Ver estado de cuenta” | SnackBar: modo demostración |
| 8 | Módulo Créditos | ✅ Cumple | `CreditsScreen` (`/credits`) | Tab Créditos + tarjeta desde Dashboard |
| 9 | Cronograma de pagos | ✅ Cumple | Créditos — lista de cuotas | Estados: Pagado / Pendiente / Vencido |
| 10 | Pago de cuota mock | ✅ Cumple | Créditos — “Pagar cuota” | Navega a Transferencias con tipo pago crédito |
| 11 | Transferencias y pagos | ✅ Cumple | `TransfersScreen` (`/transfers`) | Tipos: transferencia, pago crédito, pago servicio |
| 12 | Resumen y confirmación de operación | ✅ Cumple | Transferencias — pasos resumen + confirmar | Validación monto y destino |
| 13 | Perfil de usuario | ✅ Cumple | `ProfileScreen` (`/profile`) | Datos, DNI censurado, tipo cliente |
| 14 | Cierre de sesión | ✅ Cumple | Dashboard (AppBar) y Perfil | `pushReplacementNamed` → Login |
| 15 | Navegación funcional | ✅ Cumple | Bottom nav + rutas nombradas | Inicio, Cuentas, Créditos, Perfil; links entre módulos |
| 16 | Arquitectura MVVM | ✅ Cumple | `lib/app/model`, `viewmodel`, `view` | `ChangeNotifier` + `ListenableBuilder` |
| 17 | Datos hardcodeados/mock | ✅ Cumple | ViewModels | Sin API ni persistencia |
| 18 | `flutter analyze` sin issues | ✅ Cumple | Terminal / CI local | Ejecutar antes de entregar |
| 19 | APK debug generado | ✅ Cumple | `build/app/outputs/flutter-apk/app-debug.apk` | `flutter build apk --debug` |

## Resumen de cumplimiento

| Métrica | Valor |
|---------|-------|
| Requisitos evaluados | 19 |
| Cumplidos | 19 |
| Pendientes (esta entrega) | 0 |

## Fuera de alcance (fase backend)

- Autenticación y registro en servidor
- Sincronización de saldos y movimientos reales
- Transferencias con autorización bancaria
- Persistencia y notificaciones
