/*
	Entrega 4 - Documento de instalaci�n y configuraci�n

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rub�n 
	45234709 | Gauto, Gast�n Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tom�s Andr�s

		Luego de decidirse por un motor de base de datos relacional, lleg� el momento de generar la
	base de datos. En esta oportunidad utilizar�n SQL Server.
	Deber� instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicaci�n de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregar�a al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deber� entregar
	un archivo .sql con el script completo de creaci�n (debe funcionar si se lo ejecuta �tal cual� es
	entregado en una sola ejecuci�n). Incluya comentarios para indicar qu� hace cada m�dulo
	de c�digo.
	Genere store procedures para manejar la inserci�n, modificado, borrado (si corresponde,
	tambi�n debe decidir si determinadas entidades solo admitir�n borrado l�gico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con �SP�.
	Algunas operaciones implicar�n store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Aseg�rense de que los comentarios que acompa�en al c�digo lo expliquen.
	Genere esquemas para organizar de forma l�gica los componentes del sistema y aplique esto
	en la creaci�n de objetos. NO use el esquema �dbo�.
	Todos los SP creados deben estar acompa�ados de juegos de prueba. Se espera que
	realicen validaciones b�sicas en los SP (p/e cantidad mayor a cero, CUIT v�lido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicaci�n de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, n�mero de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la secci�n de pr�cticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
*/

-- Pruebas descuento

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