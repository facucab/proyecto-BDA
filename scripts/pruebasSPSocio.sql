/*
	Entrega 4 - Documento de instalaci�n y configuraci�n

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rub�n 
	45234709 | Gauto, Gast�n Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tom�s Andr�s

	Pruebas para Crear, Modificar y Eliminar Socio
*/

USE Com5600G01;
GO

-- CrearSocio:

-- Casos normales 
EXEC manejo_personas.CrearSocio
    @id_persona = 1,
    @telefono_emergencia = '11112222',
    @id_categoria = 1; -- Resultado: Socio registrado correctamente

EXEC manejo_personas.CrearSocio
    @id_persona = 2,
    @telefono_emergencia = '22223333',
    @obra_nro_socio = '123456',
    @id_obra_social = 1,
    @id_categoria = 2; -- Resultado: Socio registrado correctamente


EXEC manejo_personas.CrearSocio
    @id_persona = 3,
    @telefono_emergencia = '33334444',
    @id_categoria = 3,
    @id_grupo = 1; -- Resultado: Socio registrado correctamente



-- Persona no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 99999,
    @telefono_emergencia = '44445555',
    @id_categoria = 3; -- Resultado: La persona no existe o est� inactiva

-- Persona inactiva
EXEC manejo_personas.CrearSocio
    @id_persona = 4,
    @telefono_emergencia = '55556666',
    @id_categoria = 3; -- Resultado: La persona no existe o est� inactiva

-- Persona ya es socio
EXEC manejo_personas.CrearSocio
    @id_persona = 1,
    @telefono_emergencia = '66667777',
    @id_categoria = 1; -- Resultado: La persona ya est� registrada como socio

-- Categor�a no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '77778888',
    @id_categoria = 99; -- Resultado: La categor�a especificada no existe

-- Obra social no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '88889999',
    @id_obra_social = 99,
    @id_categoria = 3; -- Resultado: La obra social especificada no existe

-- Grupo familiar no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '99990000',
    @id_grupo = 99,
    @id_categoria = 3; -- Resultado: El grupo familiar especificado no existe o est� inactivo

-- Grupo familiar inactivo
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '00001111',
    @id_grupo = 2,
    @id_categoria = 3; -- Resultado: El grupo familiar especificado no existe o est� inactivo

-- Edad incorrecta para categor�a Menor (demasiado mayor)
EXEC manejo_personas.CrearSocio
    @id_persona = 7,
    @telefono_emergencia = '11110000',
    @id_categoria = 1; -- Resultado: La categor�a Menor es solo para personas hasta 12 a�os

-- Edad incorrecta para categor�a Cadete (demasiado joven)
EXEC manejo_personas.CrearSocio
    @id_persona = 6,
    @telefono_emergencia = '00009999',
    @id_categoria = 2; -- Resultado: La categor�a Cadete es solo para personas entre 13 y 17 a�os

-- Edad incorrecta para categor�a Mayor (demasiado joven)
EXEC manejo_personas.CrearSocio
    @id_persona = 6,
    @telefono_emergencia = '99998888',
    @id_categoria = 3; -- Resultado: La categor�a Mayor es solo para personas a partir de 18 a�os


-- TEST STORED PROCEDURE ModificarSocio:


-- Casos normales
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @telefono_emergencia = '11223344'; -- Resultado: Datos del socio actualizados correctamente

EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_obra_social = 2,
    @obra_nro_socio = '654321'; -- Resultado: Datos del socio actualizados correctamente

EXEC manejo_personas.ModificarSocio
    @id_socio = 2,
    @id_grupo = 1; -- Resultado: Datos del socio actualizados correctamente

EXEC manejo_personas.ModificarSocio
    @id_socio = 3,
    @id_categoria = 3; -- Resultado: Datos del socio actualizados correctamente



-- Socio no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 99999,
    @telefono_emergencia = '99887766'; -- Resultado: El socio no existe

-- Categor�a no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_categoria = 99; -- Resultado: La categor�a especificada no existe

-- Edad incompatible con categor�a Menor
EXEC manejo_personas.ModificarSocio
    @id_socio = 2,
    @id_categoria = 1; -- Resultado: La categor�a Menor es solo para personas hasta 12 a�os

-- Edad incompatible con categor�a Cadete
EXEC manejo_personas.ModificarSocio
    @id_socio = 3,
    @id_categoria = 2; -- Resultado: La categor�a Cadete es solo para personas entre 13 y 17 a�os

-- Edad incompatible con categor�a Mayor
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_categoria = 3; -- Resultado: La categor�a Mayor es solo para personas a partir de 18 a�os

-- Obra social no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_obra_social = 99; -- Resultado: La obra social especificada no existe

-- Grupo familiar no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_grupo = 99; -- Resultado: El grupo familiar especificado no existe o est� inactivo

-- Grupo familiar inactivo
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_grupo = 2; -- Resultado: El grupo familiar especificado no existe o est� inactivo


-- TEST STORED PROCEDURE EliminarSocio:

-- Caso normal
EXEC manejo_personas.EliminarSocio
    @id_socio = 4; -- Resultado: Socio y todas sus relaciones eliminados completamente del sistema

-- Socio con actividades (se eliminar�n las relaciones)
EXEC manejo_personas.EliminarSocio
    @id_socio = 3; -- Resultado: Socio y todas sus relaciones eliminados completamente del sistema

-- Socio con invitados (se eliminar�n las relaciones)
EXEC manejo_personas.EliminarSocio
    @id_socio = 5; -- Resultado: Socio y todas sus relaciones eliminados completamente del sistema



-- Socio no existe
EXEC manejo_personas.EliminarSocio
    @id_socio = 99999; -- Resultado: El socio no existe

-- Socio es responsable de un grupo familiar
EXEC manejo_personas.EliminarSocio
    @id_socio = 1; -- Resultado: No se puede eliminar el socio porque es responsable de un grupo familiar

-- Socio tiene facturas asociadas
EXEC manejo_personas.EliminarSocio
    @id_socio = 2; -- Resultado: No se puede eliminar el socio porque tiene facturas asociadas

