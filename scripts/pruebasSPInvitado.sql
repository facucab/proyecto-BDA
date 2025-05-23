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

-- Pruebas invitado

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