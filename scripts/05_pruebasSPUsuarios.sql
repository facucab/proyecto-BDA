USE Com5600G01;
GO

/*
	Entrega 4 - Documento de instalaci�n y configuraci�n

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rub�n 
	45234709 | Gauto, Gast�n Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tom�s Andr�s

    Pruebas para Crear, Modificar y Eliminar Usuario
*/

DECLARE @uid1 INT, @uid2 INT;

-------------------------------------------------------------------------------
-- 1) CrearUsuario: caso normal
-------------------------------------------------------------------------------
PRINT 'Caso normal 1: crear usuario Juan';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '12345678',
    @nombre        = 'Juan',
    @apellido      = 'Perez',
    @email         = 'juan.perez@example.com',
    @fecha_nac     = '1985-05-05',
    @telefono      = '555111222',
    @username      = 'juanperez',
    @password_hash = 'hash1';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 2: crear usuario Luis';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '9876543',
    @nombre        = 'Luis',
    @apellido      = 'Mandioca',
    @email         = 'luis.mandioca@example.com',
    @fecha_nac     = '1985-05-05',
    @telefono      = '333333333',
    @username      = 'luismandioca',
    @password_hash = 'hash2';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 3: crear usuario Mario';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '12312231',
    @nombre        = 'Mario',
    @apellido      = 'Cata�eda',
    @email         = 'mario.casta@example.com',
    @fecha_nac     = '1985-05-05',
    @telefono      = '6666666666',
    @username      = 'XXmarioCasXX',
    @password_hash = 'hash3';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 4: crear usuario Laura';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '22334455',
    @nombre        = 'Laura',
    @apellido      = 'Gonz�lez',
    @email         = 'laura.gonzalez@example.com',
    @fecha_nac     = '1990-08-12',
    @telefono      = '1162349876',
    @username      = 'lauraG90',
    @password_hash = 'hash4';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 5: crear usuario Pablo';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '33445566',
    @nombre        = 'Pablo',
    @apellido      = 'Mart�nez',
    @email         = 'pablo.martinez@example.com',
    @fecha_nac     = '1982-03-22',
    @telefono      = '1155558888',
    @username      = 'pabMart82',
    @password_hash = 'hash5';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 6: crear usuario Julieta';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '44556677',
    @nombre        = 'Julieta',
    @apellido      = 'Rodr�guez',
    @email         = 'julieta.rod@example.com',
    @fecha_nac     = '1995-10-15',
    @telefono      = '1177889900',
    @username      = 'julRod95',
    @password_hash = 'hash6';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 7: crear usuario Ernesto';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '55667788',
    @nombre        = 'Ernesto',
    @apellido      = 'L�pez',
    @email         = 'ernesto.lopez@example.com',
    @fecha_nac     = '1979-12-01',
    @telefono      = '1199990000',
    @username      = 'ernLo79',
    @password_hash = 'hash7';
-- Esperado: OK, Usuario creado correctamente.


-------------------------------------------------------------------------------
-- 1b) CrearUsuario: otro usuario para duplicados
-------------------------------------------------------------------------------
PRINT 'Caso normal 2: crear usuario Maria';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '22223333',
    @nombre        = 'Maria',
    @apellido      = 'Gomez',
    @email         = 'maria.gomez@example.com',
    @fecha_nac     = '1992-02-02',
    @telefono      = '555444555',
    @username      = 'mariagomez',
    @password_hash = 'hash2';
-- Esperado: OK, Usuario creado correctamente.

SELECT @uid2 = id_usuario 
  FROM usuarios.usuario 
 WHERE username = 'mariagomez';

-------------------------------------------------------------------------------
-- 2) CrearUsuario: duplicado de username
-------------------------------------------------------------------------------
PRINT 'Username duplicado';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '33334444',
    @nombre        = 'Luis',
    @apellido      = 'Lopez',
    @email         = 'luis.lopez@example.com',
    @fecha_nac     = '1990-01-01',
    @telefono      = '555333444',
    @username      = 'juanperez',   -- ya existe Juan
    @password_hash = 'hash3';
-- Esperado: Error, Ya existe un usuario con ese username.

-------------------------------------------------------------------------------
-- 3) CrearUsuario: username vac�o
-------------------------------------------------------------------------------
PRINT 'Username vac�o';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '44445555',
    @nombre        = 'Ana',
    @apellido      = 'Ruiz',
    @email         = 'ana.ruiz@example.com',
    @fecha_nac     = '1991-03-03',
    @telefono      = '555666777',
    @username      = '',
    @password_hash = 'hash4';
-- Esperado: Error, El username es obligatorio.

-------------------------------------------------------------------------------
-- 4) CrearUsuario: password_hash vac�o
-------------------------------------------------------------------------------
PRINT 'Password_hash vac�o';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '55556666',
    @nombre        = 'Pedro',
    @apellido      = 'Diaz',
    @email         = 'pedro.diaz@example.com',
    @fecha_nac     = '1988-04-04',
    @telefono      = '555888999',
    @username      = 'pedrodiaz',
    @password_hash = '';
-- Esperado: Error, El password_hash es obligatorio.

-------------------------------------------------------------------------------
-- EliminarUsuario (antes de inactivar)
-------------------------------------------------------------------------------
PRINT 'EliminarUsuario: caso normal';
EXEC usuarios.EliminarUsuario
    @id_usuario = @uid2;  -- borramos a Maria
-- Esperado: OK, Usuario dado de baja correctamente.

PRINT 'EliminarUsuario: id inexistente';
EXEC usuarios.EliminarUsuario
    @id_usuario = 99999;
-- Esperado: Error, Usuario no encontrado.

-------------------------------------------------------------------------------
-- ModificarUsuario
-------------------------------------------------------------------------------
PRINT 'ModificarUsuario: cambiar username v�lido';
EXEC usuarios.ModificarUsuario
    @id_usuario = @uid1,
    @username   = 'juanperez2';
-- Esperado: OK, Usuario modificado correctamente.

PRINT 'ModificarUsuario: username duplicado';
EXEC usuarios.ModificarUsuario
    @id_usuario = @uid1,
    @username   = 'mariagomez';   -- el username de Maria a�n est� en BD (aunque inactivo)
-- Esperado: Error, Ya existe un usuario con ese username.

PRINT 'ModificarUsuario: cambiar password_hash';
EXEC usuarios.ModificarUsuario
    @id_usuario    = @uid1,
    @password_hash = 'nuevohash';
-- Esperado: OK, Usuario modificado correctamente.

PRINT 'ModificarUsuario: cambiar estado a inactivo';
EXEC usuarios.ModificarUsuario
    @id_usuario = @uid1,
    @estado     = 0;
-- Esperado: OK, Usuario modificado correctamente.

PRINT 'ModificarUsuario: usuario no existe';
EXEC usuarios.ModificarUsuario
    @id_usuario = 99999,
    @username   = 'ghost';
-- Esperado: Error, Usuario no encontrado.

-------------------------------------------------------------------------------
-- Limpieza manual de todo lo creado
-------------------------------------------------------------------------------
PRINT 'Limpieza: borrando datos de prueba';
DELETE FROM usuarios.usuario
 WHERE id_usuario IN (@uid1, @uid2);

DELETE FROM usuarios.persona
 WHERE dni IN ('12345678','22223333','33334444','44445555','55556666');

GO

PRINT 'Limpieza: reseteando identity';
DBCC CHECKIDENT('usuarios.usuario',  RESEED, 0);
DBCC CHECKIDENT('usuarios.persona',  RESEED, 0);
GO

select * 
from usuarios.usuario
GO
