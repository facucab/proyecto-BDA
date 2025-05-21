/*
Entrega 4 - Documento de instalaci�n y configuraci�n
Fecha de entrega: 23/05/2025
Grupo: 01
Materia: Bases de Datos Aplicadas (3641)
Integrantes:
	43990422 | Aguirre, Alex Rub�n 
	45234709 | Gauto, Gast�n Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tom�s Andr�s

Enunciado:
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

-- Creacion de la base de datos
CREATE DATABASE Com5600G01;

-- Selecciona
USE Com5600G01;

-- Crea esquemas
CREATE SCHEMA manejo_personas; -- Relativo a todo lo que tiene que ver con personas fisicas

CREATE SCHEMA manejo_actividades; -- Relativo a las actividades del club

CREATE SCHEMA pagos_y_facturas; -- Relativo a pagos 

-- Crea las tablas para el schema de personas

-- PERSONA
CREATE TABLE manejo_personas.persona(
	id_persona INT IDENTITY(1,1) PRIMARY KEY,
	dni VARCHAR(8) NOT NULL UNIQUE,
	nombre NVARCHAR(50) NOT NULL, -- Son Nvarchar porque considero que puedo tener nombres extranjeros
	apellido NVARCHAR(50) NOT NULL,
	email VARCHAR(320) NOT NULL UNIQUE, -- Estandar RFC 5321
	fecha_nac DATE NOT NULL,
	telefono VARCHAR(15) NOT NULL, -- Estandar E.164
	fecha_alta DATE NOT NULL DEFAULT GETDATE()
);



-- OBRA SOCIAL
CREATE TABLE manejo_personas.obra_social (
    id_obra_social INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(50) NOT NULL
);

-- GRUPO FAMILIAR
CREATE TABLE manejo_personas.grupo_familiar (
    id_grupo INT IDENTITY(1,1) PRIMARY KEY,
    fecha_alta DATE NOT NULL DEFAULT GETDATE(),
    estado BIT NOT NULL DEFAULT 1 -- 1 significa activo y 0 inactivo
);

-- CATEGORIA
CREATE TABLE manejo_actividades.categoria (
    id_categoria INT IDENTITY(1,1) PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL,
    costo_membrecia DECIMAL(10, 2) NOT NULL,
    edad_maxima INT NOT NULL
);

-- SOCIO
CREATE TABLE manejo_personas.socio (
	--Atributos propios
    id_socio INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL UNIQUE, -- Enlace con su identidad padre
    telefono_emergencia VARCHAR(15) NOT NULL,
    obra_nro_socio VARCHAR(20) NULL,
	--Atributos que vienen de otras entidades o relaciones
    id_obra_social INT NULL,
    id_categoria INT NOT NULL,
    id_grupo INT NULL,
	--SCHEMA PARA PERSONAS
    CONSTRAINT FK_Socio_Persona FOREIGN KEY (id_persona) REFERENCES manejo_personas.persona(id_persona),
    CONSTRAINT FK_Socio_Obra_social FOREIGN KEY (id_obra_social) REFERENCES manejo_personas.obra_social(id_obra_social),
    CONSTRAINT FK_Socio_Grupo_Familiar FOREIGN KEY (id_grupo) REFERENCES manejo_personas.grupo_familiar(id_grupo),
	-- SCHEMA PARA ACTIVIDADES
	CONSTRAINT FK_Socio_Categoria FOREIGN KEY (id_categoria) REFERENCES manejo_actividades.categoria(id_categoria)
);

-- INVITADO
CREATE TABLE manejo_personas.invitado (
    id_invitado INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL UNIQUE, -- Conexion con su entidad padre
    id_socio INT NOT NULL, -- Conexion con la entidad fuerte
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Invitado_Persona FOREIGN KEY (id_persona) REFERENCES manejo_personas.persona(id_persona),
    CONSTRAINT FK_Invitado_Socio FOREIGN KEY (id_socio) REFERENCES manejo_personas.socio(id_socio)
);

-- USUARIO
CREATE TABLE manejo_personas.usuario (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL UNIQUE, -- Conexion identidad padre
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL, -- Asumo que vamos a hashear en SHA-256
    fecha_alta_contrase�a DATE NOT NULL DEFAULT GETDATE(),
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (id_persona) REFERENCES manejo_personas.persona(id_persona)
);

-- RESPONSABLE
CREATE TABLE manejo_personas.responsable (
    id_grupo INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    id_responsable INT UNIQUE,
    id_persona INT NOT NULL UNIQUE,
    parentesco VARCHAR(10) NOT NULL, -- Todos los roles que dice el TP Pone 5 digitos, le doy 10 por la dudas
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Responsable_Persona FOREIGN KEY (id_persona) REFERENCES manejo_personas.persona(id_persona),
    CONSTRAINT FK_Responsable_Grupo_Familiar FOREIGN KEY (id_grupo) REFERENCES manejo_personas.grupo_familiar(id_grupo)
);

-- ACTIVIDAD
CREATE TABLE manejo_actividades.actividad (
    id_actividad INT IDENTITY(1,1) PRIMARY KEY,
    nombre_actividad VARCHAR(100) NOT NULL,
    costo_mensual DECIMAL(10, 2) NOT NULL
);

-- CLASE
CREATE TABLE manejo_actividades.clase (
    id_clase INT IDENTITY(1,1) PRIMARY KEY,
    id_actividad INT NOT NULL,
    id_categoria INT NOT NULL,
    dia VARCHAR(9) NOT NULL, -- El dia de la semana con el nombre mas largo es MIE RCO LES
    horario TIME NOT NULL,
    id_usuario INT NOT NULL,
	-- SCHEMA PARA PERSONAS
	CONSTRAINT FK_Clase_Usuario FOREIGN KEY (id_usuario) REFERENCES manejo_personas.usuario(id_usuario),
	-- SCHEMA PARA ACTIVIDADES
    CONSTRAINT FK_Clase_Actividad FOREIGN KEY (id_actividad) REFERENCES manejo_actividades.actividad(id_actividad),
    CONSTRAINT FK_Clase_Categoria FOREIGN KEY (id_categoria) REFERENCES manejo_actividades.categoria(id_categoria)
    
);

-- ROL
CREATE TABLE Rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
);

-- USUARIO <-N----N-> ROL
CREATE TABLE Usuario_Rol (
    id_usuario INT NOT NULL,
    id_rol INT NOT NULL,
    PRIMARY KEY (id_usuario, id_rol),
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Usuario_Rol_Usuario FOREIGN KEY (id_usuario) REFERENCES manejo_personas.usuario(id_usuario),
    CONSTRAINT FK_Usuario_Rol_Rol FOREIGN KEY (id_rol) REFERENCES manejo_personas.rol(id_rol)
);

-- SOCIO <-N----N-> ACTIVIDAD
CREATE TABLE Socio_Actividad (
    id_socio INT NOT NULL,
    id_actividad INT NOT NULL,
    fecha_inicio DATE NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (id_socio, id_actividad),
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Socio_Actividad_Socio FOREIGN KEY (id_socio) REFERENCES manejo_personas.socio(id_socio),
	-- SCHEMA PARA ACTIVIDADES
    CONSTRAINT FK_Socio_Actividad_Actividad FOREIGN KEY (id_actividad) REFERENCES manejo_actividades.actividad(id_actividad)
);