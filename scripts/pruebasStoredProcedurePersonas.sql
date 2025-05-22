-- PRUEBAS
-- CREAR PERSONA:

-- Caso normal
EXEC manejo_personas.CrearPersona
  @dni = '12345678',
  @nombre = N'Juan',
  @apellido = N'Pérez',
  @email = 'juan.perez@email.com',
  @fecha_nac = '1990-05-20',
  @telefono = '123456789';

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
