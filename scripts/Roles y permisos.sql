USE Com5600G01;
GO

-- Crear roles
CREATE ROLE Jefe_Tesoreria;
CREATE ROLE Administrativo_Cobranza;
CREATE ROLE Administrativo_Morosidad;
CREATE ROLE Administrativo_Facturacion;
CREATE ROLE Administrativo_Socio;
CREATE ROLE Socio_Web;
CREATE ROLE Presidente;
CREATE ROLE Vicepresidente;
CREATE ROLE Secretario;
CREATE ROLE Vocal;
 --Asignar permisos
 GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::pagos_y_facturas TO Jefe_Tesoreria;
 
 GRANT SELECT ON pagos_y_facturas.VistaFacturasCompleta TO Administrativo_Cobranza;

 GRANT EXECUTE ON manejo_personas.morosos_recurrentes TO Administrativo_Morosidad;

GRANT SELECT, INSERT, UPDATE, DELETE ON Pagos_y_facturas.Factura TO Administrativo_Facturacion;
GRANT EXECUTE ON Pagos_y_facturas.CreacionFactura TO Administrativo_Facturacion;
GRANT EXECUTE ON Pagos_y_facturas.ModificacionFactura TO Administrativo_Facturacion;
GRANT EXECUTE ON Pagos_y_facturas.EliminacionFactura TO Administrativo_Facturacion;

GRANT EXECUTE ON SCHEMA::manejo_personas TO Administrador_Socio;
GRANT SELECT ON SCHEMA::manejo_personas TO Administrador_Socio;

GRANT SELECT ON manejo_personas.MiInformacion TO Socio_Web;

GRANT SELECT To Presidente;

GRANT SELECT To Vicepresidente;

GRANT SELECT ON manejo_personas.VistaSociosCompleta To Secretario;
GRANT SELECT ON manejo_personas.VistaInvitadosCompleta To Secretario;
GRANT SELECT ON manejo_actividades.VistaSociosPorClase To Secretario;
GRANT SELECT ON pagos_y_facturas.ingresos_mensuales_actividades To Secretario;

--Eliminar roles
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