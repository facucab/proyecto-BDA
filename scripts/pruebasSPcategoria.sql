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

USE Com5600G01
GO

--creacion

--Caso normal
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Menor', @costo_membrecia = 1500.00,@edad_maxima = 12;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Cadete', @costo_membrecia = 2000.00,@edad_maxima = 17;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Mayor', @costo_membrecia = 2500.00,@edad_maxima = 50;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Veterano', @costo_membrecia = 2000.00,@edad_maxima = 70;
-- Resultado: Categoria crada correctamente

--Nombre vacio
EXEC manejo_actividades.CrearCategoria @nombre_categoria = '', @costo_membrecia = 900.00,@edad_maxima = 40;--Resultado: El nombre de la categora no puede estar vaco

-- costo de membresia menor o igual a 0
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Adulto Joven', @costo_membrecia = -900.00,@edad_maxima = 40;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Jubilado', @costo_membrecia = 0,@edad_maxima = 40;
-- Resultado: El costo de membresa debe ser mayor a cero

-- Edad menor o igual a 0
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Bebe', @costo_membrecia = 900.00,@edad_maxima = 0;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Bebe', @costo_membrecia = 900.00,@edad_maxima = -5;
-- Resultado: La edad maxima debe estar entre 1 y 120 años

-- Edad mayor a 120
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Super Centenario', @costo_membrecia = 900.00,@edad_maxima = 150;
-- Resultado: La edad maxima debe estar entre 1 y 120 años

-- Nombre duplicado (considerando normalización a mayúsculas)
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'menor', @costo_membrecia = 1800.00,@edad_maxima = 13;-- Resultado: Ya existe una categora con ese nombre

-- Solapamiento de edades - edad mxima dentro del rango existente
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Pre-adolescente', @costo_membrecia = 1800.00, @edad_maxima = 14;
-- Resultado: El rango de edad se solapa con otra categoria existente

-- Hueco en rangos - intentar crear 30-40 cuando tenemos hasta 25
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Adulto', @costo_membrecia = 3000.00, @edad_maxima = 40;
-- Resultado: Hay un hueco en el rango de edades entre esta categoria y la siguiente

--Modificacion

--Caso normal
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Adolecente',
	@costo_membrecia = 1900.00;
-- Resultado: Categoria modificada correctamente

-- Id inexistente
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 99999,
	@nombre_categoria = 'adulto',
	@costo_membrecia = 1900.00;
--Resultado: La categoria no existe

--Nombre vacio
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = '',
	@costo_membrecia = 1400.00;
--Resultado: El nombre de la categoria no puede estar vacio

--Costo menor o igual a 0
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Adulto',
	@costo_membrecia = 0;
-- Resultado: El costo de membresa debe ser mayor a cero

--Nombre ya usado (considerando normalización a mayúsculas)
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'cadete',
	@costo_membrecia = 1000.00;
--Resultado: Ya existe otra categora con ese nombre

--Eliminacion

--Caso normal
EXEC manejo_actividades.EliminarCategoria @id_categoria = 4;
-- Resultado: Categoria eliminada correctamente

-- Id inexistente
EXEC manejo_actividades.EliminarCategoria @id_categoria = 99999;
--Resultado: La categoria no existe

-- Intentar eliminar categoría ya eliminada
EXEC manejo_actividades.EliminarCategoria @id_categoria = 4;
--Resultado: La categoria no existe

-- Intentar eliminar categoría con socios asignados (asumiendo que hay socios en categoría 1)
-- EXEC manejo_actividades.EliminarCategoria @id_categoria = 1;
--Resultado: No se puede eliminar la categoría porque hay socios asignados a ella

