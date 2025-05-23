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

--Pruebas Grupo Familiar

--Modificacion 

--Casos Normales
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =1,
    @estado =0;
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =5,
    @estado =0;
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =4,
    @estado =1;
--Respuesta: Estado del Grupo familiar actualizado correctamente

--Grupo inexistente
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =78964,
    @estado =1;
--Resultado: Grupo familiar no encontrado

--Estado invalido
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =3,
    @estado =61;
--Resultado: Estado debe ser 0 (inactivo) o 1 (activo)

--Eliminacion

--Casos Normales
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =3;
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =6;
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =9;
--Resultado: Grupo familiar inactivado correctamente

--Grupo inexistente
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =27894;
--Resultado: Grupo familiar no encontrado

--Responsable asignado
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =2;
--Resultado: No se puede eliminar: grupo tiene responsables asignados

--Miembros activos
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =4;
--Resultado: No se puede eliminar: grupo tiene socios asignados