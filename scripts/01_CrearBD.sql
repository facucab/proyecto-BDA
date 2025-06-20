/*
	Entrega 4 - Documento de instalacion y configuracion

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Ruben 
	45234709 | Gauto, Gaston Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomas Andres

		Luego de decidirse por un motor de base de datos relacional, llego el momento de generar la
	base de datos. En esta oportunidad utilizaron SQL Server.
	Debera instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicacion de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregaro al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Debera entregar
	un archivo .sql con el script completo de creacion (debe funcionar si se lo ejecuta tal cual es
	entregado en una sola ejecucion). Incluya comentarios para indicar que hace cada modulo
	de codigo.
	Genere store procedures para manejar la insercion, modificado, borrado (si corresponde,
	tambien debe decidir si determinadas entidades solo admitiran borrado logico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con SP.
	Algunas operaciones implicaran store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Asegurense de que los comentarios que acompañen al codigo lo expliquen.
	Genere esquemas para organizar de forma logica los componentes del sistema y aplique esto
	en la creacion de objetos. NO use el esquema dbo.
	Todos los SP creados deben estar acompañados de juegos de prueba. Se espera que
	realicen validaciones basicas en los SP (p/e cantidad mayor a cero, CUIT valido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicacion de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, numero de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la seccion de practicas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
*/

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


