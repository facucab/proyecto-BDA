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

--Pruebas Grupo Familiar

--Modificacion 

--Casos Normales
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =1,
    @estado =0;
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =5,
    @estado =0;
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =4,
    @estado =1;
--Respuesta: Estado del Grupo familiar actualizado correctamente

--Grupo inexistente
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =78964,
    @estado =1;
--Resultado: Grupo familiar no encontrado

--Estado invalido
EXEC manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo =3,
    @estado =61;
--Resultado: Estado debe ser 0 (inactivo) o 1 (activo)

--Eliminacion

--Casos Normales
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =3;
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =6;
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =9;
--Resultado: Grupo familiar inactivado correctamente

--Grupo inexistente
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =27894;
--Resultado: Grupo familiar no encontrado

--Responsable asignado
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =2;
--Resultado: No se puede eliminar: grupo tiene responsables asignados

--Miembros activos
EXEC manejo_personas.EliminarGrupoFamiliar @id_grupo =4;
--Resultado: No se puede eliminar: grupo tiene socios asignados