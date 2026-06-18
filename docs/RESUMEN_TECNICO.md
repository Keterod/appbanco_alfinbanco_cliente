# Resumen técnico — App Cliente / Home Banking (Alfin Banco)

## Estructura de carpetas

```
lib/
├── main.dart                          # runApp(AppNavigation)
└── app/
    ├── model/                         # Entidades de dominio
    ├── viewmodel/                     # Lógica + datos mock (ChangeNotifier)
    ├── view/
    │   ├── auth/                      # Login, Registro
    │   ├── home/                      # Dashboard
    │   ├── accounts/                  # Cuentas / Ahorros
    │   ├── credits/                   # Créditos
    │   ├── transfers/                 # Transferencias y pagos
    │   ├── profile/                   # Perfil
    │   └── widgets/                   # Bottom nav, AppBar compartidos
    ├── navigation/                    # Rutas y MaterialApp
    ├── ui/theme/                      # AppColors, AppTheme
    └── util/                          # FormatUtils (soles, fechas)

assets/images/alfin_logo.png
docs/                                  # Checklist, evidencias, este archivo
android/ ios/ web/ ...                 # Plataformas Flutter (template)
```

## Lista de módulos

| Módulo | Pantalla | ViewModel |
|--------|----------|-----------|
| Autenticación — Login | `login_screen.dart` | `auth_viewmodel.dart` |
| Autenticación — Registro | `register_screen.dart` | `register_viewmodel.dart` |
| Inicio | `dashboard_screen.dart` | `home_viewmodel.dart` |
| Cuentas / Ahorros | `accounts_screen.dart` | `accounts_viewmodel.dart` |
| Créditos | `credits_screen.dart` | `credits_viewmodel.dart` |
| Transferencias y pagos | `transfers_screen.dart` | `transfers_viewmodel.dart` |
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
| `AccountsViewModel` | Detalle cuenta y movimientos |
| `CreditsViewModel` | Crédito, cronograma, progreso |
| `TransfersViewModel` | Formulario, validación, confirmación, éxito |
| `ProfileViewModel` | Datos del cliente |

## Rutas principales

| Ruta | Constante | Pantalla |
|------|-----------|----------|
| `/` | `AppRoutes.login` | Login |
| `/register` | `AppRoutes.register` | Registro |
| `/dashboard` | `AppRoutes.dashboard` | Inicio |
| `/accounts` | `AppRoutes.accounts` | Cuentas |
| `/credits` | `AppRoutes.credits` | Créditos |
| `/transfers` | `AppRoutes.transfers` | Transferencias (`onGenerateRoute`, arg `pagoCredito`) |
| `/profile` | `AppRoutes.profile` | Perfil |

Navegación entre tabs: `AppBottomNav` con `pushReplacementNamed`.

## Decisiones técnicas

1. **MaterialApp + rutas nombradas** — simple, adecuado para alcance académico.
2. **ChangeNotifier sin Provider** — requisito del proyecto; instanciación local por pantalla.
3. **Datos mock en ViewModels** — desacopla UI de futura capa `services/`.
4. **`FormatUtils`** — formateo de soles y fechas reutilizable.
5. **Widgets compartidos** — `AlfinAppBar`, `AppBottomNav` para consistencia de marca.
6. **`flutter_launcher_icons`** — icono desde `alfin_logo.png` (solo dev/build).

## Limitaciones actuales

- No hay autenticación ni registro en servidor.
- No hay persistencia (sesión, formularios, historial).
- ViewModels no se comparten entre pantallas (datos duplicados en mocks).
- Un solo crédito y una sola cuenta en los datos demo.
- iOS/Web/desktop no priorizados frente a Android para la demo.
- Sin tests automatizados en el repositorio.

## Próximos pasos recomendados

1. Introducir capa **`repository` + `services`** (HTTP o Supabase).
2. **Provider** o **Riverpod** para sesión y ViewModels globales.
3. **Secure storage** para token y preferencias.
4. Tests **unit** (ViewModels) y **widget** (flujos críticos).
5. Flujos de error de red y estados vacíos.
6. Firma release y `applicationId` definitivo (`com.alfinbanco.cliente` o similar).
7. Integración con notificaciones y biometría según requerimientos del banco.
