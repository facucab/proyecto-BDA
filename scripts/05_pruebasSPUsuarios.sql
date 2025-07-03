USE Com5600G01;
GO

/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

    Pruebas para Crear, Modificar y Eliminar Usuario
*/

DECLARE @uid1 INT, @uid2 INT;

-------------------------------------------------------------------------------
-- 1) CrearUsuario: caso normal
-------------------------------------------------------------------------------
PRINT 'Caso normal 1: crear usuario Juan';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123456789',
    @nombre        = 'Pablo',
    @apellido      = 'Rodriguez',
    @email         = 'juan.perez@example.com',
    @fecha_nac     = '1985-05-05',
    @telefono      = '555111222',
    @username      = 'juanperez',
    @password_hash = 'hash1';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 2: crear usuario Luis';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '98765439',
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
    @dni           = '123122319',
    @nombre        = 'Mario',
    @apellido      = 'Catañeda',
    @email         = 'mario.casta@example.com',
    @fecha_nac     = '1985-05-05',
    @telefono      = '6666666666',
    @username      = 'XXmarioCasXX',
    @password_hash = 'hash3';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 4: crear usuario Laura';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '223344559',
    @nombre        = 'Laura',
    @apellido      = 'González',
    @email         = 'laura.gonzalez@example.com',
    @fecha_nac     = '1990-08-12',
    @telefono      = '1162349876',
    @username      = 'lauraG90',
    @password_hash = 'hash4';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 5: crear usuario Pablo';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '334455669',
    @nombre        = 'Pablo',
    @apellido      = 'Martínez',
    @email         = 'pablo.martinez@example.com',
    @fecha_nac     = '1982-03-22',
    @telefono      = '1155558888',
    @username      = 'pabMart82',
    @password_hash = 'hash5';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 6: crear usuario Julieta';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '445566779',
    @nombre        = 'Julieta',
    @apellido      = 'Rodríguez',
    @email         = 'julieta.rod@example.com',
    @fecha_nac     = '1995-10-15',
    @telefono      = '1177889900',
    @username      = 'julRod95',
    @password_hash = 'hash6';
-- Esperado: OK, Usuario creado correctamente.

PRINT 'Caso normal 7: crear usuario Ernesto';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '556677889',
    @nombre        = 'Ernesto',
    @apellido      = 'López',
    @email         = 'ernesto.lopez@example.com',
    @fecha_nac     = '1979-12-01',
    @telefono      = '1199990000',
    @username      = 'ernLo79',
    @password_hash = 'hash7';
-- Esperado: OK, Usuario creado correctamente.

-- Caso normal 8: crear usuario Pablo;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122320',
    @nombre        = 'Pablo',
    @apellido      = 'Rodriguez',
    @email         = 'pablo.rodriguez@example.com',
    @fecha_nac     = '1984-04-04',
    @telefono      = '6666666667',
    @username      = 'XXpabloRodXX',
    @password_hash = 'hash8';

-- Caso normal 9: crear usuario Ana Paula;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122321',
    @nombre        = 'Ana Paula',
    @apellido      = 'Alvarez',
    @email         = 'ana.alvarez@example.com',
    @fecha_nac     = '1990-09-09',
    @telefono      = '6666666668',
    @username      = 'XXanaAlvXX',
    @password_hash = 'hash9';

-- Caso normal 10: crear usuario Kito;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122322',
    @nombre        = 'Kito',
    @apellido      = 'Mihaji',
    @email         = 'kito.mihaji@example.com',
    @fecha_nac     = '1992-02-02',
    @telefono      = '6666666669',
    @username      = 'XXkitoMihXX',
    @password_hash = 'hash10';

-- Caso normal 11: crear usuario Carolina;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122323',
    @nombre        = 'Carolina',
    @apellido      = 'Herreta',
    @email         = 'carolina.herreta@example.com',
    @fecha_nac     = '1986-06-06',
    @telefono      = '6666666670',
    @username      = 'XXcaroHerXX',
    @password_hash = 'hash11';

-- Caso normal 12: crear usuario Paula;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122324',
    @nombre        = 'Paula',
    @apellido      = 'Quiroga',
    @email         = 'paula.quiroga@example.com',
    @fecha_nac     = '1991-01-01',
    @telefono      = '6666666671',
    @username      = 'XXpaulaQuiXX',
    @password_hash = 'hash12';

-- Caso normal 13: crear usuario Hector 1;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122325',
    @nombre        = 'Hector',
    @apellido      = 'Alvarez',
    @email         = 'hector.alvarez1@example.com',
    @fecha_nac     = '1983-03-03',
    @telefono      = '6666666672',
    @username      = 'XXhectorAlv1XX',
    @password_hash = 'hash13';

-- Caso normal 14: crear usuario Roxana;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122326',
    @nombre        = 'Roxana',
    @apellido      = 'Guiterrez',
    @email         = 'roxana.guiterrez@example.com',
    @fecha_nac     = '1989-09-09',
    @telefono      = '6666666673',
    @username      = 'XXroxaGuiXX',
    @password_hash = 'hash14';

-- Caso normal 15: crear usuario Hector 2;
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '123122327',
    @nombre        = 'Hector',
    @apellido      = 'Alvarez',
    @email         = 'hector.alvarez2@example.com',
    @fecha_nac     = '1983-03-04',
    @telefono      = '6666666674',
    @username      = 'XXhectorAlv2XX',
    @password_hash = 'hash15';


-------------------------------------------------------------------------------
-- 1b) CrearUsuario: otro usuario para duplicados
-------------------------------------------------------------------------------
PRINT 'Caso normal 2: crear usuario Maria';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '222233339',
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
    @dni           = '333344449',
    @nombre        = 'Luis',
    @apellido      = 'Lopez',
    @email         = 'luis.lopez@example.com',
    @fecha_nac     = '1990-01-01',
    @telefono      = '555333444',
    @username      = 'juanperez',   -- ya existe Juan
    @password_hash = 'hash3';
-- Esperado: Error, Ya existe un usuario con ese username.

-------------------------------------------------------------------------------
-- 3) CrearUsuario: username vacío
-------------------------------------------------------------------------------
PRINT 'Username vacío';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '444455559',
    @nombre        = 'Ana',
    @apellido      = 'Ruiz',
    @email         = 'ana.ruiz@example.com',
    @fecha_nac     = '1991-03-03',
    @telefono      = '555666777',
    @username      = '',
    @password_hash = 'hash4';
-- Esperado: Error, El username es obligatorio.

-------------------------------------------------------------------------------
-- 4) CrearUsuario: password_hash vacío
-------------------------------------------------------------------------------
PRINT 'Password_hash vacío';
EXEC usuarios.CrearUsuario
    @id_persona    = NULL,
    @dni           = '555566669',
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
PRINT 'ModificarUsuario: cambiar username válido';
EXEC usuarios.ModificarUsuario
    @id_usuario = @uid1,
    @username   = 'juanperez2';
-- Esperado: OK, Usuario modificado correctamente.

PRINT 'ModificarUsuario: username duplicado';
EXEC usuarios.ModificarUsuario
    @id_usuario = @uid1,
    @username   = 'mariagomez';   -- el username de Maria aún está en BD (aunque inactivo)
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
 WHERE dni IN ('123456789','222233339','333344449','444455559','555566669');

GO

PRINT 'Limpieza: reseteando identity';
DBCC CHECKIDENT('usuarios.usuario',  RESEED, 0);
DBCC CHECKIDENT('usuarios.persona',  RESEED, 0);
GO

select * 
from usuarios.usuario
GO
