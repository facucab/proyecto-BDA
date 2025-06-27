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
	numero_socio VARCHAR(7) NOT NULL UNIQUE,
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
GO
CREATE TABLE facturacion.descuento (
	id_descuento INT IDENTITY(1,1) PRIMARY KEY,
	descripcion  VARCHAR(100) NOT NULL,
	cantidad     DECIMAL(10,2) NOT NULL,
	CONSTRAINT CK_descuento_cantidad CHECK(cantidad >= 0)
);
GO
CREATE TABLE facturacion.factura (
	id_factura    INT IDENTITY(1,1) PRIMARY KEY,
	id_persona    INT NOT NULL,
	id_metodo_pago INT NULL,
	estado_pago   VARCHAR(20) NOT NULL,
	fecha_emision DATE NOT NULL DEFAULT GETDATE(),
	monto_a_pagar DECIMAL(10,2) NOT NULL,
	detalle       VARCHAR(200) NULL,
	CONSTRAINT FK_factura_persona FOREIGN KEY(id_persona) REFERENCES usuarios.persona(id_persona),
	CONSTRAINT FK_factura_metodo_pago FOREIGN KEY(id_metodo_pago) REFERENCES facturacion.metodo_pago(id_metodo_pago),
	CONSTRAINT CK_factura_monto CHECK(monto_a_pagar > 0)
);
GO
CREATE TABLE facturacion.factura_descuento (
	id_factura    INT NOT NULL,
	id_descuento  INT NOT NULL,
	PRIMARY KEY (id_factura, id_descuento),
	CONSTRAINT FK_factura_descuento_factura FOREIGN KEY(id_factura) REFERENCES facturacion.factura(id_factura),
	CONSTRAINT FK_factura_descuento_descuento FOREIGN KEY(id_descuento) REFERENCES facturacion.descuento(id_descuento)
);
GO
-- ############################################################
-- ######################## SP PERSONA ########################
-- ############################################################

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
*	@id_persona INT OUTPUT - ID generado(SCOPE_IDENTITY).
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
	@telefono VARCHAR(20),
	@id_persona INT OUTPUT
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
		SET @id_persona = SCOPE_IDENTITY();
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

-- ############################################################
-- ######################## SP SOCIO ##########################
-- ############################################################

