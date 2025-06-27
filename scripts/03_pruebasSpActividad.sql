/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Actividad
*/

USE Com5600G01;
GO

--  Crear Actividad

-- Caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'Futbol', @costo_mensual = 2000.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'Tenis', @costo_mensual = 2500.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'Voley', @costo_mensual = 1800.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'Remo', @costo_mensual = 1800.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'Rugby', @costo_mensual = 1800.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'Basket', @costo_mensual = 1800.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC actividades.CrearActividad @nombre_actividad = 'FULBO', @costo_mensual = 1800.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Nombre vacío
EXEC actividades.CrearActividad @nombre_actividad = '', @costo_mensual = 9500.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo

-- Nombre nulo
EXEC actividades.CrearActividad @nombre_actividad = NULL, @costo_mensual = 9500.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo

-- Nombre repetido
EXEC actividades.CrearActividad @nombre_actividad = 'Futbol', @costo_mensual = 3000.00;
-- Resultado esperado: Error, Ya existe una actividad con ese nombre

-- Costo menor o igual a 0
EXEC actividades.CrearActividad @nombre_actividad = 'Golf', @costo_mensual = 0;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

EXEC actividades.CrearActividad @nombre_actividad = 'Padel', @costo_mensual = -100;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

-- Modificar Actividad

-- Caso normal: modificar nombre y costo
EXEC actividades.ModificarActividad @id = 1, @nombre_actividad = 'Futbol 5', @costo_mensual = 2100.00;
-- Resultado esperado: Exito, Actividad modificada correctamente

-- Caso normal: solo cambiar costo
EXEC actividades.ModificarActividad @id = 2, @nombre_actividad = 'Tenis', @costo_mensual = 2600.00;
-- Resultado esperado: Exito, Actividad modificada correctamente

-- ID nulo
EXEC actividades.ModificarActividad @id = NULL, @nombre_actividad = 'Ciclismo', @costo_mensual = 4200.00;
-- Resultado esperado: Error, id nulo

-- ID inexistente
EXEC actividades.ModificarActividad @id = 99999, @nombre_actividad = 'Handball', @costo_mensual = 4200.00;
-- Resultado esperado: Error, id no existente

-- Nombre vacío
EXEC actividades.ModificarActividad @id = 2, @nombre_actividad = '', @costo_mensual = 1200.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo o vacio

-- Nombre nulo
EXEC actividades.ModificarActividad @id = 2, @nombre_actividad = NULL, @costo_mensual = 1200.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo o vacio

-- Nombre ya usado por otra actividad
EXEC actividades.ModificarActividad @id = 2, @nombre_actividad = 'Voley', @costo_mensual = 1200.00;
-- Resultado esperado: Error, Ya existe una actividad con ese nombre

-- Costo menor o igual a 0
EXEC actividades.ModificarActividad @id = 1, @nombre_actividad = 'Natacion', @costo_mensual = 0;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

EXEC actividades.ModificarActividad @id = 1, @nombre_actividad = 'Natacion', @costo_mensual = -100;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

-- Eliminar Actividad

-- Caso normal: eliminar actividad activa
EXEC actividades.EliminarActividad @id = 7;
-- Resultado esperado: Exito, Actividad eliminada lógicamente correctamente

-- Caso normal: eliminar otra actividad activa
EXEC actividades.EliminarActividad @id = 6;
-- Resultado esperado: Exito, Actividad eliminada lógicamente correctamente

-- ID nulo
EXEC actividades.EliminarActividad @id = NULL;
-- Resultado esperado: Error, id nulo

-- ID inexistente o ya eliminada
EXEC actividades.EliminarActividad @id = 99999;
-- Resultado esperado: Error, id no existente o ya eliminada

-- ID de actividad ya eliminada
EXEC actividades.EliminarActividad @id = 7;
-- Resultado esperado: Error, id no existente o ya eliminada

SELECT *
FROM actividades.actividad
GO