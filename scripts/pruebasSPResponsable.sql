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

	Pruebas para Crear, Modificar y Eliminar Responsable
*/

-- Preparación de datos previos
DECLARE @gid1 INT, @pidPrep INT, @rid1 INT, @pid2 INT;

INSERT INTO usuarios.grupo_familiar(fecha_alta, estado)
VALUES (GETDATE(), 1);
SET @gid1 = SCOPE_IDENTITY();

EXEC usuarios.CrearPersona
  @dni        = '55544433',
  @nombre     = 'Prep',
  @apellido   = 'Prueba',
  @email      = 'prep.prueba@example.com',
  @fecha_nac  = '1990-10-10',
  @telefono   = '123123123',
  @id_persona = @pidPrep OUTPUT;

-------------------------------------------------------------------------------
-- CrearResponsable
-------------------------------------------------------------------------------

PRINT 'Caso normal 1: crea persona + responsable';
EXEC usuarios.CrearResponsable
  @id_persona = @pidPrep,
  @dni        = '55544433',
  @nombre     = 'Prep',
  @apellido   = 'Prueba',
  @email      = 'prep.prueba@example.com',
  @fecha_nac  = '1990-10-10',
  @telefono   = '123123123',
  @id_grupo   = @gid1,
  @parentesco = 'Madre';
-- Resultado esperado: OK, Responsable creado correctamente.

-- Capturar id_responsable
SELECT @rid1 = id_responsable
  FROM usuarios.responsable
 WHERE id_persona = @pidPrep;

PRINT 'Caso normal 2: duplicado de persona';
EXEC usuarios.CrearResponsable
  @id_persona = @pidPrep,
  @dni        = '55544433',
  @nombre     = 'Prep',
  @apellido   = 'Prueba',
  @email      = 'prep.prueba@example.com',
  @fecha_nac  = '1990-10-10',
  @telefono   = '123123123',
  @id_grupo   = @gid1,
  @parentesco = 'Padre';
-- Resultado esperado: Error, La persona ya es responsable de otro grupo.

PRINT 'Persona no existe';
EXEC usuarios.CrearResponsable
  @id_persona = 99999,
  @dni        = '00000000',
  @nombre     = 'X',
  @apellido   = 'Y',
  @email      = 'x.y@example.com',
  @fecha_nac  = '2000-01-01',
  @telefono   = '000000000',
  @id_grupo   = @gid1,
  @parentesco = 'Tutor';
-- Resultado esperado: Error, La persona a reasignar no existe y no hay datos para crearla.

PRINT 'Grupo no existe';
EXEC usuarios.CrearResponsable
  @id_persona = @pidPrep,
  @dni        = '55544433',
  @nombre     = 'Prep',
  @apellido   = 'Prueba',
  @email      = 'prep.prueba@example.com',
  @fecha_nac  = '1990-10-10',
  @telefono   = '123123123',
  @id_grupo   = 88888,
  @parentesco = 'Madre';
-- Resultado esperado: Error, Grupo familiar no encontrado.

PRINT 'Parentesco vacío';
EXEC usuarios.CrearResponsable
  @id_persona = @pidPrep,
  @dni        = '55544433',
  @nombre     = 'Prep',
  @apellido   = 'Prueba',
  @email      = 'prep.prueba@example.com',
  @fecha_nac  = '1990-10-10',
  @telefono   = '123123123',
  @id_grupo   = @gid1,
  @parentesco = '';
-- Resultado esperado: Error, El parentesco es obligatorio.

-------------------------------------------------------------------------------
-- ModificarResponsable
-------------------------------------------------------------------------------

PRINT 'ModificarResponsable: cambiar parentesco';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @parentesco     = 'Tutor';
-- Resultado esperado: OK, Responsable modificado correctamente.

PRINT 'ModificarResponsable: grupo inexistente';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @new_id_grupo   = 77777;
-- Resultado esperado: Error, Grupo familiar no encontrado.

PRINT 'ModificarResponsable: parentesco vacío';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @parentesco     = '';
-- Resultado esperado: Error, El parentesco no puede estar vacío.

PRINT 'ModificarResponsable: cambiar DNI válido';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @dni            = '11223344';
-- Resultado esperado: OK, Responsable modificado correctamente.

PRINT 'ModificarResponsable: cambiar DNI inválido';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @dni            = 'ABC123';
-- Resultado esperado: Error, DNI inválido. Debe contener entre 7 y 8 dígitos numéricos.

PRINT 'Preparar persona para reasignación';
EXEC usuarios.CrearPersona
  @dni        = '22334455',
  @nombre     = 'Reasignar',
  @apellido   = 'Persona',
  @email      = 'reasignar@test.com',
  @fecha_nac  = '1992-02-02',
  @telefono   = '222333222',
  @id_persona = @pid2 OUTPUT;

PRINT 'ModificarResponsable: reasignar persona existente';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @new_id_persona = @pid2;
-- Resultado esperado: OK, Responsable modificado correctamente.

PRINT 'ModificarResponsable: reasignar persona no existe sin datos';
EXEC usuarios.ModificarResponsable
  @id_responsable = @rid1,
  @new_id_persona = 99999;
-- Resultado esperado: Error, La persona a reasignar no existe y no hay datos para crearla.

-------------------------------------------------------------------------------
-- EliminarResponsable
-------------------------------------------------------------------------------

PRINT 'EliminarResponsable: caso normal';
EXEC usuarios.EliminarResponsable
  @id_responsable = @rid1;
-- Resultado esperado: OK, Responsable eliminado correctamente.

PRINT 'EliminarResponsable: id inexistente';
EXEC usuarios.EliminarResponsable
  @id_responsable = 99999;
-- Resultado esperado: Error, Responsable no encontrado.

-- Limpieza manual de todo lo creado
PRINT 'Limpieza: borrando datos de prueba';

-- 1) Eliminar todos los responsables de ese grupo
DELETE FROM usuarios.responsable
 WHERE id_grupo = @gid1;

-- 2) Eliminar las personas de prueba
DELETE FROM usuarios.persona
 WHERE id_persona IN (@pidPrep, @pid2);

-- 3) Eliminar el grupo
DELETE FROM usuarios.grupo_familiar
 WHERE id_grupo_familiar = @gid1;

PRINT 'Limpieza: reseteando identity';
DBCC CHECKIDENT('usuarios.responsable',      RESEED, 0);
DBCC CHECKIDENT('usuarios.persona',          RESEED, 0);
DBCC CHECKIDENT('usuarios.grupo_familiar',   RESEED, 0);
GO