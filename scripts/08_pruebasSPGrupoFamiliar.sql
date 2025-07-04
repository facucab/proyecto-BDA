/*
	Entrega 4 - Documento de instalacion y configuracion

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Ruben 
	45234709 | Gauto, Gaston Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomas Andres

	Pruebas para Crear, Modificar y Eliminar Grupo Familiar
*/
-- Funciona, pero debemos tener socios si o si
USE Com5600G01;
GO

-- Crear Grupo Familiar

-- Caso normal
EXEC usuarios.CrearGrupoFamiliar
    @id_socio_rp = 1;
    
EXEC usuarios.CrearGrupoFamiliar @id_socio_rp = '000002';
-- Resultado esperado: OK, Grupo familiar creado correctamente
select * from usuarios.socio

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

SELECT *
FROM usuarios.grupo_familiar