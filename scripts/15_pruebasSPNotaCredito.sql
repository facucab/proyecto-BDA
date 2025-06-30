/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
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
	@monto = 150.00D,
	@motivo = 'Devolucion por mal servicio',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-16',
	@monto = 75.50D,
	@motivo = 'Descuento por lluvia',
	@id_factura = 2,
	@id_clima = 1;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-17',
	@monto = 200.00D,
	@motivo = NULL,
	@id_factura = 3,
	@id_clima = NULL;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-18',
	@monto = 50.25D,
	@motivo = 'Error en facturacion',
	@id_factura = 4,
	@id_clima = 2;
--Resultado: Nota de credito creada correctamente

EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-19',
	@monto = 300.00D,
	@motivo = 'Cancelacion de servicio',
	@id_factura = 5,
	@id_clima = NULL;
--Resultado: Nota de credito creada correctamente

-- ERRORES

-- Error: Fecha de emision nula
EXEC facturacion.CrearNotaCredito
	@fecha_emision = NULL,
	@monto = 150.00D,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: La fecha de emision es obligatoria

-- Error: Fecha de emision futura
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2025-12-31',
	@monto = 150.00D,
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
	@monto = 0.00D,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: El monto debe ser mayor a 0

-- Error: Monto negativo
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = -50.00D,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = NULL;
--Resultado: El monto debe ser mayor a 0

-- Error: ID factura nulo
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 150.00D,
	@motivo = 'Test',
	@id_factura = NULL,
	@id_clima = NULL;
--Resultado: El ID de factura es obligatorio

-- Error: Factura inexistente
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 150.00D,
	@motivo = 'Test',
	@id_factura = 999,
	@id_clima = NULL;
--Resultado: La factura especificada no existe

-- Error: Clima inexistente
EXEC facturacion.CrearNotaCredito
	@fecha_emision = '2024-01-20',
	@monto = 150.00D,
	@motivo = 'Test',
	@id_factura = 1,
	@id_clima = 999;
--Resultado: El clima especificado no existe

-- MODIFICACION

-- Casos Normales
EXEC facturacion.ModificarNotaCredito
	@id_nota_credito = 1,
	@fecha_emision = '2024-01-21',
	@monto = 175.00D,
	@motivo = 'Devolucion actualizada',
	@id_clima = 1;
--Resultado: Nota de credito modificada correctamente

EXEC facturacion.ModificarNotaCredito
	@id_nota_credito = 2,
	@monto = 80.00D,
	@motivo = 'Descuento por lluvia actualizado';
--Resultado: Nota de credito modificada correctamente

-- ERRORES

-- Error: Nota de credito inexistente
EXEC facturacion.ModificarNotaCredito
	@id_nota_credito = 999,
	@monto = 100.00D;
--Resultado: La nota de credito no existe

-- Error: Fecha futura en modificacion
EXEC facturacion.ModificarNotaCredito
	@id_nota_credito = 1,
	@fecha_emision = '2025-12-31';
--Resultado: La fecha de emision no puede ser futura

-- Error: Monto invalido en modificacion
EXEC facturacion.ModificarNotaCredito
	@id_nota_credito = 1,
	@monto = -25.00D;
--Resultado: El monto debe ser mayor a 0

-- Error: Clima inexistente en modificacion
EXEC facturacion.ModificarNotaCredito
	@id_nota_credito = 1,
	@id_clima = 999;
--Resultado: El clima especificado no existe

-- ELIMINACION

-- Casos Normales
EXEC facturacion.EliminarNotaCredito
	@id_nota_credito = 3;
--Resultado: Nota de credito eliminada correctamente

EXEC facturacion.EliminarNotaCredito
	@id_nota_credito = 4;
--Resultado: Nota de credito eliminada correctamente

-- ERRORES

-- Error: Nota de credito inexistente
EXEC facturacion.EliminarNotaCredito
	@id_nota_credito = 999;
--Resultado: La nota de credito no existe

-- Verificar estado final de la tabla
SELECT *
FROM facturacion.nota_credito
ORDER BY id_nota_credito;
GO 