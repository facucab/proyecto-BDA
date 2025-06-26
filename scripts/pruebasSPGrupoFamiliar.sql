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
EXEC usuarios.CrearGrupoFamiliar;
-- Resultado esperado: OK, Grupo familiar creado correctamente

-- ModificarEstadoGrupoFamiliar

-- Casos Normales
EXEC usuarios.ModificarEstadoGrupoFamiliar
    @id_grupo = 1,
    @estado   = 0;
-- Resultado esperado: OK, Estado del grupo familiar actualizado correctamente

EXEC usuarios.ModificarEstadoGrupoFamiliar
    @id_grupo = 5,
    @estado   = 0;
-- Resultado esperado: OK, Estado del grupo familiar actualizado correctamente

EXEC usuarios.ModificarEstadoGrupoFamiliar
    @id_grupo = 4,
    @estado   = 1;
-- Resultado esperado: OK, Estado del grupo familiar actualizado correctamente

-- Grupo inexistente
EXEC usuarios.ModificarEstadoGrupoFamiliar
    @id_grupo = 78964,
    @estado   = 1;
-- Resultado esperado: Error, Grupo familiar no encontrado

-- Estado invalido
EXEC usuarios.ModificarEstadoGrupoFamiliar
    @id_grupo = 3,
    @estado   = 61;
-- Resultado esperado: Error, Estado debe ser 0 (inactivo) o 1 (activo)


-- EliminarGrupoFamiliar

-- Casos Normales
EXEC usuarios.EliminarGrupoFamiliar @id_grupo = 3;
-- Resultado esperado: OK, Grupo familiar inactivado correctamente

EXEC usuarios.EliminarGrupoFamiliar @id_grupo = 6;
-- Resultado esperado: OK, Grupo familiar inactivado correctamente

EXEC usuarios.EliminarGrupoFamiliar @id_grupo = 9;
-- Resultado esperado: OK, Grupo familiar inactivado correctamente

-- Grupo inexistente
EXEC usuarios.EliminarGrupoFamiliar @id_grupo = 27894;
-- Resultado esperado: Error, Grupo familiar no encontrado

-- Responsable asignado
EXEC usuarios.EliminarGrupoFamiliar @id_grupo = 2;
-- Resultado esperado: Error, No se puede eliminar: grupo tiene responsables asignados

-- Miembros activos
EXEC usuarios.EliminarGrupoFamiliar @id_grupo = 4;
-- Resultado esperado: Error, No se puede eliminar: grupo tiene socios asignados