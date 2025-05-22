-- PRUEBAS Personas
-- TEST STORED PROCEDURE CrearPersona:

-- Casos normales
EXEC manejo_personas.CrearPersona
  @dni = '12345678',
  @nombre = N'Juan',
  @apellido = N'Pérez',
  @email = 'juan.perez@email.com',
  @fecha_nac = '1990-05-20',
  @telefono = '123456789';

EXEC manejo_personas.CrearPersona
  @dni = '987654321',
  @nombre = N'Mariano',
  @apellido = N'Diaz',
  @email = 'mariano.diaz@email.com',
  @fecha_nac = '1990-05-20',
  @telefono = '33335555';

EXEC manejo_personas.CrearPersona
  @dni = '987651234',
  @nombre = N'Don Diego',
  @apellido = N'De La Vega',
  @email = 'elzorro@email.com',
  @fecha_nac = '1998-07-17',
  @telefono = '2222222';

-- DNI Invalido (7 digitos)
EXEC manejo_personas.CrearPersona
  @dni = '123456',
  @nombre = N'Laura',
  @apellido = N'Gómez',
  @email = 'laura.gomez@email.com',
  @fecha_nac = '1980-10-10',
  @telefono = '1111111'; -- Resultado: DNI Invalido. Debe contener entre 7 y 8 digitos númericos.

-- Email mal formateado 
EXEC manejo_personas.CrearPersona
  @dni = '23456789',
  @nombre = N'Maria',
  @apellido = N'Rodriguez',
  @email = 'maria.rodriguez.email.com',
  @fecha_nac = '2000-03-25',
  @telefono = '3333333'; -- Resultado: El formato del email no es valido.

-- Fecha Invalida
EXEC manejo_personas.CrearPersona
  @dni = '45678901',
  @nombre = N'Ana',
  @apellido = N'Torres',
  @email = 'ana.torres@email.com',
  @fecha_nac = '2050-01-01',
  @telefono = '5555555'; -- Resultado: La fecha de nacimiento no es valida.

-- Nacimiento mayor a 120 años
EXEC manejo_personas.CrearPersona
  @dni = '56789012',
  @nombre = N'Pedro',
  @apellido = N'Sosa',
  @email = 'pedro.sosa@email.com',
  @fecha_nac = '1900-01-01',
  @telefono = '6666666'; -- Resultado: 


-- TEST STORED PROCEDURE ModificarPersona:

-- Caso normal
EXEC manejo_personas.ModificarPersona
  @id_persona = 1,
  @nombre = N'Carlos',
  @apellido = N'Tevez',
  @email = 'carlos.tevez@email.com',
  @telefono = '123456789'; -- Resultado: Se modifica a Juan Perez exitosamente

-- Persona inexistente (Id muy alto)
EXEC manejo_personas.ModificarPersona
  @id_persona = 9999999,
  @nombre = N'Ignacio'; -- Resultado: La persona no existe

-- Intentar modificar a Carlos Tevez con un email mal formateado
EXEC manejo_personas.ModificarPersona
  @id_persona = 1,
  @email = 'carlos.sanchezemail.com';  -- Resultado: El formato del email no es valido.

-- Email ya en uso (Moidifico a Mario Diaz con el email de Carlos Tevez)
EXEC manejo_personas.ModificarPersona
  @id_persona = 3,
  @email = 'carlos.tevez@email.com'; -- Resultado: El email esta en uso por otra persona.


-- TEST STORED PROCEDURE EliminarPersona:

-- Caso Normal (Elimino al zorro)
EXEC manejo_personas.EliminarPersona @id_persona = 4; -- Resultado: Persona eliminada completamente.

-- Eliminacion Logica
-- PLACE HOLDER, ACA HAY QUE PONER ALGUN ID QUE TENGA DEPENDENCIAS EN OTRA TABLA

-- Eliminar a alguien que no existe
EXEC manejo_personas.EliminarPersona @id_persona = 9999; -- Resultado: La persona no existe
