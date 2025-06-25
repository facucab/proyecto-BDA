USE master;
GO
-- Elimino la BD, si existe: 
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'Com5600G01')
BEGIN 
    -- Fuerzo ser el unico usuario conectado a la BD
    ALTER DATABASE Com5600G01 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;  
    DROP DATABASE Com5600G01; 
END;

-- Creo la BD: 
GO
CREATE DATABASE Com5600G01;

GO
USE Com5600G01;

--Crear SCHEMA
GO
CREATE SCHEMA usuarios; 
GO
CREATE SCHEMA actividades; 
GO
CREATE SCHEMA facturacion;

-- Crear tablas (Esquema usuario): 
GO
CREATE TABLE usuarios.persona(
	id_persona INT IDENTITY(1,1) PRIMARY KEY,
	dni VARCHAR(9) NOT NULL UNIQUE,
	nombre VARCHAR(50) NOT NULL, 
	apellido VARCHAR(50) NOT NULL,
	email VARCHAR(320) NOT NULL UNIQUE, -- Estandar RFC 5321
	fecha_nac DATE NOT NULL,
	telefono VARCHAR(20) NOT NULL,
	fecha_alta DATE NOT NULL DEFAULT GETDATE(),
	activo BIT NOT NULL DEFAULT 1,

    CONSTRAINT CK_persona_email CHECK (email LIKE '%@%.%' AND email NOT LIKE '@%' AND email NOT LIKE '%@%@%'),
	CONSTRAINT CK_persona_dni CHECK (dni LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT CK_persona_fecha_nac CHECK(fecha_nac < GETDATE()) 
);
GO
CREATE TABLE usuarios.obra_social(
	id_obra_social INT IDENTITY PRIMARY KEY,
	descripcion VARCHAR(50) NOT NULL
	);
GO
CREATE TABLE usuarios.grupo_familiar(
	id_grupo_familiar INT IDENTITY(1,1) PRIMARY KEY,
    fecha_alta DATE NOT NULL DEFAULT GETDATE(),
    estado BIT NOT NULL DEFAULT 1
);
GO
CREATE TABLE actividades.categoria(
	id_categoria INT IDENTITY(1,1) PRIMARY KEY, 
	nombre_categoria VARCHAR(50) NOT NULL,
	costo_membrecia DECIMAL(10, 2) NOT NULL,
    vigencia DATE NOT NULL,
	CONSTRAINT CK_categoria_costo_membrecia CHECK (costo_membrecia >0)
); 
GO
CREATE TABLE usuarios.socio(
	id_socio INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    numero_socio VARCHAR(7) NOT NULL UNIQUE, 
    id_persona INT NOT NULL,
    telefono_emergencia VARCHAR(20) NULL,   
    obra_nro_socio VARCHAR(20) NULL,
    fecha_alta DATE NOT NULL DEFAULT GETDATE(),
    fecha_baja DATE NULL,
    activo BIT NOT NULL DEFAULT 1,
	id_obra_social INT NULL,
    id_categoria INT NOT NULL,
    id_grupo INT NULL,
	
	CONSTRAINT FK_socio_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) 
	ON DELETE CASCADE, -- Se elimina socio, si se elimina persona. 
	CONSTRAINT FK_socio_obra_social FOREIGN KEY (id_obra_social) REFERENCES  usuarios.obra_social(id_obra_social)
	ON DELETE SET NULL, -- Si se elimina la obra social, se asigna NULL
	CONSTRAINT FK_socio_grupo_familiar FOREIGN KEY (id_grupo) REFERENCES usuarios.grupo_familiar(id_grupo_familiar)
	ON DELETE SET NULL, -- Si se elimina el grupo familiar, se asigna NULL
	CONSTRAINT FK_Socio_Categoria FOREIGN KEY (id_categoria) REFERENCES actividades.categoria(id_categoria)

);
GO
CREATE TABLE usuarios.invitado(
	id_invitado INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL UNIQUE,
	id_socio INT NOT NULL,
	fecha_invitacion DATE NOT NULL DEFAULT GETDATE()

	CONSTRAINT FK_invitado_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona)
	ON DELETE CASCADE, 
	CONSTRAINT FK_invitado_socio FOREIGN KEY (id_socio) REFERENCES usuarios.socio(id_socio)
);
GO
CREATE TABLE usuarios.usuario(
	id_usuario INT IDENTITY PRIMARY KEY,
	id_persona INT NOT NULL UNIQUE,
	username VARCHAR(50) NOT NULL UNIQUE,
	password_hash VARCHAR(256) NOT NULL,
	fecha_alta_contra DATE NOT NULL DEFAULT GETDATE(),
	estado BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_usuario_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona)
	ON DELETE CASCADE,
	CONSTRAINT CK_usuario_username CHECK (
        username NOT LIKE '% %' AND  -- No espacios en blanco
        username = LOWER(username)  -- Solo minúsculas
    )
);
GO
CREATE TABLE usuarios.responsable(
	id_responsable INT IDENTITY(1,1) PRIMARY KEY,
	id_grupo INT NOT NULL,
	id_persona INT NOT NULL UNIQUE,
	parentesco VARCHAR(10) NOT NULL
	CONSTRAINT FK_responsable_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona),
	CONSTRAINT FK_responsable_grupo_familiar FOREIGN KEY (id_grupo) REFERENCES usuarios.grupo_familiar(id_grupo_familiar)
);
GO
CREATE TABLE actividades.actividad (
	id_actividad INT IDENTITY PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL,
	costo_mensual DECIMAL(10,2) NOT NULL,
	estado BIT NOT NULL DEFAULT 1,
	CONSTRAINT CK_costo_mensual CHECK(costo_mensual > 0)
);
GO
CREATE TABLE actividades.clase(
	id_clase INT IDENTITY(1,1) PRIMARY KEY,
	id_actividad INT NOT NULL,
	id_categoria INT NOT NULL,
	dia VARCHAR(9) NOT NULL,
	horario TIME NOT NULL,
	id_usuario INT NOT NULL, -- Usuario que dicta la clase. 
	estado BIT NOT NULL DEFAULT 1,
	CONSTRAINT FK_clase_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario),
	CONSTRAINT FK_clase_actividad FOREIGN KEY (id_actividad) REFERENCES actividades.actividad(id_actividad),
	CONSTRAINT FK_clase_categoria FOREIGN KEY (id_categoria) REFERENCES actividades.categoria(id_categoria),
	CONSTRAINT CK_dia CHECK(dia IN('lunes', 'martes', 'miercoles', 'jueves', 'viernes','sabado', 'domingo'))
); 
GO
CREATE TABLE usuarios.Rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(100) NOT NULL
);
GO
CREATE TABLE usuarios.Usuario_Rol(
	id_usuario INT NOT NULL,
    id_rol INT NOT NULL,
    PRIMARY KEY (id_usuario, id_rol),
	CONSTRAINT FK_Usuario_Rol_Usuario FOREIGN KEY (id_usuario) REFERENCES usuarios.usuario(id_usuario),
    CONSTRAINT FK_Usuario_Rol_Rol FOREIGN KEY (id_rol) REFERENCES usuarios.rol(id_rol)
);
GO
CREATE TABLE facturacion.metodo_pago (
	id_metodo_pago INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE
);

