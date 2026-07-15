# Resumen técnico — App Cliente / Home Banking (Alfin Banco)

## Estructura de carpetas

```
lib/
├── main.dart                          # runApp(AppNavigation)
└── app/
    ├── core/
    │   ├── session/                   # SessionTimeoutManager (shared_preferences)
    │   └── supabase/                  # URL, anon key, bootstrap, getter
    ├── model/                         # Entidades de dominio
    ├── viewmodel/                     # Lógica + datos mock (ChangeNotifier)
    ├── view/
    │   ├── splash/                    # Splash (verificación de sesión)
    │   ├── auth/                      # Login, Registro
    │   ├── home/                      # Dashboard
    │   ├── accounts/                  # Cuentas / Ahorros
    │   ├── credits/                   # Créditos
    │   ├── requests/                  # Mis Solicitudes (C1)
    │   ├── transfers/                 # Transferencias y pagos
    │   ├── profile/                   # Perfil
    │   └── widgets/                   # Bottom nav, AppBar compartidos
    ├── navigation/                    # Rutas y MaterialApp
    ├── ui/theme/                      # AppColors, AppTheme
    ├── repository/                    # Acceso a Supabase
    └── util/                          # FormatUtils (soles, fechas)

assets/images/alfin_logo.png
docs/                                  # Checklist, evidencias, este archivo
android/ ios/ web/ ...                 # Plataformas Flutter (template)
```

## Lista de módulos

| Módulo | Pantalla | ViewModel |
|--------|----------|-----------|
| Splash | `splash_screen.dart` | — (lógica inline) |
| Autenticación — Login | `login_screen.dart` | `auth_viewmodel.dart` |
| Autenticación — Registro | `register_screen.dart` | `register_viewmodel.dart` |
| Inicio | `dashboard_screen.dart` | `home_viewmodel.dart` |
| Cuentas / Ahorros | `accounts_screen.dart` | `accounts_viewmodel.dart` |
| Créditos | `credits_screen.dart` | `credits_viewmodel.dart` |
| Pago de cuota | `credit_payment_screen.dart` | `credit_payment_viewmodel.dart` |
| Mis Solicitudes | `requests_screen.dart`, `request_detail_screen.dart` | `requests_viewmodel.dart` |
| Transferencias y pagos | `transfers_screen.dart` | `transfers_viewmodel.dart` |
| Solicitar crédito empresarial | `client_loan_request_screen.dart` | `client_loan_request_viewmodel.dart` |
| Historial de operaciones | `operations_screen.dart` | `operations_viewmodel.dart` |
| Comprobante de operación | `operation_detail_screen.dart` | — (datos por argumento) |
| Perfil | `profile_screen.dart` | `profile_viewmodel.dart` |

## Patrón MVVM aplicado

```
View (StatefulWidget + ListenableBuilder)
        ↕ eventos / binding manual
ViewModel (ChangeNotifier, notifyListeners)
        ↕ lee/escribe
Model (clases Dart inmutables o simples)
```

- **Sin** lógica de negocio pesada en `build()` de las vistas.
- ViewModels instanciados en `initState` y liberados en `dispose`.
- Navegación decidida en la **View** (no en ViewModel), salvo flujos internos de transferencias (`TransferFlowStep`).

## Modelos principales

| Modelo | Archivo | Uso |
|--------|---------|-----|
| `AccountModel` | `account_model.dart` | Cuenta de ahorros |
| `CreditModel` | `credit_model.dart` | Préstamo activo |
| `MovementModel` | `movement_model.dart` | Movimientos |
| `PaymentScheduleModel` | `payment_schedule_model.dart` | Cuotas del crédito |
| `TransferModel` | `transfer_model.dart` | Comprobante de operación |
| `UserProfileModel` | `user_profile_model.dart` | Perfil del cliente |
| `RegisterModel` | `register_model.dart` | Alta de cliente (memoria) |

## ViewModels principales

| ViewModel | Responsabilidad |
|-----------|-----------------|
| `AuthViewModel` | Login simulado, credenciales de ejemplo |
| `RegisterViewModel` | Validación y registro mock |
| `HomeViewModel` | Resumen dashboard |
| `AccountsViewModel` | Lista de cuentas, movimientos |
| `CreditsViewModel` | Crédito, cronograma, progreso |
| `TransfersViewModel` | Formulario, validación, confirmación, éxito; soporta transferencia entre cuentas propias |
| `ProfileViewModel` | Datos del cliente |
| `OperationsViewModel` | Historial de operaciones con pull-to-refresh |
| `ClientLoanRequestViewModel` | Formulario de solicitud de crédito empresarial, cálculos, envío, autocarga datos del usuario logueado |
| `CreditsViewModel` (reload) | Recarga créditos post-pago |
| `CreditPaymentViewModel` | Selección de cuenta, validación, confirmación de pago de cuota |

## Rutas principales

