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

-- Crear Grupo Familiar

-- Caso normal
EXEC manejo_personas.CrearGrupoFamiliar;
-- Resultado esperado: Exito, Grupo familiar creado correctamente (deberia funcionar siempre a no ser error desconocido)

-- ModificarEstadoGrupoFamiliar

-- Casos Normales
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo = 1,
    @estado   = 0;
-- Resultado esperado: Exito, Estado del grupo familiar actualizado correctamente

EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo = 5,
    @estado   = 0;
-- Resultado esperado: Exito, Estado del grupo familiar actualizado correctamente

EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo = 4,
    @estado   = 1;
-- Resultado esperado: Exito, Estado del grupo familiar actualizado correctamente

-- Grupo inexistente
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo = 78964,
    @estado   = 1;
-- Resultado esperado: Error, Grupo familiar no encontrado

-- Estado invalido
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo = 3,
    @estado   = 61;
-- Resultado esperado: Error, Estado debe ser 0 (inactivo) o 1 (activo)


-- EliminarGrupoFamiliar

-- Casos Normales
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo = 3;
-- Resultado esperado: Exito, Grupo familiar inactivado correctamente

EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo = 6;
-- Resultado esperado: Exito, Grupo familiar inactivado correctamente

EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo = 9;
-- Resultado esperado: Exito, Grupo familiar inactivado correctamente

-- Grupo inexistente
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo = 27894;
-- Resultado esperado: Error, Grupo familiar no encontrado

-- Responsable asignado
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo = 2;
-- Resultado esperado: Error, No se puede eliminar: grupo tiene responsables asignados

-- Miembros activos
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo = 4;
-- Resultado esperado: Error, No se puede eliminar: grupo tiene socios asignados