-- QUEDAN LAS TABLAS DE FACTURA: 

-- ############################################################
-- ######################## SP PERSONA ########################
-- ############################################################
GO 
/*
* Nombre: CrearPersona
* Descripcion: Inserta una nueva persona en la tabla persona, validando su informacion. 
* Parametros:
*	@dni  VARCHAR(8) - DNI de la persona.
*	@nombre VARCHAR(50) - Nombre de la persona. 
*	@apellido VARCHAR(50) - Apellido de la persona. 
* 	@email VARCHAR(320) - Email de la persona. 
* 	@fecha_nac DATE - Fecha de nacimiento.
*	@telefono VARCHAR(15) - Telefono de la persona
*
* Aclaracion: No se utiliza transaccione explicitas ya que: 
*	Solo se trabaja con una unica tablas y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.CrearPersona
	@dni VARCHAR(9),
	@nombre VARCHAR(50),
	@apellido VARCHAR(50),
	@email VARCHAR(320),
	@fecha_nac DATE,
	@telefono VARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON;
	-- Valido DNI:
	IF @dni IS NULL OR LEN(@dni) < 7 OR LEN(@dni) > 8 OR @dni LIKE '%[^0-9]%' BEGIN
		SELECT 'Error' as Resultado, 'DNI inválido. Debe contener entre 7 y 8 dígitos numéricos.' AS Mensaje, '400' AS Estado; 
		RETURN; 
	END;
	-- Valido email: 
	 IF @email NOT LIKE '%@%.%' OR @email LIKE '@%' OR @email LIKE '%@%@%' BEGIN
        SELECT 'Error' AS Resultado, 'Formato de email inválido.' AS Mensaje, '400' AS Estado;
        RETURN;
    END; 
	-- Valido nombre
	IF @nombre IS NULL
	BEGIN
		SELECT 'Error' AS Resultado, 'El nombre es obligatorio' AS Mensaje, '400' AS Estado;
	END;
	-- Valido apellido
	IF @apellido IS NULL
	BEGIN
		SELECT 'Error' AS Resultado, 'El apellido es obligatorio' AS Mensaje, '400' AS Estado;
	END;
	--Valido fecha de nacimiento: 
	 IF @fecha_nac >= GETDATE() BEGIN
        SELECT 'Error' AS Resultado, 'La fecha de nacimiento debe ser anterior a hoy.' AS Mensaje, '400' AS Estado;
        RETURN;
    END; 
	-- Valido telefono: 
	IF @telefono IS NULL OR LEN(@telefono) = 0 BEGIN
        SELECT 'Error' AS Resultado, 'Teléfono obligatorio.' AS Mensaje;
        RETURN;
    END; 
	-- Inserto en la tabla: 
	BEGIN TRY
		INSERT INTO usuarios.persona(dni, nombre, apellido, email, fecha_nac, telefono)
        VALUES (@dni, @nombre, @apellido, @email, @fecha_nac, @telefono);
		SELECT 'OK' as Resultado, 'La persona fue creada correctamente' AS Mensaje, '200' AS Estado;
	END TRY 
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH; 
END; 

GO
/*
* Nombre: ModificarPersona
* Descripcion: Permite modificar de una persona los campos: nombre, apellido, email y telefono.
* Parametros:
*	@id_persona  INT - ID de persona. 
*	@nombre NVARCHAR(50) - Nombre nuevo para la persona. (Parametro opcional)
*	@apellido NVARCHAR(50) - Apellido nuevo para la persona. (Parametro opcional)
* 	@email VARCHAR(320) - Nuevo email para la persona. (Parametro opcional) 
*	@telefono VARCHAR(15) - Nuevo telefono para la persona
*/
CREATE OR ALTER PROCEDURE usuarios.ModificarPersona
	@id_persona INT,
    @nombre VARCHAR(50),
    @apellido VARCHAR(50),
    @email VARCHAR(320),
    @fecha_nac DATE,
    @telefono VARCHAR(20)
