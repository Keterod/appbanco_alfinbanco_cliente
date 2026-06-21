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

## Fase C4.4 — Transferencia entre cuentas propias ✅ (COMPLETADA)
- [x] Carga de todas las cuentas propias desde `clientes_cuentas`
- [x] Dropdown cuenta origen con saldo disponible
- [x] Dropdown cuenta destino excluyendo origen
- [x] Validación origen ≠ destino, saldo suficiente
- [x] Flujo TRANSFERENCIA_PROPIA: débito origen + abono destino + 2 movimientos
- [x] Pantalla de éxito "Transferencia entre cuentas realizada"
- [x] Refresco de saldos en Cuentas y Dashboard post-operación
- [x] CuentasScreen muestra lista de cuentas con badge "Principal"
- [x] Documentación FASE_C4_4_TRANSFERENCIA_CUENTAS_PROPIAS.md

## Fase C4.5 — Solicitud de Crédito Empresarial desde App Clientes ✅ (COMPLETADA)
- [x] Formulario stepper: Negocio → Crédito → Confirmar
- [x] Cálculo de TEA/TEM/cuota (amortización francesa)
- [x] Pre-evaluación con score, riesgo, elegibilidad
- [x] Generación de cronograma de pagos
- [x] Puente de identidad auth.uid() → clientes.id
- [x] Inserción en solicitudes_credito con estado "enviado"
- [x] Generación de número de expediente
- [x] Pantalla de éxito con enlace a Mis Solicitudes
- [x] Documentación FASE_C4_5_SOLICITUD_CREDITO_CLIENTE.md

## Fase C4.6 — Seguimiento visual del expediente ✅ (COMPLETADA)
- [x] Timeline vertical con 5 pasos en detalle de solicitud
- [x] Card "Resultado de evaluación" según estado (aprobado/condicionado/rechazado/desembolsado)
- [x] Indicador "Paso X de 5" y descripción en lista de solicitudes
- [x] Sección "Estado de tus expedientes" en Dashboard con conteos
- [x] Badge de actualización cuando updated_at > created_at
- [x] Soporte para nuevos campos (monto_aprobado, motivo_rechazo, fecha_decision, etc.)
- [x] Documentación FASE_C4_6_SEGUIMIENTO_EXPEDIENTE.md

## Fase C4.7 — Crédito desembolsado → crédito activo ✅ (COMPLETADA)
- [x] `DisbursementRepository` refleja solicitudes desembolsadas como créditos activos
- [x] Inserta cronograma, acredita cuenta, registra movimiento y operación
- [x] `CreditsViewModel` llama a reflejar antes de cargar créditos
- [x] `RequestDetailScreen` muestra "Crédito desembolsado" con enlace a Mis créditos

## Fase C4.8 — Pago de cuota del crédito ✅ (COMPLETADA)
- [x] `CreditPaymentRepository` con flujo completo sobre schema real de `clientes_cronograma_pagos`
- [x] Flujo reordenado: update cuota → update crédito → débito → movimiento → operación
- [x] Validación de estado actual de la cuota (re-query antes de pagar)
- [x] Solo columnas reales: `estado='pagado'`, `fecha_pago=now()` en cronograma
- [x] `CreditPaymentViewModel` carga siguiente cuota pendiente, selecciona cuenta, valida saldo, confirma
- [x] `CreditPaymentScreen` con formulario, dropdown cuentas, confirmación AlertDialog, pantalla de éxito
- [x] Botón "Pagar cuota" en Créditos navega a nueva pantalla (condicional si hay cuotas pendientes)
- [x] Reload de créditos al regresar post-pago
- [x] Cancelación cuando todas las cuotas están pagadas
- [x] `monto_pendiente` se reduce por `installment.amount` (no hay columna `capital`)
- [x] Documentación FASE_C4_8_PAGO_CUOTA_CREDITO.md

## Fase C4.9 — Funcionalidades extra (pendiente)
- [ ] Pago de Luz
- [ ] Metas de ahorro
- [ ] Depósito a cuenta propia

## Fase C5 — Mejoras transversales (pendiente)
- [ ] Pago de servicio Luz
- [ ] Metas de ahorro
- [ ] Depósito a cuenta propia
- [ ] RPC transaccional en backend
- [ ] Historial con paginación
- [ ] Filtros por tipo y fecha
- [ ] Descarga de comprobante PDF
- [ ] SQLite para caché offline
- [ ] Notificaciones
- [ ] Edición de perfil
- [ ] Secure storage en lugar de shared_preferences
- [ ] Biometría (huella/face ID)
- [ ] Tests unitarios y widget tests
- [ ] Integración con Core/FastAPI
- [ ] RPC transaccional en backend
- [ ] Historial con paginación
- [ ] Filtros por tipo y fecha
- [ ] Descarga de comprobante PDF
- [ ] SQLite para caché offline
- [ ] Notificaciones
- [ ] Edición de perfil
- [ ] Secure storage en lugar de shared_preferences
- [ ] Biometría (huella/face ID)
- [ ] Tests unitarios y widget tests
- [ ] Integración con Core/FastAPI
