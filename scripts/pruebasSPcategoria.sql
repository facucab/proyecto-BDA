-- Pruebas categoria

--creacion

--Caso normal
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Menor', @costo_membrecia = 1500.00,@edad_maxima = 12;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Cadete', @costo_membrecia = 2000.00,@edad_maxima = 17;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Mayor', @costo_membrecia = 2500.00,@edad_maxima = 50;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Veterano', @costo_membrecia = 2000.00,@edad_maxima = 70;
-- Resultado: Categoria crada correctamente

--Nombre vacio
EXEC manejo_actividades.CrearCategoria @nombre_categoria = '', @costo_membrecia = 900.00,@edad_maxima = 40;--Resultado: El nombre de la categoría no puede estar vacío

-- costo de membresia menor o igual a 0
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Adulto Joven', @costo_membrecia = -900.00,@edad_maxima = 40;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Jubilado', @costo_membrecia = 0,@edad_maxima = 40;
-- Resultado: El costo de membresía debe ser mayor a cero

-- Edad menor o igual a 0
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Bebe', @costo_membrecia = 900.00,@edad_maxima = 0;
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Bebe', @costo_membrecia = 900.00,@edad_maxima = -5;
-- Resultado: La edad maxima debe ser mayor a cero

-- Nombre duplicado
EXEC manejo_actividades.CrearCategoria @nombre_categoria = 'Menor', @costo_membrecia = 1800.00,@edad_maxima = 13;-- Resultado: Ya existe una categoría con ese nombre

-- Solapamiento de edades - edad máxima dentro del rango existente
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
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@costo_membrecia = 1700.00;
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Niños';
-- Resultado: Categoria modificada correctamente

-- Id inexistente
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 99999,
	@nombre_categoria = 'adulto',
	@costo_membrecia = 1900.00;
--Resultado: 'La categoria no existe

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
-- Resultado: El costo de membresía debe ser mayor a cero

--Nombre ya usado
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Cadete',
	@costo_membrecia = 1000.00;
--Resultado: Ya existe otra categoría con ese nombre

