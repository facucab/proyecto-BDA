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

-- CrearRol

-- Casos normales
EXEC usuarios.CrearRol
	@nombre       = 'Admin',
	@descripcion  = 'Administrador del sistema';
-- Resultado esperado: OK, Rol creado correctamente.

EXEC usuarios.CrearRol
	@nombre       = 'Usuario',
	@descripcion  = 'Usuario estándar';
-- Resultado esperado: OK, Rol creado correctamente.

-- Nombre vacío
EXEC usuarios.CrearRol
	@nombre       = '',
	@descripcion  = 'Sin nombre';
-- Resultado esperado: Error, El nombre del rol es obligatorio.

-- Descripción vacía
EXEC usuarios.CrearRol
	@nombre       = 'Test',
	@descripcion  = '';
-- Resultado esperado: Error, La descripcion del rol es obligatoria.

-- Parámetros nulos
EXEC usuarios.CrearRol
	@nombre       = NULL,
	@descripcion  = NULL;
-- Resultado esperado: Error, El nombre del rol es obligatorio.

-- Nombre duplicado
EXEC usuarios.CrearRol
	@nombre       = 'Admin',
	@descripcion  = 'Duplicado';
-- Resultado esperado: Error, Ya existe un rol con ese nombre.


-- ModificarRol

-- Casos normales
EXEC usuarios.ModificarRol
	@id_rol       = 1,
	@nombre       = 'SuperAdmin',
	@descripcion  = 'Super administrador';
-- Resultado esperado: OK, Rol modificado correctamente.

EXEC usuarios.ModificarRol
	@id_rol       = 2,
	@nombre       = 'UsuarioPremium',
	@descripcion  = 'Usuario con beneficios';
-- Resultado esperado: OK, Rol modificado correctamente.

-- ID inexistente
EXEC usuarios.ModificarRol
	@id_rol       = 99999,
	@nombre       = 'NoExiste',
	@descripcion  = 'Sin rol';
-- Resultado esperado: Error, El rol no fue encontrado.

-- Nombre vacío
EXEC usuarios.ModificarRol
	@id_rol       = 1,
	@nombre       = '',
	@descripcion  = 'Desc';
-- Resultado esperado: Error, El nombre del rol es obligatorio.

-- Descripción vacía
EXEC usuarios.ModificarRol
	@id_rol       = 1,
	@nombre       = 'Test',
	@descripcion  = '';
-- Resultado esperado: Error, La descripcion del rol es obligatoria.

-- Nombre duplicado en otro rol
EXEC usuarios.ModificarRol
	@id_rol       = 1,
	@nombre       = 'UsuarioPremium',
	@descripcion  = 'Duplicado';
-- Resultado esperado: Error, Ya existe otro rol con ese nombre.


-- EliminarRol

-- Casos normales
EXEC usuarios.EliminarRol
	@id_rol = 1;
-- Resultado esperado: OK, Rol eliminado correctamente.

EXEC usuarios.EliminarRol
	@id_rol = 2;
-- Resultado esperado: OK, Rol eliminado correctamente.

-- ID inexistente
EXEC usuarios.EliminarRol
	@id_rol = 99999;
-- Resultado esperado: Error, El rol no fue encontrado.

-- Intentar eliminar nuevamente
EXEC usuarios.EliminarRol
	@id_rol = 1;
-- Resultado esperado: Error, El rol no fue encontrado.
