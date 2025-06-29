/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Stored Procedures de Factura
*/

USE Com5600G01;
GO

BEGIN TRAN TestFacturaAll;

-- CrearFactura

-- Casos normales
EXEC facturacion.CrearFactura
	@id_persona     = 1,
	@id_metodo_pago = 1,
	@estado_pago    = 'Pendiente',
	@monto_a_pagar  = 150.75,
	@detalle        = 'Factura test 1';
-- Resultado esperado: OK, Factura creada correctamente.

EXEC facturacion.CrearFactura
	@id_persona     = 1,
	@id_metodo_pago = NULL,
	@estado_pago    = 'Pagado',
	@monto_a_pagar  = 200.00,
	@detalle        = NULL;
-- Resultado esperado: OK, Factura creada correctamente.

-- Persona inexistente
EXEC facturacion.CrearFactura
	@id_persona     = 99999,
	@id_metodo_pago = 1,
	@estado_pago    = 'Pendiente',
	@monto_a_pagar  = 50.00,
	@detalle        = NULL;
-- Resultado esperado: Error, Persona no encontrada.

-- Metodo de pago inexistente
EXEC facturacion.CrearFactura
	@id_persona     = 1,
	@id_metodo_pago = 999,
	@estado_pago    = 'Pendiente',
	@monto_a_pagar  = 75.00,
	@detalle        = NULL;
-- Resultado esperado: Error, Metodo de pago no existe.

-- Estado de pago vacío
EXEC facturacion.CrearFactura
	@id_persona     = 1,
	@id_metodo_pago = 1,
	@estado_pago    = '',
	@monto_a_pagar  = 60.00,
	@detalle        = NULL;
-- Resultado esperado: Error, El estado de pago es obligatorio.

-- Monto a pagar inválido (<= 0)
EXEC facturacion.CrearFactura
	@id_persona     = 1,
	@id_metodo_pago = 1,
	@estado_pago    = 'Pendiente',
	@monto_a_pagar  = 0,
	@detalle        = NULL;
-- Resultado esperado: Error, El monto a pagar debe ser mayor a 0.

-- Capturar IDs de factura creadas
DECLARE @fid1 INT, @fid2 INT;
SELECT
	@fid1 = MIN(id_factura),
	@fid2 = MAX(id_factura)
  FROM facturacion.factura;

-- ModificarFactura

-- Caso normal: cambiar estado
EXEC facturacion.ModificarFactura
	@id_factura  = @fid1,
	@estado_pago = 'Cancelado';
-- Resultado esperado: OK, Factura modificada correctamente.

-- Caso normal: cambiar metodo de pago y monto
EXEC facturacion.ModificarFactura
	@id_factura     = @fid2,
	@id_metodo_pago = 1,
	@monto_a_pagar  = 250.00;
-- Resultado esperado: OK, Factura modificada correctamente.

-- Factura inexistente
EXEC facturacion.ModificarFactura
	@id_factura  = 99999,
	@estado_pago = 'X';
-- Resultado esperado: Error, Factura no encontrada.

-- Metodo de pago inválido
EXEC facturacion.ModificarFactura
	@id_factura     = @fid1,
	@id_metodo_pago = 999;
-- Resultado esperado: Error, Metodo de pago no existe.

-- Estado de pago vacío
EXEC facturacion.ModificarFactura
	@id_factura  = @fid1,
	@estado_pago = '';
-- Resultado esperado: Error, El estado de pago no puede estar vacio.

-- Monto inválido
EXEC facturacion.ModificarFactura
	@id_factura    = @fid1,
	@monto_a_pagar = -10.00;
-- Resultado esperado: Error, El monto a pagar debe ser mayor a 0.

-- EliminarFactura

-- Caso normal 1
EXEC facturacion.EliminarFactura @id_factura = @fid1;
-- Resultado esperado: OK, Factura eliminada correctamente.

-- Caso normal 2
EXEC facturacion.EliminarFactura @id_factura = @fid2;
-- Resultado esperado: OK, Factura eliminada correctamente.

-- Factura inexistente
EXEC facturacion.EliminarFactura @id_factura = 99999;
-- Resultado esperado: Error, Factura no encontrada.

-- Intentar eliminar nuevamente
EXEC facturacion.EliminarFactura @id_factura = @fid1;
-- Resultado esperado: Error, Factura no encontrada.

ROLLBACK TRAN TestFacturaAll;
GO

SELECT *
FROM facturacion.factura