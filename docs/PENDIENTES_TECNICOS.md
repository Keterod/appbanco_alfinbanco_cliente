# Pendientes técnicos — App Clientes

## Implementados en Fase C1
- [x] Mis Solicitudes: lectura de `solicitudes_credito` vía puente DNI
- [x] Ruta `/requests` + navegación desde Dashboard

## Implementados en Fase C2
- [x] Sesión temporal con shared_preferences
- [x] SplashScreen con verificación de sesión, timeout e internet
- [x] Timeout de 5 minutos por inactividad
- [x] Banner no-internet en Login
- [x] Logout real con signOut + limpieza de sesión temporal
- [x] Actualización de timestamp al navegar a pantallas principales

## Implementados en Fase C3
- [x] Pull-to-refresh en RequestsScreen
- [x] Pantalla detalle individual de solicitud
- [x] Cronograma completo en detalle
- [x] Contactar asesor (simulado vía AlertDialog)
- [x] Badges de estado con colores suaves
- [x] Estado vacío mejorado

## Pendientes para fase siguiente
- [ ] Reflejar solicitudes aprobadas → créditos activos
- [ ] Pago de cuota real desde créditos desembolsados
- [ ] SQLite / modo offline
- [ ] Notificaciones
- [ ] Edición de perfil
- [ ] Tests unitarios (ViewModels) y widget tests
- [ ] Mover credenciales Supabase a .env
- [ ] Secure storage en lugar de shared_preferences para datos sensibles
- [ ] Biometría
- [ ] Integración con Core/FastAPI
