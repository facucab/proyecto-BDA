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

-- Caso normal
EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Lunes',
	@horario = '10:00:00',
	@id_usuario = 1;

EXEC manejo_actividades.CrearClase 
	@id_actividad = 2,
	@id_categoria = 2,
	@dia = 'MARTES',
	@horario = '14:30:00',
	@id_usuario = 2;

EXEC manejo_actividades.CrearClase 
	@id_actividad = 3,
	@id_categoria = 1,
	@dia = 'miercoles',
	@horario = '18:00:00',
	@id_usuario = 3;
-- Resultado: Clase creada correctamente

-- Actividad inexistente
EXEC manejo_actividades.CrearClase 
	@id_actividad = 99999,
	@id_categoria = 1,
	@dia = 'Jueves',
	@horario = '16:00:00',
	@id_usuario = 1;
-- Resultado: La actividad no existe

-- Categoría inexistente
EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 99999,
	@dia = 'Viernes',
	@horario = '12:00:00',
	@id_usuario = 1;
-- Resultado: La categoría no existe

-- Usuario inexistente
EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Sabado',
	@horario = '08:00:00',
	@id_usuario = 99999;
-- Resultado: El usuario no existe

-- Día inválido
EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Lunnes',
	@horario = '15:00:00',
	@id_usuario = 1;

EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Monday',
	@horario = '15:00:00',
	@id_usuario = 1;
-- Resultado: El dia debe ser un dia de la semana valido

-- Horario antes de las 6:00 AM
EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Domingo',
	@horario = '05:30:00',
	@id_usuario = 1;

EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Domingo',
	@horario = '22:30:00',
	@id_usuario = 1;
-- Resultado: El horario debe ser entre 06 am y 22 pm

-- Clase duplicada (misma actividad, categoría, día y horario)
EXEC manejo_actividades.CrearClase 
	@id_actividad = 1,
	@id_categoria = 1,
	@dia = 'Lunes',
	@horario = '10:00:00',
	@id_usuario = 2;
-- Resultado: Ya existe una clase con la misma actividad, categoría, día y horario

-- Profesor ya ocupado en ese día y horario
EXEC manejo_actividades.CrearClase 
	@id_actividad = 6,
	@id_categoria = 3,
	@dia = 'Lunes',
	@horario = '10:00:00',
	@id_usuario = 1;
-- Resultado: El profesor ya tiene otra clase asignada en ese dia y horario

--Modificacion

-- Caso normal
EXEC manejo_actividades.ModificarClase
    @id_clase =1, 
	@id_actividad =2,
	@id_categoria = 1,
	@dia = 'Viernes',
	@horario = '19:00:00',
	@id_usuario = 1;

EXEC manejo_actividades.ModificarClase
    @id_clase =4, 
	@id_actividad = 2,
	@id_categoria = 1,
	@dia = 'Jueves',
	@horario = '11:30:00',
	@id_usuario = 2;

EXEC manejo_actividades.ModificarClase
    @id_clase =2, 
	@id_actividad = 5,
	@id_categoria = 1,
	@dia = 'miercoles',
	@horario = '18:00:00',
	@id_usuario = 9;
-- Resultado: Clase modificada correctamente

-- clase inexistente
EXEC manejo_actividades.ModificarClase
    @id_clase =9999999, 
	@id_actividad = 3,
	@id_categoria = 1,
	@dia = 'Martes',
	@horario = '16:30:00',
	@id_usuario = 12;
-- Resultado: La clase no existe

-- Actividad inexistente
EXEC manejo_actividades.ModificarClase
    @id_clase =1, 
	@id_actividad = 99999,
	@id_categoria = 1,
	@dia = 'Sabado',
	@horario = '16:00:00',
	@id_usuario = 1;
-- Resultado: La actividad no existe

-- Categoría inexistente
EXEC manejo_actividades.ModificarClase
    @id_clase =5, 
	@id_actividad = 11,
	@id_categoria = 99999,
	@dia = 'Domingo',
	@horario = '17:20:00',
	@id_usuario = 4;
-- Resultado: La categoría no existe

-- Usuario inexistente
EXEC manejo_actividades.ModificarClase
    @id_clase =6, 
	@id_actividad = 11,
	@id_categoria = 3,
	@dia = 'Martes',
	@horario = '08:00:00',
	@id_usuario = 99999;
-- Resultado: El usuario no existe

-- Día inválido
EXEC manejo_actividades.ModificarClase
    @id_clase =1, 
	@id_actividad = 10,
	@id_categoria = 4,
	@dia = 'Lunnes',
	@horario = '15:00:00',
	@id_usuario = 1;
-- Resultado: El dia debe ser un dia de la semana valido

-- Horario invalido
EXEC  manejo_actividades.ModificarClase
    @id_clase =5, 
	@id_actividad = 3,
	@id_categoria = 2,
	@dia = 'Domingo',
	@horario = '05:30:00',
	@id_usuario = 1;
-- Resultado: El horario debe ser entre 06 am y 22 pm

-- Clase duplicada 
EXEC  manejo_actividades.ModificarClase
    @id_clase =6,
	@id_actividad = 3,
	@id_categoria = 1,
	@dia = 'Lunes',
	@horario = '10:00:00',
	@id_usuario = 2;
-- Resultado: Ya existe una clase con la misma actividad, categoría, día y horario

-- Profesor ya ocupado en ese día y horario
EXEC  manejo_actividades.ModificarClase
    @id_clase =1,
	@id_actividad = 3,
	@id_categoria = 3,
	@dia = 'Lunes',
	@horario = '10:00:00',
	@id_usuario = 1;
-- Resultado: El profesor ya tiene otra clase asignada en ese dia y horario

--Eliminacion

--Casos Normales
EXEC manejo_actividades.EliminarClase @id_clase =1;
EXEC manejo_actividades.EliminarClase @id_clase =9;
EXEC manejo_actividades.EliminarClase @id_clase =7;
--Respuestas: Clase inactivada correctamente

--Id inexistente o ya eliminada
EXEC manejo_actividades.EliminarClase @id_clase =11;
--Respuestas: La clase no existe o ya está inactiva

--Clase solicitada
EXEC manejo_actividades.EliminarClase @id_clase =5;
--Respuestas: No se puede eliminar la clase porque hay socios inscritos en esta actividad y categoría