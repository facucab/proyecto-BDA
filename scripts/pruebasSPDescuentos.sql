/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Descuento
*/

USE Com5600G01;
GO

--Creacion
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = 'Estudiante', 
    @cantidad = 0.100;
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = 'Lluvia', 
    @cantidad = 0.600;
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = 'Familiar', 
    @cantidad = 0.150;
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = 'actividades', 
    @cantidad = 0.100;
--Resultado: Descuento Ingresado Correctamente

--Descuento ya existente
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = 'Estudiante', 
    @cantidad = 0.560;
--Resultado: Ya existe un descuento con esta descripcion

--Descripcion vacia
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = '', 
    @cantidad = 0.500;
--Resultado: Los descuentos no pueden tener nombres nulos

--Sin descuento
EXEC pagos_y_facturas.CrearDescuento 
    @descripcion = 'Regalo', 
    @cantidad = 0;
--Resultado: Un descuento no puede no tener descuento

--Modificacion

-- Caso normal
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 1, 
    @descripcion = 'Estudiante Universitario', 
    @cantidad = 0.120;
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 2, 
    @descripcion = 'Adulto Mayor', 
    @cantidad = 0.050;
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 3, 
    @descripcion = 'Empleado', 
    @cantidad = 0.300;
-- Resultado: Descuento modificado correctamente

--Sin descuento
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 3, 
    @descripcion = 'Feriado', 
    @cantidad = 0;
--Resultado: Una descuento no puede no tener descuento

--Descuento ya existente
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 2, 
    @descripcion = 'Lluvia', 
    @cantidad = 0.050;
--Resultado: Ya existe un descuento con esta descripcion

--Descuento sin nombre
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 4, 
    @descripcion = '', 
    @cantidad = 0.050;
--Resultado: Los descuentos no pueden tener nombres nulos

--Id inexistente
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 99992, 
    @descripcion = 'Familiar', 
    @cantidad = 0.050;
--Resultado: id no existente

--Id nulo
EXEC pagos_y_facturas.ModificarDescuento 
    @id = 0, 
    @descripcion = 'Familiar', 
    @cantidad = 0.050;
--Resultado: id nulo

--Eliminar

--Caso normal
EXEC pagos_y_facturas.EliminarDescuento @id = 1;
EXEC pagos_y_facturas.EliminarDescuento @id = 2;
EXEC pagos_y_facturas.EliminarDescuento @id = 3;
--Resultado: Descuento eliminado correctamente

--Id nulo
EXEC pagos_y_facturas.EliminarDescuento @id = 0;
--Resultado: id nulo

--Id inexistente
EXEC pagos_y_facturas.EliminarDescuento @id = 99999;
--Resultado: id no existente