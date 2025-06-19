/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

		Luego de decidirse por un motor de base de datos relacional, llegó el momento de generar la
	base de datos. En esta oportunidad utilizarán SQL Server.
	Deberá instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicación de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregaría al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar
	un archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es
	entregado en una sola ejecución). Incluya comentarios para indicar qué hace cada módulo
	de código.
	Genere store procedures para manejar la inserción, modificado, borrado (si corresponde,
	también debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con “SP”.
	Algunas operaciones implicarán store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Asegúrense de que los comentarios que acompañen al código lo expliquen.
	Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto
	en la creación de objetos. NO use el esquema “dbo”.
	Todos los SP creados deben estar acompañados de juegos de prueba. Se espera que
	realicen validaciones básicas en los SP (p/e cantidad mayor a cero, CUIT válido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicación de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la sección de prácticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
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