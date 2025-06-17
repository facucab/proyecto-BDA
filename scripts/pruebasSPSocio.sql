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
USE Com5600G01;
GO

-- TEST STORED PROCEDURE CrearSocio:

-- Casos normales 
EXEC manejo_personas.CrearSocio
    @id_persona = 1,
    @nro_socio = 'SN-0001',
    @telefono_emergencia = '11112222',
    @id_categoria = 1; -- Éxito

EXEC manejo_personas.CrearSocio
    @id_persona = 2,
    @nro_socio = 'SN-0002',
    @telefono_emergencia = '22223333',
    @obra_nro_socio = '123456',
    @id_obra_social = 1,
    @id_categoria = 2; -- Éxito

EXEC manejo_personas.CrearSocio
    @id_persona = 3,
    @nro_socio = 'SN-0003',
    @telefono_emergencia = '33334444',
    @id_categoria = 3,
    @id_grupo = 1; -- Éxito

-- Persona no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 99999,
    @nro_socio = 'SN-0004',
    @telefono_emergencia = '44445555',
    @id_categoria = 3; -- Error: persona no existe

-- Persona inactiva
EXEC manejo_personas.CrearSocio
    @id_persona = 4,
    @nro_socio = 'SN-0005',
    @telefono_emergencia = '55556666',
    @id_categoria = 3; -- Error: persona inactiva

-- Persona ya es socio
EXEC manejo_personas.CrearSocio
    @id_persona = 1,
    @nro_socio = 'SN-0006',
    @telefono_emergencia = '66667777',
    @id_categoria = 1; -- Error: ya es socio

-- Categoría no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @nro_socio = 'SN-0007',
    @telefono_emergencia = '77778888',
    @id_categoria = 99; -- Error

-- Obra social no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @nro_socio = 'SN-0008',
    @telefono_emergencia = '88889999',
    @id_obra_social = 99,
    @id_categoria = 3; -- Error

-- Grupo familiar no existe
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @nro_socio = 'SN-0009',
    @telefono_emergencia = '99990000',
    @id_grupo = 99,
    @id_categoria = 3; -- Error

-- Grupo familiar inactivo
EXEC manejo_personas.CrearSocio
    @id_persona = 5,
    @nro_socio = 'SN-0010',
    @telefono_emergencia = '00001111',
    @id_grupo = 2,
    @id_categoria = 3; -- Error

-- Edad incorrecta para Menor (demasiado mayor)
EXEC manejo_personas.CrearSocio
    @id_persona = 7,
    @nro_socio = 'SN-0011',
    @telefono_emergencia = '11110000',
    @id_categoria = 1; -- Error

-- Edad incorrecta para Cadete (muy joven)
EXEC manejo_personas.CrearSocio
    @id_persona = 6,
    @nro_socio = 'SN-0012',
    @telefono_emergencia = '00009999',
    @id_categoria = 2; -- Error

-- Edad incorrecta para Mayor (muy joven)
EXEC manejo_personas.CrearSocio
    @id_persona = 6,
    @nro_socio = 'SN-0013',
    @telefono_emergencia = '99998888',
    @id_categoria = 3; -- Error

-- Formato inválido de numero de socio
EXEC manejo_personas.CrearSocio
    @id_persona = 8,
    @nro_socio = 'INVALID',
    @telefono_emergencia = '11112222',
    @id_categoria = 1; -- Error: formato inválido

-- Número de socio duplicado
EXEC manejo_personas.CrearSocio
    @id_persona = 9,
    @nro_socio = 'SN-0001',
    @telefono_emergencia = '11112222',
    @id_categoria = 1; -- Error: numero de socio ya en uso


