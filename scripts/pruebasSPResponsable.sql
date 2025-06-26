/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Responsable
*/

USE Com5600G01;
GO

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
--Resultado: Parentesco no puede estar vacío

--Eliminacion

--Casos Normales 
EXEC manejo_personas.EliminarResponsable @id_grupo =2;
EXEC manejo_personas.EliminarResponsable @id_grupo =4;
EXEC manejo_personas.EliminarResponsable @id_grupo =6;
--Resultado: Responsable eliminado correctamente

--Id inexistente
EXEC manejo_personas.EliminarResponsable @id_grupo =78962;
--Resultado: Responsable no encontrado