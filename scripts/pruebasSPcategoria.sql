/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

		Luego de decidirse por un motor de base de datos relacional, llegó el momento de generar la
	base de datos. En esta oportunidad utilizarán SQL Server.
	Deberá instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicación de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregaría al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar
	un archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es
	entregado en una sola ejecución). Incluya comentarios para indicar qué hace cada módulo
	de código.
	Genere store procedures para manejar la inserción, modificado, borrado (si corresponde,
	también debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con “SP”.
	Algunas operaciones implicarán store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Asegúrense de que los comentarios que acompañen al código lo expliquen.
	Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto
	en la creación de objetos. NO use el esquema “dbo”.
	Todos los SP creados deben estar acompañados de juegos de prueba. Se espera que
	realicen validaciones básicas en los SP (p/e cantidad mayor a cero, CUIT válido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicación de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la sección de prácticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
*/

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

