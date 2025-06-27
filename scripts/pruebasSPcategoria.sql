/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Categoría
*/

USE Com5600G01;
GO

BEGIN TRAN TestCategoria;
GO

-- CrearCategoria

-- Caso normal 1
EXEC actividades.CrearCategoria
	@nombre_categoria = 'Básica',
	@costo_membrecia  = 100.00,
	@vigencia         = GETDATE();
-- Resultado esperado: OK, Categoría creada correctamente.
GO

-- Caso normal 2
EXEC actividades.CrearCategoria
	@nombre_categoria = 'Premium',
	@costo_membrecia  = 200.00,
	@vigencia         = GETDATE();
-- Resultado esperado: OK, Categoría creada correctamente.
GO

-- Nombre vacío
EXEC actividades.CrearCategoria
	@nombre_categoria = '',
	@costo_membrecia  = 50.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, El nombre de la categoría es obligatorio.
GO

-- Costo inválido (<= 0)
EXEC actividades.CrearCategoria
	@nombre_categoria = 'DescuentoTest',
	@costo_membrecia  = 0.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, El costo de membresía debe ser mayor a 0.
GO

-- Vigencia nula
EXEC actividades.CrearCategoria
	@nombre_categoria = 'TestNulVig',
	@costo_membrecia  = 75.00,
	@vigencia         = NULL;
-- Resultado esperado: Error, La fecha de vigencia es obligatoria.
GO

-- Nombre duplicado
EXEC actividades.CrearCategoria
	@nombre_categoria = 'Básica',
	@costo_membrecia  = 120.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, Ya existe una categoría con ese nombre.
GO


-- ModificarCategoria

-- Caso normal 1
EXEC actividades.ModificarCategoria
	@id_categoria     = 1,
	@nombre_categoria = 'BásicaMod',
	@costo_membrecia  = 150.00,
	@vigencia         = GETDATE();
-- Resultado esperado: OK, Categoría modificada correctamente.
GO

-- Caso normal 2
EXEC actividades.ModificarCategoria
	@id_categoria     = 2,
	@nombre_categoria = 'PremiumMod',
	@costo_membrecia  = 250.00,
	@vigencia         = GETDATE();
-- Resultado esperado: OK, Categoría modificada correctamente.
GO

-- ID inexistente
EXEC actividades.ModificarCategoria
	@id_categoria     = 99999,
	@nombre_categoria = 'X',
	@costo_membrecia  = 10.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, Categoría no encontrada.
GO

-- Nombre vacío
EXEC actividades.ModificarCategoria
	@id_categoria     = 1,
	@nombre_categoria = '',
	@costo_membrecia  = 150.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, El nombre de la categoría es obligatorio.
GO

-- Costo inválido
EXEC actividades.ModificarCategoria
	@id_categoria     = 1,
	@nombre_categoria = 'Valido',
	@costo_membrecia  = 0.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, El costo de membresía debe ser mayor a 0.
GO

-- Vigencia nula
EXEC actividades.ModificarCategoria
	@id_categoria     = 1,
	@nombre_categoria = 'Valido2',
	@costo_membrecia  = 120.00,
	@vigencia         = NULL;
-- Resultado esperado: Error, La fecha de vigencia es obligatoria.
GO

-- Nombre duplicado en otro registro
EXEC actividades.ModificarCategoria
	@id_categoria     = 1,
	@nombre_categoria = 'PremiumMod',
	@costo_membrecia  = 150.00,
	@vigencia         = GETDATE();
-- Resultado esperado: Error, Ya existe otra categoría con ese nombre.
GO


-- EliminarCategoria

-- Caso normal 1
EXEC actividades.EliminarCategoria
	@id_categoria = 1;
-- Resultado esperado: OK, Categoría eliminada correctamente.
GO

-- Caso normal 2
EXEC actividades.EliminarCategoria
	@id_categoria = 2;
-- Resultado esperado: OK, Categoría eliminada correctamente.
GO

-- ID inexistente
EXEC actividades.EliminarCategoria
	@id_categoria = 99999;
-- Resultado esperado: Error, Categoría no encontrada.
GO

-- Intentar eliminar nuevamente
EXEC actividades.EliminarCategoria
	@id_categoria = 1;
-- Resultado esperado: Error, Categoría no encontrada.
GO

ROLLBACK TRAN TestCategoria;
GO
