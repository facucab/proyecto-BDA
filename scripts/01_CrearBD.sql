-- Crear la base de datos
CREATE DATABASE Com5600G01;
GO

-- Seleccionar la base de datos
USE Com5600G01;
GO

-- Crear esquemas (cada uno en su propio lote)
CREATE SCHEMA manejo_personas; -- Relativo a personas físicas
GO

CREATE SCHEMA manejo_actividades; -- Relativo a actividades del club
GO

CREATE SCHEMA pagos_y_facturas; -- Relativo a pagos y facturación
GO
