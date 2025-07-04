
USE Com5600G01; 

-- TEST CREAR PERSONA: 
-- Caso OK:
GO
DECLARE @id_persona INT;
EXEC usuarios.CrearPersona 
    @dni = '12345678',
    @nombre = 'Juan',
    @apellido = 'Pérez',
    @email = 'juan.perez@mail.com',
    @fecha_nac = '1990-05-15',
    @telefono = '1123456789',
    @id_persona = @id_persona OUTPUT;
-- Resultado esperado: La persona se crea
GO
--  DNI inválido 
EXEC usuarios.CrearPersona 
    @dni = '123456',
    @nombre = 'Laura',
    @apellido = 'Gomez',
    @email = 'laura@mail.com',
    @fecha_nac = '1985-01-01',
    @telefono = '1133334444',
    @id_persona = NULL;
-- Resultado esperado: DNI invalido
GO
-- Email inválido
EXEC usuarios.CrearPersona 
    @dni = '87654321',
    @nombre = 'Carlos',
    @apellido = 'Lopez',
    @email = 'carlosmail.com',
    @fecha_nac = '1991-06-01',
    @telefono = '1144445555',
    @id_persona = NULL;
-- Resultado esperado: EMAIl invalido
GO
-- Fecha de nacimiento futura
EXEC usuarios.CrearPersona 
    @dni = '12345679',
    @nombre = 'Ana',
    @apellido = 'Martinez',
    @email = 'ana@mail.com',
    @fecha_nac = '2100-01-01',
    @telefono = '1177778888',
    @id_persona = NULL;
-- Resultado esperado: fECHA DE NACIMIENTO INCORRECTA
GO
-- Teléfono vacío
EXEC usuarios.CrearPersona 
    @dni = '12345680',
    @nombre = 'Mauro',
    @apellido = 'Ibarra',
    @email = 'mauro@mail.com',
    @fecha_nac = '1980-08-08',
    @telefono = '',
    @id_persona = NULL;
-- Resultado esperado: Telefono obligatorio

-- TEST MODIFICAR PERSONA: 
GO
-- Caso OK: 
DECLARE @id_modificar INT;
EXEC usuarios.CrearPersona 
    @dni = '45678901',
    @nombre = 'Diego',
    @apellido = 'Fernandez',
    @email = 'diego@mail.com',
    @fecha_nac = '1982-04-03',
    @telefono = '1199991111',
    @id_persona = @id_modificar OUTPUT;

EXEC usuarios.ModificarPersona 
    @id_persona = @id_modificar,
    @nombre = 'Diego Alberto',
    @apellido = 'Fernandez',
    @email = 'diego.alberto@mail.com',
    @fecha_nac = '1982-04-03',
    @telefono = '1199990000';
-- Resultado Esperado: OK

-- Persona inexistente
EXEC usuarios.ModificarPersona 
    @id_persona = -1,
    @nombre = 'X',
    @apellido = 'Y',
    @email = 'x@y.com',
    @fecha_nac = '1990-01-01',
    @telefono = '1111111111';
-- Resultado Esperado: OKLa persona no fue encontrada

-- Email inválido
EXEC usuarios.ModificarPersona 
    @id_persona = @id_modificar,
    @nombre = 'Diego',
    @apellido = 'Fernandez',
    @email = 'emailmalo.com',
    @fecha_nac = '1982-04-03',
    @telefono = '1122334455';
-- Resultado esperado: EMAIl invalido

-- Fecha futura
EXEC usuarios.ModificarPersona 
    @id_persona = @id_modificar,
    @nombre = 'Diego',
    @apellido = 'Fernandez',
    @email = 'nuevo@mail.com',
    @fecha_nac = '2050-01-01',
    @telefono = '1122334455';
-- Resultado esperado: Fecha de  nacimiento incorrecta

--- ELIMINAR Persona: 
-- Caso OK: 
GO
DECLARE @id_borrar INT = 1;
EXEC usuarios.EliminarPersona @id_persona = @id_borrar;
-- Resultado Esperado: OK 

-- Persona ya eliminada
EXEC usuarios.EliminarPersona @id_persona = @id_borrar;
-- Resultado Esperado: La persona no fue encontrada


