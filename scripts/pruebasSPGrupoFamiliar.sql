/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Grupo Familiar
*/

USE Com5600G01;
GO

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