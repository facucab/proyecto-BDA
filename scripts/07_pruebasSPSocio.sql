/*
	Entrega 4 - Documento de instalacion y configuracion

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Ruben 
	45234709 | Gauto, Gaston Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomas Andres

	Pruebas para Crear, Modificar y Eliminar Socio
*/

USE Com5600G01;
GO

-- CrearSocio

-- Caso normal 1: crear persona y socio
EXEC usuarios.CrearSocio
	@id_persona          = NULL,
	@dni                 = '12345678',
	@nombre              = 'Juan',
	@apellido            = 'Perez',
	@email               = 'juan.perez@example.com',
	@fecha_nac           = '1990-05-15',
	@telefono            = '123456789',
	@numero_socio        = 'S000001',
	@telefono_emergencia = '987654321',
	@obra_nro_socio      = 'OS123',
	@id_obra_social      = 1,
	@id_categoria        = 1,
	@id_grupo            = 1;
-- Resultado esperado: OK, Socio creado correctamente

-- Caso normal 2: reutilizar persona existente (id_persona = 1), nuevo socio
EXEC usuarios.CrearSocio
	@id_persona          = 1,
	@dni                 = '00000000',  
	@nombre              = 'Ignorado',
	@apellido            = 'Ignorado',
	@email               = 'ignorado@example.com',
	@fecha_nac           = '2000-01-01',
	@telefono            = '000000000',
	@numero_socio        = 'S000002',
	@telefono_emergencia = '111222333',
	@obra_nro_socio      = 'OS124',
	@id_obra_social      = 1,
	@id_categoria        = 1,
	@id_grupo            = 1;
-- Resultado esperado: OK, Socio creado correctamente

-- DNI invalido
EXEC usuarios.CrearSocio
	@id_persona          = NULL,
	@dni                 = 'ABC123',
	@nombre              = 'Ana',
	@apellido            = 'Gomez',
	@email               = 'ana.gomez@example.com',
	@fecha_nac           = '1985-07-20',
	@telefono            = '222333444',
	@numero_socio        = 'S000003',
	@telefono_emergencia = NULL,
	@obra_nro_socio      = NULL,
	@id_obra_social      = NULL,
	@id_categoria        = 1,
	@id_grupo            = NULL;
-- Resultado esperado: Error, DNI invalido. Debe contener entre 7 y 8 digitos numericos.

-- Numero de socio duplicado
EXEC usuarios.CrearSocio
	@id_persona          = NULL,
	@dni                 = '22334455',
	@nombre              = 'Luis',
	@apellido            = 'Martinez',
	@email               = 'luis.martinez@example.com',
	@fecha_nac           = '1992-03-10',
	@telefono            = '555666777',
	@numero_socio        = 'S000001',
	@telefono_emergencia = NULL,
	@obra_nro_socio      = NULL,
	@id_obra_social      = NULL,
	@id_categoria        = 1,
	@id_grupo            = NULL;
-- Resultado esperado: Error, Numero de socio duplicado

-- Obra social inexistente
EXEC usuarios.CrearSocio
	@id_persona          = NULL,
	@dni                 = '33445566',
	@nombre              = 'Maria',
	@apellido            = 'Lopez',
	@email               = 'maria.lopez@example.com',
	@fecha_nac           = '1988-11-05',
	@telefono            = '888999000',
	@numero_socio        = 'S000004',
	@telefono_emergencia = NULL,
	@obra_nro_socio      = NULL,
	@id_obra_social      = 999,
	@id_categoria        = 1,
	@id_grupo            = NULL;
-- Resultado esperado: Error, Obra social no existe

-- Categoria inexistente
EXEC usuarios.CrearSocio
	@id_persona          = NULL,
	@dni                 = '44556677',
	@nombre              = 'Carlos',
	@apellido            = 'Ruiz',
	@email               = 'carlos.ruiz@example.com',
	@fecha_nac           = '1995-09-25',
	@telefono            = '444555666',
	@numero_socio        = 'S000005',
	@telefono_emergencia = NULL,
	@obra_nro_socio      = NULL,
	@id_obra_social      = NULL,
	@id_categoria        = 999,
	@id_grupo            = NULL;
-- Resultado esperado: Error, Categoria no existe

-- Grupo inexistente
EXEC usuarios.CrearSocio
	@id_persona          = NULL,
	@dni                 = '55667788',
	@nombre              = 'Elena',
	@apellido            = 'Diaz',
	@email               = 'elena.diaz@example.com',
	@fecha_nac           = '1993-02-14',
	@telefono            = '777888999',
	@numero_socio        = 'S000006',
	@telefono_emergencia = NULL,
	@obra_nro_socio      = NULL,
	@id_obra_social      = NULL,
	@id_categoria        = 1,
	@id_grupo            = 999;
-- Resultado esperado: Error, Grupo familiar no existe


-- ModificarSocio

-- Caso normal: cambiar numero de socio y telefono de emergencia
EXEC usuarios.ModificarSocio
	@id_socio            = 1,
	@numero_socio        = 'S000010',
	@telefono_emergencia = '999888777';
-- Resultado esperado: OK, Socio modificado correctamente

-- Caso normal: asignar nuevo grupo
EXEC usuarios.ModificarSocio
	@id_socio = 2,
	@id_grupo = 1;
-- Resultado esperado: OK, Socio modificado correctamente

-- Socio inexistente
EXEC usuarios.ModificarSocio
	@id_socio = 99999,
	@numero_socio = 'S000011';
-- Resultado esperado: Error, Socio no encontrado

-- Numero de socio duplicado
EXEC usuarios.ModificarSocio
	@id_socio     = 1,
	@numero_socio = 'S000002';
-- Resultado esperado: Error, Numero de socio duplicado

-- Obra social inexistente
EXEC usuarios.ModificarSocio
	@id_socio       = 1,
	@id_obra_social = 999;
-- Resultado esperado: Error, Obra social no existe

-- Categoria inexistente
EXEC usuarios.ModificarSocio
	@id_socio     = 1,
	@id_categoria = 999;
-- Resultado esperado: Error, Categoria no existe

-- Grupo inexistente
EXEC usuarios.ModificarSocio
	@id_socio = 1,
	@id_grupo = 999;
-- Resultado esperado: Error, Grupo familiar no existe


-- EliminarSocio

-- Caso normal 1
EXEC usuarios.EliminarSocio @id_socio = 1;
-- Resultado esperado: OK, Socio dado de baja correctamente

-- Caso normal 2
EXEC usuarios.EliminarSocio @id_socio = 2;
-- Resultado esperado: OK, Socio dado de baja correctamente

-- Socio inexistente
EXEC usuarios.EliminarSocio @id_socio = 99999;
-- Resultado esperado: Error, Socio no encontrado

-- Intentar baja nuevamente
EXEC usuarios.EliminarSocio @id_socio = 1;
-- Resultado esperado: Error, Socio no encontrado

SELECT * 
FROM usuarios.socio
GO
