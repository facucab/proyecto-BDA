/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Clase
*/

USE Com5600G01;
GO

-- Creacion

-- Caso normal 1
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia         = 'LUNES', 
    @horario     = '08:00:00', 
    @id_usuario  = 1;
-- Resultado esperado: Exito, Clase creada correctamente

-- Caso normal 2
EXEC manejo_actividades.CrearClase 
    @id_actividad = 2, 
    @id_categoria = 2, 
    @dia         = 'MIERCOLES', 
    @horario     = '18:30:00', 
    @id_usuario  = 2;
-- Resultado esperado: Exito, Clase creada correctamente

-- Actividad inexistente
EXEC manejo_actividades.CrearClase 
    @id_actividad = 99999, 
    @id_categoria = 1, 
    @dia         = 'LUNES', 
    @horario     = '08:00:00', 
    @id_usuario  = 1;
-- Resultado esperado: Error, La actividad no existe

-- Categoría inexistente o inactiva
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 99999, 
    @dia         = 'LUNES', 
    @horario     = '08:00:00', 
    @id_usuario  = 1;
-- Resultado esperado: Error, La categoría no existe o está inactiva

-- Usuario inexistente
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia         = 'LUNES', 
    @horario     = '08:00:00', 
    @id_usuario  = 99999;
-- Resultado esperado: Error, El usuario no existe

-- Día inválido
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia         = 'LUUNES', 
    @horario     = '08:00:00', 
    @id_usuario  = 1;
-- Resultado esperado: Error, Día inválido

-- Horario inválido (antes de 06:00)
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia         = 'MARTES', 
    @horario     = '05:59:59', 
    @id_usuario  = 1;
-- Resultado esperado: Error, Horario inválido

-- Horario inválido (22:00 o más)
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia         = 'MARTES', 
    @horario     = '22:00:00', 
    @id_usuario  = 1;
-- Resultado esperado: Error, Horario inválido

-- Conflicto exacto
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia         = 'LUNES', 
    @horario     = '08:00:00', 
    @id_usuario  = 1;
-- Resultado esperado: Error, Ya existe una clase activa con la misma actividad, categoría, día y horario

-- Conflicto profesor
EXEC manejo_actividades.CrearClase 
    @id_actividad = 1, 
    @id_categoria = 2, 
    @dia         = 'MIERCOLES', 
    @horario     = '18:30:00', 
    @id_usuario  = 2;
-- Resultado esperado: Error, El profesor ya tiene otra clase activa en ese día y horario


-- Modificar Clase

-- Caso normal: cambiar día
EXEC manejo_actividades.ModificarClase 
    @id_clase = 1, 
    @dia      = 'VIERNES';
-- Resultado esperado: Exito, Clase modificada correctamente

-- Caso normal: cambiar horario
EXEC manejo_actividades.ModificarClase 
    @id_clase = 2, 
    @horario  = '19:00:00';
-- Resultado esperado: Exito, Clase modificada correctamente

-- Caso normal: cambiar profesor y actividad
EXEC manejo_actividades.ModificarClase 
    @id_clase     = 1, 
    @id_usuario   = 3, 
    @id_actividad = 2;
-- Resultado esperado: Exito, Clase modificada correctamente

-- Clase nula (no existe)
EXEC manejo_actividades.ModificarClase 
    @id_clase = NULL, 
    @dia      = 'JUEVES';
-- Resultado esperado: Error, La clase no existe o está inactiva

-- Clase inexistente
EXEC manejo_actividades.ModificarClase 
    @id_clase = 99999, 
    @dia      = 'JUEVES';
-- Resultado esperado: Error, La clase no existe o está inactiva

-- Actividad inexistente
EXEC manejo_actividades.ModificarClase 
    @id_clase     = 1, 
    @id_actividad = 99999;
-- Resultado esperado: Error, La actividad no existe

-- Categoría inexistente
EXEC manejo_actividades.ModificarClase 
    @id_clase     = 1, 
    @id_categoria = 99999;
-- Resultado esperado: Error, La categoría no existe o está inactiva

-- Usuario inexistente
EXEC manejo_actividades.ModificarClase 
    @id_clase   = 1, 
    @id_usuario = 99999;
-- Resultado esperado: Error, El usuario no existe

-- Día inválido
EXEC manejo_actividades.ModificarClase 
    @id_clase = 1, 
    @dia      = 'DIA';
-- Resultado esperado: Error, Día inválido

-- Horario inválido
EXEC manejo_actividades.ModificarClase 
    @id_clase = 1, 
    @horario  = '23:00:00';
-- Resultado esperado: Error, Horario inválido

-- Conflicto exacto
EXEC manejo_actividades.ModificarClase 
    @id_clase     = 2, 
    @id_actividad = 1, 
    @id_categoria = 1, 
    @dia          = 'LUNES', 
    @horario      = '08:00:00';
-- Resultado esperado: Error, Ya existe otra clase activa con la misma combinación

-- Conflicto profesor
EXEC manejo_actividades.ModificarClase 
    @id_clase   = 1, 
    @id_usuario = 2, 
    @dia        = 'MIERCOLES', 
    @horario    = '18:30:00';
-- Resultado esperado: Error, El profesor ya tiene otra clase activa en ese día y horario


-- EliminarClase

-- Caso normal 1
EXEC manejo_actividades.EliminarClase @id_clase = 1;
-- Resultado esperado: Exito, Clase inactivada correctamente

-- Caso normal 2
EXEC manejo_actividades.EliminarClase @id_clase = 2;
-- Resultado esperado: Exito, Clase inactivada correctamente

-- Clase nula (no existe o inactiva)
EXEC manejo_actividades.EliminarClase @id_clase = NULL;
-- Resultado esperado: Error, La clase no existe o ya está inactiva

-- Clase inexistente
EXEC manejo_actividades.EliminarClase @id_clase = 99999;
-- Resultado esperado: Error, La clase no existe o ya está inactiva

-- Intentar eliminar ya inactiva
EXEC manejo_actividades.EliminarClase @id_clase = 1;
-- Resultado esperado: Error, La clase no existe o ya está inactiva
