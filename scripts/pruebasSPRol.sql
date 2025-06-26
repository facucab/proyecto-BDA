/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Stored Procedures de Rol
*/

USE Com5600G01;
GO

-- Pruebas rol

-- Crear Rol

-- Casos normales
EXEC manejo_personas.CrearRol
	@descripcion = 'Admin';
-- Resultado esperado: Exito, Rol creado correctamente

EXEC manejo_personas.CrearRol 
	@descripcion = 'Usuario';
-- Resultado esperado: Exito, Rol creado correctamente

-- Descripción vacía
EXEC manejo_personas.CrearRol 
	@descripcion = '';
-- Resultado esperado: Error, La descripción no puede ser nula o vacía

-- Descripción nula
EXEC manejo_personas.CrearRol 
	@descripcion = NULL;
-- Resultado esperado: Error, La descripción no puede ser nula o vacía

-- Descripción duplicada
EXEC manejo_personas.CrearRol 
	@descripcion = 'Admin';
-- Resultado esperado: Error, Ya existe un rol con esa descripción


-- ModificarRol

-- Caso normal: cambiar descripción
EXEC manejo_personas.ModificarRol 
	@id = 1, @descripcion = 'SuperAdmin';
-- Resultado esperado: Exito, Rol modificado correctamente

-- Caso normal: cambiar otra descripción
EXEC manejo_personas.ModificarRol 
	@id = 2, @descripcion = 'UsuarioPremium';
-- Resultado esperado: Exito, Rol modificado correctamente

-- ID nulo
EXEC manejo_personas.ModificarRol 
	@id = NULL, @descripcion = 'Test';
-- Resultado esperado: Error, id nulo

-- ID inexistente
EXEC manejo_personas.ModificarRol 
	@id = 99999, @descripcion = 'NoExiste';
-- Resultado esperado: Error, Rol no encontrado

-- Descripción vacía
EXEC manejo_personas.ModificarRol 
	@id = 1, @descripcion = '';
-- Resultado esperado: Error, La descripción no puede ser nula o vacía

-- Descripción nula
EXEC manejo_personas.ModificarRol 
	@id = 1, @descripcion = NULL;
-- Resultado esperado: Error, La descripción no puede ser nula o vacía

-- Descripción duplicada de otro rol
EXEC manejo_personas.ModificarRol 
	@id = 1, @descripcion = 'UsuarioPremium';
-- Resultado esperado: Error, Ya existe otro rol con esa descripción


-- EliminarRol

-- Caso normal: eliminar rol existente
EXEC manejo_personas.EliminarRol 
	@id = 1;
-- Resultado esperado: Exito, Rol eliminado correctamente

-- Caso normal: eliminar otro rol existente
EXEC manejo_personas.EliminarRol 
	@id = 2;
-- Resultado esperado: Exito, Rol eliminado correctamente

-- ID nulo
EXEC manejo_personas.EliminarRol 
	@id = NULL;
-- Resultado esperado: Error, id nulo

-- ID inexistente
EXEC manejo_personas.EliminarRol 
	@id = 99999;
-- Resultado esperado: Error, Rol no existente

-- Intentar eliminar rol ya eliminado
EXEC manejo_personas.EliminarRol 
	@id = 1;
-- Resultado esperado: Error, Rol no existente
