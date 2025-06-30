/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Stored Procedures de Datos Empresa
*/

USE Com5600G01;
GO

-- Pruebas datos empresa

-- CREACION

--Casos Normales
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-12345678-9',
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Gimnasio Fitness Pro';
--Resultado: Datos ingresados correctamente

EXEC facturacion.CrearDatosEmpresa
	@cuit = '30-98765432-1',
	@domicilio_comercial = 'Belgrano 567',
	@condicion_iva = 'Monotributista',
	@nombre = 'Centro Deportivo ABC';
--Resultado: Datos ingresados correctamente

EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-55556666-7',
	@domicilio_comercial = 'San Martín 890',
	@condicion_iva = 'Exento',
	@nombre = 'Club Deportivo XYZ';
--Resultado: Datos ingresados correctamente

EXEC facturacion.CrearDatosEmpresa
	@cuit = '30-11112222-3',
	@domicilio_comercial = 'Rivadavia 456',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Gimnasio Power Gym';
--Resultado: Datos ingresados correctamente

EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-77778888-5',
	@domicilio_comercial = 'Mitre 321',
	@condicion_iva = 'Monotributista',
	@nombre = 'Centro Fitness Plus';
--Resultado: Datos ingresados correctamente

EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99999999-9',
	@domicilio_comercial = 'Av. del Sol 1000',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Sol Norte';
--Resultado: Datos ingresados correctamente

-- ERRORES

-- Error: CUIT duplicado
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-12345678-9',
	@domicilio_comercial = 'Otra dirección',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Empresa Duplicada';
--Resultado: Error - CUIT Repetido

-- Error: CUIT nulo
EXEC facturacion.CrearDatosEmpresa
	@cuit = NULL,
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Empresa Test';
--Resultado: Los parámetros no pueden ser nulos

-- Error: CUIT vacío
EXEC facturacion.CrearDatosEmpresa
	@cuit = '',
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Empresa Test';
--Resultado: El CUIT no puede estar vacío

-- Error: Domicilio nulo
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99998888-1',
	@domicilio_comercial = NULL,
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Empresa Test';
--Resultado: Los parámetros no pueden ser nulos

-- Error: Domicilio vacío
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99998888-1',
	@domicilio_comercial = '',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = 'Empresa Test';
--Resultado: El domicilio no puede estar vacío

-- Error: Condición IVA nula
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99998888-1',
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = NULL,
	@nombre = 'Empresa Test';
--Resultado: Los parámetros no pueden ser nulos

-- Error: Condición IVA inválida
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99998888-1',
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = 'Consumidor Final',
	@nombre = 'Empresa Test';
--Resultado: Las condiciones válidas frente al IVA son "Responsable Inscripto", "Monotributista" y "Exento"

-- Error: Nombre nulo
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99998888-1',
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = NULL;
--Resultado: Los parámetros no pueden ser nulos

-- Error: Nombre vacío
EXEC facturacion.CrearDatosEmpresa
	@cuit = '20-99998888-1',
	@domicilio_comercial = 'Av. Corrientes 1234',
	@condicion_iva = 'Responsable Inscripto',
	@nombre = '';
--Resultado: El nombre de la empresa no puede estar vacío

-- ELIMINACION

-- Casos Normales
EXEC facturacion.EliminarDatosEmpresa
	@cuit = '20-77778888-5';
--Resultado: Empresa eliminada correctamente

EXEC facturacion.EliminarDatosEmpresa
	@cuit = '30-11112222-3';
--Resultado: Empresa eliminada correctamente

-- ERRORES

-- Error: CUIT nulo
EXEC facturacion.EliminarDatosEmpresa
	@cuit = NULL;
--Resultado: El CUIT es obligatorio para identificar la empresa a eliminar

-- Error: CUIT vacío
EXEC facturacion.EliminarDatosEmpresa
	@cuit = '';
--Resultado: El CUIT no puede estar vacío

-- Error: CUIT inexistente
EXEC facturacion.EliminarDatosEmpresa
	@cuit = '99-99999999-9';
--Resultado: No existe una empresa con el CUIT proporcionado

-- LIMPIEZA FINAL - Eliminar todas las empresas excepto "Sol Norte"
EXEC facturacion.EliminarDatosEmpresa
	@cuit = '20-12345678-9';
--Resultado: Empresa eliminada correctamente

EXEC facturacion.EliminarDatosEmpresa
	@cuit = '30-98765432-1';
--Resultado: Empresa eliminada correctamente

EXEC facturacion.EliminarDatosEmpresa
	@cuit = '20-55556666-7';
--Resultado: Empresa eliminada correctamente

SELECT *
FROM facturacion.datos_empresa;
GO