/*
* Nombre: CrearSocio
* Descripcion: Crea un socio, reutilizando o creando la persona asociada.
* Parametros:
*   @id_persona           INT           = NULL - Si existe, se reutiliza; si no, se crea.
*   @dni                  VARCHAR(9)       - DNI de la persona.
*   @nombre               VARCHAR(50)      - Nombre de la persona.
*   @apellido             VARCHAR(50)      - Apellido de la persona.
*   @email                VARCHAR(320)     - Email de la persona.
*   @fecha_nac            DATE             - Fecha de nacimiento de la persona.
*   @telefono             VARCHAR(20)      - Telefono de la persona.
*   @numero_socio         VARCHAR(7)       - Numero de socio (único).
*   @telefono_emergencia  VARCHAR(20) = NULL - Teléfono de emergencia.
*   @obra_nro_socio       VARCHAR(20) = NULL - Numero en obra social.
*   @id_obra_social       INT         = NULL - FK a usuarios.obra_social.
*   @id_categoria         INT               - FK a actividades.categoria.
*   @id_grupo             INT         = NULL - FK a usuarios.grupo_familiar.
* Aclaracion: Se utiliza transaccion explicita porque se afectan multiple tablas.
*/
CREATE OR ALTER PROCEDURE usuarios.CrearSocio
    @id_persona          INT           = NULL,
    @dni                 VARCHAR(9),
    @nombre              VARCHAR(50),
    @apellido            VARCHAR(50),
    @email               VARCHAR(320),
    @fecha_nac           DATE,
    @telefono            VARCHAR(20),
    @numero_socio        VARCHAR(7),
    @telefono_emergencia VARCHAR(20)   = NULL,
    @obra_nro_socio      VARCHAR(20)   = NULL,
    @id_obra_social      INT           = NULL,
    @id_categoria        INT,
    @id_grupo            INT           = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	DECLARE @new_persona INT;
	BEGIN TRY
		BEGIN TRANSACTION;

		-- 1) Reutilizar o crear persona
		IF @id_persona IS NOT NULL
			AND EXISTS(SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
		BEGIN
			SET @new_persona = @id_persona;
		END
		ELSE
		BEGIN
			EXEC usuarios.CrearPersona
				@dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
				@id_persona = @new_persona OUTPUT;
		END;

		-- 2) Valido numero_socio unico
		IF EXISTS(SELECT 1 FROM usuarios.socio WHERE numero_socio = @numero_socio)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Numero de socio duplicado' AS Mensaje, '400' AS Estado;
			RETURN;
		END;

		-- 3) FK obra_social
		IF @id_obra_social IS NOT NULL
		   AND NOT EXISTS(SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id_obra_social)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Obra social no existe' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 4) FK categoria
		IF NOT EXISTS(SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Categoria no existe' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 5) FK grupo (opcional)
		IF @id_grupo IS NOT NULL
		   AND NOT EXISTS(SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @id_grupo)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Grupo familiar no existe' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 6) Inserto socio
		INSERT INTO usuarios.socio
			(numero_socio, id_persona, telefono_emergencia, obra_nro_socio,
			 id_obra_social, id_categoria, id_grupo)
		VALUES
			(@numero_socio, @new_persona, @telefono_emergencia, @obra_nro_socio,
			 @id_obra_social, @id_categoria, @id_grupo);

		COMMIT TRANSACTION;
		SELECT 'OK' AS Resultado, 'Socio creado correctamente' AS Mensaje, '200' AS Estado;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH;
END;
GO

/*
* Nombre: ModificarSocio
* Descripcion: Modifica un socio y, opcionalmente, la persona asociada.
* Parametros:
*   @id_socio            INT             - ID del socio a modificar.
*   @id_persona          INT         = NULL - Si se proporciona y existe, se reutiliza; si no existe, se crea.
*   @dni                 VARCHAR(9)      = NULL - DNI (para crear/nuevo).
*   @nombre              VARCHAR(50)     = NULL - Nombre (para crear/nuevo).
*   @apellido            VARCHAR(50)     = NULL - Apellido (para crear/nuevo).
*   @email               VARCHAR(320)    = NULL - Email (para crear/nuevo).
*   @fecha_nac           DATE            = NULL - Fecha de nacimiento (para crear/nuevo).
*   @telefono            VARCHAR(20)     = NULL - Telefono (para crear/nuevo).
*   @numero_socio        VARCHAR(7)      = NULL - Nuevo numero de socio.
*   @telefono_emergencia VARCHAR(20)     = NULL - Nuevo telefono de emergencia.
*   @obra_nro_socio      VARCHAR(20)     = NULL - Nuevo numero en obra social.
*   @id_obra_social      INT         = NULL - Nueva FK obra_social.
*   @id_categoria        INT         = NULL - Nueva FK categoria.
*   @id_grupo            INT         = NULL - Nueva FK grupo.
* Aclaracion: Se utiliza transaccion explicita porque se afectan persona y socio.
*/

CREATE OR ALTER PROCEDURE usuarios.ModificarSocio
    @id_socio            INT,
    @id_persona          INT           = NULL,
    @dni                 VARCHAR(9)    = NULL,
    @nombre              VARCHAR(50)   = NULL,
    @apellido            VARCHAR(50)   = NULL,
    @email               VARCHAR(320)  = NULL,
    @fecha_nac           DATE          = NULL,
    @telefono            VARCHAR(20)   = NULL,
    @numero_socio        VARCHAR(7)    = NULL,
    @telefono_emergencia VARCHAR(20)   = NULL,
    @obra_nro_socio      VARCHAR(20)   = NULL,
    @id_obra_social      INT           = NULL,
    @id_categoria        INT           = NULL,
    @id_grupo            INT           = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	DECLARE @new_persona INT;
	BEGIN TRY
		BEGIN TRANSACTION;

		-- 1) Verifico socio
		IF NOT EXISTS(SELECT 1 FROM usuarios.socio WHERE id_socio = @id_socio AND activo = 1) BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Socio no encontrado' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 2) Reutilizar o crear persona si alguno de los campos viene
		IF @id_persona IS NOT NULL
			AND EXISTS(SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
		BEGIN
			SET @new_persona = @id_persona;
		END
		ELSE IF @dni IS NOT NULL OR @nombre IS NOT NULL OR @apellido IS NOT NULL OR @email IS NOT NULL OR @fecha_nac IS NOT NULL OR @telefono IS NOT NULL
		BEGIN
			EXEC usuarios.CrearPersona
				@dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
				@id_persona = @new_persona OUTPUT;
		END;

		-- 3) Numero_socio único
		IF @numero_socio IS NOT NULL
		   AND EXISTS(SELECT 1 FROM usuarios.socio WHERE numero_socio = @numero_socio AND id_socio <> @id_socio) 
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Numero de socio duplicado' AS Mensaje, '400' AS Estado;
			RETURN;
		END;

		-- 4) FK obra_social
		IF @id_obra_social IS NOT NULL
		   AND NOT EXISTS(SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id_obra_social)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Obra social no existe' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 5) FK categoria
		IF @id_categoria IS NOT NULL
		   AND NOT EXISTS(SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Categoria no existe' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 6) FK grupo
		IF @id_grupo IS NOT NULL
		   AND NOT EXISTS(SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @id_grupo)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Grupo familiar no existe' AS Mensaje, '404' AS Estado;
			RETURN;
		END;

		-- 7) Update socio
		UPDATE usuarios.socio
		SET
			id_persona          = ISNULL(@new_persona, id_persona),
			numero_socio        = ISNULL(@numero_socio, numero_socio),
			telefono_emergencia = ISNULL(@telefono_emergencia, telefono_emergencia),
			obra_nro_socio      = ISNULL(@obra_nro_socio, obra_nro_socio),
			id_obra_social      = ISNULL(@id_obra_social, id_obra_social),
			id_categoria        = ISNULL(@id_categoria, id_categoria),
			id_grupo            = ISNULL(@id_grupo, id_grupo)
		WHERE id_socio = @id_socio;

		COMMIT TRANSACTION;
		SELECT 'OK' AS Resultado, 'Socio modificado correctamente' AS Mensaje, '200' AS Estado;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH;
