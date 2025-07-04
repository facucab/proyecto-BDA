USE Com5600G01;
GO

/*
	Entrega 4 - Pruebas para Crear, Modificar y Eliminar Invitado

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Ruben 
	45234709 | Gauto, Gaston Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomas Andres
*/

DECLARE 
    @pidSocio   INT,     -- para crear socios
    @sid1       INT,     -- primer socio invitador
    @sid2       INT,     -- segundo socio (reasignacion)
    @pidInv     INT,     -- persona invitada
    @iid1       INT;     -- id_invitado

-------------------------------------------------------------------------------
-- 0) Crear categoria  (para que CrearSocio funcione)
-------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = 1)
BEGIN
    INSERT INTO actividades.categoria (nombre_categoria, costo_membrecia, vigencia)
    VALUES ('CatPrueba', 10.00, DATEADD(year,1,GETDATE()));
END;

-------------------------------------------------------------------------------
-- 1) Preparacion: crear dos socios de prueba
-------------------------------------------------------------------------------

-- Socio 1
EXEC usuarios.CrearPersona
    @dni        = '11111111',
    @nombre     = 'Socio',
    @apellido   = 'Uno',
    @email      = 'socio.uno@example.com',
    @fecha_nac  = '1980-01-01',
    @telefono   = '100200300',
    @id_persona = @pidSocio OUTPUT;

EXEC usuarios.CrearSocio
    @id_persona          = @pidSocio,
    @dni                 = '11111111',
    @nombre              = 'Socio',
    @apellido            = 'Uno',
    @email               = 'socio.uno@example.com',
    @fecha_nac           = '1980-01-01',
    @telefono            = '100200300',
    @numero_socio        = 'S001',
    @id_categoria        = 1;  
SELECT @sid1 = id_socio FROM usuarios.socio WHERE numero_socio = 'S001';

-- Socio 2 (para reasignar)
EXEC usuarios.CrearPersona
    @dni        = '22222222',
    @nombre     = 'Socio',
    @apellido   = 'Dos',
    @email      = 'socio.dos@example.com',
    @fecha_nac  = '1981-02-02',
    @telefono   = '200300400',
    @id_persona = @pidSocio OUTPUT;

EXEC usuarios.CrearSocio
    @id_persona          = @pidSocio,
    @dni                 = '22222222',
    @nombre              = 'Socio',
    @apellido            = 'Dos',
    @email               = 'socio.dos@example.com',
    @fecha_nac           = '1981-02-02',
    @telefono            = '200300400',
    @numero_socio        = 'S002',
    @id_categoria        = 1;
SELECT @sid2 = id_socio FROM usuarios.socio WHERE numero_socio = 'S002';

-------------------------------------------------------------------------------
-- 2) CrearInvitado
-------------------------------------------------------------------------------

PRINT 'Caso normal: crear invitado con nueva persona';
EXEC usuarios.CrearInvitado
    @id_persona = NULL,
    @dni        = '33333333',
    @nombre     = 'Invitado',
    @apellido   = 'Uno',
    @email      = 'invitado.uno@example.com',
    @fecha_nac  = '1995-03-03',
    @telefono   = '300400500',
    @id_socio   = @sid1;
SELECT 
    @pidInv = p.id_persona,
    @iid1   = i.id_invitado
  FROM usuarios.persona AS p
  JOIN usuarios.invitado AS i ON i.id_persona = p.id_persona
 WHERE p.dni = '33333333';

PRINT 'Error duplicado: misma persona';
EXEC usuarios.CrearInvitado
    @id_persona = @pidInv,  -- ahora si el id_persona correcto
    @id_socio   = @sid1;
-- Esperado: Error, La persona ya esta invitada.

PRINT 'Error: falta datos para crear persona';
EXEC usuarios.CrearInvitado
    @id_persona = NULL,
    @dni        = NULL,
    @id_socio   = @sid1;
-- Esperado: Error, Faltan datos de persona para crearla.

PRINT 'Error: socio no existe';
EXEC usuarios.CrearInvitado
    @id_persona = NULL,
    @dni        = '44444444',
    @nombre     = 'Invitado',
    @apellido   = 'Dos',
    @email      = 'invitado.dos@example.com',
    @fecha_nac  = '1996-04-04',
    @telefono   = '400500600',
    @id_socio   = 99999;
-- Esperado: Error, Socio no encontrado.

-------------------------------------------------------------------------------
-- 3) ModificarInvitado
-------------------------------------------------------------------------------

PRINT 'ModificarInvitado: cambiar datos de persona';
EXEC usuarios.ModificarInvitado
    @id_invitado = @iid1,
    @nombre      = 'InvitadoMod',
    @email       = 'invitado.mod@example.com';
-- Esperado: OK, Invitado modificado correctamente.

PRINT 'ModificarInvitado: reasignar a otro socio';
EXEC usuarios.ModificarInvitado
    @id_invitado  = @iid1,
    @new_id_socio = @sid2;
-- Esperado: OK, Invitado modificado correctamente.

PRINT 'Error: invitado no existe';
EXEC usuarios.ModificarInvitado
    @id_invitado  = 99999,
    @nombre       = 'X';
-- Esperado: Error, Invitado no encontrado.

-------------------------------------------------------------------------------
-- 4) EliminarInvitado
-------------------------------------------------------------------------------

PRINT 'EliminarInvitado: caso normal';
EXEC usuarios.EliminarInvitado
    @id_invitado = @iid1;
-- Esperado: OK, Invitado y persona eliminados correctamente.

PRINT 'Error: id inexistente';
EXEC usuarios.EliminarInvitado
    @id_invitado = 99999;
-- Esperado: Error, Invitado no encontrado.

-------------------------------------------------------------------------------
-- 5) Limpieza manual de todo lo creado
-------------------------------------------------------------------------------

PRINT 'Limpieza: borrando datos de prueba';
DELETE FROM usuarios.invitado WHERE id_invitado = @iid1;
DELETE FROM usuarios.socio   WHERE id_socio   IN (@sid1, @sid2);
DELETE FROM usuarios.persona WHERE dni IN ('11111111','22222222','33333333','44444444');
DELETE FROM actividades.categoria WHERE nombre_categoria = 'CatPrueba';

PRINT 'Limpieza: reseteando identity';
DBCC CHECKIDENT('usuarios.invitado', RESEED, 0);
DBCC CHECKIDENT('usuarios.socio',   RESEED, 0);
DBCC CHECKIDENT('usuarios.persona', RESEED, 0);
DBCC CHECKIDENT('actividades.categoria', RESEED, 0);
GO