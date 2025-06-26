/*
	Entrega 4 - Pruebas para Metodo de Pago

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Metodo de Pago
*/

USE Com5600G01;
GO

-- Caso normal: crear
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Efectivo';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Tarjeta de Crédito';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Transferencia';
-- Resultado: Nuevo método de pago creado

-- Nombre duplicado
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Efectivo';
-- Resultado: Ya hay un método de pago con ese nombre

-- Nombre nulo o vacío
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = NULL;
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = '';
-- Resultado: El nombre no puede ser nulo

-- Modificación normal
EXEC pagos_y_facturas.ModificacionMetodoPago @id = 1, @nombre_nuevo = 'Efectivo Modificado';
-- Resultado: Método de pago modificado

-- Modificación a nombre ya existente
EXEC pagos_y_facturas.ModificacionMetodoPago @id = 2, @nombre_nuevo = 'Efectivo Modificado';
-- Resultado: Ese método de pago ya está registrado

-- Modificación de método inactivo
EXEC pagos_y_facturas.EliminacionMetodoPago @id = 3;
EXEC pagos_y_facturas.ModificacionMetodoPago @id = 3, @nombre_nuevo = 'Cheque';
-- Resultado: Método de pago no encontrado o inactivo

-- Eliminación lógica (caso normal)
EXEC pagos_y_facturas.EliminacionMetodoPago @id = 2;
-- Resultado: Método de pago eliminado lógicamente

-- Eliminación lógica de método ya inactivo
EXEC pagos_y_facturas.EliminacionMetodoPago @id = 2;
-- Resultado: Método de pago no encontrado o ya inactivo

-- Eliminación lógica con id inexistente
EXEC pagos_y_facturas.EliminacionMetodoPago @id = 9999;
-- Resultado: Método de pago no encontrado o ya inactivo

-- Prueba de uso en factura (solo métodos activos)
-- Intentar crear factura con método de pago inactivo
EXEC pagos_y_facturas.CreacionFactura @estado_pago = 'Pendiente', @monto_a_pagar = 1000, @id_persona = 1, @id_metodo_pago = 2;
-- Resultado: Método de pago no válido o inactivo

-- Crear factura con método de pago activo
EXEC pagos_y_facturas.CreacionFactura @estado_pago = 'Pagado', @monto_a_pagar = 500, @id_persona = 1, @id_metodo_pago = 1;
-- Resultado: Factura creada correctamente

-- Modificar factura a método de pago inactivo
EXEC pagos_y_facturas.ModificacionFactura @id_factura = 1, @nuevo_estado_pago = 'Pagado', @nuevo_monto = 600, @nuevo_metodo_pago = 2;
-- Resultado: Método de pago no válido o inactivo

-- Modificar factura a método de pago activo
EXEC pagos_y_facturas.ModificacionFactura @id_factura = 1, @nuevo_estado_pago = 'Pagado', @nuevo_monto = 600, @nuevo_metodo_pago = 1;
-- Resultado: Factura actualizada correctamente
