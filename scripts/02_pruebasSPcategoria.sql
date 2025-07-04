/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Categoria
*/
-- [FUNCIONANDO]
USE Com5600G01
GO

--Caso normal
EXEC actividades.CrearCategoria @nombre_categoria = 'Menor', @costo_membrecia = 1500.00, @vigencia = '2024-06-01';
EXEC actividades.CrearCategoria @nombre_categoria = 'Cadete', @costo_membrecia = 2000.00, @vigencia = '2024-06-01';
EXEC actividades.CrearCategoria @nombre_categoria = 'Mayor', @costo_membrecia = 2500.00, @vigencia = '2024-06-01';
EXEC actividades.CrearCategoria @nombre_categoria = 'Veterano', @costo_membrecia = 2000.00, @vigencia = '2024-06-01';
-- Resultado: Categoria creada correctamente

--Nombre vacio
EXEC actividades.CrearCategoria @nombre_categoria = '', @costo_membrecia = 900.00, @vigencia = '2024-06-01'; --Resultado: El nombre de la categoria es obligatorio

-- costo de membresia menor o igual a 0
EXEC actividades.CrearCategoria @nombre_categoria = 'Adulto Joven', @costo_membrecia = -900.00, @vigencia = '2024-06-01';
EXEC actividades.CrearCategoria @nombre_categoria = 'Jubilado', @costo_membrecia = 0, @vigencia = '2024-06-01';
-- Resultado: El costo de membresía debe ser mayor a cero

-- Vigencia nula
EXEC actividades.CrearCategoria @nombre_categoria = 'Bebe', @costo_membrecia = 900.00, @vigencia = NULL;
-- Resultado: La fecha de vigencia es obligatoria

-- Nombre duplicado (considerando normalización a mayúsculas)
EXEC actividades.CrearCategoria @nombre_categoria = 'menor', @costo_membrecia = 1800.00, @vigencia = '2024-06-01';-- Resultado: Ya existe una categoria con ese nombre

-- Solapamiento de edades - edad mxima dentro del rango existente
EXEC actividades.CrearCategoria @nombre_categoria = 'Pre-adolescente', @costo_membrecia = 1800.00, @vigencia = '2024-06-01';
-- Resultado: El rango de edad se solapa con otra categoria existente

-- Hueco en rangos - intentar crear 30-40 cuando tenemos hasta 25
EXEC actividades.CrearCategoria @nombre_categoria = 'Adulto', @costo_membrecia = 3000.00, @vigencia = '2024-06-01';
-- Resultado: Hay un hueco en el rango de edades entre esta categoria y la siguiente

--Modificacion

--Caso normal
EXEC actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Adolecente',
	@costo_membrecia = 1900.00,
	@vigencia = '2024-06-01';
-- Resultado: Categoria modificada correctamente

-- Id inexistente
EXEC actividades.ModificarCategoria 
	@id_categoria = 99999,
	@nombre_categoria = 'adulto',
	@costo_membrecia = 1900.00,
	@vigencia = '2024-06-01';
--Resultado: La categoria no existe

--Nombre vacio
EXEC actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = '',
	@costo_membrecia = 1400.00,
	@vigencia = '2024-06-01';
--Resultado: El nombre de la categoria es obligatorio

--Costo menor o igual a 0
EXEC actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Adulto',
	@costo_membrecia = 0,
	@vigencia = '2024-06-01';
-- Resultado: El costo de membresía debe ser mayor a cero

--Nombre ya usado (considerando normalización a mayúsculas)
EXEC actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'cadete',
	@costo_membrecia = 1000.00,
	@vigencia = '2024-06-01';
--Resultado: Ya existe otra categoria con ese nombre

--Eliminacion

--Caso normal
EXEC actividades.EliminarCategoria @id_categoria = 5;
-- Resultado: Categoria eliminada correctamente

-- Id inexistente
EXEC actividades.EliminarCategoria @id_categoria = 99999;
--Resultado: La categoria no existe

-- Intentar eliminar categoría ya eliminada (borrado lógico)
EXEC actividades.EliminarCategoria @id_categoria = 4;
--Resultado: La categoria no existe

-- Intentar modificar categoría ya eliminada (borrado lógico)
EXEC actividades.ModificarCategoria 
	@id_categoria = 4,
	@nombre_categoria = 'Eliminada',
	@costo_membrecia = 1000.00,
	@vigencia = '2024-06-01';
--Resultado: La categoria no existe

-- Intentar crear una categoría con el mismo nombre de una eliminada lógicamente (debería permitirlo si solo se consideran activas)
EXEC actividades.CrearCategoria @nombre_categoria = 'Veterano', @costo_membrecia = 2100.00, @vigencia = '2024-06-01';
-- Resultado: Categoria creada correctamente (si la anterior fue eliminada lógicamente)

-- Intentar eliminar categoría con socios asignados (asumiendo que hay socios en categoría 1)
-- EXEC actividades.EliminarCategoria @id_categoria = 1;
--Resultado: No se puede eliminar la categoría porque hay socios asignados a ella

-- LIMPIEZA FINAL: Restaurar estado deseado
-- Restablecer la categoría ID 1 a "Menor" (ya que fue modificada a "Adolecente")
EXEC actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Menor',
	@costo_membrecia = 1500.00,
	@vigencia = '2024-06-01';
-- Resultado: Categoria modificada correctamente

-- Eliminar la categoría "Veterano" recreada (si existe y no tiene socios asignados)
-- Nota: Se asume que el ID de la categoría "Veterano" recreada es el siguiente disponible
-- Esto puede variar según la implementación de la base de datos
DECLARE @id_veterano_recreada INT;
SELECT @id_veterano_recreada = id_categoria 
FROM actividades.categoria
WHERE UPPER(nombre_categoria) = 'VETERANO';

IF @id_veterano_recreada IS NOT NULL
BEGIN
    EXEC actividades.EliminarCategoria @id_categoria = @id_veterano_recreada;
END

-- Estado final esperado: Solo deben quedar las categorías "Menor", "Cadete" y "Mayor"
-- Verificación del estado final
SELECT nombre_categoria, costo_membrecia, vigencia 
FROM actividades.categoria 
ORDER BY nombre_categoria;