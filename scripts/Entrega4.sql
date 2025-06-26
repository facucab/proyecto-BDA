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


-- ############################################################
-- ######################## SP ROL ############################
-- ############################################################

/*
* Nombre: CrearRol
* Descripcion: Inserta un nuevo rol en la tabla usuarios.Rol, validando su informacion.
* Parametros:
*   @nombre VARCHAR(50)       - Nombre del rol.
*   @descripcion VARCHAR(100) - Descripcion del rol.
* Aclaracion: No se utiliza transacciones explicitas ya que: 
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.CrearRol
    @nombre VARCHAR(50),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido nombre:
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre del rol es obligatorio.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido descripcion:
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La descripcion del rol es obligatoria.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Verifico duplicado de nombre:
    IF EXISTS (SELECT 1 FROM usuarios.Rol WHERE nombre = LTRIM(RTRIM(@nombre)))
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe un rol con ese nombre.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        INSERT INTO usuarios.Rol (nombre, descripcion)
        VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@descripcion)));
        SELECT 'OK' AS Resultado, 'Rol creado correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO

/*
* Nombre: ModificarRol
* Descripcion: Modifica el nombre y descripcion de un rol existente, validando su informacion.
* Parametros:
*   @id_rol      INT          - ID del rol a modificar.
*   @nombre      VARCHAR(50)  - Nuevo nombre del rol.
*   @descripcion VARCHAR(100) - Nueva descripcion del rol.
* Aclaracion: No se utiliza transacciones explicitas ya que: 
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.ModificarRol
    @id_rol      INT,
    @nombre      VARCHAR(50),
    @descripcion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia del rol:
    IF NOT EXISTS (SELECT 1 FROM usuarios.Rol WHERE id_rol = @id_rol)
    BEGIN
        SELECT 'Error' AS Resultado, 'Rol no encontrado.' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    -- Valido nombre:
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre del rol es obligatorio.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido descripcion:
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La descripcion del rol es obligatoria.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Verifico duplicado de nombre en otro rol:
    IF EXISTS (
        SELECT 1
          FROM usuarios.Rol
         WHERE nombre = LTRIM(RTRIM(@nombre))
           AND id_rol <> @id_rol
    )
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe otro rol con ese nombre.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE usuarios.Rol
           SET nombre      = LTRIM(RTRIM(@nombre)),
               descripcion = LTRIM(RTRIM(@descripcion))
         WHERE id_rol = @id_rol;
        SELECT 'OK' AS Resultado, 'Rol modificado correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO

/*
* Nombre: EliminarRol
* Descripcion: Elimina fisicamente un rol de la tabla usuarios.Rol.
* Parametros:
*   @id_rol INT - ID del rol a eliminar.
* Aclaracion: No se utiliza transacciones explicitas ya que: 
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.EliminarRol
    @id_rol INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia del rol:
    IF NOT EXISTS (SELECT 1 FROM usuarios.Rol WHERE id_rol = @id_rol)
    BEGIN
        SELECT 'Error' AS Resultado, 'Rol no encontrado.' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        DELETE FROM usuarios.Rol
        WHERE id_rol = @id_rol;
        SELECT 'OK' AS Resultado, 'Rol eliminado correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO

-- ############################################################
-- ######################## SP CLASE ##########################
-- ############################################################

/*
* Nombre: CrearClase
* Descripcion: Crea una nueva clase, validando que no haya conflictos de horarios.
* Parametros:
*	@id_actividad INT    - ID de la actividad que se realiza en la clase.
*	@id_categoria INT    - ID de la categoria.
*	@dia VARCHAR(9)      - Dia de la semana.
*	@horario TIME        - Horario de la clase.
*	@id_usuario INT      - ID del usuario responsable de la clase.
*
* Aclaracion: Se utiliza transaccion explicita porque se validan varias tablas y se requiere rollback ante cualquier fallo.
*/
CREATE OR ALTER PROCEDURE actividades.CrearClase
	@id_actividad INT,
	@id_categoria INT,
	@dia VARCHAR(9),
	@horario TIME,
	@id_usuario INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRY
		BEGIN TRANSACTION;

		-- 1) Validar actividad
		IF NOT EXISTS (SELECT 1 FROM actividades.actividad WHERE id_actividad = @id_actividad AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La actividad no existe' AS Mensaje, '404' AS Estado;
			RETURN -1;
		END;

		-- 2) Validar categoria
		IF NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La categoria no existe' AS Mensaje, '404' AS Estado;
			RETURN -2;
		END;

		-- 3) Validar usuario
		IF NOT EXISTS (SELECT 1 FROM usuarios.usuario WHERE id_usuario = @id_usuario AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El usuario no existe' AS Mensaje, '404' AS Estado;
			RETURN -3;
		END;

		-- 4) Validar dia
		SET @dia = LOWER(LTRIM(RTRIM(@dia)));
		IF @dia NOT IN ('lunes','martes','miercoles','jueves','viernes','sabado','domingo')
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Dia invalido' AS Mensaje, '400' AS Estado;
			RETURN -4;
		END;

		-- 5) Validar horario
		IF @horario < '06:00:00' OR @horario >= '22:00:00'
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Horario invalido' AS Mensaje, '400' AS Estado;
			RETURN -5;
		END;

		-- 6) Conflicto exacto
		IF EXISTS (
			SELECT 1 
			  FROM actividades.clase 
			 WHERE id_actividad = @id_actividad
			   AND id_categoria = @id_categoria
			   AND dia          = @dia
			   AND horario      = @horario
			   AND estado       = 1
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe una clase activa con la misma actividad, categoria, dia y horario' AS Mensaje, '409' AS Estado;
			RETURN -6;
		END;

		-- 7) Conflicto profesor
		IF EXISTS (
			SELECT 1 
			  FROM actividades.clase 
			 WHERE id_usuario = @id_usuario
			   AND dia        = @dia
			   AND horario    = @horario
			   AND estado     = 1
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El profesor ya tiene otra clase activa en ese dia y horario' AS Mensaje, '409' AS Estado;
			RETURN -7;
		END;

		-- Insertar
		INSERT INTO actividades.clase (id_actividad, id_categoria, dia, horario, id_usuario)
		VALUES (@id_actividad, @id_categoria, @dia, @horario, @id_usuario);

		COMMIT TRANSACTION;
		SELECT 'OK' AS Resultado, 'Clase creada correctamente' AS Mensaje, '200' AS Estado;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
		RETURN -99;
	END CATCH;
END;
GO

/*
* Nombre: ModificarClase
* Descripcion: Modifica campos de una clase existente, validando conflictos de horarios.
* Parametros:
*	@id_clase       INT          - ID de la clase a modificar.
*	@id_actividad   INT    = NULL - (Opcional) Nueva actividad.
*	@id_categoria   INT    = NULL - (Opcional) Nueva categoria.
*	@dia            VARCHAR(9) = NULL - (Opcional) Nuevo dia.
*	@horario        TIME       = NULL - (Opcional) Nuevo horario.
*	@id_usuario     INT        = NULL - (Opcional) Nuevo profesor.
*
* Aclaracion: Se utiliza transaccion explicita porque se validan varias tablas y se requiere rollback ante cualquier fallo.
*/
CREATE OR ALTER PROCEDURE actividades.ModificarClase
	@id_clase       INT,
	@id_actividad   INT    = NULL,
	@id_categoria   INT    = NULL,
	@dia            VARCHAR(9) = NULL,
	@horario        TIME       = NULL,
	@id_usuario     INT        = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRY
		BEGIN TRANSACTION;

		-- 1) Validar existencia
		IF NOT EXISTS (SELECT 1 FROM actividades.clase WHERE id_clase = @id_clase AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La clase no existe o esta inactiva' AS Mensaje, '404' AS Estado;
			RETURN -1;
		END;

		-- 2) Validar actividad
		IF @id_actividad IS NOT NULL
		   AND NOT EXISTS (SELECT 1 FROM actividades.actividad WHERE id_actividad = @id_actividad AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La actividad no existe' AS Mensaje, '404' AS Estado;
			RETURN -2;
		END;

		-- 3) Validar categoria
		IF @id_categoria IS NOT NULL
		   AND NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La categoria no existe' AS Mensaje, '404' AS Estado;
			RETURN -3;
		END;

		-- 4) Validar usuario
		IF @id_usuario IS NOT NULL
		   AND NOT EXISTS (SELECT 1 FROM usuarios.usuario WHERE id_usuario = @id_usuario AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El usuario no existe' AS Mensaje, '404' AS Estado;
			RETURN -4;
		END;

		-- 5) Validar dia
		IF @dia IS NOT NULL
		BEGIN
			SET @dia = LOWER(LTRIM(RTRIM(@dia)));
			IF @dia NOT IN ('lunes','martes','miercoles','jueves','viernes','sabado','domingo')
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'Dia invalido' AS Mensaje, '400' AS Estado;
				RETURN -5;
			END;
		END;

		-- 6) Validar horario
		IF @horario IS NOT NULL
		   AND (@horario < '06:00:00' OR @horario >= '22:00:00')
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Horario invalido' AS Mensaje, '400' AS Estado;
			RETURN -6;
		END;

		-- 7) Conflicto exacto
		IF EXISTS (
			SELECT 1 
			  FROM actividades.clase
			 WHERE id_actividad = ISNULL(@id_actividad,   id_actividad)
			   AND id_categoria = ISNULL(@id_categoria,   id_categoria)
			   AND dia          = ISNULL(@dia,            dia)
			   AND horario      = ISNULL(@horario,        horario)
			   AND id_clase    <> @id_clase
			   AND estado       = 1
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe otra clase activa con la misma combinacion' AS Mensaje, '409' AS Estado;
			RETURN -7;
		END;

		-- 8) Conflicto profesor
		IF EXISTS (
			SELECT 1 
			  FROM actividades.clase
			 WHERE id_usuario = ISNULL(@id_usuario, id_usuario)
			   AND dia        = ISNULL(@dia,       dia)
			   AND horario    = ISNULL(@horario,   horario)
			   AND id_clase  <> @id_clase
			   AND estado     = 1
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El profesor ya tiene otra clase activa en ese dia y horario' AS Mensaje, '409' AS Estado;
			RETURN -8;
		END;

		-- Actualizar
		UPDATE actividades.clase
		   SET id_actividad = ISNULL(@id_actividad, id_actividad),
		       id_categoria = ISNULL(@id_categoria, id_categoria),
		       dia          = ISNULL(@dia,          dia),
		       horario      = ISNULL(@horario,      horario),
		       id_usuario   = ISNULL(@id_usuario,   id_usuario)
		 WHERE id_clase = @id_clase;

		COMMIT TRANSACTION;
		SELECT 'OK' AS Resultado, 'Clase modificada correctamente' AS Mensaje, '200' AS Estado;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
		RETURN -99;
	END CATCH;
END;
GO

/*
* Nombre: EliminarClase
* Descripcion: Realiza un borrado logico de una clase desactivandola.
* Parametros:
*	@id_clase INT - ID de la clase a eliminar.
*
* Aclaracion: Se utiliza transaccion explicita porque se cambia el estado y se requiere rollback ante fallo.
*/
CREATE OR ALTER PROCEDURE actividades.EliminarClase
	@id_clase INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRY
		BEGIN TRANSACTION;

		-- Validar existencia y estado
		IF NOT EXISTS (SELECT 1 FROM actividades.clase WHERE id_clase = @id_clase AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La clase no existe o ya esta inactiva' AS Mensaje, '404' AS Estado;
			RETURN -1;
		END;

		-- Borrado logico
		UPDATE actividades.clase
		   SET estado = 0
		 WHERE id_clase = @id_clase;

		COMMIT TRANSACTION;
		SELECT 'OK' AS Resultado, 'Clase inactivada correctamente' AS Mensaje, '200' AS Estado;
		RETURN 0;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
		RETURN -99;
	END CATCH;
END;
GO


-- ############################################################
-- ################### SP GrupoFamiliar #######################
-- ############################################################

/*
* Nombre: CrearGrupoFamiliar
* Descripcion: Crea un nuevo grupo familiar con la fecha de alta actual y estado activo.
* Parametros: Ninguno.
* Aclaracion: No se utilizan transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.CrearGrupoFamiliar
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO usuarios.grupo_familiar(fecha_alta, estado)
        VALUES (GETDATE(), 1);
        SELECT 'OK' AS Resultado, 'Grupo familiar creado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO

/*
* Nombre: ModificarEstadoGrupoFamiliar
* Descripcion: Modifica el estado (activo/inactivo) de un grupo familiar existente.
* Parametros:
*   @id_grupo INT      - ID del grupo familiar a modificar.
*   @estado   BIT = NULL - Nuevo estado: 1 (activo) o 0 (inactivo). Opcional.
* Aclaracion: No se utilizan transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.ModificarEstadoGrupoFamiliar
    @id_grupo INT,
    @estado   BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia del grupo:
    IF NOT EXISTS (SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @id_grupo)
    BEGIN
        SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    -- Valido estado si se proporciona:
    IF @estado IS NOT NULL AND @estado NOT IN (0,1)
    BEGIN
        SELECT 'Error' AS Resultado, 'Estado debe ser 0 (inactivo) o 1 (activo)' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE usuarios.grupo_familiar
        SET estado = ISNULL(@estado, estado)
        WHERE id_grupo_familiar = @id_grupo;
        SELECT 'OK' AS Resultado, 'Estado del grupo familiar actualizado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO

/*
* Nombre: EliminarGrupoFamiliar
* Descripcion: Realiza la eliminacion logica de un grupo familiar si no tiene responsables ni socios asignados.
* Parametros:
*   @id_grupo INT - ID del grupo familiar a eliminar.
* Aclaracion: No se utilizan transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE usuarios.EliminarGrupoFamiliar
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia del grupo:
    IF NOT EXISTS (SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @id_grupo)
    BEGIN
        SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    -- Verifico responsables asignados:
    IF EXISTS (SELECT 1 FROM usuarios.responsable WHERE id_grupo = @id_grupo)
    BEGIN
        SELECT 'Error' AS Resultado, 'No se puede eliminar: grupo tiene responsables asignados' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Verifico socios asignados:
    IF EXISTS (SELECT 1 FROM usuarios.socio WHERE id_grupo = @id_grupo)
    BEGIN
        SELECT 'Error' AS Resultado, 'No se puede eliminar: grupo tiene socios asignados' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE usuarios.grupo_familiar
        SET estado = 0
        WHERE id_grupo_familiar = @id_grupo;
        SELECT 'OK' AS Resultado, 'Grupo familiar inactivado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO