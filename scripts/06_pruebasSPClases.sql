/*
	Entrega 4 - Documento de instalacion y configuracion

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Ruben 
	45234709 | Gauto, Gaston Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomas Andres

	Pruebas para Crear, Modificar y Eliminar Clase
*/

USE Com5600G01;
GO

-- Busqueda de IDs validos
DECLARE @id_actividad1 INT, @id_actividad2 INT;
DECLARE @id_categoria1 INT, @id_categoria2 INT;
DECLARE @id_usuario1 INT, @id_usuario2 INT, @id_usuario3 INT;

-- Buscar dos actividades distintas activas
SELECT TOP 1 @id_actividad1 = id_actividad FROM actividades.actividad WHERE estado = 1;
SELECT TOP 1 @id_actividad2 = id_actividad FROM actividades.actividad WHERE estado = 1 AND id_actividad <> @id_actividad1;

-- Buscar dos categorías distintas
SELECT TOP 1 @id_categoria1 = id_categoria FROM actividades.categoria;
SELECT TOP 1 @id_categoria2 = id_categoria FROM actividades.categoria WHERE id_categoria <> @id_categoria1;

-- Buscar tres usuarios distintos activos
SELECT TOP 1 @id_usuario1 = id_usuario FROM usuarios.usuario WHERE estado = 1;
SELECT TOP 1 @id_usuario2 = id_usuario FROM usuarios.usuario WHERE estado = 1 AND id_usuario <> @id_usuario1;
SELECT TOP 1 @id_usuario3 = id_usuario FROM usuarios.usuario WHERE estado = 1 AND id_usuario NOT IN (@id_usuario1, @id_usuario2);

-- CrearClase

-- Caso normal 1
EXEC actividades.CrearClase 
	@id_actividad = @id_actividad1, 
	@id_categoria = @id_categoria1, 
	@dia         = 'lunes', 
	@horario     = '08:00:00', 
	@id_usuario  = @id_usuario1;
-- Resultado esperado: OK, Clase creada correctamente.

-- Caso normal 2
EXEC actividades.CrearClase 
	@id_actividad = @id_actividad2, 
	@id_categoria = @id_categoria2, 
	@dia         = 'MIERCOLES', 
	@horario     = '18:30:00', 
	@id_usuario  = @id_usuario1;
-- Resultado esperado: OK, Clase creada correctamente.

-- Actividad inexistente
EXEC actividades.CrearClase 
	@id_actividad = 99999, 
	@id_categoria = 1, 
	@dia         = 'LUNES', 
	@horario     = '08:00:00', 
	@id_usuario  = 1;
-- Resultado esperado: Error, La actividad no existe.

-- Categoria inexistente
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 99999, 
	@dia         = 'LUNES', 
	@horario     = '08:00:00', 
	@id_usuario  = 1;
-- Resultado esperado: Error, La categoria no existe.

-- Usuario inexistente
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 1, 
	@dia         = 'LUNES', 
	@horario     = '08:00:00', 
	@id_usuario  = 99999;
-- Resultado esperado: Error, El usuario no existe.

-- Dia invalido
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 1, 
	@dia         = 'LUUNES', 
	@horario     = '08:00:00', 
	@id_usuario  = 1;
-- Resultado esperado: Error, Dia invalido.

-- Horario invalido (antes de 06:00)
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 1, 
	@dia         = 'MARTES', 
	@horario     = '05:59:59', 
	@id_usuario  = 1;
-- Resultado esperado: Error, Horario invalido.

-- Horario invalido (22:00 o mas)
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 1, 
	@dia         = 'MARTES', 
	@horario     = '22:00:00', 
	@id_usuario  = 1;
-- Resultado esperado: Error, Horario invalido.

-- Conflicto exacto
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 1, 
	@dia         = 'LUNES', 
	@horario     = '08:00:00', 
	@id_usuario  = 1;
-- Resultado esperado: Error, Ya existe una clase activa con la misma actividad, categoria, dia y horario.

-- Conflicto profesor
EXEC actividades.CrearClase 
	@id_actividad = 1, 
	@id_categoria = 2, 
	@dia         = 'MIERCOLES', 
	@horario     = '18:30:00', 
	@id_usuario  = 2;
-- Resultado esperado: Error, El profesor ya tiene otra clase activa en ese dia y horario.


-- ModificarClase

-- Caso normal: cambiar dia
EXEC actividades.ModificarClase 
	@id_clase = 1, 
	@dia      = 'VIERNES';
-- Resultado esperado: OK, Clase modificada correctamente.

-- Caso normal: cambiar horario
EXEC actividades.ModificarClase 
	@id_clase = 2, 
	@horario  = '19:00:00';
-- Resultado esperado: OK, Clase modificada correctamente.

-- Caso normal: cambiar profesor y actividad
EXEC actividades.ModificarClase 
	@id_clase     = 1, 
	@id_usuario   = 3, 
	@id_actividad = 2;
-- Resultado esperado: OK, Clase modificada correctamente.

-- Clase nula
EXEC actividades.ModificarClase 
	@id_clase = NULL, 
	@dia      = 'JUEVES';
-- Resultado esperado: Error, La clase no existe o esta inactiva.

-- Clase inexistente
EXEC actividades.ModificarClase 
	@id_clase = 99999, 
	@dia      = 'JUEVES';
-- Resultado esperado: Error, La clase no existe o esta inactiva.

-- Actividad inexistente
EXEC actividades.ModificarClase 
	@id_clase     = 1, 
	@id_actividad = 99999;
-- Resultado esperado: Error, La actividad no existe.

-- Categoria inexistente
EXEC actividades.ModificarClase 
	@id_clase     = 1, 
	@id_categoria = 99999;
-- Resultado esperado: Error, La categoria no existe.

-- Usuario inexistente
EXEC actividades.ModificarClase 
	@id_clase   = 1, 
	@id_usuario = 99999;
-- Resultado esperado: Error, El usuario no existe.

-- Dia invalido
EXEC actividades.ModificarClase 
	@id_clase = 1, 
	@dia      = 'DIA';
-- Resultado esperado: Error, Dia invalido.

-- Horario invalido
EXEC actividades.ModificarClase 
	@id_clase = 1, 
	@horario  = '23:00:00';
-- Resultado esperado: Error, Horario invalido.

-- Conflicto exacto
EXEC actividades.ModificarClase 
	@id_clase     = 2, 
	@id_actividad = 1, 
	@id_categoria = 1, 
	@dia          = 'LUNES', 
	@horario      = '08:00:00';
-- Resultado esperado: Error, Ya existe otra clase activa con la misma combinacion.

-- Conflicto profesor
EXEC actividades.ModificarClase 
	@id_clase   = 1, 
	@id_usuario = 2, 
	@dia        = 'MIERCOLES', 
	@horario    = '18:30:00';
-- Resultado esperado: Error, El profesor ya tiene otra clase activa en ese dia y horario.


-- EliminarClase

-- Caso normal 1
EXEC actividades.EliminarClase 
	@id_clase = 1;
-- Resultado esperado: OK, Clase inactivada correctamente.

-- Caso normal 2
EXEC actividades.EliminarClase 
	@id_clase = 2;
-- Resultado esperado: OK, Clase inactivada correctamente.

-- Clase nula
EXEC actividades.EliminarClase 
	@id_clase = NULL;
-- Resultado esperado: Error, La clase no existe o ya esta inactiva.

-- Clase inexistente
EXEC actividades.EliminarClase 
	@id_clase = 99999;
-- Resultado esperado: Error, La clase no existe o ya esta inactiva.

-- Intentar eliminar ya inactiva
EXEC actividades.EliminarClase 
	@id_clase = 1;
-- Resultado esperado: Error, La clase no existe o ya esta inactiva.

SELECT *
FROM actividades.clase
GO