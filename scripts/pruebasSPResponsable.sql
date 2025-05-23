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

-- Pruebas Responsable

--Creacion 

--Casos Normales
EXEC manejo_personas.CrearResponsable
    @id_persona =1,
    @parentesco ='Madre',
    @id_grupo =2;
EXEC manejo_personas.CrearResponsable
    @id_persona =7,
    @parentesco ='Padre',
    @id_grupo =5;
EXEC manejo_personas.CrearResponsable
    @id_persona =3,
    @parentesco ='Tutor',
    @id_grupo =1;
--Respuestas: Responsable creado correctamente

--Persona no existe
EXEC manejo_personas.CrearResponsable
    @id_persona =789783,
    @parentesco ='Tutor',
    @id_grupo =1;
--Respuesta: Persona no encontrada

--Grupo no existe
EXEC manejo_personas.CrearResponsable
    @id_persona =3,
    @parentesco ='Madre',
    @id_grupo =242424;
--Respuesta: Grupo familiar no encontrado

--Parentesco vacio
EXEC manejo_personas.CrearResponsable
    @id_persona =4,
    @parentesco ='',
    @id_grupo =4;
--Respuesta: El parentesco no puede estar vacio

--Persona ya es responsble
EXEC manejo_personas.CrearResponsable
    @id_persona =3,
    @parentesco ='Padre',
    @id_grupo =6;
--Respuesta: La persona ya esta registrada como responsable

--Modificacion:

--Casos Normales
EXEC manejo_personas.ModificarResponsable
    @id_grupo =1,
    @parentesco ='Padre';
EXEC manejo_personas.ModificarResponsable
    @id_grupo =4,
    @parentesco ='Tutor';
EXEC manejo_personas.ModificarResponsable
    @id_grupo =3,
    @parentesco ='Madre';
--Resultado: Responsable actualizado correctamente

--Grupo inexistente
EXEC manejo_personas.ModificarResponsable
    @id_grupo =99993,
    @parentesco ='Madre';
--Resultado: Responsable no encontrado

--Parentesco vacio
EXEC manejo_personas.ModificarResponsable
    @id_grupo =1,
    @parentesco ='';
--Resultado: Parentesco no puede estar vac�o

--Eliminacion

--Casos Normales 
EXEC manejo_personas.EliminarResponsable @id_grupo =2;
EXEC manejo_personas.EliminarResponsable @id_grupo =4;
EXEC manejo_personas.EliminarResponsable @id_grupo =6;
--Resultado: Responsable eliminado correctamente

--Id inexistente
EXEC manejo_personas.EliminarResponsable @id_grupo =78962;
--Resultado: Responsable no encontrado