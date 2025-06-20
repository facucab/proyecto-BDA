-- Prueba SP de crear socio

USE Com5600G01;
GO

-- Casos validos
EXEC manejo_personas.CrearPersona '12345678', 'Ana',    'López',   'ana@example.com',     '1990-01-01', '1111111111';
EXEC manejo_personas.CrearPersona '23456789', 'Bruno',  'Pérez',   'bruno@correo.com',     '1985-05-15', '2222222222';
EXEC manejo_personas.CrearPersona '34567890', 'Carla',  'Sosa',    'carla@mail.org',       '1970-07-22', '3333333333';
EXEC manejo_personas.CrearPersona '45678901', 'Diego',  'Gómez',   'diego@domain.net',     '2000-12-30', '4444444444';
EXEC manejo_personas.CrearPersona '56789012', 'Elena',  'Ruiz',    'elena@email.com',      '1995-03-10', '5555555555';
EXEC manejo_personas.CrearPersona '67890123', 'Facundo','Fernández','facu@ejemplo.com',   '1980-08-08', '6666666666';
EXEC manejo_personas.CrearPersona '78901234', 'Gisela', 'Martínez','gisela@web.ar',        '2005-04-04', '7777777777';
EXEC manejo_personas.CrearPersona '89012345', 'Hugo',   'Luna',    'hugo@dominio.com',     '1993-11-11', '8888888888';
EXEC manejo_personas.CrearPersona '90123456', 'Ivana',  'Acosta',  'ivana@xmail.com',      '1988-09-09', '9999999999';
EXEC manejo_personas.CrearPersona '91234567', 'Jorge',  'Méndez',  'jorge@foo.org',        '1978-06-06', '1010101010';

-- DNI invalido (menos de 7 digitos)
EXEC manejo_personas.CrearPersona '123456', 'Error', 'DniCorto', 'valid@dom.com', '1990-01-01', '1000000000';

-- DNI invalido (más de 8 digitos)
EXEC manejo_personas.CrearPersona '123456789', 'Error', 'DniLargo', 'valid@dom.com', '1990-01-01', '1000000001';

-- DNI invalido (no numerico)
EXEC manejo_personas.CrearPersona 'ABC12345', 'Error', 'DniTexto', 'valid@dom.com', '1990-01-01', '1000000002';

-- Email invalido (sin @)
EXEC manejo_personas.CrearPersona '11223344', 'Error', 'Email1', 'email.com', '1990-01-01', '1000000003';

-- Email invalido (sin punto)
EXEC manejo_personas.CrearPersona '22334455', 'Error', 'Email2', 'correo@dominio', '1990-01-01', '1000000004';

-- Email invalido (sin dominio final)
EXEC manejo_personas.CrearPersona '33445566', 'Error', 'Email3', 'user@com.', '1990-01-01', '1000000005';

-- Fecha invalida (futuro)
EXEC manejo_personas.CrearPersona '44556677', 'Error', 'Futuro', 'valido@ok.com', '2100-01-01', '1000000006';

-- Fecha invalida (mayor a 120 años)
EXEC manejo_personas.CrearPersona '55667788', 'Error', 'Anciano', 'valido@ok.com', '1900-01-01', '1000000007';

-- DNI duplicado (ya usado arriba)
EXEC manejo_personas.CrearPersona '12345678', 'Error', 'DuplicadoDni', 'nuevo@ok.com', '1990-01-01', '1000000008';

-- Email duplicado (ya usado arriba)
EXEC manejo_personas.CrearPersona '66778899', 'Error', 'DuplicadoEmail', 'ana@example.com', '1990-01-01', '1000000009';

-- Modificacion valida: cambiar nombre y telefono (persona 1)
EXEC manejo_personas.ModificarPersona
    @id_persona = 1,
    @nombre = 'Analia',
    @telefono = '123123123';

-- Modificacion valida: solo email (persona 2)
EXEC manejo_personas.ModificarPersona
    @id_persona = 2,
    @email = 'nuevo.email@correo.com';

-- Modificacion valida: solo apellido (persona 3)
EXEC manejo_personas.ModificarPersona
    @id_persona = 3,
    @apellido = 'Actualizado';

-- Error: persona no existe
EXEC manejo_personas.ModificarPersona
    @id_persona = 99999,
    @nombre = 'Inexistente';

-- Error: email invalido
EXEC manejo_personas.ModificarPersona
    @id_persona = 1,
    @email = 'emailinvalido';

-- Error: email en uso por otra persona (persona 1 quiere usar email de persona 2)
EXEC manejo_personas.ModificarPersona
    @id_persona = 1,
    @email = 'nuevo.email@correo.com'; -- ya lo tiene persona 2

-- Eliminacion valida (persona 4)
EXEC manejo_personas.EliminarPersona
    @id_persona = 4;

-- Error: persona ya eliminada (persona 4 nuevamente)
EXEC manejo_personas.EliminarPersona
    @id_persona = 4;

-- Error: persona no existe
EXEC manejo_personas.EliminarPersona
    @id_persona = 99999;


