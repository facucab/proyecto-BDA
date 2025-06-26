/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Invitado
*/

--Creacion

--Casos normales
EXEC manejo_personas.CrearInvitado
	@id_persona =1,
	@id_socio =1;
EXEC manejo_personas.CrearInvitado
	@id_persona =2,
	@id_socio =1;
EXEC manejo_personas.CrearInvitado
	@id_persona =3,
	@id_socio =2;
--Respuestas: Invitado creado
--Ids nulas
EXEC manejo_personas.CrearInvitado
	@id_persona =NULL,
	@id_socio =1;
EXEC manejo_personas.CrearInvitado
	@id_persona =1,
	@id_socio =NULL;
--Respuestas: Id de persona nulo

--Ids inexistentes
EXEC manejo_personas.CrearInvitado
	@id_persona =99999,
	@id_socio =2;
--Respuesta: El invitado tiene que ser persona
EXEC manejo_personas.CrearInvitado
	@id_persona =3,
	@id_socio =99999;
--Respuestas: Socio no existe

--Invitado ya registrado
EXEC manejo_personas.CrearInvitado
	@id_persona =3,
	@id_socio =2;
--Respuesta: Ya existe invitado para esa persona

--Modificacion

--Casos normales
EXEC manejo_personas.ModificarInvitado
	@id_invitado =4,
	@id_socio =3;
EXEC manejo_personas.ModificarInvitado
	@id_invitado =4,
	@id_socio =7;
EXEC manejo_personas.ModificarInvitado
	@id_invitado =2,
	@id_socio =6;
--Resultado: Invitado modificado

--Id inexistente de socio
EXEC manejo_personas.CrearInvitado
	@id_persona =4,
	@id_socio =99999;
--Respuestas: Socio no existe

--Id inexistente de invitado
EXEC manejo_personas.CrearInvitado
	@id_persona =55555,
	@id_socio =2;
--Respuestas: invitado no existe

--Ids nulas
EXEC manejo_personas.CrearInvitado
	@id_persona =NULL,
	@id_socio =3;
EXEC manejo_personas.CrearInvitado
	@id_persona =2,
	@id_socio =NULL;
--Respuestas: Parametros nulos

--Eliminacion:

-- Caso normal - Invitado sin referencias en otras tablas
EXEC manejo_personas.EliminarInvitado 
	@id_invitado = 1;
-- Resultado: Invitado y persona eliminados

-- Caso normal - Invitado con referencias en otras tablas (borrado lógico)
EXEC manejo_personas.EliminarInvitado 
	@id_invitado = 2;
-- Resultado: Invitado eliminado. Persona inactivada (borrado logico)

-- ID nulo
EXEC manejo_personas.EliminarInvitado 
	@id_invitado = NULL;
-- Resultado: id_invitado nulo

-- ID inexistente
EXEC manejo_personas.EliminarInvitado 
	@id_invitado = 99999;
-- Resultado: Invitado no existe