END;
GO

/*
* Nombre: EliminarSocio
* Descripcion: Realiza eliminacion logica de un socio.
* Parametros:
*   @id_socio INT - ID del socio a eliminar.
* Aclaracion: No se utiliza transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/

CREATE OR ALTER PROCEDURE usuarios.EliminarSocio
    @id_socio INT
AS
BEGIN
	SET NOCOUNT ON;
	-- Verifico existencia y activo
	IF NOT EXISTS(SELECT 1 FROM usuarios.socio WHERE id_socio = @id_socio AND activo = 1) BEGIN
		SELECT 'Error' AS Resultado, 'Socio no encontrado' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	BEGIN TRY
		UPDATE usuarios.socio
		SET
			activo    = 0,
			fecha_baja = GETDATE()
		WHERE id_socio = @id_socio;
		SELECT 'OK' AS Resultado, 'Socio dado de baja correctamente' AS Mensaje, '200' AS Estado;
	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH;
END;
GO


-- ############################################################
-- ###################### SP FACTURA ##########################
-- ############################################################


/*
* Nombre: CrearFactura
* Descripcion: Inserta una nueva factura en la tabla facturacion.factura, validando su informacion.
* Parametros:
*   @id_persona    INT             - ID de la persona que paga.
*   @id_metodo_pago INT   = NULL   - Metodo de pago. Opcional.
*   @estado_pago   VARCHAR(20)     - Estado del pago.
*   @monto_a_pagar DECIMAL(10,2)   - Monto a pagar.
*   @detalle       VARCHAR(200) = NULL - Detalle de la factura. Opcional.
* Aclaracion: No se utilizan transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE facturacion.CrearFactura
	@id_persona    INT,
	@id_metodo_pago INT    = NULL,
	@estado_pago   VARCHAR(20),
	@monto_a_pagar DECIMAL(10,2),
	@detalle       VARCHAR(200) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	-- Valido persona:
	IF NOT EXISTS (SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
	BEGIN
		SELECT 'Error' AS Resultado, 'Persona no encontrada' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	-- Valido metodo de pago:
	IF @id_metodo_pago IS NOT NULL
	   AND NOT EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE id_metodo_pago = @id_metodo_pago)
	BEGIN
		SELECT 'Error' AS Resultado, 'Metodo de pago no existe' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	-- Valido estado de pago:
	IF @estado_pago IS NULL OR LTRIM(RTRIM(@estado_pago)) = ''
	BEGIN
		SELECT 'Error' AS Resultado, 'El estado de pago es obligatorio' AS Mensaje, '400' AS Estado;
		RETURN;
	END;
	-- Valido monto a pagar:
	IF @monto_a_pagar <= 0
	BEGIN
		SELECT 'Error' AS Resultado, 'El monto a pagar debe ser mayor a 0' AS Mensaje, '400' AS Estado;
		RETURN;
	END;
	BEGIN TRY
		INSERT INTO facturacion.factura(id_persona, id_metodo_pago, estado_pago, monto_a_pagar, detalle)
		VALUES(@id_persona, @id_metodo_pago, @estado_pago, @monto_a_pagar, @detalle);
		SELECT 'OK' AS Resultado, 'Factura creada correctamente' AS Mensaje, '200' AS Estado;
	END TRY 
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH; 
END;
GO

/*
* Nombre: ModificarFactura
* Descripcion: Modifica los campos de una factura existente, validando su informacion.
* Parametros:
*   @id_factura    INT             - ID de la factura a modificar.
*   @id_persona    INT         = NULL - Nueva persona. Opcional.
*   @id_metodo_pago INT   = NULL - Nuevo metodo de pago. Opcional.
*   @estado_pago   VARCHAR(20)= NULL - Nuevo estado de pago. Opcional.
*   @monto_a_pagar DECIMAL(10,2)= NULL - Nuevo monto a pagar. Opcional.
*   @detalle       VARCHAR(200)= NULL - Nuevo detalle. Opcional.
* Aclaracion: No se utilizan transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE facturacion.ModificarFactura
	@id_factura    INT,
	@id_persona    INT             = NULL,
	@id_metodo_pago INT           = NULL,
	@estado_pago   VARCHAR(20)     = NULL,
	@monto_a_pagar DECIMAL(10,2)   = NULL,
	@detalle       VARCHAR(200)    = NULL
AS
BEGIN
	SET NOCOUNT ON;
	-- Valido existencia de factura:
	IF NOT EXISTS (SELECT 1 FROM facturacion.factura WHERE id_factura = @id_factura)
	BEGIN
		SELECT 'Error' AS Resultado, 'Factura no encontrada' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	-- Valido persona:
	IF @id_persona IS NOT NULL
	   AND NOT EXISTS (SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
	BEGIN
		SELECT 'Error' AS Resultado, 'Persona no encontrada' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	-- Valido metodo de pago:
	IF @id_metodo_pago IS NOT NULL
	   AND NOT EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE id_metodo_pago = @id_metodo_pago)
	BEGIN
		SELECT 'Error' AS Resultado, 'Metodo de pago no existe' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	-- Valido estado de pago:
	IF @estado_pago IS NOT NULL
	   AND LTRIM(RTRIM(@estado_pago)) = ''
	BEGIN
		SELECT 'Error' AS Resultado, 'El estado de pago no puede estar vacio' AS Mensaje, '400' AS Estado;
		RETURN;
	END;
	-- Valido monto a pagar:
	IF @monto_a_pagar IS NOT NULL
	   AND @monto_a_pagar <= 0
	BEGIN
		SELECT 'Error' AS Resultado, 'El monto a pagar debe ser mayor a 0' AS Mensaje, '400' AS Estado;
		RETURN;
	END;
	BEGIN TRY
		UPDATE facturacion.factura
		SET
			id_persona    = ISNULL(@id_persona,    id_persona),
			id_metodo_pago = ISNULL(@id_metodo_pago, id_metodo_pago),
			estado_pago   = ISNULL(@estado_pago,    estado_pago),
			monto_a_pagar = ISNULL(@monto_a_pagar,  monto_a_pagar),
			detalle       = ISNULL(@detalle,        detalle)
		WHERE id_factura = @id_factura;
		SELECT 'OK' AS Resultado, 'Factura modificada correctamente' AS Mensaje, '200' AS Estado;
	END TRY 
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH; 
END;
GO

/*
* Nombre: EliminarFactura
* Descripcion: Elimina fisicamente una factura de la tabla facturacion.factura.
* Parametros:
*   @id_factura INT - ID de la factura a eliminar.
* Aclaracion: No se utilizan transacciones explicitas ya que:
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
CREATE OR ALTER PROCEDURE facturacion.EliminarFactura
	@id_factura INT
AS
BEGIN
	SET NOCOUNT ON;
	-- Valido existencia de factura:
	IF NOT EXISTS (SELECT 1 FROM facturacion.factura WHERE id_factura = @id_factura)
	BEGIN
		SELECT 'Error' AS Resultado, 'Factura no encontrada' AS Mensaje, '404' AS Estado;
		RETURN;
	END;
	BEGIN TRY
		DELETE FROM facturacion.factura
		WHERE id_factura = @id_factura;
		SELECT 'OK' AS Resultado, 'Factura eliminada correctamente' AS Mensaje, '200' AS Estado;
	END TRY 
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH; 
END;
GO

-- ############################################################
-- #################### SP METODO PAGO ########################
-- ############################################################

/*
* Nombre: CrearMetodoPago
* Descripcion: Crea un nuevo método de pago, validando que el nombre no sea nulo, vacío ni repetido.
* Parametros:
*   @nombre VARCHAR(50) - Nombre del método de pago.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE facturacion.CrearMetodoPago
    @nombre VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido nombre
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- Valido duplicado
    IF EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE nombre = LTRIM(RTRIM(@nombre)))
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe un método de pago con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO facturacion.metodo_pago(nombre)
        VALUES (LTRIM(RTRIM(@nombre)));
        SELECT 'OK' AS Resultado, 'Método de pago creado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

/*
* Nombre: ModificarMetodoPago
* Descripcion: Modifica el nombre de un método de pago existente, validando parámetros y unicidad.
* Parametros:
*   @id_metodo_pago INT     - ID del método de pago a modificar.
*   @nombre          VARCHAR(50) - Nuevo nombre. Opcional.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE facturacion.ModificarMetodoPago
    @id_metodo_pago INT,
    @nombre          VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE id_metodo_pago = @id_metodo_pago)
    BEGIN
        SELECT 'Error' AS Resultado, 'Método de pago no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    -- Valido nombre
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- Valido duplicado en otro registro
    IF EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE nombre = LTRIM(RTRIM(@nombre)) AND id_metodo_pago <> @id_metodo_pago)
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe otro método de pago con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        UPDATE facturacion.metodo_pago
        SET nombre = LTRIM(RTRIM(@nombre))
        WHERE id_metodo_pago = @id_metodo_pago;
        SELECT 'OK' AS Resultado, 'Método de pago modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

/*
* Nombre: EliminarMetodoPago
* Descripcion: Elimina físicamente un método de pago.
* Parametros:
*   @id_metodo_pago INT - ID del método de pago a eliminar.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE facturacion.EliminarMetodoPago
    @id_metodo_pago INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE id_metodo_pago = @id_metodo_pago)
    BEGIN
        SELECT 'Error' AS Resultado, 'Método de pago no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM facturacion.metodo_pago
        WHERE id_metodo_pago = @id_metodo_pago;
        SELECT 'OK' AS Resultado, 'Método de pago eliminado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

-- ############################################################
-- #################### SP DESCUENTO ##########################
-- ############################################################

/*
* Nombre: CrearDescuento
* Descripcion: Inserta un nuevo descuento en la tabla facturacion.descuento, validando su información.
* Parametros:
*   @descripcion VARCHAR(100) - Descripción del descuento.
*   @cantidad    DECIMAL(10,2) - Valor del descuento (>= 0).
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE facturacion.CrearDescuento
    @descripcion VARCHAR(100),
    @cantidad    DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido descripción
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La descripción es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- Valido cantidad
    IF @cantidad < 0
    BEGIN
        SELECT 'Error' AS Resultado, 'Cantidad inválida. Debe ser mayor o igual a 0' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO facturacion.descuento(descripcion, cantidad)
        VALUES (LTRIM(RTRIM(@descripcion)), @cantidad);
        SELECT 'OK' AS Resultado, 'Descuento creado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

/*
* Nombre: ModificarDescuento
* Descripcion: Modifica los datos de un descuento existente.
* Parametros:
*   @id_descuento INT           - ID del descuento a modificar.
*   @descripcion  VARCHAR(100)  - Nueva descripción. Obligatoria.
*   @cantidad     DECIMAL(10,2) - Nuevo valor del descuento (>= 0). Obligatorio.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE facturacion.ModificarDescuento
    @id_descuento INT,
    @descripcion  VARCHAR(100),
    @cantidad     DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM facturacion.descuento WHERE id_descuento = @id_descuento)
    BEGIN
        SELECT 'Error' AS Resultado, 'Descuento no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    -- Valido descripción
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La descripción es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- Valido cantidad
    IF @cantidad < 0
    BEGIN
        SELECT 'Error' AS Resultado, 'Cantidad inválida. Debe ser mayor o igual a 0' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        UPDATE facturacion.descuento
        SET
            descripcion = LTRIM(RTRIM(@descripcion)),
            cantidad    = @cantidad
        WHERE id_descuento = @id_descuento;
        SELECT 'OK' AS Resultado, 'Descuento modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

/*
* Nombre: EliminarDescuento
* Descripcion: Elimina físicamente un descuento de la tabla facturacion.descuento.
* Parametros:
*   @id_descuento INT - ID del descuento a eliminar.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE facturacion.EliminarDescuento
    @id_descuento INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM facturacion.descuento WHERE id_descuento = @id_descuento)
    BEGIN
        SELECT 'Error' AS Resultado, 'Descuento no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM facturacion.descuento
        WHERE id_descuento = @id_descuento;
        SELECT 'OK' AS Resultado, 'Descuento eliminado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

-- ############################################################
-- #################### SP CATEGORIA ##########################
-- ############################################################

/*
* Nombre: CrearCategoria
* Descripcion: Inserta una nueva categoría en la tabla actividades.categoria, validando su información.
* Parametros:
*   @nombre_categoria VARCHAR(50) - Nombre de la categoría.
*   @costo_membrecia  DECIMAL(10,2) - Costo de membresía (debe ser > 0).
*   @vigencia         DATE - Fecha de vigencia de la categoría.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE actividades.CrearCategoria
    @nombre_categoria VARCHAR(50),
    @costo_membrecia  DECIMAL(10,2),
    @vigencia         DATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido nombre
    IF @nombre_categoria IS NULL OR LTRIM(RTRIM(@nombre_categoria)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre de la categoría es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido costo
    IF @costo_membrecia <= 0
    BEGIN
        SELECT 'Error' AS Resultado, 'El costo de membresía debe ser mayor a 0' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido vigencia
    IF @vigencia IS NULL
    BEGIN
        SELECT 'Error' AS Resultado, 'La fecha de vigencia es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido duplicado
    IF EXISTS (
        SELECT 1 FROM actividades.categoria
        WHERE nombre_categoria = LTRIM(RTRIM(@nombre_categoria))
    )
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe una categoría con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        INSERT INTO actividades.categoria(nombre_categoria, costo_membrecia, vigencia)
        VALUES (LTRIM(RTRIM(@nombre_categoria)), @costo_membrecia, @vigencia);
        SELECT 'OK' AS Resultado, 'Categoría creada correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO

/*
* Nombre: ModificarCategoria
* Descripcion: Modifica los datos de una categoría existente, validando su información.
* Parametros:
*   @id_categoria     INT - ID de la categoría a modificar.
*   @nombre_categoria VARCHAR(50) - Nuevo nombre de la categoría.
*   @costo_membrecia  DECIMAL(10,2) - Nuevo costo de membresía (debe ser > 0).
*   @vigencia         DATE - Nueva fecha de vigencia.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/

CREATE OR ALTER PROCEDURE actividades.ModificarCategoria
    @id_categoria     INT,
    @nombre_categoria VARCHAR(50),
    @costo_membrecia  DECIMAL(10,2),
    @vigencia         DATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
    BEGIN
        SELECT 'Error' AS Resultado, 'Categoría no encontrada' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    -- Valido nombre
    IF @nombre_categoria IS NULL OR LTRIM(RTRIM(@nombre_categoria)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre de la categoría es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido costo
    IF @costo_membrecia <= 0
    BEGIN
        SELECT 'Error' AS Resultado, 'El costo de membresía debe ser mayor a 0' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido vigencia
    IF @vigencia IS NULL
    BEGIN
        SELECT 'Error' AS Resultado, 'La fecha de vigencia es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido duplicado en otro registro
    IF EXISTS (
        SELECT 1 FROM actividades.categoria
        WHERE nombre_categoria = LTRIM(RTRIM(@nombre_categoria)) AND id_categoria <> @id_categoria)
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe otra categoría con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE actividades.categoria
        SET
            nombre_categoria = LTRIM(RTRIM(@nombre_categoria)),
            costo_membrecia  = @costo_membrecia,
            vigencia         = @vigencia
        WHERE id_categoria = @id_categoria;
        SELECT 'OK' AS Resultado, 'Categoría modificada correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO

/*
* Nombre: EliminarCategoria
* Descripcion: Elimina físicamente una categoría de la tabla actividades.categoria.
* Parametros:
*   @id_categoria INT - ID de la categoría a eliminar.
* Aclaracion: No se utilizan transacciones explícitas ya que solo se trabaja con una única tabla.
*/
CREATE OR ALTER PROCEDURE actividades.EliminarCategoria
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
    BEGIN
        SELECT 'Error' AS Resultado, 'Categoría no encontrada' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        DELETE FROM actividades.categoria
        WHERE id_categoria = @id_categoria;
        SELECT 'OK' AS Resultado, 'Categoría eliminada correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

