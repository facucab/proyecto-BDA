/*
	Entrega 4 - Documento de instalación y configuración
	
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Stored Procedures de Nota de Crédito
*/

USE Com5600G01;
GO

-- Pruebas nota de credito

-- CREACION

--Casos Normales
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-15',
	@monto = 150.00,
	@motivo = 'Devolucion por mal servicio',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-16',
	@monto = 75.50,
	@motivo = 'Descuento por lluvia',
	@id_factura = 2,
	@id_clima = 1;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-17',
	@monto = 200.00,
	@motivo = NULL,
	@id_factura = 3,
	@id_clima = NULL;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-18',
	@monto = 50.25,
	@motivo = 'Error en facturacion',
	@id_factura = 4,
	@id_clima = 2;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-19',
	@monto = 300.00,
	@motivo = 'Cancelacion de servicio',
	@id_factura = 5,
	@id_clima = NULL;
--Resultado: Nota de credito creada correctamente

-- ERRORES

-- Error: Fecha de emision nula
EXEC facturacion.CrearNotaCredito
	@fecha_emision = NULL,
	@monto = 150.00,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: La fecha de emision es obligatoria

-- Error: Fecha de emision futura
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2025-12-31',
	@monto = 150.00,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: La fecha de emision no puede ser futura

-- Error: Monto nulo
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = NULL,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: El monto debe ser mayor a 0

-- Error: Monto cero
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 0.00,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: El monto debe ser mayor a 0

-- Error: Monto negativo
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = -50.00,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: El monto debe ser mayor a 0

-- Error: ID factura nulo
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 150.00,
	@motivo = 'Test',
	@id_factura = NULL,
	@id_clima = NULL;
--Resultado: El ID de factura es obligatorio

-- Error: Factura inexistente
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 150.00,
	@motivo = 'Test',
	@id_factura = 999,
	@id_clima = NULL;
--Resultado: La factura especificada no existe

-- Error: Clima inexistente
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 150.00,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = 999;
--Resultado: El clima especificado no existe

-- Verificar estado final de la tabla
SELECT *
FROM facturacion.nota_credito
ORDER BY id_nota_credito;
GO 