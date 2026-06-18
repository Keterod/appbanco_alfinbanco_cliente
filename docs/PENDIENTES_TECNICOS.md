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

## Implementados en Fase C4.4
- [x] Carga de todas las cuentas (`getAccounts()`)
- [x] Dropdown cuenta origen con saldo disponible
- [x] Dropdown cuenta destino excluyendo origen
- [x] Validación origen ≠ destino
- [x] Flujo TRANSFERENCIA_PROPIA: 1 operación + 2 movimientos + débito origen + crédito destino
- [x] CuentasScreen con lista de cuentas y badge "Principal"
- [x] Pantalla de éxito específica "Transferencia entre cuentas realizada"
- [x] Refresco de saldos post-operación

## Implementados en Fase C4.5
- [x] Formulario stepper: Negocio → Crédito → Confirmar
- [x] Cálculo de TEA/TEM/cuota (amortización francesa)
- [x] Pre-evaluación con score, riesgo, elegibilidad
- [x] Generación de cronograma de pagos
- [x] Puente de identidad auth.uid() → clientes.id
- [x] Inserción en solicitudes_credito con estado "enviado"
- [x] Generación de número de expediente
- [x] Pantalla de éxito con enlace a Mis Solicitudes

## Implementados en Fase C4.6
- [x] Timeline vertical con 5 pasos en detalle de solicitud
- [x] Card "Resultado de evaluación" según estado
- [x] Indicador "Paso X de 5" y descripción en lista de solicitudes
- [x] Sección "Estado de tus expedientes" en Dashboard con conteos
- [x] Badge de actualización cuando updated_at > created_at
- [x] Soporte para campos extendidos (monto_aprobado, motivo_rechazo, etc.)

## Pendientes para fase siguiente (C4.7 — Crédito desembolsado / activo)
- [ ] Solicitud aprobada → reflejar como crédito activo en clientes_creditos
- [ ] Opción de pago de cuota desde transferencias

## Pendientes para fases posteriores (C4.7, C5)
- [ ] Crédito desembolsado → reflejar como crédito activo en clientes_creditos
- [ ] Opción de pago de cuota desde transferencias
- [ ] Pago de servicio Luz
- [ ] Metas de ahorro
- [ ] Depósito a cuenta propia
- [ ] RPC transaccional en backend (reemplazar pasos del cliente)
- [ ] Historial con paginación
- [ ] Filtros por tipo y fecha
- [ ] Descarga de comprobante PDF
- [ ] SQLite / modo offline
- [ ] Notificaciones
- [ ] Edición de perfil
- [ ] Tests unitarios (ViewModels) y widget tests
- [ ] Mover credenciales Supabase a .env
- [ ] Secure storage en lugar de shared_preferences para datos sensibles
- [ ] Biometría
- [ ] Integración con Core/FastAPI