| Ruta | Constante | Pantalla |
|------|-----------|----------|
| `/` | `AppRoutes.splash` | Splash (verificación de sesión) |
| `/login` | `AppRoutes.login` | Login |
| `/register` | `AppRoutes.register` | Registro |
| `/dashboard` | `AppRoutes.dashboard` | Inicio |
| `/accounts` | `AppRoutes.accounts` | Cuentas |
| `/credits` | `AppRoutes.credits` | Créditos |
| `/requests` | `AppRoutes.requests` | Mis Solicitudes |
| `/requests/detail` | `AppRoutes.requestDetail` | Detalle individual (`onGenerateRoute`, arg `RequestModel`) |
| `/transfers` | `AppRoutes.transfers` | Transferencias (`onGenerateRoute`, arg `pagoCredito`) |
| `/loan-request` | `AppRoutes.clientLoanRequest` | Solicitar crédito empresarial |
| `/operations` | `AppRoutes.operations` | Historial de operaciones |
| `/operations/detail` | `AppRoutes.operationDetail` | Comprobante (`onGenerateRoute`, arg `OperationModel`) |
| `/credits/payment` | `AppRoutes.creditPayment` | Pago de cuota (`onGenerateRoute`, arg `CreditModel`) |
| `/profile` | `AppRoutes.profile` | Perfil |

Navegación entre tabs: `AppBottomNav` con `pushReplacementNamed`.

## Decisiones técnicas

1. **MaterialApp + rutas nombradas** — simple, adecuado para alcance académico.
2. **ChangeNotifier sin Provider** — requisito del proyecto; instanciación local por pantalla.
3. **Datos mock en ViewModels** — desacopla UI de futura capa `services/`.
4. **`FormatUtils`** — formateo de soles y fechas reutilizable.
5. **Widgets compartidos** — `AlfinAppBar`, `AppBottomNav` para consistencia de marca.
6. **`flutter_launcher_icons`** — icono desde `alfin_logo.png` (solo dev/build).
7. **Sesión temporal con shared_preferences** — `SessionTimeoutManager` guarda timestamp de última actividad.
8. **Timeout de 5 minutos** — constante configurable; al expirar se cierra sesión y redirige a Login.
9. **Pull-to-refresh con RefreshIndicator** — `isRefreshing` separado de `isLoading`; mantiene datos anteriores en fallo.
10. **Badges de estado con colores suaves** — `Container` con `BorderRadius` en lugar de `Chip`; colores Material `shade50`/`shade700`.

## Limitaciones actuales

- No hay autenticación ni registro en servidor (demo mode como respaldo).
- ViewModels no se comparten entre pantallas (datos duplicados en mocks).
- iOS/Web/desktop no priorizados frente a Android para la demo.
- Sin tests automatizados en el repositorio.
- Sin modo offline real: sin internet no se puede iniciar sesión.
- La sesión temporal solo usa shared_preferences, no secure storage.
- "Contactar asesor" es simulado (AlertDialog), no hay envío real de notificación.
- Operación → movimiento → saldo se ejecuta desde el cliente sin transacción atómica; en producción debe ser RPC.
- Pago de cuota: orden de ejecución con rollback (snapshot → débito → movimiento → operación → cuota → crédito).
- Schema real `clientes_cronograma_pagos` usa `monto`, `fecha_vencimiento`, `fecha_pago`, `estado` (minúscula). No tiene `capital`, `interes`, `saldo`, `fecha_pago_real`, `numero_operacion`.
- Schema real `clientes_creditos` usa `progreso_pago` (0.0–1.0), `monto_original`, `monto_pendiente`, `estado`, `activo`, `proxima_fecha_pago`. No tiene `progreso`, `cuotas_pagadas`, `total_cuotas`.
- El monto pendiente del crédito se reduce por el monto total de la cuota («installment.amount»), no por capital (columna no disponible).
- `CreditsViewModel` normaliza `progreso_pago`: si > 1 lo divide entre 100.
- Historial de operaciones sin paginación (carga completa).
- Transferencia entre cuentas propias usa 2 lecturas + 2 escrituras separadas para débito/crédito; sin RPC hay riesgo de inconsistencia si falla un paso intermedio.
- Solicitud de crédito empresarial inserta en `solicitudes_credito` con un solo insert completo. Si falla, el error es visible para el usuario (no hay fallback silencioso).
- Timeline de expediente usa índice de paso calculado del estado; no requiere cambios de backend.

## Próximos pasos recomendados

1. **C4.9** — Pago de Luz, Metas de ahorro, Depósito a cuenta propia
2. **C5** — RPC transaccional, paginación, filtros, PDF, SQLite offline
5. Introducir capa **`repository` + `services`** (HTTP o Supabase).
6. **Provider** o **Riverpod** para sesión y ViewModels globales.
7. **Secure storage** para token y preferencias.
8. Tests **unit** (ViewModels) y **widget** (flujos críticos).
9. Firma release y `applicationId` definitivo (`com.alfinbanco.cliente` o similar).
10. Integración con notificaciones y biometría según requerimientos del banco.
