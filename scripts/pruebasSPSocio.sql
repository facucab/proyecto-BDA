/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

		Luego de decidirse por un motor de base de datos relacional, llegó el momento de generar la
	base de datos. En esta oportunidad utilizarán SQL Server.
	Deberá instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicación de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregaría al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar
	un archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es
	entregado en una sola ejecución). Incluya comentarios para indicar qué hace cada módulo
	de código.
	Genere store procedures para manejar la inserción, modificado, borrado (si corresponde,
	también debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con “SP”.
	Algunas operaciones implicarán store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Asegúrense de que los comentarios que acompañen al código lo expliquen.
	Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto
	en la creación de objetos. NO use el esquema “dbo”.
	Todos los SP creados deben estar acompañados de juegos de prueba. Se espera que
	realicen validaciones básicas en los SP (p/e cantidad mayor a cero, CUIT válido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicación de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la sección de prácticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
*/

-- Pruebas Socio
-- TEST STORED PROCEDURE CrearSocio:

-- Casos normales 
EXEC manejo_personas.CrearSocio
    @id_persona = 1,
    @telefono_emergencia = '11112222',
    @id_categoria = 1; -- Resultado: Socio registrado correctamente

EXEC manejo_personas.CrearSocio
    @id_persona = 2,
    @telefono_emergencia = '22223333',
    @obra_nro_socio = '123456',
    @id_obra_social = 1,
    @id_categoria = 2; -- Resultado: Socio registrado correctamente


EXEC manejo_personas.CrearSocio
    @id_persona = 3,
    @telefono_emergencia = '33334444',
    @id_categoria = 3,
    @id_grupo = 1; -- Resultado: Socio registrado correctamente



-- Persona no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 99999,
    @telefono_emergencia = '44445555',
    @id_categoria = 3; -- Resultado: La persona no existe o está inactiva

-- Persona inactiva
EXEC manejo_personas.CrearSocio
    @id_persona = 4,
    @telefono_emergencia = '55556666',
    @id_categoria = 3; -- Resultado: La persona no existe o está inactiva

-- Persona ya es socio
EXEC manejo_personas.CrearSocio
    @id_persona = 1,
    @telefono_emergencia = '66667777',
    @id_categoria = 1; -- Resultado: La persona ya está registrada como socio

-- Categoría no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '77778888',
    @id_categoria = 99; -- Resultado: La categoría especificada no existe

-- Obra social no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '88889999',
    @id_obra_social = 99,
    @id_categoria = 3; -- Resultado: La obra social especificada no existe

-- Grupo familiar no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '99990000',
    @id_grupo = 99,
    @id_categoria = 3; -- Resultado: El grupo familiar especificado no existe o está inactivo

-- Grupo familiar inactivo
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @telefono_emergencia = '00001111',
    @id_grupo = 2,
    @id_categoria = 3; -- Resultado: El grupo familiar especificado no existe o está inactivo

-- Edad incorrecta para categoría Menor (demasiado mayor)
EXEC manejo_personas.CrearSocio
    @id_persona = 7,
    @telefono_emergencia = '11110000',
    @id_categoria = 1; -- Resultado: La categoría Menor es solo para personas hasta 12 años

-- Edad incorrecta para categoría Cadete (demasiado joven)
EXEC manejo_personas.CrearSocio
    @id_persona = 6,
    @telefono_emergencia = '00009999',
    @id_categoria = 2; -- Resultado: La categoría Cadete es solo para personas entre 13 y 17 años

-- Edad incorrecta para categoría Mayor (demasiado joven)
EXEC manejo_personas.CrearSocio
    @id_persona = 6,
    @telefono_emergencia = '99998888',
    @id_categoria = 3; -- Resultado: La categoría Mayor es solo para personas a partir de 18 años


-- TEST STORED PROCEDURE ModificarSocio:


-- Casos normales
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @telefono_emergencia = '11223344'; -- Resultado: Datos del socio actualizados correctamente

EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_obra_social = 2,
    @obra_nro_socio = '654321'; -- Resultado: Datos del socio actualizados correctamente

EXEC manejo_personas.ModificarSocio
    @id_socio = 2,
    @id_grupo = 1; -- Resultado: Datos del socio actualizados correctamente

EXEC manejo_personas.ModificarSocio
    @id_socio = 3,
    @id_categoria = 3; -- Resultado: Datos del socio actualizados correctamente



-- Socio no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 99999,
    @telefono_emergencia = '99887766'; -- Resultado: El socio no existe

-- Categoría no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_categoria = 99; -- Resultado: La categoría especificada no existe

-- Edad incompatible con categoría Menor
EXEC manejo_personas.ModificarSocio
    @id_socio = 2,
    @id_categoria = 1; -- Resultado: La categoría Menor es solo para personas hasta 12 años

-- Edad incompatible con categoría Cadete
EXEC manejo_personas.ModificarSocio
    @id_socio = 3,
    @id_categoria = 2; -- Resultado: La categoría Cadete es solo para personas entre 13 y 17 años

-- Edad incompatible con categoría Mayor
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_categoria = 3; -- Resultado: La categoría Mayor es solo para personas a partir de 18 años

-- Obra social no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_obra_social = 99; -- Resultado: La obra social especificada no existe

-- Grupo familiar no existe
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_grupo = 99; -- Resultado: El grupo familiar especificado no existe o está inactivo

-- Grupo familiar inactivo
EXEC manejo_personas.ModificarSocio
    @id_socio = 1,
    @id_grupo = 2; -- Resultado: El grupo familiar especificado no existe o está inactivo


-- TEST STORED PROCEDURE EliminarSocio:

-- Caso normal
EXEC manejo_personas.EliminarSocio
    @id_socio = 4; -- Resultado: Socio y todas sus relaciones eliminados completamente del sistema

-- Socio con actividades (se eliminarán las relaciones)
EXEC manejo_personas.EliminarSocio
    @id_socio = 3; -- Resultado: Socio y todas sus relaciones eliminados completamente del sistema

-- Socio con invitados (se eliminarán las relaciones)
EXEC manejo_personas.EliminarSocio
    @id_socio = 5; -- Resultado: Socio y todas sus relaciones eliminados completamente del sistema



-- Socio no existe
EXEC manejo_personas.EliminarSocio
    @id_socio = 99999; -- Resultado: El socio no existe

-- Socio es responsable de un grupo familiar
EXEC manejo_personas.EliminarSocio
    @id_socio = 1; -- Resultado: No se puede eliminar el socio porque es responsable de un grupo familiar

-- Socio tiene facturas asociadas
EXEC manejo_personas.EliminarSocio
    @id_socio = 2; -- Resultado: No se puede eliminar el socio porque tiene facturas asociadas

