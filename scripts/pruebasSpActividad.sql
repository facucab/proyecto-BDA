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

USE Com5600G01;
GO

-- Pruebas actividades

--Creacion

--Casos Normales
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Fulbol',
	@costo_mensual = 2000.00,
	@vigencia = '2024-12-31';
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Tenis',
	@costo_mensual = 2500.00,
	@vigencia = '2024-12-31';
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Voley',
	@costo_mensual = 2000.00,
	@vigencia = '2024-12-31';
--Resultado: Actividad creada correctamente

--Actividad ya creada
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Fulbol',
	@costo_mensual = 2500.00,
	@vigencia = '2024-12-31';
--Resultado: Ya existe una actividad con ese nombre

--Nombre vacio
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='',
	@costo_mensual = 9500.00,
	@vigencia = '2024-12-31';
--Resultado: El nombre de actividad no puede ser nulo

--Costo menor o igual a 0
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Golf',
	@costo_mensual = 0,
	@vigencia = '2024-12-31';
--Resultado: El costo mensual debe ser mayor a cero

--Modificacion

--Caso normal
EXEC manejo_actividades.ModificarActividad
	@id =2,
	@nombre_actividad ='Futbol 5',
	@costo_mensual =1300.00;
EXEC manejo_actividades.ModificarActividad
	@id =2,
	@nombre_actividad ='Atletismo',
	@costo_mensual =3300.00;
EXEC manejo_actividades.ModificarActividad
	@id =3,
	@nombre_actividad ='Ciclismo',
	@costo_mensual =2300.00;
--Resultado: Actividad modificada correctamente

--Id nulo
EXEC manejo_actividades.ModificarActividad
	@id =NULL,
	@nombre_actividad ='Ciclismo',
	@costo_mensual =4200.00;
--Resultado: id nulo

--Id inexistente
EXEC manejo_actividades.ModificarActividad
	@id =99999,
	@nombre_actividad ='Handball',
	@costo_mensual =4200.00;
--Resultado: id no existente

--Nombre invalido
EXEC manejo_actividades.ModificarActividad
	@id =2,
	@nombre_actividad ='',
	@costo_mensual =1200.00;
--Resultado: El nombre de actividad no puede ser nulo o vacio

--Nombre ya usado
EXEC manejo_actividades.ModificarActividad
	@id =3,
	@nombre_actividad ='Futbol',
	@costo_mensual =1200.00;
--Resultado: Ya existe una actividad con ese nombre

--Costo menor o igual a 0
EXEC manejo_actividades.ModificarActividad
	@id =1,
	@nombre_actividad ='Natacion',
	@costo_mensual =0;
--Resultado: El costo mensual debe ser mayor a cero

--Eliminacion

--Caso normal
EXEC manejo_actividades.EliminarActividad @id =1;
EXEC manejo_actividades.EliminarActividad @id =2;
EXEC manejo_actividades.EliminarActividad @id =3;
--Resultado: Actividad eliminada correctamente

--Id nulo
EXEC manejo_actividades.EliminarActividad @id =NULL;
--Resultado: id nulo

--Id inexistente
EXEC manejo_actividades.EliminarActividad @id =99999;
--Resultado: id no existente