/*
* Nombre: CreacionObraSocial
* Descripcion: Crea una nueva obra social.
* Parametros:
*	@nombre VARCHAR(50) - Nombre de la obra social. 
* Valores de retorno:
*	 0: Exito. 
*	-1: @nombre es nulo. 
*	-2: El nombre ya esta en uso.
*	-99: Error desconocido.
*/
CREATE OR ALTER PROCEDURE usuarios.CreacionObraSocial
	@nombre VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Verifico que no sea nulo
		IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
		BEGIN
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Normalizo el nombre
		SET @nombre = LTRIM(RTRIM(@nombre));

		-- Verifico que el nombre no exista ya
		IF EXISTS (SELECT 1 FROM usuarios.obra_social WHERE descripcion = @nombre)
		BEGIN
			SELECT 'Error' AS Resultado, 'Ya hay una obra social con ese nombre' AS Mensaje;
			RETURN -2;
		END

		-- Inserto los datos
		INSERT INTO usuarios.obra_social(descripcion)
		VALUES (@nombre);

		SELECT 'Exito' AS Resultado, 'Obra Social Ingresada' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO


/*
* Nombre: ModificacionObraSocial
* Descripcion: Permite modificar el nombre de una obra social.
* Parametros:
*	@id INT - id de la obra social. (DEBE SER NO NULO)
*	@nombre_nuevo VARCHAR(50) - Nuevo nombre de la obra social.
* Valores de retorno:
*	 0: Exito. 
*	-1: @id o @nombre_nuevo son nulo. 
*	-2: Obra social no encontrada.
*	-3: Nombre esta en uso. 
*	-99: Error desconocido.
*/
CREATE OR ALTER PROCEDURE usuarios.ModificacionObraSocial
	@id INT,
	@nombre_nuevo VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id)
		BEGIN
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -2;
		END

		-- Verifico que el nombre no sea nulo
		IF @nombre_nuevo IS NULL OR LTRIM(RTRIM(@nombre_nuevo)) = ''
		BEGIN
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Normalizo el nombre
		SET @nombre_nuevo = LTRIM(RTRIM(@nombre_nuevo));

		-- Verifico que el nombre no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM usuarios.obra_social WHERE descripcion = @nombre_nuevo)
		BEGIN
			SELECT 'Error' AS Resultado, 'La obra social ya esta registrada' AS Mensaje;
			RETURN -3;
		END

		-- Actualizo los datos
		UPDATE usuarios.obra_social
		SET descripcion = @nombre_nuevo
		WHERE id_obra_social = @id;

		SELECT 'Exito' AS Resultado, 'Obra Social Modificada' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO


/*
* Nombre: EliminacionObraSocial
* Descripcion: Elimina una obra social de forma fisica.
* Parametros:
*	@id INT - id de la obra social. (DEBE SER NO NULO)
* Valores de retorno:
*	 0: Exito. 
*	-1: @id es nulo o no existente.
*	-99: Error desconocido.
*/
CREATE OR ALTER PROCEDURE usuarios.EliminacionObraSocial
	@id INT
AS BEGIN
	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id)
		BEGIN
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		-- Borrado fisico
		DELETE FROM usuarios.obra_social
		WHERE id_obra_social = @id;

		SELECT 'Exito' AS Resultado, 'Obra Social eliminada' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO
