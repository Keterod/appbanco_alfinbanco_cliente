# App Cliente / Home Banking — Alfin Banco

Aplicación móvil Flutter para clientes de **Alfin Banco**. Home Banking con **Supabase** (Auth + datos) y **modo demostración** de respaldo si el backend no responde.

## Stack

| Tecnología | Uso |
|------------|-----|
| **Flutter** | Framework UI multiplataforma |
| **Dart** | Lenguaje (SDK `^3.11.4`) |
| **Material 3** | Sistema de diseño |
| **ChangeNotifier** | Estado en ViewModels (MVVM) |
| **supabase_flutter** | Auth, PostgREST y RPC |

## Arquitectura

**MVVM** con capas en `lib/app/`:

- **Model** — entidades y `fromSupabase`
- **Repository** — acceso a Supabase (`auth`, `profile`, `accounts`, `credits`, `operations`)
- **ViewModel** — lógica de presentación (`ChangeNotifier`)
- **View** — pantallas Flutter
- **Navigation** — rutas nombradas (`MaterialApp`)
- **Core/Supabase** — URL, anon key e inicialización

No se usa Provider, Riverpod ni GoRouter.

## Supabase

### URL y clave

| Parámetro | Valor |
|-----------|--------|
| **URL base** (solo esta, sin `/rest/v1/`) | `https://lynkauvinqfzamixszqo.supabase.co` |
| **Clave** | Publishable / **anon** (`sb_publishable_...`) en `lib/app/core/supabase/supabase_config.dart` |

No se usa `service_role` en la app cliente.

### Configuración

1. Las credenciales ya están en `supabase_config.dart`.
2. En el [Dashboard de Supabase](https://supabase.com/dashboard) deben existir las tablas y la función RPC (ver abajo).
3. Ejecutar `flutter pub get` y `flutter run`.

`main.dart` inicializa Supabase con `WidgetsFlutterBinding.ensureInitialized()`. Si falla la inicialización, la app **no crashea** y sigue en modo demo (ver logs `[Supabase]`).

### Tablas requeridas

| Tabla | Uso en la app |
|-------|----------------|
| `clientes_perfil` | Perfil del cliente |
| `clientes_cuentas` | Cuentas y saldos |
| `clientes_movimientos` | Movimientos |
| `clientes_creditos` | Préstamos activos |
| `clientes_cronograma_pagos` | Cuotas del crédito |
| `clientes_operaciones` | Transferencias y pagos registrados |

### Función RPC

- `crear_data_demo_cliente(user_id uuid)` — crea cuenta, movimientos, crédito y cronograma demo tras el registro.

> **Nota:** Al verificar el proyecto `lynkauvinqfzamixszqo`, las tablas anteriores **aún no aparecen** en el schema público. Debes crearlas en Supabase (SQL/migraciones) con esos nombres exactos antes de que registro y lectura remota funcionen. La app detecta errores de tablas y muestra un mensaje claro.

### Flujo con Supabase

1. **Registro** — `signUp` en Auth → insert en `clientes_perfil` → RPC `crear_data_demo_cliente` → `signOut` → mensaje para iniciar sesión con el correo.
2. **Login** — correo y contraseña con `signInWithPassword`.
3. **Dashboard / Cuentas / Créditos / Perfil** — lectura de tablas con sesión activa.
4. **Transferencias** — insert en `clientes_operaciones` con `numero_operacion` tipo `ALF-OP-{timestamp}` (sin actualizar saldos ni cuotas).

### Modo demostración (fallback)

Si Supabase no está configurado, no inicializa o hay error de red, las pantallas usan datos locales en `lib/app/data/demo_client_data.dart`. El login permite entrar en modo demo cuando no hay respuesta del servidor.

## Cómo probar

### Registro real

1. Asegúrate de que existan las tablas y la RPC en Supabase.
2. En la app: **Regístrate** con DNI, nombres, teléfono, correo y contraseña (mín. 6 caracteres).
3. Tras el éxito, inicia sesión con el **mismo correo y contraseña**.

### Login real

1. Pantalla de ingreso → **Correo electrónico** + **Contraseña**.
2. Tras autenticación correcta, el Dashboard carga perfil, cuenta, crédito y movimientos desde Supabase.

### Verificar datos en Supabase

En el Dashboard → **Table Editor** o SQL:

- `auth.users` — usuario creado al registrarse.
- `clientes_perfil` — fila con `id` = UUID del usuario.
- Tras el RPC: filas en `clientes_cuentas`, `clientes_movimientos`, `clientes_creditos`, `clientes_cronograma_pagos`.
- Tras una transferencia: fila en `clientes_operaciones`.

## Flujo principal

```
Login ──► Dashboard (Inicio)
   │         ├── Cuentas / Ahorros
   │         ├── Créditos
   │         ├── Transferencias y Pagos
   │         └── Perfil ──► Cerrar sesión ──► Login
   └──► Registro ──► (éxito) ──► Login
```

## Cómo ejecutar

```bash
flutter pub get
flutter run
```

Validación:

```bash
flutter analyze
flutter build apk --debug
```

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`

## Estructura (resumen)

```
lib/
├── main.dart
└── app/
    ├── core/supabase/
    ├── repository/
    ├── data/demo_client_data.dart
    ├── model/
    ├── viewmodel/
    ├── view/
    ├── navigation/
    ├── ui/theme/
    └── util/
```

## Documentación de evaluación

| Archivo | Contenido |
|---------|-----------|
| [docs/CHECKLIST_EVALUACION.md](docs/CHECKLIST_EVALUACION.md) | Cumplimiento de requisitos |
| [docs/EVIDENCIAS_DEMO.md](docs/EVIDENCIAS_DEMO.md) | Capturas sugeridas |
| [docs/RESUMEN_TECNICO.md](docs/RESUMEN_TECNICO.md) | MVVM, rutas y decisiones |

## Licencia / uso

Proyecto académico — Alfin Banco (demostración).