AS BEGIN
    SET NOCOUNT ON;
	-- Valido que exista el id enviado
	IF NOT EXISTS (SELECT 1 FROM usuarios.persona AS p WHERE p.id_persona = @id_persona AND p.activo = 1)
	BEGIN
		SELECT 'Error' AS Resultado, 'La persona no fue encontrada' AS Mensaje, '404' AS Estado;
        RETURN;
	END; 
	-- Valido email: 
	 IF @email NOT LIKE '%@%.%' OR @email LIKE '@%' OR @email LIKE '%@%@%' BEGIN
        SELECT 'Error' AS Resultado, 'Formato de email inválido.' AS Mensaje, '400' AS Estado;
        RETURN;
    END; 
	-- Valido nombre
	IF @nombre IS NULL
	BEGIN
		SELECT 'Error' AS Resultado, 'El nombre es obligatorio' AS Mensaje, '400' AS Estado;
	END;
	-- Valido apellido
	IF @apellido IS NULL
	BEGIN
		SELECT 'Error' AS Resultado, 'El apellido es obligatorio' AS Mensaje, '400' AS Estado;
	END;
	--Valido fecha de nacimiento: 
	 IF @fecha_nac >= GETDATE() BEGIN
        SELECT 'Error' AS Resultado, 'La fecha de nacimiento debe ser anterior a hoy.' AS Mensaje, '400' AS Estado;
        RETURN;
    END; 
	-- Valido telefono: 
	IF @telefono IS NULL OR LEN(@telefono) = 0 BEGIN
        SELECT 'Error' AS Resultado, 'Teléfono obligatorio.' AS Mensaje;
        RETURN;
    END; 
	BEGIN TRY
		UPDATE usuarios.persona SET 
			nombre = @nombre,
			apellido = @apellido,
            email = @email,
            fecha_nac = @fecha_nac,
            telefono = @telefono
        WHERE id_persona = @id_persona;
        SELECT 'OK' AS Resultado, 'La persona fue modificada correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END; 
GO 
/*
* Nombre: EliminarPersona
* Descripcion: Realiza una eliminacion logica de una persona.
* Parametros:
*	@id_persona  INT - ID de persona a eliminar. 
*/
CREATE OR ALTER PROCEDURE usuarios.EliminarPersona
    @id_persona INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
    BEGIN
        SELECT 'Error' AS Resultado, 'La persona no fue encontrada' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        UPDATE usuarios.persona
        SET activo = 0
        WHERE id_persona = @id_persona;

        SELECT 'OK' AS Resultado, 'La persona fue dada de baja correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH
END;
GO
