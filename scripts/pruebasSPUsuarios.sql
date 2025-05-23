--Pruebas usuario

--Creacion

--Casos Normales
-- Pruebas CrearUsuario
EXEC manejo_personas.CrearUsuario 
	@id_persona = 1,
	@username = 'usuario1',
	@password_hash = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
	@fecha_alta_contraseña = '2024-01-15';
EXEC manejo_personas.CrearUsuario 
	@id_persona = 2,
	@username = 'usuario2',
	@password_hash = 'b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: Usuario creado correctamente

-- ID persona nulo
EXEC manejo_personas.CrearUsuario 
	@id_persona = NULL,
	@username = 'usuario3',
	@password_hash = 'c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: id_persona nulo

-- Username nulo
EXEC manejo_personas.CrearUsuario 
	@id_persona = 3,
	@username = NULL,
	@password_hash = 'd665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3d665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3d665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3d665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: username nulo

-- Password hash nulo
EXEC manejo_personas.CrearUsuario 
	@id_persona = 4,
	@username = 'usuario4',
	@password_hash = NULL;
-- Resultado: password_hash nulo

-- Password hash con menos de 256 caracteres
EXEC manejo_personas.CrearUsuario 
	@id_persona = 5,
	@username = 'usuario5',
	@password_hash = 'hashcorto';
-- Resultado: password_hash debe tener 256 caracteres

-- Password hash con más de 256 caracteres
EXEC manejo_personas.CrearUsuario 
	@id_persona = 6,
	@username = 'usuario6',
	@password_hash = 'e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3extra';
-- Resultado: password_hash debe tener 256 caracteres

-- Persona inexistente
EXEC manejo_personas.CrearUsuario 
	@id_persona = 99999,
	@username = 'usuario_inexistente',
	@password_hash = 'f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: La persona especificada no existe

-- Persona que ya tiene usuario
EXEC manejo_personas.CrearUsuario 
	@id_persona = 1,
	@username = 'usuario_duplicado',
	@password_hash = '1665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae31665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae31665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae31665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: La persona ya tiene un usuario asignado

-- Username ya en uso
EXEC manejo_personas.CrearUsuario 
	@id_persona = 7,
	@username = 'usuario1',
	@password_hash = '2665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae32665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae32665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae32665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: El nombre de usuario ya esta en uso

--Modificacion

-- Caso normal 
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@username = 'nuevo_usuario1';

EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@password_hash = 'a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';

EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@fecha_alta_contraseña = '2024-02-15';

EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 2,
	@username = 'usuario_completo',
	@password_hash = 'b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
	@fecha_alta_contraseña = '2024-03-10';
-- Resultado: Usuario modificado correctamente

-- ID usuario nulo
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = NULL,
	@username = 'test_usuario';
-- Resultado: id_usuario nulo

-- Usuario inexistente
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 99999,
	@username = 'usuario_inexistente';
-- Resultado: El usuario especificado no existe

-- Username ya en uso por otro usuario
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@username = 'usuario2';
-- Resultado: El nombre de usuario ya esta en uso por otro usuario

--Eliminacion

--Casos Normales
EXEC manejo_personas.EliminarUsuario @id_usuario =1;
EXEC manejo_personas.EliminarUsuario @id_usuario =2;
EXEC manejo_personas.EliminarUsuario @id_usuario =3;
--Resultados: Usuario borrado, persona inactivada

--Id null
EXEC manejo_personas.EliminarUsuario @id_usuario =NULL;
--Resultado: id_usuario nulo

--Id inexistente
EXEC manejo_personas.EliminarUsuario @id_usuario =9;
--Resultado: El usuario especificado no existe

--Clases asignadas
EXEC manejo_personas.EliminarUsuario @id_usuario =12;
--Resultado: No se puede eliminar el usuario porque tiene clases asignadas