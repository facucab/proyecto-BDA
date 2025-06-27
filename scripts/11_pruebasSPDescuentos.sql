/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Descuento
*/

USE Com5600G01;
GO

BEGIN TRAN TestDescuento;
GO

-- CrearDescuento

-- Caso normal 1
EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento A',
	@cantidad    = 10.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento B',
	@cantidad    = 20.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento C',
	@cantidad    = 30.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento D',
	@cantidad    = 40.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento 1',
	@cantidad    = 50.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento 2',
	@cantidad    = 10.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

-- Caso normal 2 (cantidad = 0)
EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento Cero',
	@cantidad    = 0.00;
-- Resultado esperado: OK, Descuento creado correctamente.
GO

-- Descripción vacía
EXEC facturacion.CrearDescuento
	@descripcion = '',
	@cantidad    = 5.00;
-- Resultado esperado: Error, La descripción es obligatoria.
GO

-- Descripción nula
EXEC facturacion.CrearDescuento
	@descripcion = NULL,
	@cantidad    = 5.00;
-- Resultado esperado: Error, La descripción es obligatoria.
GO

-- Cantidad negativa
EXEC facturacion.CrearDescuento
	@descripcion = 'Negativo',
	@cantidad    = -1.00;
-- Resultado esperado: Error, Cantidad inválida. Debe ser mayor o igual a 0.
GO

-- Descripción duplicada
EXEC facturacion.CrearDescuento
	@descripcion = 'Descuento A',
	@cantidad    = 20.00;
-- Resultado esperado: Error, Ya existe un descuento con esa descripción.
GO


-- ModificarDescuento

-- Caso normal
EXEC facturacion.ModificarDescuento
	@id_descuento = 1,
	@descripcion  = 'Descuento A Mod',
	@cantidad     = 15.50;
-- Resultado esperado: OK, Descuento modificado correctamente.
GO

-- ID inexistente
EXEC facturacion.ModificarDescuento
	@id_descuento = 99999,
	@descripcion  = 'X',
	@cantidad     = 1.00;
-- Resultado esperado: Error, Descuento no encontrado.
GO

-- Descripción vacía
EXEC facturacion.ModificarDescuento
	@id_descuento = 1,
	@descripcion  = '',
	@cantidad     = 15.50;
-- Resultado esperado: Error, La descripción es obligatoria.
GO

-- Cantidad negativa
EXEC facturacion.ModificarDescuento
	@id_descuento = 1,
	@descripcion  = 'Valido',
	@cantidad     = -5.00;
-- Resultado esperado: Error, Cantidad inválida. Debe ser mayor o igual a 0.
GO


-- EliminarDescuento

-- Caso normal 1
EXEC facturacion.EliminarDescuento
	@id_descuento = 1;
-- Resultado esperado: OK, Descuento eliminado correctamente.
GO

-- Caso normal 2
EXEC facturacion.EliminarDescuento
	@id_descuento = 2;
-- Resultado esperado: OK, Descuento eliminado correctamente.
GO

-- ID inexistente
EXEC facturacion.EliminarDescuento
	@id_descuento = 99999;
-- Resultado esperado: Error, Descuento no encontrado.
GO

-- Intentar eliminar nuevamente
EXEC facturacion.EliminarDescuento
	@id_descuento = 1;
-- Resultado esperado: Error, Descuento no encontrado.
GO

ROLLBACK TRAN TestDescuento;
GO

SELECT * 
FROM facturacion.descuento