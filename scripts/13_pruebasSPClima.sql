/*
	Entrega 4 - Documento de instalacion

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Stored Procedures de Clima
*/

USE Com5600G01;
GO

-- Pruebas clima

-- CREACION

--Casos Normales
EXEC facturacion.RegistrarClima
	@fecha = '2024-01-15',
	@lluvia = 0.00;
--Resultado: Registro de clima creado correctamente

EXEC facturacion.RegistrarClima
	@fecha = '2024-01-16',
	@lluvia = 25.50;
--Resultado: Registro de clima creado correctamente

EXEC facturacion.RegistrarClima
	@fecha = '2024-01-17',
	@lluvia = 150.75;
--Resultado: Registro de clima creado correctamente

EXEC facturacion.RegistrarClima
	@fecha = '2024-01-18',
	@lluvia = 999.99;
--Resultado: Registro de clima creado correctamente

EXEC facturacion.RegistrarClima
	@fecha = '2024-01-19',
	@lluvia = 45.25;
--Resultado: Registro de clima creado correctamente

EXEC facturacion.RegistrarClima
	@fecha = '2024-01-20',
	@lluvia = 0.01;
--Resultado: Registro de clima creado correctamente

-- ERRORES

-- Error: Fecha nula
EXEC facturacion.RegistrarClima
	@fecha = NULL,
	@lluvia = 25.50;
--Resultado: La fecha es obligatoria

-- Error: Fecha futura
EXEC facturacion.RegistrarClima
	@fecha = '2025-12-31',
	@lluvia = 25.50;
--Resultado: La fecha no puede ser futura

-- Error: Lluvia nula
EXEC facturacion.RegistrarClima
	@fecha = '2024-01-21',
	@lluvia = NULL;
--Resultado: La cantidad de lluvia es obligatoria

-- Error: Lluvia negativa
EXEC facturacion.RegistrarClima
	@fecha = '2024-01-21',
	@lluvia = -5.00;
--Resultado: La cantidad de lluvia debe estar entre 0 y 999.99

-- Error: Fecha duplicada
EXEC facturacion.RegistrarClima
	@fecha = '2024-01-15',
	@lluvia = 30.00;
--Resultado: Ya existe un registro de clima para esa fecha

-- Error: Fecha duplicada con diferente lluvia
EXEC facturacion.RegistrarClima
	@fecha = '2024-01-16',
	@lluvia = 100.00;
--Resultado: Ya existe un registro de clima para esa fecha

-- Casos límite
EXEC facturacion.RegistrarClima
	@fecha = '2024-01-22',
	@lluvia = 0.00;
--Resultado: Registro de clima creado correctamente

EXEC facturacion.RegistrarClima
	@fecha = '2024-01-23',
	@lluvia = 999.99;
--Resultado: Registro de clima creado correctamente

-- Verificar estado final de la tabla
SELECT *
FROM facturacion.clima
ORDER BY fecha;
GO
