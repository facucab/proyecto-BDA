USE Com5600G01; -- Selecciona la base de datos de trabajo
GO

-- Crea roles para distintos perfiles del club
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
GO

-- Asigna permisos específicos según rol

-- Jefe de Tesorería: acceso total al esquema de pagos y facturas
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::facturacion TO Jefe_Tesoreria;
GO

-- Cobranza: solo lectura sobre vista de facturas
GRANT SELECT ON facturacion.VistaFacturasCompleta TO Administrativo_Cobranza;
GO

-- Morosidad: puede ejecutar SP de morosos recurrentes
GRANT EXECUTE ON usuarios.MorososRecurrentes TO Administrativo_Morosidad;
GO

-- Crea roles para distintos perfiles del club
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
GO

-- Asigna permisos específicos según rol
-- Jefe de Tesorería: acceso total al esquema de pagos y facturas
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::facturacion TO Jefe_Tesoreria;
GO

-- Cobranza: solo lectura sobre vista de facturas
GRANT SELECT ON facturacion.VistaFacturasCompleta TO Administrativo_Cobranza;
GO

-- Morosidad: puede ejecutar SP de morosos recurrentes
GRANT EXECUTE ON usuarios.MorososRecurrentes TO Administrativo_Morosidad;
GO

-- Facturación: CRUD sobre Factura + ejecución de SPs de gestión
GRANT SELECT, INSERT, UPDATE, DELETE ON facturacion.Factura TO Administrativo_Facturacion;
GRANT EXECUTE ON facturacion.CrearFactura TO Administrativo_Facturacion;
GRANT EXECUTE ON facturacion.ModificarFactura TO Administrativo_Facturacion;
GRANT EXECUTE ON facturacion.EliminarFactura TO Administrativo_Facturacion;
GO

-- Socios: acceso total y lectura sobre usuarios
GRANT EXECUTE ON SCHEMA::usuarios TO Administrativo_Socio;
GRANT SELECT ON SCHEMA::usuarios TO Administrativo_Socio;
GO

-- Socio Web: solo puede ver su propia información
GRANT SELECT ON usuarios.MiInformacion TO Socio_Web;
GO

-- Autoridades: permisos de lectura variados
GRANT SELECT ON SCHEMA::usuarios TO Presidente;
GRANT SELECT ON SCHEMA::facturacion TO Presidente;
GRANT SELECT ON SCHEMA::usuarios TO Vicepresidente;
GRANT SELECT ON SCHEMA::facturacion TO Vicepresidente;

-- Secretario: acceso a vistas completas e ingresos mensuales
GRANT SELECT ON usuarios.VistaSociosCompleta TO Secretario;
GRANT SELECT ON usuarios.VistaInvitadosCompleta TO Secretario;
GRANT SELECT ON actividades.VistaSociosPorClase TO Secretario;
GRANT SELECT ON facturacion.IngresosMensualesActividades TO Secretario;
GO

/*
-- Elimina todos los roles creados
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
*/

/* Política de Respaldo:

Decidimos que se realiza automáticamente un respaldo completo una vez por semana, durante la madrugada del día lunes.  
Luego, se realiza un respaldo diferencial cada 24 horas (también durante la madrugada), y un respaldo del log de transacciones cada 10 minutos.

Justificación: El sistema gestiona la facturación de un local con carga de trabajo intermitente. 
Dado que opera en un servidor local donde no van a haber operaciones constantes, creemos que hace falta un RTO bajo 
que minimice la pérdida de datos, sin un uso excesivo de recursos.

Por ese motivo:
- Se realiza un respaldo diferencial diario para reducir el tiempo de restauración.
- Se respaldan los logs de transacciones cada 10 minutos, lo que nos garantiza como maximo 10 minutos de perdida de datos.
- Los respaldos completos y diferenciales se programan durante la madrugada para no alterar la performance del sistema durante los tiempos de carga
(Segun lo que pudimos ver en Google Maps, es el período de menor concurrencia en este tipo de negocios).
- Elegimos el dia lunes para el respaldo completo porque (Segun maps) es de los días de menor actividad.

En caso de poder acceder a una nube, haríamos un respaldo adicional en ella para complementar los respaldos locales en caso de que fallase uno u otro.*/
