# Fase C2 — Sesión temporal con expiración por inactividad

## Objetivo

La App Clientes mantiene la sesión solo si han pasado menos de 5 minutos desde el último uso. Si la app se cierra y se reabre dentro de ese lapso, el cliente entra directo al Dashboard. Si pasan más de 5 minutos, se cierra la sesión y se muestra Login.

## Regla de 5 minutos

```
última actividad + 5 min >= ahora → sesión VÁLIDA → Dashboard
última actividad + 5 min <  ahora → sesión EXPIRADA → signOut + Login
```

## Comportamiento con internet

- Al abrir la app, `SplashScreen` verifica sesión Supabase + timeout + conectividad
- Intenta una consulta ligera (`clientes_perfil.select('id').limit(1)`) para confirmar internet
- Si todo OK → Dashboard

## Comportamiento sin internet

- Splash detecta error de red en la consulta de verificación
- Navega a Login con argumento `internetRequired: true`
- Login muestra banner: "Necesitas conexión a internet para iniciar sesión"
- No se puede iniciar sesión sin internet

## Comportamiento al cerrar y abrir

1. Cerrar la app
2. Reabrir antes de 5 min → **Dashboard directo**
3. Reabrir después de 5 min → **Login** (sesión expirada)

## Comportamiento logout

1. Botón "Cerrar sesión" en Dashboard (AppBar) o Perfil
2. Llama a `Supabase.instance.client.auth.signOut()`
3. Llama a `SessionTimeoutManager.clearActivity()`
4. Navega a Login limpiando el stack

## Archivos creados

| Archivo | Propósito |
|---------|-----------|
| `lib/app/core/session/session_timeout_manager.dart` | Helper para guardar/verificar timestamp de actividad |
| `lib/app/view/splash/splash_screen.dart` | Pantalla de carga que verifica sesión, timeout e internet |

## Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `pubspec.yaml` | +`shared_preferences: ^2.2.0` |
| `lib/app/navigation/app_routes.dart` | +`splash` como ruta `/`, login cambia a `/login` |
| `lib/app/navigation/app_navigation.dart` | +`SplashScreen`, `initialRoute: AppRoutes.splash` |
| `lib/app/viewmodel/auth_viewmodel.dart` | +import `SessionTimeoutManager`, guarda actividad al login exitoso |
| `lib/app/view/auth/login_screen.dart` | +banner no-internet, +saveActivity en login exitoso |
| `lib/app/view/home/dashboard_screen.dart` | +logout real con signOut + clearActivity, +saveActivity en init |
| `lib/app/viewmodel/home_viewmodel.dart` | +método `logout()` con signOut + clearActivity |
| `lib/app/viewmodel/profile_viewmodel.dart` | +clearActivity en logout |
| `lib/app/view/accounts/accounts_screen.dart` | +saveActivity en init |
| `lib/app/view/credits/credits_screen.dart` | +saveActivity en init |
| `lib/app/view/requests/requests_screen.dart` | +saveActivity en init |
| `lib/app/view/transfers/transfers_screen.dart` | +saveActivity en init |
| `lib/app/view/profile/profile_screen.dart` | +saveActivity en init |

## Limitación

- No hay modo offline real. Sin internet no se puede iniciar sesión.
- El timeout es fijo de 5 minutos (constante en `SessionTimeoutManager`).
- No hay biometría ni PIN como alternativa al login con contraseña.
