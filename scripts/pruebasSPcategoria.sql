/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	- Se documenta la instalación y configuración de SQL Server.
	- Se crea base de datos, entidades, relaciones, restricciones y claves.
	- SP para inserción, modificación y borrado.
	- No se usan prefijos "SP".
	- Validaciones en SP y juegos de prueba documentados.
	- Uso de esquemas propios, no dbo.
	- Este script incluye pruebas para SP de categoría.
*/

USE Com5600G01;
GO

-- Pruebas categoria

-- CREACION

-- Caso normal: se agrega parámetro vigencia
EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Menor', 
	@costo_membrecia = 1500.00,
	@vigencia = '2025-01-01';

EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Cadete', 
	@costo_membrecia = 2000.00,
	@vigencia = '2025-01-01';

EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Mayor', 
	@costo_membrecia = 2500.00,
	@vigencia = '2025-01-01';

EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Veterano', 
	@costo_membrecia = 2000.00,
	@vigencia = '2025-01-01';

-- Resultado esperado: Categoria creada correctamente

-- Nombre vacío
EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = '', 
	@costo_membrecia = 900.00,
	@vigencia = '2025-01-01';
-- Resultado esperado: El nombre de la categoría no puede estar vacío

-- Costo membresía menor o igual a 0
EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Adulto Joven', 
	@costo_membrecia = -900.00,
	@vigencia = '2025-01-01';

EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Jubilado', 
	@costo_membrecia = 0,
	@vigencia = '2025-01-01';
-- Resultado esperado: El costo de membresía debe ser mayor a cero

-- Nombre duplicado
EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Menor', 
	@costo_membrecia = 1800.00,
	@vigencia = '2025-01-01';
-- Resultado esperado: Ya existe una categoría con ese nombre

-- Solapamiento de edades
EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Pre-adolescente', 
	@costo_membrecia = 1800.00, 
	@vigencia = '2025-01-01';
-- Resultado esperado: El rango de edad se solapa con otra categoría existente

-- Hueco en rangos
EXEC manejo_actividades.CrearCategoria 
	@nombre_categoria = 'Adulto', 
	@costo_membrecia = 3000.00, 
	@vigencia = '2025-01-01';
-- Resultado esperado: Hay un hueco en el rango de edades entre esta categoría y la siguiente


-- MODIFICACION (asumiendo que ModificarCategoria no cambia vigencia)

-- Caso normal
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
-- Resultado esperado: Categoría modificada correctamente

-- Id inexistente
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 99999,
	@nombre_categoria = 'adulto',
	@costo_membrecia = 1900.00;
-- Resultado esperado: La categoría no existe

-- Nombre vacío
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = '',
	@costo_membrecia = 1400.00;
-- Resultado esperado: El nombre de la categoría no puede estar vacío

-- Costo menor o igual a 0
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Adulto',
	@costo_membrecia = 0;
-- Resultado esperado: El costo de membresía debe ser mayor a cero

-- Nombre ya usado
EXEC manejo_actividades.ModificarCategoria 
	@id_categoria = 1,
	@nombre_categoria = 'Cadete',
	@costo_membrecia = 1000.00;
-- Resultado esperado: Ya existe otra categoría con ese nombre
