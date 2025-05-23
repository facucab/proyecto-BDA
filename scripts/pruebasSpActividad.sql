-- Pruebas actividades

--Creacion

--Casos Normales
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Fulbol',
	@costo_mensual = 2000.00;
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Tenis',
	@costo_mensual = 2500.00;
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Voley',
	@costo_mensual = 2000.00;
--Resultado: Actividad creada correctamente

--Actividad ya creada
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Fulbol',
	@costo_mensual = 2500.00;
--Resultado: Ya existe una actividad con ese nombre

--Nombre vacio
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='',
	@costo_mensual = 9500.00;
--Resultado: El nombre de actividad no puede ser nulo

--Costo menor o igual a 0
EXEC manejo_actividades.CrearActividad
	@nombre_actividad ='Golf',
	@costo_mensual = 0;
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