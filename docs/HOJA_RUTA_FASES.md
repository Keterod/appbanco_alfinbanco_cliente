# Hoja de ruta — App Clientes Banco Alfin

## Fase C0 — Correcciones base (no iniciada)
- [ ] Mover credenciales Supabase a .env
- [ ] Actualizar .gitignore

## Fase C1 — Mis Solicitudes ✅ (COMPLETADA)
- [x] Modelo `RequestModel` + `RequestScheduleRow`
- [x] Repositorio con puente DNI
- [x] ViewModel con load/refresh
- [x] Pantalla con lista expandible, cronograma, pre-evaluación
- [x] Ruta `/requests` + navegación desde Dashboard
- [x] Documentación FASE_C1_MIS_SOLICITUDES.md

## Fase C2 — Sesión temporal ✅ (COMPLETADA)
- [x] Dependencia shared_preferences
- [x] SessionTimeoutManager (5 min de inactividad)
- [x] SplashScreen con verificación de sesión + timeout + internet
- [x] Banner no-internet en Login
- [x] Logout real con signOut + clearActivity
- [x] Actualización de timestamp en pantallas principales
- [x] Documentación FASE_C2_SESION_TEMPORAL.md

## Fase C3 — Mejoras a solicitudes ✅ (COMPLETADA)
- [x] Pull-to-refresh con RefreshIndicator
- [x] Pantalla detalle individual
- [x] Cronograma completo con tarjetas compactas
- [x] Contactar asesor (AlertDialog simulado)
- [x] Badges de estado con colores suaves
- [x] Estado vacío mejorado
- [x] Documentación FASE_C3_MEJORAS_SOLICITUDES.md

## Fase C4.1 — Core funcional — Carga real sin mock ✅ (COMPLETADA)
- [x] Conectar `clientes_cuentas` con datos reales
- [x] Conectar `clientes_movimientos` con movimientos reales
- [x] Conectar `clientes_creditos` con créditos desembolsados
- [x] Dashboard, Cuentas, Créditos y Perfil cargan datos reales sin mostrar demo al inicio

## Fase C4.2 — Operaciones persistentes ✅ (COMPLETADA)
- [x] Insertar operación en `clientes_operaciones` al confirmar transferencia
- [x] Insertar movimiento en `clientes_movimientos` como débito
- [x] Actualizar saldo en `clientes_cuentas` post-operación
- [x] Validación de saldo suficiente antes de operar
- [x] Refresco de Dashboard/Cuentas al regresar post-operación
- [x] Documentación FASE_C4_2_OPERACIONES_PERSISTENTES.md

## Fase C4.3 — Historial de operaciones ✅ (COMPLETADA)
- [x] Modelo `OperationModel`
- [x] Repositorio `getOperations()` desde `clientes_operaciones`
- [x] ViewModel con load/refresh
- [x] Pantalla historial con pull-to-refresh, vacío, error
- [x] Pantalla detalle/comprobante
- [x] Ruta `/operations` + `/operations/detail`
- [x] Acceso desde Dashboard y Perfil
- [x] Documentación FASE_C4_3_HISTORIAL_OPERACIONES.md

## Fase C4.4 — Mejoras de historial (pendiente)
- [ ] RPC transaccional en backend
- [ ] Historial con paginación
- [ ] Filtros por tipo y fecha
- [ ] Descarga de comprobante PDF
- [ ] SQLite para caché offline

## Fase C5 — Experiencia completa (pendiente)
- [ ] Notificaciones
- [ ] Edición de perfil
- [ ] Todos los productos financieros (tarjetas, CTS, etc.)
- [ ] Secure storage en lugar de shared_preferences
- [ ] Biometría (huella/face ID)
- [ ] Tests unitarios y widget tests
- [ ] Integración con Core/FastAPI
