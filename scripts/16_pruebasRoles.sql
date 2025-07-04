/*
	Entrega 7 - Requisitos de seguridad

	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés
*/

USE Com5600G01;
GO

-- Crear usuarios de prueba y asignar a los roles (asumiendo que los roles ya existen y la base está vacía)
-- Jefe Tesoreria
CREATE LOGIN test_jefe_tesoreria WITH PASSWORD = 'Test1234!';
CREATE USER test_jefe_tesoreria FOR LOGIN test_jefe_tesoreria;
ALTER ROLE Jefe_Tesoreria ADD MEMBER test_jefe_tesoreria;
GO
-- Administrativo Cobranza
CREATE LOGIN test_cobranza WITH PASSWORD = 'Test1234!';
CREATE USER test_cobranza FOR LOGIN test_cobranza;
ALTER ROLE Administrativo_Cobranza ADD MEMBER test_cobranza;
GO
-- Administrativo Morosidad
CREATE LOGIN test_morosidad WITH PASSWORD = 'Test1234!';
CREATE USER test_morosidad FOR LOGIN test_morosidad;
ALTER ROLE Administrativo_Morosidad ADD MEMBER test_morosidad;
GO
-- Administrativo Facturacion
CREATE LOGIN test_facturacion WITH PASSWORD = 'Test1234!';
CREATE USER test_facturacion FOR LOGIN test_facturacion;
ALTER ROLE Administrativo_Facturacion ADD MEMBER test_facturacion;
GO
-- Socio Web
CREATE LOGIN test_socio WITH PASSWORD = 'Test1234!';
CREATE USER test_socio FOR LOGIN test_socio;
ALTER ROLE Socio_Web ADD MEMBER test_socio;
GO
-- Secretario
CREATE LOGIN test_secretario WITH PASSWORD = 'Test1234!';
CREATE USER test_secretario FOR LOGIN test_secretario;
ALTER ROLE Secretario ADD MEMBER test_secretario;
GO

-- Pruebas de permisos exitosos
-- Jefe_Tesoreria: acceso total a facturacion
EXECUTE AS USER = 'test_jefe_tesoreria';
SELECT TOP 1 * FROM facturacion.factura; 
INSERT INTO facturacion.factura (id_persona, estado_pago, monto_a_pagar) VALUES (1, 'Pendiente', 100); 
UPDATE facturacion.factura SET estado_pago = 'Pagado' WHERE id_factura = 1; 
DELETE FROM facturacion.factura WHERE id_factura = 1; 
REVERT;
GO

-- Administrativo_Cobranza: solo lectura sobre vista de facturas
EXECUTE AS USER = 'test_cobranza';
SELECT TOP 1 * FROM facturacion.VistaFacturasCompleta; 
REVERT;
GO

-- Administrativo_Morosidad: puede ejecutar SP de morosos recurrentes
EXECUTE AS USER = 'test_morosidad';
EXEC usuarios.MorososRecurrentes @fechaInicio = '2024-01-01', @fechaFin = '2024-12-31'; 
REVERT;
GO

-- Administrativo_Facturacion: CRUD sobre Factura y SPs de gestión
EXECUTE AS USER = 'test_facturacion';
INSERT INTO facturacion.factura (id_persona, estado_pago, monto_a_pagar) VALUES (1, 'Pendiente', 100); 
UPDATE facturacion.factura SET estado_pago = 'Pagado' WHERE id_factura = 1; 
DELETE FROM facturacion.factura WHERE id_factura = 1; 
EXEC facturacion.CrearFactura @id_persona = 1, @estado_pago = 'Pendiente', @monto_a_pagar = 100; 
EXEC facturacion.ModificarFactura @id_factura = 1, @estado_pago = 'Pagado'; 
EXEC facturacion.EliminarFactura @id_factura = 1; 
REVERT;
GO

-- Socio_Web: solo puede ver su propia información
EXECUTE AS USER = 'test_socio';
EXEC usuarios.MiInformacion @numero_socio = '0000001'; 
GO

-- Secretario: acceso a vistas completas e ingresos mensuales
EXECUTE AS USER = 'test_secretario';
SELECT TOP 1 * FROM usuarios.VistaSociosCompleta; 
SELECT TOP 1 * FROM usuarios.VistaInvitadosCompleta; 
SELECT TOP 1 * FROM actividades.VistaSociosPorClase;
EXEC facturacion.IngresosMensualesActividades;
REVERT;
GO


DROP ROLE Jefe_Tesoreria;
DROP ROLE Administrativo_Cobranza;
DROP ROLE Administrativo_Morosidad;
DROP ROLE Administrativo_Facturacion;
DROP ROLE Administrativo_Socio;
DROP ROLE Socio_Web;
DROP ROLE Presidente;
DROP ROLE Vicepresidente;
DROP ROLE Secretario;
DROP ROLE Vocal;
DROP USER test_jefe_tesoreria; DROP LOGIN test_jefe_tesoreria;
DROP USER test_cobranza; DROP LOGIN test_cobranza;
DROP USER test_morosidad; DROP LOGIN test_morosidad;
DROP USER test_facturacion; DROP LOGIN test_facturacion;
DROP USER test_socio; DROP LOGIN test_socio;
DROP USER test_secretario; DROP LOGIN test_secretario;
GO