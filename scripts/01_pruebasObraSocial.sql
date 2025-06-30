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
EXEC usuarios.CrearObraSocial
	@nombre = 'OSDE',
	@nro_telefono = '123456789';
--Resultado: Obra Social creada correctamente

EXEC usuarios.CrearObraSocial
	@nombre = 'OSDE 10',
	@nro_telefono = '987654321';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CrearObraSocial
	@nombre = 'OSMTT',
	@nro_telefono = '111111111';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CrearObraSocial
	@nombre = 'OSDE 10',
	@nro_telefono = '222222222';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CrearObraSocial
	@nombre = 'Swiss Medical',
	@nro_telefono = '333333333';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CrearObraSocial
	@nombre = 'Medifé',
	@nro_telefono = '444444444';
--Resultado: Obra Social creada correctamente


EXEC usuarios.CrearObraSocial
	@nombre = 'OSPROTURA',
	@nro_telefono = '555555555';
--Resultado: Obra Social creada correctamente

EXEC usuarios.CrearObraSocial
	@nombre = 'Sancor Salud',
	@nro_telefono = '666666666';
--Resultado: Obra Social creada correctamente

EXEC usuarios.CrearnObraSocial
	@nombre = 'TEST',
	@nro_telefono = '777777777';
--Resultado: Obra Social creada correctamente

EXEC usuarios.ModificarObraSocial
	@id = 8,
	@nombre_nuevo = 'TEST 1';
-- Resultado: Obra Social Modificada

EXEC usuarios.EliminacionObraSocial
	@id = 8;
-- Resultado: Obra social eliminada


-- ERRORES

EXEC usuarios.CrearObraSocial
	@nombre = 'Sancor Salud',
	@nro_telefono = '888888888';
--Resultado: Ya hay una obra social con ese nombre

EXEC usuarios.CrearObraSocial
	@nombre = '',
	@nro_telefono = '999999999';
--Resultado: El nombre no puede ser nulo

EXEC usuarios.ModificarObraSocial
	@id = 99999,
	@nombre_nuevo = 'ESTO FALLA';
-- Resultado: id no existe

EXEC usuarios.ModificarObraSocial
	@id = 1,
	@nombre_nuevo = '';
-- Resultado: El nombre no puede ser nulo

EXEC usuarios.EliminarObraSocial
	@id = 99999;

--Resultado: id no existe

SELECT *
FROM usuarios.obra_social;
GO