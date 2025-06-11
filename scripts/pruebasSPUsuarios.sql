/*
	Entrega 4 - Documento de instalaci�n y configuraci�n

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rub�n 
	45234709 | Gauto, Gast�n Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tom�s Andr�s

		Luego de decidirse por un motor de base de datos relacional, lleg� el momento de generar la
	base de datos. En esta oportunidad utilizar�n SQL Server.
	Deber� instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicaci�n de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregar�a al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deber� entregar
	un archivo .sql con el script completo de creaci�n (debe funcionar si se lo ejecuta �tal cual� es
	entregado en una sola ejecuci�n). Incluya comentarios para indicar qu� hace cada m�dulo
	de c�digo.
	Genere store procedures para manejar la inserci�n, modificado, borrado (si corresponde,
	tambi�n debe decidir si determinadas entidades solo admitir�n borrado l�gico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con �SP�.
	Algunas operaciones implicar�n store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Aseg�rense de que los comentarios que acompa�en al c�digo lo expliquen.
	Genere esquemas para organizar de forma l�gica los componentes del sistema y aplique esto
	en la creaci�n de objetos. NO use el esquema �dbo�.
	Todos los SP creados deben estar acompa�ados de juegos de prueba. Se espera que
	realicen validaciones b�sicas en los SP (p/e cantidad mayor a cero, CUIT v�lido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicaci�n de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, n�mero de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la secci�n de pr�cticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
*/

--Pruebas usuario

--Creacion

--Casos Normales
-- Pruebas CrearUsuario
EXEC manejo_personas.CrearUsuario 
	@id_persona = 1,
	@username = 'usuario1',
	@password_hash = 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
	@fecha_alta_contra = '2024-01-15';
EXEC manejo_personas.CrearUsuario 
	@id_persona = 2,
	@username = 'usuario2',
	@password_hash = 'b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: Usuario creado correctamente

-- ID persona nulo
EXEC manejo_personas.CrearUsuario 
	@id_persona = NULL,
	@username = 'usuario3',
	@password_hash = 'c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3c665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: id_persona nulo

-- Username nulo
EXEC manejo_personas.CrearUsuario 
	@id_persona = 3,
	@username = NULL,
	@password_hash = 'd665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3d665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3d665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3d665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: username nulo

-- Password hash nulo
EXEC manejo_personas.CrearUsuario 
	@id_persona = 4,
	@username = 'usuario4',
	@password_hash = NULL;
-- Resultado: password_hash nulo

-- Password hash con menos de 256 caracteres
EXEC manejo_personas.CrearUsuario 
	@id_persona = 5,
	@username = 'usuario5',
	@password_hash = 'hashcorto';
-- Resultado: password_hash debe tener 256 caracteres

-- Password hash con m�s de 256 caracteres
EXEC manejo_personas.CrearUsuario 
	@id_persona = 6,
	@username = 'usuario6',
	@password_hash = 'e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3e665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3extra';
-- Resultado: password_hash debe tener 256 caracteres

-- Persona inexistente
EXEC manejo_personas.CrearUsuario 
	@id_persona = 99999,
	@username = 'usuario_inexistente',
	@password_hash = 'f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3f665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: La persona especificada no existe

-- Persona que ya tiene usuario
EXEC manejo_personas.CrearUsuario 
	@id_persona = 1,
	@username = 'usuario_duplicado',
	@password_hash = '1665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae31665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae31665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae31665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: La persona ya tiene un usuario asignado

-- Username ya en uso
EXEC manejo_personas.CrearUsuario 
	@id_persona = 7,
	@username = 'usuario1',
	@password_hash = '2665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae32665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae32665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae32665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
-- Resultado: El nombre de usuario ya esta en uso

--Modificacion

-- Caso normal 
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@username = 'nuevo_usuario1';

EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@password_hash = 'a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3a775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';

EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@fecha_alta_contra = '2024-02-15';

EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 2,
	@username = 'usuario_completo',
	@password_hash = 'b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3b775a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
	@fecha_alta_contra = '2024-03-10';
-- Resultado: Usuario modificado correctamente

-- ID usuario nulo
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = NULL,
	@username = 'test_usuario';
-- Resultado: id_usuario nulo

-- Usuario inexistente
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 99999,
	@username = 'usuario_inexistente';
-- Resultado: El usuario especificado no existe

-- Username ya en uso por otro usuario
EXEC manejo_personas.ModificarUsuario 
	@id_usuario = 1,
	@username = 'usuario2';
-- Resultado: El nombre de usuario ya esta en uso por otro usuario

--Eliminacion

--Casos Normales
EXEC manejo_personas.EliminarUsuario @id_usuario =1;
EXEC manejo_personas.EliminarUsuario @id_usuario =2;
EXEC manejo_personas.EliminarUsuario @id_usuario =3;
--Resultados: Usuario borrado, persona inactivada

--Id null
EXEC manejo_personas.EliminarUsuario @id_usuario =NULL;
--Resultado: id_usuario nulo

--Id inexistente
EXEC manejo_personas.EliminarUsuario @id_usuario =9;
--Resultado: El usuario especificado no existe

--Clases asignadas
EXEC manejo_personas.EliminarUsuario @id_usuario =12;
--Resultado: No se puede eliminar el usuario porque tiene clases asignadas