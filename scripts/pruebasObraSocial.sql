/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Stored Procedures de Obra Social
*/

USE Com5600G01;
GO

-- Pruebas obra social

--Creacion

--Casos Normales
EXEC manejo_personas.CreacionObraSocial
	@nombre = 'OSDE';
--Resultado: Obra Social creada correctamente

EXEC manejo_personas.CreacionObraSocial
	@nombre = 'SWISS MEDICAL';
--Resultado: Obra Social creada correctamente

EXEC manejo_personas.CreacionObraSocial
	@nombre = 'GALENO';
--Resultado: Obra Social creada correctamente

--Obra social ya creada
EXEC manejo_personas.CreacionObraSocial
	@nombre = 'OSDE';
--Resultado: Ya hay una obra social con ese nombre

--Nombre vacio
EXEC manejo_personas.CreacionObraSocial
	@nombre = '';
--Resultado: El nombre no puede ser nulo

--Nombre nulo
EXEC manejo_personas.CreacionObraSocial
	@nombre = NULL;
--Resultado: El nombre no puede ser nulo

--Nombre con espacios
EXEC manejo_personas.CreacionObraSocial
	@nombre = '   PREVENCION SALUD   ';
--Resultado: Obra Social creada correctamente (normalizada a 'PREVENCION SALUD')

--Modificacion

--Caso normal
EXEC manejo_personas.ModificacionObraSocial
	@id = 1,
	@nombre_nuevo = 'OSDE 310';
--Resultado: Obra Social modificada correctamente

EXEC manejo_personas.ModificacionObraSocial
	@id = 2,
	@nombre_nuevo = 'SWISS MEDICAL GROUP';
--Resultado: Obra Social modificada correctamente

EXEC manejo_personas.ModificacionObraSocial
	@id = 3,
	@nombre_nuevo = 'GALENO ART';
--Resultado: Obra Social modificada correctamente

--Id nulo
EXEC manejo_personas.ModificacionObraSocial
	@id = NULL,
	@nombre_nuevo = 'NUEVA OBRA SOCIAL';
--Resultado: id nulo

--Id inexistente
EXEC manejo_personas.ModificacionObraSocial
	@id = 99999,
	@nombre_nuevo = 'OBRA SOCIAL INEXISTENTE';
--Resultado: id no existente

--Nombre nuevo nulo
EXEC manejo_personas.ModificacionObraSocial
	@id = 1,
	@nombre_nuevo = NULL;
--Resultado: El nombre no puede ser nulo

--Nombre nuevo vacio
EXEC manejo_personas.ModificacionObraSocial
	@id = 1,
	@nombre_nuevo = '';
--Resultado: El nombre no puede ser nulo

--Nombre ya usado
EXEC manejo_personas.ModificacionObraSocial
	@id = 4,
	@nombre_nuevo = 'OSDE 310';
--Resultado: La obra social ya esta registrada

--Nombre con espacios (normalización)
EXEC manejo_personas.ModificacionObraSocial
	@id = 4,
	@nombre_nuevo = '   MEDICUS   ';
--Resultado: Obra Social modificada correctamente

--Eliminacion

--Caso normal
EXEC manejo_personas.EliminacionObraSocial
	@id = 1;
--Resultado: Obra Social desactivada correctamente

EXEC manejo_personas.EliminacionObraSocial
	@id = 2;
--Resultado: Obra Social desactivada correctamente

EXEC manejo_personas.EliminacionObraSocial
	@id = 3;
--Resultado: Obra Social desactivada correctamente

--Id nulo
EXEC manejo_personas.EliminacionObraSocial
	@id = NULL;
--Resultado: id nulo

--Id inexistente
EXEC manejo_personas.EliminacionObraSocial
	@id = 99999;
--Resultado: id no existente

--Intentar eliminar obra social ya eliminada
EXEC manejo_personas.EliminacionObraSocial
	@id = 1;
--Resultado: Obra Social desactivada correctamente (no debería dar error)
