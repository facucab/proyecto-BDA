/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés
*/


-- Crear la base de datos
-- Crear base de datos
IF DB_ID('Com5600G01') IS NULL
    CREATE DATABASE Com5600G01;
GO

-- Usar la base
USE Com5600G01;
GO

-- Crear esquema: manejo_personas
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'manejo_personas'
)
    EXEC('CREATE SCHEMA manejo_personas');
GO

-- Crear esquema: manejo_actividades
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'manejo_actividades'
)
    EXEC('CREATE SCHEMA manejo_actividades');
GO

-- Crear esquema: pagos_y_facturas
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'pagos_y_facturas'
)
    EXEC('CREATE SCHEMA pagos_y_facturas');
GO


