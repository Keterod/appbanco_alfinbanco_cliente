# Hoja de ruta — App Clientes Banco Alfin

## Fase C0 — Correcciones base (no iniciada)
- [ ] Sesión persistente (shared_preferences)
- [ ] Splash screen con verificación de sesión
- [ ] Mover credenciales Supabase a .env
- [ ] Actualizar .gitignore

## Fase C1 — Mis Solicitudes ✅ (COMPLETADA)
- [x] Modelo `RequestModel` + `RequestScheduleRow`
- [x] Repositorio con puente DNI
- [x] ViewModel con load/refresh
- [x] Pantalla con lista expandible, cronograma, pre-evaluación
- [x] Ruta `/requests` + navegación desde Dashboard
- [x] Documentación FASE_C1_MIS_SOLICITUDES.md

## Fase C2 — Mejoras a solicitudes (pendiente)
- [ ] Pull-to-refresh
- [ ] Indicador de carga inicial con shimmer
- [ ] Pantalla detalle individual
- [ ] Acción "Contactar asesor"
- [ ] Badge notificación si hay cambios de estado

## Fase C3 — Core funcional (pendiente)
- [ ] Conectar `clientes_cuentas` con datos reales
- [ ] Conectar `clientes_movimientos` con movimientos reales
- [ ] Conectar `clientes_creditos` con créditos desembolsados
- [ ] Reflejar saldo post-operación en UI
- [ ] SQLite para caché offline

## Fase C4 — Experiencia completa (pendiente)
- [ ] Notificaciones
- [ ] Edición de perfil
- [ ] Todos los productos financieros (tarjetas, CTS, etc.)
- [ ] Biometría (huella/face ID)
- [ ] Tests unitarios y widget tests
- [ ] Integración con Core/FastAPI
