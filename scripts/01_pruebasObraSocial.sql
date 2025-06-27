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

-- CREACION

--Casos Normales
EXEC usuarios.CreacionObraSocial
	@nombre = 'OSDE';
--Resultado: Obra Social creada correctamente

EXEC usuarios.CreacionObraSocial
	@nombre = 'OSDE 10';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CreacionObraSocial
	@nombre = 'OSMTT';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CreacionObraSocial
	@nombre = 'OSDE 10';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CreacionObraSocial
	@nombre = 'Swiss Medical';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CreacionObraSocial
	@nombre = 'Medifé';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CreacionObraSocial
	@nombre = 'OSPROTURA';
--Resultado: Obra Social creada correctamente

EXEC usuarios.CreacionObraSocial
	@nombre = 'Sancor Salud';
--Resultado: Obra Social creada correctamente

EXEC usuarios.CreacionObraSocial
	@nombre = 'TEST';
--Resultado: Obra Social creada correctamente

EXEC usuarios.ModificacionObraSocial
	@id = 8,
	@nombre_nuevo = 'TEST 1';
-- Resultado: Obra Social Modificada

EXEC usuarios.EliminacionObraSocial
	@id = 8;
-- Resultado: Obra social eliminada


-- ERRORES

EXEC usuarios.CreacionObraSocial
	@nombre = 'Sancor Salud';
--Resultado: Ya hay una obra social con ese nombre

EXEC usuarios.CreacionObraSocial
	@nombre = '';
--Resultado: El nombre no puede ser nulo

EXEC usuarios.ModificacionObraSocial
	@id = 99999,
	@nombre_nuevo = 'ESTO FALLA';
-- Resultado: id no existe

EXEC usuarios.ModificacionObraSocial
	@id = 1,
	@nombre_nuevo = '';
-- Resultado: El nombre no puede ser nulo

EXEC usuarios.EliminacionObraSocial
	@id = 99999;

--Resultado: id no existe

SELECT *
FROM usuarios.obra_social;
GO