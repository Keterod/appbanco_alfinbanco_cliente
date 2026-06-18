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

## Implementados en Fase C4.1
- [x] Dashboard, Cuentas, Créditos y Perfil cargan datos reales desde Supabase
- [x] Eliminado parpadeo de datos demo al inicio
- [x] Manejo de loading, vacío y error en cada pantalla

## Implementados en Fase C4.2
- [x] Persistencia de operaciones en `clientes_operaciones`
- [x] Persistencia de movimientos en `clientes_movimientos`
- [x] Actualización de saldo en `clientes_cuentas`
- [x] Validación de saldo suficiente antes de operar

## Implementados en Fase C4.3
- [x] Modelo `OperationModel`
- [x] Repositorio `getOperations()` desde `clientes_operaciones`
- [x] ViewModel con load/refresh
- [x] Pantalla historial con pull-to-refresh, vacío, error
- [x] Pantalla detalle/comprobante
- [x] Ruta `/operations` + `/operations/detail`
- [x] Acceso desde Dashboard y Perfil

## Pendientes para fase siguiente (C4.4)
- [ ] RPC transaccional en backend (reemplazar 3 pasos del cliente)
- [ ] Historial con paginación
- [ ] Filtros por tipo y fecha
- [ ] Descarga de comprobante PDF
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
