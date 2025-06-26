-- Pruebas para manejo_actividades.CrearActividad, ModificarActividad y EliminarActividad

USE Com5600G01;
GO

--  Crear Actividad

-- Caso normal
EXEC manejo_actividades.CrearActividad @nombre_actividad = 'Futbol', @costo_mensual = 2000.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC manejo_actividades.CrearActividad @nombre_actividad = 'Tenis', @costo_mensual = 2500.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Otro caso normal
EXEC manejo_actividades.CrearActividad @nombre_actividad = 'Voley', @costo_mensual = 1800.00;
-- Resultado esperado: Exito, Actividad creada correctamente

-- Nombre vacío
EXEC manejo_actividades.CrearActividad @nombre_actividad = '', @costo_mensual = 9500.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo

-- Nombre nulo
EXEC manejo_actividades.CrearActividad @nombre_actividad = NULL, @costo_mensual = 9500.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo

-- Nombre repetido
EXEC manejo_actividades.CrearActividad @nombre_actividad = 'Futbol', @costo_mensual = 3000.00;
-- Resultado esperado: Error, Ya existe una actividad con ese nombre

-- Costo menor o igual a 0
EXEC manejo_actividades.CrearActividad @nombre_actividad = 'Golf', @costo_mensual = 0;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

EXEC manejo_actividades.CrearActividad @nombre_actividad = 'Padel', @costo_mensual = -100;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

-- Modificar Actividad

-- Caso normal: modificar nombre y costo
EXEC manejo_actividades.ModificarActividad @id = 1, @nombre_actividad = 'Futbol 5', @costo_mensual = 2100.00;
-- Resultado esperado: Exito, Actividad modificada correctamente

-- Caso normal: solo cambiar costo
EXEC manejo_actividades.ModificarActividad @id = 2, @nombre_actividad = 'Tenis', @costo_mensual = 2600.00;
-- Resultado esperado: Exito, Actividad modificada correctamente

-- ID nulo
EXEC manejo_actividades.ModificarActividad @id = NULL, @nombre_actividad = 'Ciclismo', @costo_mensual = 4200.00;
-- Resultado esperado: Error, id nulo

-- ID inexistente
EXEC manejo_actividades.ModificarActividad @id = 99999, @nombre_actividad = 'Handball', @costo_mensual = 4200.00;
-- Resultado esperado: Error, id no existente

-- Nombre vacío
EXEC manejo_actividades.ModificarActividad @id = 2, @nombre_actividad = '', @costo_mensual = 1200.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo o vacio

-- Nombre nulo
EXEC manejo_actividades.ModificarActividad @id = 2, @nombre_actividad = NULL, @costo_mensual = 1200.00;
-- Resultado esperado: Error, El nombre de actividad no puede ser nulo o vacio

-- Nombre ya usado por otra actividad
EXEC manejo_actividades.ModificarActividad @id = 2, @nombre_actividad = 'Voley', @costo_mensual = 1200.00;
-- Resultado esperado: Error, Ya existe una actividad con ese nombre

-- Costo menor o igual a 0
EXEC manejo_actividades.ModificarActividad @id = 1, @nombre_actividad = 'Natacion', @costo_mensual = 0;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

EXEC manejo_actividades.ModificarActividad @id = 1, @nombre_actividad = 'Natacion', @costo_mensual = -100;
-- Resultado esperado: Error, El costo mensual debe ser mayor a cero

-- Eliminar Actividad

-- Caso normal: eliminar actividad activa
EXEC manejo_actividades.EliminarActividad @id = 1;
-- Resultado esperado: Exito, Actividad eliminada lógicamente correctamente

-- Caso normal: eliminar otra actividad activa
EXEC manejo_actividades.EliminarActividad @id = 2;
-- Resultado esperado: Exito, Actividad eliminada lógicamente correctamente

-- ID nulo
EXEC manejo_actividades.EliminarActividad @id = NULL;
-- Resultado esperado: Error, id nulo

-- ID inexistente o ya eliminada
EXEC manejo_actividades.EliminarActividad @id = 99999;
-- Resultado esperado: Error, id no existente o ya eliminada

-- ID de actividad ya eliminada
EXEC manejo_actividades.EliminarActividad @id = 1;
-- Resultado esperado: Error, id no existente o ya eliminada