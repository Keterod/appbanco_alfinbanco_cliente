# Evidencias sugeridas — Demo App Cliente (Alfin Banco)

Guía para capturas de pantalla y exposición oral. Orden recomendado para una presentación de 8–12 minutos.

---

## 0. Splash — Verificación de sesión

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Logo Alfin, "Alfin Banco", "Verificando sesión..." con spinner |
| **Qué explicar** | Punto de entrada; verifica sesión Supabase, timeout de 5 min e internet; si todo ok va directo al Dashboard; si expiró o no hay sesión va al Login |

---

## 1. Login

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Logo Alfin, título "Alfin Banco", campos DNI y contraseña, botón "Ingresar", enlace "¿No tienes cuenta? Regístrate", texto modo demostración, posible banner de conexión requerida |
| **Qué explicar** | Punto de entrada tras splash; credenciales de ejemplo; muestra banner si no hay internet; en producción validaría contra el core bancario |

---

## 2. Registro

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Formulario completo (DNI, nombres, apellidos, teléfono, correo, contraseñas, términos), botón “Crear cuenta” |
| **Qué explicar** | Validaciones locales (8 dígitos DNI, 9 teléfono, email, contraseña ≥ 6); alta simulada sin backend |

---

## 3. Dashboard

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Saludo “Hola, Diego”, botón Transferencias y Pagos, tarjetas ahorro y crédito, bottom navigation |
| **Qué explicar** | Hub principal del Home Banking; acceso rápido a productos y operaciones |

---

## 4. Cuentas / Ahorros

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Número de cuenta, CCI, saldo disponible y contable, botones estado de cuenta y Transferir |
| **Qué explicar** | Detalle del producto de ahorros; en fase backend vendría del API de cuentas |

---

## 5. Últimos movimientos

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Lista en Dashboard o en pantalla Cuentas (depósitos/retiros con montos y fechas) |
| **Qué explicar** | Trazabilidad de operaciones; categorías y referencias mock |

---

## 6. Créditos

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Préstamo personal, monto pendiente, cuota mensual, TEA, barra de progreso, botón “Pagar cuota” |
| **Qué explicar** | Vista consolidada del crédito activo del cliente |

---

## 7. Cronograma de pagos

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Lista de cuotas con chips Pagado / Pendiente / Vencido |
| **Qué explicar** | Seguimiento de obligaciones; estados visuales para mora y pagos al día |

---

## 8. Transferencias — formulario

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Selector de tipo (Transferencia / Crédito / Servicio), cuenta origen, destino, monto, descripción |
| **Qué explicar** | Un solo flujo para varios tipos de operación; validación antes de continuar |

---

## 9. Resumen de operación

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Card con tipo, origen, destino, monto, descripción y botón “Confirmar operación” |
| **Qué explicar** | Paso de confirmación obligatorio (doble factor en producción) |

---

## 10. Operación exitosa

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Ícono de éxito, número `ALF-OP-XXXX`, fecha, monto, botones “Nueva operación” y “Volver al inicio” |
| **Qué explicar** | Comprobante simulado; en producción se registraría en el ledger |

---

## 11. Perfil de usuario

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Nombre, DNI censurado, correo, teléfono, dirección, tipo de cliente, sección seguridad |
| **Qué explicar** | Datos de identificación; opciones de seguridad en modo demostración |

---

## 12. Cierre de sesión

| Aspecto | Detalle |
|---------|---------|
| **Qué mostrar** | Botón cerrar sesión en Perfil o icono en Dashboard → pantalla Login |
| **Qué explicar** | Fin de sesión; en producción invalidaría token y limpiaría datos sensibles |

---

## Tips para la exposición

- Usar un solo dispositivo o emulador con tema claro.
- Nombrar siempre **Alfin Banco** y **modo demostración** al hablar de datos ficticios.
- Cerrar con roadmap: Supabase/API, persistencia, notificaciones (ver `README.md`).
