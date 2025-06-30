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

GO
-- Crear tablas:
CREATE TABLE usuarios.persona(
	id_persona INT IDENTITY(1,1) PRIMARY KEY,
	dni VARCHAR(9) NOT NULL UNIQUE,
	-- numero_socio VARCHAR(7) NOT NULL UNIQUE,
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
CREATE TABLE actividades.pileta(
	id_pileta INT IDENTITY(1,1) PRIMARY KEY,
	detalle VARCHAR(50) NOT NULL,
	metro_cuadrado DECIMAL(5,2),
	CONSTRAINT CK_metro_cuadrado CHECK(metro_cuadrado > 0)
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
	id_pileta INT NULL -- relacion opcional
	
	CONSTRAINT FK_socio_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona) 
	ON DELETE CASCADE, -- Se elimina socio, si se elimina persona. 
	CONSTRAINT FK_socio_obra_social FOREIGN KEY (id_obra_social) REFERENCES  usuarios.obra_social(id_obra_social)
	ON DELETE SET NULL, -- Si se elimina la obra social, se asigna NULL
	CONSTRAINT FK_socio_grupo_familiar FOREIGN KEY (id_grupo) REFERENCES usuarios.grupo_familiar(id_grupo_familiar)
	ON DELETE SET NULL, -- Si se elimina el grupo familiar, se asigna NULL
	CONSTRAINT FK_socio_Categoria FOREIGN KEY (id_categoria) REFERENCES actividades.categoria(id_categoria),
	CONSTRAINT FK_socio_pileta FOREIGN KEY (id_pileta) REFERENCES actividades.pileta(id_pileta) 
	ON DELETE SET NULL
);
GO
CREATE TABLE usuarios.invitado(
	id_invitado INT IDENTITY(1,1) PRIMARY KEY,
    id_persona INT NOT NULL UNIQUE,
	id_socio INT NOT NULL,
	fecha_invitacion DATE NOT NULL DEFAULT GETDATE(),
	id_pileta INT NULL,
	CONSTRAINT FK_invitado_persona FOREIGN KEY (id_persona) REFERENCES usuarios.persona(id_persona)
	ON DELETE CASCADE, 
	CONSTRAINT FK_invitado_socio FOREIGN KEY (id_socio) REFERENCES usuarios.socio(id_socio),
	CONSTRAINT FK_invitado_pileta FOREIGN KEY (id_pileta) REFERENCES actividades.pileta(id_pileta)
	ON DELETE SET NULL
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
        username = LOWER(username)  -- Solo min�sculas
    )
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
CREATE TABLE actividades.costo(
	id_costo INT IDENTITY(1,1) PRIMARY KEY,
	tipo CHAR(3) NOT NULL, -- dia/tem(Temporada)/mes
	tipo_grupo CHAR(3) NOT NULL, -- adu (Adultos)/men (Menores)
	precio_socios DECIMAL(10, 2) NOT NULL,
	precio_invitados DECIMAL(10, 2) NOT NULL,
	id_pileta INT NOT NULL,
	CONSTRAINT FK_costo_pileta	FOREIGN KEY (id_pileta) REFERENCES actividades.pileta(id_pileta)
	ON DELETE CASCADE,
	CONSTRAINT CK_tipo CHECK(tipo IN ('dia', 'tem', 'mes')),
	CONSTRAINT CK_tipo_grupo CHECK(tipo_grupo IN ('adu','men')),
	CONSTRAINT CK_precios_socios CHECK(precio_socios > 0),
	CONSTRAINT CK_precios_invitados CHECK(precio_invitados > 0),
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
CREATE TABLE usuarios.rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(100) NOT NULL
);
GO
CREATE TABLE usuarios.usuario_Rol(
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
CREATE TABLE facturacion.clima(
	id_clima INT IDENTITY(1,1) PRIMARY KEY,
	fecha DATE NOT NULL,
	lluvia DECIMAL(5,2) NOT NULL --limite 999,99
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
CREATE TABLE facturacion.nota_credito(
	id_nota_credito INT IDENTITY(1,1) PRIMARY KEY,
	fecha_emision DATE NOT NULL,
	monto DECIMAL(10,2) NOT NULL,
	motivo VARCHAR(40) NULL,
	id_factura INT NOT NULL,
	id_clima INT NULL,

	CONSTRAINT CK_fecha_emision CHECK(fecha_emision <= GETDATE()),
	CONSTRAINT CK_monto CHECK(monto > 0),
	CONSTRAINT FK_nota_credito_factura FOREIGN KEY (id_factura) REFERENCES facturacion.factura(id_factura)
	ON DELETE CASCADE,
	CONSTRAINT FK_nota_credito_clima FOREIGN KEY (id_clima) REFERENCES facturacion.clima(id_clima)
	ON DELETE SET NULL
); 
GO
CREATE TABLE facturacion.datos_empresa (
	id_empresa INT IDENTITY(1,1) PRIMARY KEY,
	cuit_emisor VARCHAR(20) NOT NULL,
	domicilio_comercial VARCHAR(25) NOT NULL,
	condicion_IVA VARCHAR(25) NOT NULL,
	nombre VARCHAR(35)
);
GO
CREATE TABLE facturacion.detalle(
	id_detalle INT IDENTITY(1,1) PRIMARY KEY,
	tipo_comprobante CHAR(1) NOT NULL, -- A,B,C,M
	numero_comprobante VARCHAR(20),
	descripcion VARCHAR(50) NULL,
	cantidad SMALLINT,
	precio_unitario DECIMAL(10,2) NOT NULL,
	id_factura INT NOT NULL,
	id_empresa INT NOT NULL,
	CONSTRAINT FK_detalle_factura FOREIGN KEY (id_factura) REFERENCES facturacion.factura(id_factura)
	ON DELETE CASCADE,
	CONSTRAINT CK_precio_unitario CHECK(precio_unitario > 0),
	CONSTRAINT FK_detalle_empresa FOREIGN KEY (id_empresa) REFERENCES facturacion.datos_empresa(id_empresa),
	CONSTRAINT CK_tipo_comprobante CHECK (tipo_comprobante IN ('A', 'B', 'C', 'M'))
);
GO
CREATE TABLE actividades.actividad_socio(
	id_socio INT NOT NULL,
	id_actividad INT NOT NULL,
	PRIMARY KEY (id_socio, id_actividad),
	CONSTRAINT FK_socio FOREIGN KEY (id_socio) REFERENCES usuarios.socio(id_socio),
	CONSTRAINT FK_actividad FOREIGN KEY (id_actividad) REFERENCES actividades.actividad(id_actividad)
);
GO
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
		SELECT 'Error' as Resultado, 'DNI inv�lido. Debe contener entre 7 y 8 d�gitos num�ricos.' AS Mensaje, '400' AS Estado; 
		RETURN; 
	END;
	-- Valido email: 
	 IF @email NOT LIKE '%@%.%' OR @email LIKE '@%' OR @email LIKE '%@%@%' BEGIN
        SELECT 'Error' AS Resultado, 'Formato de email inv�lido.' AS Mensaje, '400' AS Estado;
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
        SELECT 'Error' AS Resultado, 'Tel�fono obligatorio.' AS Mensaje;
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
		SET @id_persona = NULL; 
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
        SELECT 'Error' AS Resultado, 'Formato de email inv�lido.' AS Mensaje, '400' AS Estado;
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
        SELECT 'Error' AS Resultado, 'Tel�fono obligatorio.' AS Mensaje;
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
-- #################### SP ObraSocial #########################
-- ############################################################
GO
/*
* Nombre: CreacionObraSocial
* Descripcion: Crea una nueva obra social.
* Parametros:
*	@nombre VARCHAR(50) - Nombre de la obra social. 
*/
CREATE OR ALTER PROCEDURE usuarios.CreacionObraSocial
	@nombre VARCHAR(50)
AS
BEGIN
	BEGIN TRY
		-- Verifico que no sea nulo
		IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
		BEGIN
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje, '400' AS Estado;
			RETURN;
		END

		-- Normalizo el nombre
		SET @nombre = UPPER(LTRIM(RTRIM(@nombre)))

		-- Verifico que el nombre no exista ya
		IF EXISTS (SELECT 1 FROM usuarios.obra_social WHERE descripcion = @nombre)
		BEGIN
			SELECT 'Error' AS Resultado, 'Ya hay una obra social con ese nombre' AS Mensaje, '400' AS Estado;
			RETURN;
		END

		-- Inserto los datos
		INSERT INTO usuarios.obra_social(descripcion)
		VALUES (@nombre);

		SELECT 'Exito' AS Resultado, 'Obra Social Ingresada' AS Mensaje,'200' AS Estado;
		RETURN;

	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
		RETURN;
	END CATCH
END;
GO
/*
* Nombre: ModificacionObraSocial
* Descripcion: Permite modificar el nombre de una obra social.
* Parametros:
*	@id INT - id de la obra social. (DEBE SER NO NULO)
*	@nombre_nuevo VARCHAR(50) - Nuevo nombre de la obra social.
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
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje, '400' AS Estado;
			RETURN;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id)
		BEGIN
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje, '404' AS Estado;
			RETURN;
		END

		-- Verifico que el nombre no sea nulo
		IF @nombre_nuevo IS NULL OR LTRIM(RTRIM(@nombre_nuevo)) = ''
		BEGIN
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje, '400' AS Estado;;
			RETURN;
		END

		-- Normalizo el nombre
		SET @nombre_nuevo = UPPER(LTRIM(RTRIM(@nombre_nuevo)));

		-- Verifico que el nombre no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM usuarios.obra_social WHERE descripcion = @nombre_nuevo AND id_obra_social <> @id) -- evita si el usuario carga el mismo nombre
		BEGIN
			SELECT 'Error' AS Resultado, 'La obra social ya esta registrada' AS Mensaje, '400' AS Estado;;
			RETURN;
		END

		-- Actualizo los datos
		UPDATE usuarios.obra_social
		SET descripcion = @nombre_nuevo
		WHERE id_obra_social = @id;

		SELECT 'Exito' AS Resultado, 'Obra Social Modificada' AS Mensaje, '200' AS Estado;;
		RETURN;

	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;;
		RETURN;
	END CATCH
END;
GO
/*
* Nombre: EliminacionObraSocial
* Descripcion: Elimina una obra social de forma fisica.
* Parametros:
*	@id INT - id de la obra social. (DEBE SER NO NULO)
*/
CREATE OR ALTER PROCEDURE usuarios.EliminacionObraSocial
	@id INT
AS BEGIN
	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje, '400' AS Estado;
			RETURN;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id)
		BEGIN
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje, '404' AS Estado;
			RETURN;
		END

		-- Borrado fisico
		DELETE FROM usuarios.obra_social
		WHERE id_obra_social = @id;

		SELECT 'Exito' AS Resultado, 'Obra Social eliminada' AS Mensaje, '200' AS Estado;
		RETURN;

	END TRY
	BEGIN CATCH
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje,'500' AS Estado;
		RETURN;
	END CATCH
END;
GO
-- ############################################################
-- ################### SP GrupoFamiliar #######################
-- ############################################################
GO
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
GO
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
*   @numero_socio         VARCHAR(7)       - Numero de socio (�nico).
*   @telefono_emergencia  VARCHAR(20) = NULL - Tel�fono de emergencia.
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
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED; -- Evita lecturas sucias
	DECLARE @new_persona INT;
	BEGIN TRY
		BEGIN TRANSACTION;

		-- 1) Reutilizar o crear persona: Si la persona existe, se reutiliza y se asocia a un socio
		IF @id_persona IS NOT NULL
			AND EXISTS(SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
		BEGIN
			SET @new_persona = @id_persona;
		END
		ELSE
		BEGIN
			-- Si no por defecto se crea la persona 
			EXEC usuarios.CrearPersona
				@dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
				@id_persona = @new_persona OUTPUT;
			IF @new_persona IS NULL
			BEGIN
					ROLLBACK TRANSACTION;
					RETURN;
			END
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
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- VALIDO SI ES CORRECTO LANZAR ROLLBACK
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH;
END;
GO
/*
* Nombre: ModificarSocio
* Descripcion: Modifica un socio y, opcionalmente, la persona asociada.
* Parametros:
*   @id_socio            INT             - ID del socio a modificar.
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
    @id_grupo            INT           = NULL,
    @id_pileta           INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Verificar socio existente y activo
        DECLARE @persona_id INT;
        SELECT @persona_id = id_persona 
        FROM usuarios.socio 
        WHERE id_socio = @id_socio AND activo = 1;
        
        IF @persona_id IS NULL BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Socio no encontrado o inactivo' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 2) Verificar que la persona existe si se proporciona DNI
        IF @dni IS NOT NULL
        BEGIN
            -- Buscar persona por DNI
            DECLARE @persona_con_dni INT;
            SELECT @persona_con_dni = id_persona 
            FROM usuarios.persona 
            WHERE dni = @dni AND activo = 1;
            
            -- Si no existe persona con ese DNI
            IF @persona_con_dni IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'No existe persona con el DNI proporcionado' AS Mensaje, '404' AS Estado;
                RETURN;
            END
            
            -- Si existe pero es diferente a la persona actual del socio
            IF @persona_con_dni <> @persona_id
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El DNI proporcionado pertenece a otra persona' AS Mensaje, '400' AS Estado;
                RETURN;
            END
        END

        -- 3) Validar email �nico si se proporciona
        IF @email IS NOT NULL
           AND EXISTS(SELECT 1 FROM usuarios.persona WHERE email = @email AND id_persona <> @persona_id) 
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Email ya existe para otra persona' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 4) Numero_socio �nico
        IF @numero_socio IS NOT NULL
           AND EXISTS(SELECT 1 FROM usuarios.socio WHERE numero_socio = @numero_socio AND id_socio <> @id_socio) 
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Numero de socio duplicado' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 5) Validar FK obra_social
        IF @id_obra_social IS NOT NULL
           AND NOT EXISTS(SELECT 1 FROM usuarios.obra_social WHERE id_obra_social = @id_obra_social)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Obra social no existe' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 6) Validar FK categoria (obligatoria)
        IF @id_categoria IS NOT NULL
           AND NOT EXISTS(SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Categoria no existe' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 7) Validar FK grupo familiar
        IF @id_grupo IS NOT NULL
           AND NOT EXISTS(SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @id_grupo AND estado = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Grupo familiar no existe o est� inactivo' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 8) Validar FK pileta
        IF @id_pileta IS NOT NULL
           AND NOT EXISTS(SELECT 1 FROM actividades.pileta WHERE id_pileta = @id_pileta)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Pileta no existe' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 9) Actualizar datos de persona
        UPDATE usuarios.persona
        SET
            dni = ISNULL(@dni, dni),
            nombre = ISNULL(@nombre, nombre),
            apellido = ISNULL(@apellido, apellido),
            email = ISNULL(@email, email),
            fecha_nac = ISNULL(@fecha_nac, fecha_nac),
            telefono = ISNULL(@telefono, telefono)
        WHERE id_persona = @persona_id;

        -- 10) Actualizar datos de socio
        UPDATE usuarios.socio
        SET
            numero_socio = ISNULL(@numero_socio, numero_socio),
            telefono_emergencia = ISNULL(@telefono_emergencia, telefono_emergencia),
            obra_nro_socio = ISNULL(@obra_nro_socio, obra_nro_socio),
            id_obra_social = ISNULL(@id_obra_social, id_obra_social),
            id_categoria = ISNULL(@id_categoria, id_categoria),
            id_grupo = ISNULL(@id_grupo, id_grupo),
            id_pileta = ISNULL(@id_pileta, id_pileta)
        WHERE id_socio = @id_socio;

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Socio modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, 
               'Error al modificar socio: ' + ERROR_MESSAGE() AS Mensaje, 
               '500' AS Estado;
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
-- #################### SP INVITADO ###########################
-- ############################################################
GO
/*
* Nombre: CrearInvitado
* Descripcion: Crea un invitado, reutilizando o creando la persona asociada.
*   - @id_socio es obligatorio y debe existir y estar activo.
*   - Si se pasa @id_persona y existe y est� activa, se reutiliza.
*   - Si no, se requieren todos los datos de persona para crearla.
*   - Verifica que la persona no est� ya invitada.
* Transacci�n expl�cita porque afecta a dos tablas: persona e invitado.
*/
CREATE OR ALTER PROCEDURE usuarios.CrearInvitado
    @id_persona     INT           = NULL,
    @dni            VARCHAR(9)    = NULL,
    @nombre         VARCHAR(50)   = NULL,
    @apellido       VARCHAR(50)   = NULL,
    @email          VARCHAR(320)  = NULL,
    @fecha_nac      DATE          = NULL,
    @telefono       VARCHAR(20)   = NULL,
    @id_socio       INT,
    @id_pileta      INT           = NULL  
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    -- 0) Validar socio obligatorio
    IF @id_socio IS NULL
    BEGIN
        SELECT 'Error' AS Resultado, 'El id_socio es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END

    DECLARE @new_persona INT;

    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1) Verificar socio existe y activo
        IF NOT EXISTS(SELECT 1 FROM usuarios.socio WHERE id_socio = @id_socio AND activo = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Socio no encontrado o inactivo' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 2) Reutilizar o crear persona
        IF @id_persona IS NOT NULL
           AND EXISTS(SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
        BEGIN
            SET @new_persona = @id_persona;
        END
        ELSE
        BEGIN
            -- Validar que todos los campos obligatorios est�n presentes
            IF @dni IS NULL OR @nombre IS NULL OR @apellido IS NULL
               OR @email IS NULL OR @fecha_nac IS NULL OR @telefono IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Faltan datos obligatorios para crear la persona' AS Mensaje, '400' AS Estado;
                RETURN;
            END

            -- Verificar que el DNI no exista ya
            IF EXISTS(SELECT 1 FROM usuarios.persona WHERE dni = @dni)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El DNI ya existe en el sistema' AS Mensaje, '400' AS Estado;
                RETURN;
            END

            -- Verificar que el email no exista ya
            IF EXISTS(SELECT 1 FROM usuarios.persona WHERE email = @email)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El email ya existe en el sistema' AS Mensaje, '400' AS Estado;
                RETURN;
            END

            -- Crear la nueva persona
            INSERT INTO usuarios.persona (dni, nombre, apellido, email, fecha_nac, telefono)
            VALUES (@dni, @nombre, @apellido, @email, @fecha_nac, @telefono);
            
            SET @new_persona = SCOPE_IDENTITY();
        END;

        -- 3) Verificar que la persona no est� ya invitada por el mismo socio
        IF EXISTS(
            SELECT 1 
            FROM usuarios.invitado 
            WHERE id_persona = @new_persona 
            AND id_socio = @id_socio
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona ya est� invitada por este socio' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 4) Verificar que la pileta exista (si se proporcion�)
        IF @id_pileta IS NOT NULL 
           AND NOT EXISTS(SELECT 1 FROM actividades.pileta WHERE id_pileta = @id_pileta)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La pileta especificada no existe' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 5) Crear invitado
        INSERT INTO usuarios.invitado(id_persona, id_socio, id_pileta)
        VALUES(@new_persona, @id_socio, @id_pileta);

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Invitado creado correctamente' AS Mensaje, '200' AS Estado, @new_persona AS id_persona;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
/*
* Nombre: ModificarInvitado
* Descripcion: Modifica un invitado y/o sus datos de persona asociados.
*   - @id_invitado obligatorio.
*   - Permite cambiar datos de la persona (dni, nombre, apellido, email, fecha_nac, telefono).
*   - Permite cambiar el socio invitador (@new_id_socio).
*   - No crea nuevas personas: actualiza la existente v�a usuarios.ModificarPersona.
* Transacci�n expl�cita porque puede afectar persona e invitado.
*/
CREATE OR ALTER PROCEDURE usuarios.ModificarInvitado
    @id_invitado    INT,             
    @dni            VARCHAR(9)    = NULL,  
    @nombre         VARCHAR(50)   = NULL,  
    @apellido       VARCHAR(50)   = NULL,  
    @email          VARCHAR(320)  = NULL,  
    @fecha_nac      DATE          = NULL,  
    @telefono       VARCHAR(20)   = NULL,  
    @new_id_socio   INT           = NULL   
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    DECLARE @cur_persona INT, @cur_socio INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Verificar invitado existe
        IF NOT EXISTS (SELECT 1 FROM usuarios.invitado WHERE id_invitado = @id_invitado)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Invitado no encontrado' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 2) Obtener persona y socio actuales
        SELECT 
            @cur_persona = id_persona,
            @cur_socio   = id_socio
          FROM usuarios.invitado
         WHERE id_invitado = @id_invitado;

         -- 3) Actualizar DNI si se pide
		IF @dni IS NOT NULL
		BEGIN
			-- 3.1) Formato y rango
			IF LEN(@dni) < 7 OR LEN(@dni) > 8 OR @dni LIKE '%[^0-9]%'
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'DNI inv�lido. Debe contener entre 7 y 8 d�gitos num�ricos.' AS Mensaje, '400' AS Estado;
				RETURN;
			END;
			-- 4.2) Unicidad
			IF EXISTS(SELECT 1 FROM usuarios.persona WHERE dni = @dni AND id_persona <> @cur_persona)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'DNI duplicado.' AS Mensaje, '400' AS Estado;
				RETURN;
			END;
			-- 4.3) Update
			UPDATE usuarios.persona
			   SET dni = @dni
			 WHERE id_persona = @cur_persona;
		END;

        -- 3) Actualizar otros campos de persona si se piden
        IF  @nombre     IS NOT NULL
        OR  @apellido   IS NOT NULL
        OR  @email      IS NOT NULL
        OR  @fecha_nac  IS NOT NULL
        OR  @telefono   IS NOT NULL
        BEGIN
            SELECT
                @nombre     = COALESCE(@nombre, nombre),
                @apellido   = COALESCE(@apellido, apellido),
                @email      = COALESCE(@email, email),
                @fecha_nac  = COALESCE(@fecha_nac, fecha_nac),
                @telefono   = COALESCE(@telefono, telefono)
              FROM usuarios.persona
             WHERE id_persona = @cur_persona;

            EXEC usuarios.ModificarPersona
                @id_persona = @cur_persona,
                @nombre     = @nombre,
                @apellido   = @apellido,
                @email      = @email,
                @fecha_nac  = @fecha_nac,
                @telefono   = @telefono;
        END;

        -- 4) Cambiar socio invitador si se pide
        IF @new_id_socio IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM usuarios.socio WHERE id_socio = @new_id_socio AND activo = 1
            )
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Socio no encontrado' AS Mensaje, '404' AS Estado;
                RETURN;
            END
            SET @cur_socio = @new_id_socio;
        END;

        -- 5) Guardar cambios en invitado
        UPDATE usuarios.invitado
           SET id_socio = @cur_socio
         WHERE id_invitado = @id_invitado;

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Invitado modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
/*
* Nombre: EliminarInvitado
* Descripcion: Elimina un invitado y desactiva su persona asociada.
*   - @id_invitado obligatorio.
*   - Marca activo=0 a la persona usando usuarios.EliminarPersona.
*   - Luego elimina el registro de invitado.
* Transacci�n expl�cita porque afecta invitado y persona.
*/
CREATE OR ALTER PROCEDURE usuarios.EliminarInvitado
    @id_invitado INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    DECLARE @cur_persona INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Verificar invitado existe
        SELECT @cur_persona = id_persona
          FROM usuarios.invitado
         WHERE id_invitado = @id_invitado;

        IF @cur_persona IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Invitado no encontrado' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 2) Dar de baja la persona (activo = 0)
        EXEC usuarios.EliminarPersona @id_persona = @cur_persona;

        -- 3) Eliminar registro de invitado
        DELETE FROM usuarios.invitado
         WHERE id_invitado = @id_invitado;

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Invitado y persona eliminados correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
-- ############################################################
-- ###################### SP USUARIO ##########################
-- ############################################################
GO
/*
* Nombre: CrearUsuario
* Descripcion: Crea un usuario reutilizando o creando la persona asociada.
* Parametros:
*   @id_persona    INT           = NULL  � Si existe y activo, se reutiliza; si no, se crea.
*   @dni           VARCHAR(9)           � DNI de la persona.
*   @nombre        VARCHAR(50)          � Nombre de la persona.
*   @apellido      VARCHAR(50)          � Apellido de la persona.
*   @email         VARCHAR(320)         � Email de la persona.
*   @fecha_nac     DATE                 � Fecha de nacimiento de la persona.
*   @telefono      VARCHAR(20)          � Tel�fono de la persona.
*   @username      VARCHAR(50)          � Nombre de usuario (�nico, sin espacios, min�sculas).
*   @password_hash VARCHAR(256)         � Hash de la contrase�a.
*/
CREATE OR ALTER PROCEDURE usuarios.CrearUsuario
    @id_persona    INT           = NULL,
    @dni           VARCHAR(9),
    @nombre        VARCHAR(50),
    @apellido      VARCHAR(50),
    @email         VARCHAR(320),
    @fecha_nac     DATE,
    @telefono      VARCHAR(20),
    @username      VARCHAR(50),
    @password_hash VARCHAR(256)
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
            IF @new_persona IS NULL
            BEGIN
                ROLLBACK TRANSACTION; 
                RETURN;
            END
        END;

        -- 2) Validar username
        IF @username IS NULL OR LTRIM(RTRIM(@username)) = ''
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El username es obligatorio' AS Mensaje, '400' AS Estado;
            RETURN;
        END
        IF @username LIKE '% %' OR @username <> LOWER(@username)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El username no debe tener espacios y debe estar en min�sculas' AS Mensaje, '400' AS Estado;
            RETURN;
        END
        IF EXISTS(SELECT 1 FROM usuarios.usuario WHERE LOWER(username) = LOWER(@username))
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Ya existe un usuario con ese username' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 3) Validar hash
        IF @password_hash IS NULL OR LEN(@password_hash) = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El password_hash es obligatorio' AS Mensaje, '400' AS Estado;
            RETURN;
        END

        -- 4) Insertar usuario
        INSERT INTO usuarios.usuario(id_persona, username, password_hash)
        VALUES(@new_persona, @username, @password_hash);

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Usuario creado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
/*
* Nombre: ModificarUsuario
* Descripcion: Modifica un usuario y/o sus datos de persona asociados.
* Parametros:
*   @id_usuario     INT             � ID del usuario a modificar.
*   @new_id_persona INT           = NULL � (Opcional) Reasignar o crear nueva persona.
*   @dni            VARCHAR(9)    = NULL � (Opcional) Nuevo DNI.
*   @nombre         VARCHAR(50)   = NULL � (Opcional) Nuevo nombre.
*   @apellido       VARCHAR(50)   = NULL � (Opcional) Nuevo apellido.
*   @email          VARCHAR(320)  = NULL � (Opcional) Nuevo email.
*   @fecha_nac      DATE          = NULL � (Opcional) Nueva fecha de nacimiento.
*   @telefono       VARCHAR(20)   = NULL � (Opcional) Nuevo tel�fono.
*   @username       VARCHAR(50)   = NULL � (Opcional) Nuevo username.
*   @password_hash  VARCHAR(256)  = NULL � (Opcional) Nuevo hash de contrase�a.
*   @estado         BIT           = NULL � (Opcional) Nuevo estado (1=activo,0=inactivo).
*/
CREATE OR ALTER PROCEDURE usuarios.ModificarUsuario
    @id_usuario     INT,
    @new_id_persona INT           = NULL,
    @dni            VARCHAR(9)    = NULL,
    @nombre         VARCHAR(50)   = NULL,
    @apellido       VARCHAR(50)   = NULL,
    @email          VARCHAR(320)  = NULL,
    @fecha_nac      DATE          = NULL,
    @telefono       VARCHAR(20)   = NULL,
    @username       VARCHAR(50)   = NULL,
    @password_hash  VARCHAR(256)  = NULL,
    @estado         BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    DECLARE @cur_persona INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Verificar usuario existe y activo
        IF NOT EXISTS(SELECT 1 FROM usuarios.usuario WHERE id_usuario = @id_usuario AND estado = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Usuario no encontrado' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 2) Obtener persona actual
        SELECT @cur_persona = id_persona
          FROM usuarios.usuario
         WHERE id_usuario = @id_usuario;

        -- 3) Reasignar o crear persona si se pidi�
        IF @new_id_persona IS NOT NULL
        BEGIN
            IF EXISTS(SELECT 1 FROM usuarios.persona WHERE id_persona = @new_id_persona AND activo = 1)
                SET @cur_persona = @new_id_persona;
            ELSE IF @dni IS NOT NULL 
                 AND @nombre IS NOT NULL 
                 AND @apellido IS NOT NULL 
                 AND @email IS NOT NULL 
                 AND @fecha_nac IS NOT NULL 
                 AND @telefono IS NOT NULL
            BEGIN
                EXEC usuarios.CrearPersona
                    @dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
                    @id_persona = @cur_persona OUTPUT;
                IF @cur_persona IS NULL
                BEGIN
                    ROLLBACK TRANSACTION;
                    RETURN;
                END
            END
            ELSE
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 
                       'La persona a reasignar no existe y no hay datos para crearla' AS Mensaje, 
                       '400' AS Estado;
                RETURN;
            END;
        END;

        -- 4) Actualizar DNI si se pide
        IF @dni IS NOT NULL
        BEGIN
            IF LEN(@dni) < 7 OR LEN(@dni) > 8 OR @dni LIKE '%[^0-9]%'
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'DNI inv�lido. Debe contener entre 7 y 8 d�gitos num�ricos.' AS Mensaje, '400' AS Estado;
                RETURN;
            END;
            IF EXISTS(SELECT 1 FROM usuarios.persona WHERE dni = @dni AND id_persona <> @cur_persona)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'DNI duplicado.' AS Mensaje, '400' AS Estado;
                RETURN;
            END;
            UPDATE usuarios.persona
               SET dni = @dni
             WHERE id_persona = @cur_persona;
        END;

        -- 5) Actualizar otros campos de persona si se piden
        IF @nombre IS NOT NULL OR @apellido IS NOT NULL OR @email IS NOT NULL OR @fecha_nac IS NOT NULL OR @telefono IS NOT NULL
        BEGIN
            SELECT
                @nombre    = COALESCE(@nombre, nombre),
                @apellido  = COALESCE(@apellido, apellido),
                @email     = COALESCE(@email, email),
                @fecha_nac = COALESCE(@fecha_nac, fecha_nac),
                @telefono  = COALESCE(@telefono, telefono)
              FROM usuarios.persona
             WHERE id_persona = @cur_persona;

            EXEC usuarios.ModificarPersona
                @id_persona = @cur_persona,
                @nombre     = @nombre,
                @apellido   = @apellido,
                @email      = @email,
                @fecha_nac  = @fecha_nac,
                @telefono   = @telefono;
        END;

        -- 6) Validar username si se pide
        IF @username IS NOT NULL
        BEGIN
            IF LTRIM(@username) = '' 
               OR @username LIKE '% %' 
               OR @username <> LOWER(@username)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Username inv�lido (espacios o may�sculas)' AS Mensaje, '400' AS Estado;
                RETURN;
            END;
            IF EXISTS(SELECT 1 FROM usuarios.usuario WHERE username = @username AND id_usuario <> @id_usuario)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Username duplicado' AS Mensaje, '409' AS Estado;
                RETURN;
            END;
        END;

        -- 7) Validar hash si se pide
        IF @password_hash IS NOT NULL AND LEN(@password_hash) = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Password_hash inv�lido' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 8) Actualizar usuario
        UPDATE usuarios.usuario
           SET id_persona    = @cur_persona,
               username      = COALESCE(@username, username),
               password_hash = COALESCE(@password_hash, password_hash),
               estado        = COALESCE(@estado, estado)
         WHERE id_usuario = @id_usuario;

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Usuario modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
/*
* Nombre: EliminarUsuario
* Descripcion: Realiza eliminaci�n l�gica de un usuario (marca estado=0).
* Parametros:
*   @id_usuario INT � ID del usuario a eliminar.
*/
CREATE OR ALTER PROCEDURE usuarios.EliminarUsuario
    @id_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    -- 1) Verificar existencia y activo
    IF NOT EXISTS(SELECT 1 FROM usuarios.usuario WHERE id_usuario = @id_usuario AND estado = 1)
    BEGIN
        SELECT 'Error' AS Resultado, 'Usuario no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE usuarios.usuario
           SET estado = 0
         WHERE id_usuario = @id_usuario;
        SELECT 'OK' AS Resultado, 'Usuario dado de baja correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
-- ############################################################
-- ##################### SP RESPONSABLE [REVISAR LOGICA] #######################
-- ############################################################
GO
/*
* Nombre: CrearResponsable
* Descripcion: Crea un responsable, reutilizando o creando la persona asociada.
* Parametros:
*   @id_persona  INT           = NULL  � Si existe y activo, se reutiliza; si no, se crea.
*   @dni         VARCHAR(9)           � DNI de la persona.
*   @nombre      VARCHAR(50)          � Nombre de la persona.
*   @apellido    VARCHAR(50)          � Apellido de la persona.
*   @email       VARCHAR(320)         � Email de la persona.
*   @fecha_nac   DATE                 � Fecha de nacimiento.
*   @telefono    VARCHAR(20)          � Tel�fono de la persona.
*   @id_grupo    INT                  � FK a usuarios.grupo_familiar.
*   @parentesco  VARCHAR(10)          � Parentesco de la persona con el grupo.
* Aclaracion: Se utiliza transacci�n expl�cita porque se afectan dos tablas.
*/
CREATE OR ALTER PROCEDURE usuarios.CrearResponsable
    @id_persona  INT = NULL,
    @dni         VARCHAR(9),
    @nombre      VARCHAR(50),
    @apellido    VARCHAR(50),
    @email       VARCHAR(320),
    @fecha_nac   DATE,
    @telefono    VARCHAR(20),
    @id_grupo    INT,
    @parentesco  VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    DECLARE @new_persona INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Reutilizar persona existente o crear nueva
        IF @id_persona IS NOT NULL
        BEGIN
            -- Si me pasaron un ID, debe existir
            IF EXISTS (SELECT 1 FROM usuarios.persona WHERE id_persona = @id_persona AND activo = 1)
                SET @new_persona = @id_persona;
            ELSE
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 
                       'La persona a reasignar no existe' AS Mensaje, 
                       '404' AS Estado;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- No me pasaron ID: creo una nueva persona
            EXEC usuarios.CrearPersona
                @dni, @nombre, @apellido, @email, @fecha_nac, @telefono,
                @id_persona = @new_persona OUTPUT;
            IF @new_persona IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END;


        -- 2) Verificar grupo existente y activo
        IF NOT EXISTS(SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @id_grupo AND estado = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 3) Validar parentesco
        IF @parentesco IS NULL OR LTRIM(RTRIM(@parentesco)) = ''
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El parentesco es obligatorio' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 4) Verificar que la persona no sea ya responsable
        IF EXISTS(SELECT 1 FROM usuarios.responsable WHERE id_persona = @new_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona ya es responsable de otro grupo' AS Mensaje, '400' AS Estado;
            RETURN;
        END;

        -- 5) Inserto responsable
        INSERT INTO usuarios.responsable(id_grupo, id_persona, parentesco)
        VALUES(@id_grupo, @new_persona, LTRIM(RTRIM(@parentesco)));

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Responsable creado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
/*
* Nombre: ModificarResponsable
* Descripcion: Modifica un responsable y/o sus datos de persona asociados.
* Parametros:
*   @id_responsable INT           � ID del responsable a modificar.
*   @new_id_persona  INT     = NULL � (Opcional) Reasignar o crear nueva persona.
*   @dni             VARCHAR(9)    = NULL � (Opcional) Nuevo DNI.
*   @nombre          VARCHAR(50)   = NULL � (Opcional) Nuevo nombre.
*   @apellido        VARCHAR(50)   = NULL � (Opcional) Nuevo apellido.
*   @email           VARCHAR(320)  = NULL � (Opcional) Nuevo email.
*   @fecha_nac       DATE          = NULL � (Opcional) Nueva fecha de nacimiento.
*   @telefono        VARCHAR(20)   = NULL � (Opcional) Nuevo tel�fono.
*   @new_id_grupo    INT           = NULL � (Opcional) Nuevo grupo familiar.
*   @parentesco      VARCHAR(10)   = NULL � (Opcional) Nuevo parentesco.
* Aclaracion: Se utiliza transacci�n expl�cita porque puede afectar varias tablas.
*/
CREATE OR ALTER PROCEDURE usuarios.ModificarResponsable
    @id_responsable INT,
    @new_id_persona  INT           = NULL,
    @dni             VARCHAR(9)    = NULL,
    @nombre          VARCHAR(50)   = NULL,
    @apellido        VARCHAR(50)   = NULL,
    @email           VARCHAR(320)  = NULL,
    @fecha_nac       DATE          = NULL,
    @telefono        VARCHAR(20)   = NULL,
    @new_id_grupo    INT           = NULL,
    @parentesco      VARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    DECLARE @cur_persona INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1) Verificar responsable existe
        IF NOT EXISTS(SELECT 1 FROM usuarios.responsable WHERE id_responsable = @id_responsable)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Responsable no encontrado' AS Mensaje, '404' AS Estado;
            RETURN;
        END;

        -- 2) Obtener persona actual
        SELECT @cur_persona = id_persona
          FROM usuarios.responsable
         WHERE id_responsable = @id_responsable;

        -- 3) Reasignar o crear persona si se pidi�
        IF @new_id_persona IS NOT NULL
        BEGIN
            IF EXISTS(SELECT 1 FROM usuarios.persona WHERE id_persona = @new_id_persona AND activo = 1)
                SET @cur_persona = @new_id_persona;
            ELSE IF @dni IS NOT NULL AND @nombre IS NOT NULL AND @apellido IS NOT NULL AND @email IS NOT NULL AND @fecha_nac IS NOT NULL AND @telefono IS NOT NULL
                EXEC usuarios.CrearPersona @dni, @nombre, @apellido, @email, @fecha_nac, @telefono, @id_persona = @cur_persona OUTPUT;
            ELSE
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'La persona a reasignar no existe y no hay datos para crearla' AS Mensaje, '400' AS Estado;
                RETURN;
            END;
            IF @cur_persona IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                RETURN;
            END;
        END;

		-- 4) Actualizar DNI si se pide
		IF @dni IS NOT NULL
		BEGIN
			-- 4.1) Formato y rango
			IF LEN(@dni) < 7 OR LEN(@dni) > 8 OR @dni LIKE '%[^0-9]%'
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'DNI inv�lido. Debe contener entre 7 y 8 d�gitos num�ricos.' AS Mensaje, '400' AS Estado;
				RETURN;
			END;
			-- 4.2) Unicidad
			IF EXISTS(SELECT 1 FROM usuarios.persona WHERE dni = @dni AND id_persona <> @cur_persona)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'DNI duplicado.' AS Mensaje, '400' AS Estado;
				RETURN;
			END;
			-- 4.3) Update
			UPDATE usuarios.persona
			   SET dni = @dni
			 WHERE id_persona = @cur_persona;
		END;

        -- 5) Actualizar otros campos de persona si se piden
        IF  @nombre    IS NOT NULL
        OR  @apellido  IS NOT NULL
        OR  @email     IS NOT NULL
        OR  @fecha_nac IS NOT NULL
        OR  @telefono  IS NOT NULL
        BEGIN
            SELECT
                @nombre     = COALESCE(@nombre, nombre), -- coalesce agarra el primer NO-NULL
                @apellido   = COALESCE(@apellido, apellido),
                @email      = COALESCE(@email, email),
                @fecha_nac  = COALESCE(@fecha_nac, fecha_nac),
                @telefono   = COALESCE(@telefono, telefono)
            FROM usuarios.persona
            WHERE id_persona = @cur_persona;

            EXEC usuarios.ModificarPersona
                @id_persona = @cur_persona,
                @nombre     = @nombre,
                @apellido   = @apellido,
                @email      = @email,
                @fecha_nac  = @fecha_nac,
                @telefono   = @telefono;
        END;

        -- 6) Validar grupo si se pidi�
        IF @new_id_grupo IS NOT NULL
        BEGIN
            IF NOT EXISTS(SELECT 1 FROM usuarios.grupo_familiar WHERE id_grupo_familiar = @new_id_grupo AND estado = 1)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje, '404' AS Estado;
                RETURN;
            END;
            IF EXISTS(SELECT 1 FROM usuarios.responsable WHERE id_grupo = @new_id_grupo AND id_responsable <> @id_responsable)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Ya existe otro responsable para ese grupo' AS Mensaje, '400' AS Estado;
                RETURN;
            END;
        END;

        -- 7) Validar parentesco si se pidi�
        IF @parentesco IS NOT NULL
        BEGIN
            IF LTRIM(RTRIM(@parentesco)) = ''
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El parentesco no puede estar vac�o' AS Mensaje, '400' AS Estado;
                RETURN;
            END;
        END;

        -- 8) Actualizar responsable
        UPDATE usuarios.responsable
        SET
            id_persona = @cur_persona,
            id_grupo   = COALESCE(@new_id_grupo, id_grupo),
            parentesco = COALESCE(LTRIM(RTRIM(@parentesco)), parentesco)
        WHERE id_responsable = @id_responsable;

        COMMIT TRANSACTION;
        SELECT 'OK' AS Resultado, 'Responsable modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
/*
* Nombre: EliminarResponsable
* Descripcion: Realiza eliminaci�n f�sica de un responsable.
* Parametros:
*   @id_responsable INT � ID del responsable a eliminar.
* Aclaracion: No se utiliza transacci�n expl�cita ya que solo se trabaja con una �nica tabla.
*/
CREATE OR ALTER PROCEDURE usuarios.EliminarResponsable
    @id_responsable INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM usuarios.responsable WHERE id_responsable = @id_responsable)
    BEGIN
        SELECT 'Error' AS Resultado, 'Responsable no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM usuarios.responsable WHERE id_responsable = @id_responsable;
        SELECT 'OK' AS Resultado, 'Responsable eliminado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
-- ############################################################
-- ######################## SP ROL ############################
-- ############################################################
GO
/*
* Nombre: CrearRol
* Descripcion: Inserta un nuevo rol en la tabla usuarios.Rol, validando su informacion.
* Parametros:
*   @nombre VARCHAR(50)       - Nombre del rol.
*   @descripcion VARCHAR(100) - Descripcion del rol.
* Aclaracion: No se utiliza transacciones explicitas ya que: 
*   Solo se trabaja con una unica tabla y ejecutando sentencia DML
*/
GO
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
    IF EXISTS (SELECT 1 FROM usuarios.Rol WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre))))
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe un rol con ese nombre.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        INSERT INTO usuarios.Rol (nombre, descripcion)
        VALUES (LOWER(LTRIM(RTRIM(@nombre))), LTRIM(RTRIM(@descripcion)));
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
         WHERE LOWER(nombre) = LOWER(LTRIM(RTRIM(@nombre)))
           AND id_rol <> @id_rol
    )
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe otro rol con ese nombre.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE usuarios.Rol
           SET nombre      = LOWER(LTRIM(RTRIM(@nombre))),
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
-- ######################## SP usuario_rol ############################
-- ############################################################
GO
CREATE OR ALTER PROCEDURE usuarios.asignarRolUsuario
	@id_usuario INT,
	@id_rol INT
AS
BEGIN 
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Validar si existe el usuario
		IF @id_usuario IS NULL OR NOT EXISTS (
			SELECT 1 FROM usuarios.usuario WHERE id_usuario = @id_usuario
		)
		BEGIN
			SELECT 'Error' AS Resultado, 'Usuario no encontrado' AS Mensaje, '404' AS Estado;
			ROLLBACK;
			RETURN;
		END;

		-- Validar si existe el rol
		IF @id_rol IS NULL OR NOT EXISTS (
			SELECT 1 FROM usuarios.rol WHERE id_rol = @id_rol
		)
		BEGIN
			SELECT 'Error' AS Resultado, 'Rol no encontrado' AS Mensaje, '404' AS Estado;
			ROLLBACK;
			RETURN;
		END;

		-- Validar que el rol ya no fue asignado a la persona
		IF EXISTS (
			SELECT 1 FROM usuarios.usuario_rol 
			WHERE id_usuario = @id_usuario AND id_rol = @id_rol
		)
		BEGIN
			SELECT 'Error' AS Resultado, 'El rol ya est� asignado al usuario' AS Mensaje, '409' AS Estado;
			ROLLBACK;
			RETURN;
		END;

		-- Insertar asignaci�n
		INSERT INTO usuarios.usuario_rol (id_usuario, id_rol)
		VALUES (@id_usuario, @id_rol);

		COMMIT;
		SELECT 'OK' AS Resultado, 'Rol asignado al usuario' AS Mensaje, '200' AS Estado;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
	END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE usuarios.eliminarRolUsuario
    @id_usuario INT,
    @id_rol INT
AS
BEGIN
    SET NOCOUNT ON;

    -- validaciones de entrada
    IF @id_usuario IS NULL OR @id_rol IS NULL
    BEGIN
        SELECT 'Error' AS Resultado, 'El id_usuario y el id_rol no pueden ser nulos.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- verificar que exista la asocacion 
    IF NOT EXISTS (
        SELECT 1 FROM usuarios.Usuario_Rol 
        WHERE id_usuario = @id_usuario AND id_rol = @id_rol
    )
    BEGIN
        SELECT 'Error' AS Resultado, 'La relacion entre el usuario y el rol no existe.' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM usuarios.Usuario_Rol 
        WHERE id_usuario = @id_usuario AND id_rol = @id_rol;

        SELECT 'OK' AS Resultado, 'Rol eliminado correctamente del usuario' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
-- ############################################################
-- #################### SP CATEGORIA ##########################
-- ############################################################
GO
/*
* Nombre: CrearCategoria
* Descripcion: Inserta una nueva categor�a en la tabla actividades.categoria, validando su informaci�n.
* Parametros:
*   @nombre_categoria VARCHAR(50) - Nombre de la categor�a.
*   @costo_membrecia  DECIMAL(10,2) - Costo de membres�a (debe ser > 0).
*   @vigencia         DATE - Fecha de vigencia de la categor�a.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
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
        SELECT 'Error' AS Resultado, 'El nombre de la categor�a es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido costo
    IF @costo_membrecia <= 0
    BEGIN
        SELECT 'Error' AS Resultado, 'El costo de membres�a debe ser mayor a 0' AS Mensaje, '400' AS Estado;
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
        WHERE LOWER(nombre_categoria) = LOWER(LTRIM(RTRIM(@nombre_categoria)))
    )
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe una categor�a con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        INSERT INTO actividades.categoria(nombre_categoria, costo_membrecia, vigencia)
        VALUES (LOWER(LTRIM(RTRIM(@nombre_categoria))), @costo_membrecia, @vigencia);
        SELECT 'OK' AS Resultado, 'Categor�a creada correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
/*
* Nombre: ModificarCategoria
* Descripcion: Modifica los datos de una categor�a existente, validando su informaci�n.
* Parametros:
*   @id_categoria     INT - ID de la categor�a a modificar.
*   @nombre_categoria VARCHAR(50) - Nuevo nombre de la categor�a.
*   @costo_membrecia  DECIMAL(10,2) - Nuevo costo de membres�a (debe ser > 0).
*   @vigencia         DATE - Nueva fecha de vigencia.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
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
        SELECT 'Error' AS Resultado, 'Categor�a no encontrada' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    -- Valido nombre
    IF @nombre_categoria IS NULL OR LTRIM(RTRIM(@nombre_categoria)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El nombre de la categor�a es obligatorio' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    -- Valido costo
    IF @costo_membrecia <= 0
    BEGIN
        SELECT 'Error' AS Resultado, 'El costo de membres�a debe ser mayor a 0' AS Mensaje, '400' AS Estado;
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
        WHERE LOWER(nombre_categoria) = LOWER(LTRIM(RTRIM(@nombre_categoria))) AND id_categoria <> @id_categoria)
    BEGIN
        SELECT 'Error' AS Resultado, 'Ya existe otra categor�a con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        UPDATE actividades.categoria
        SET
            nombre_categoria = LOWER(LTRIM(RTRIM(@nombre_categoria))),
            costo_membrecia  = @costo_membrecia,
            vigencia         = @vigencia
        WHERE id_categoria = @id_categoria;
        SELECT 'OK' AS Resultado, 'Categor�a modificada correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
/*
* Nombre: EliminarCategoria
* Descripcion: Elimina f�sicamente una categor�a de la tabla actividades.categoria.
* Parametros:
*   @id_categoria INT - ID de la categor�a a eliminar.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
*/
CREATE OR ALTER PROCEDURE actividades.EliminarCategoria
    @id_categoria INT
AS
BEGIN
    SET NOCOUNT ON;
    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
    BEGIN
        SELECT 'Error' AS Resultado, 'Categor�a no encontrada' AS Mensaje, '404' AS Estado;
        RETURN;
    END;
    BEGIN TRY
        DELETE FROM actividades.categoria
        WHERE id_categoria = @id_categoria;
        SELECT 'OK' AS Resultado, 'Categor�a eliminada correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
-- ############################################################
-- ###################### ACTIVIDAD ###########################
-- ############################################################
GO
/*
* Nombre: CrearActividad
* Descripcion: Crea una nueva actividad, validando que el nombre no exista y que el costo sea v�lido.
* Parametros:
*   @nombre_actividad VARCHAR(100) - Nombre de la actividad.
*   @costo_mensual DECIMAL(10,2) - Costo mensual de la actividad.
* Valores de retorno:
*    0: �xito.
*   -1: El nombre de la actividad es nulo o vac�o.
*   -2: Ya existe una actividad con ese nombre.
*   -3: El costo mensual es inv�lido.
*  -999: Error desconocido.
*/
CREATE OR ALTER PROCEDURE actividades.CrearActividad
	@nombre_actividad VARCHAR(100),
	@costo_mensual DECIMAL(10,2)
AS
BEGIN
	BEGIN TRY
		-- Chequeo que el nombre no sea nulo ni vacio
		IF @nombre_actividad IS NULL OR LTRIM(RTRIM(@nombre_actividad)) = ''
		BEGIN
			SELECT 'Error' AS Resultado, 'El nombre de actividad no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM actividades.actividad WHERE nombre = @nombre_actividad)
		BEGIN
			SELECT 'Error' AS Resultado, 'Ya existe una actividad con ese nombre' AS Mensaje;
			RETURN -2;
		END

		-- Verifico que el costo sea valido (>0)
		IF @costo_mensual IS NULL OR @costo_mensual <= 0
		BEGIN
			SELECT 'Error' AS Resultado, 'El costo mensual debe ser mayor a cero' AS Mensaje;
			RETURN -3;
		END

		INSERT INTO actividades.actividad(nombre, costo_mensual)
		VALUES (@nombre_actividad, @costo_mensual);

		SELECT 'Exito' AS Resultado, 'Actividad creada correctamente' AS Mensaje;
		RETURN 0;

	END TRY

	BEGIN CATCH
		SELECT 
			'Error' AS Resultado,
			ERROR_MESSAGE() AS Mensaje,
			ERROR_NUMBER() AS CodigoError,
			ERROR_LINE() AS Linea,
			ERROR_PROCEDURE() AS Procedimiento;
		RETURN -999;
	END CATCH
END;
GO
/*
* Nombre: ModificarActividad
* Descripcion: Modifica el nombre y el costo mensual de una actividad existente, validando que el nombre no se repita y que el costo sea v�lido.
* Parametros:
*   @id INT - ID de la actividad a modificar.
*   @nombre_actividad VARCHAR(100) - Nuevo nombre de la actividad.
*   @costo_mensual DECIMAL(10,2) - Nuevo costo mensual de la actividad.
* Valores de retorno:
*    0: �xito.
*   -1: ID nulo.
*   -2: ID no existente.
*   -3: El nombre de la actividad es nulo o vac�o.
*   -4: Ya existe una actividad con ese nombre.
*   -5: El costo mensual es inv�lido.
*  -999: Error desconocido.
*/
CREATE OR ALTER PROCEDURE actividades.ModificarActividad
	@id INT,
	@nombre_actividad VARCHAR(100),
	@costo_mensual DECIMAL(10,2)
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
		IF NOT EXISTS (SELECT 1 FROM actividades.actividad WHERE id_actividad = @id)
		BEGIN
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -2;
		END

		-- Chequeo que el nombre no sea nulo ni vacio
		IF @nombre_actividad IS NULL OR LTRIM(RTRIM(@nombre_actividad)) = ''
		BEGIN
			SELECT 'Error' AS Resultado, 'El nombre de actividad no puede ser nulo o vacio' AS Mensaje;
			RETURN -3;
		END

		-- Verifico que no exista ya en la tabla otro registro con mismo nombre
		IF EXISTS (
			SELECT 1 FROM actividades.actividad
			WHERE nombre = @nombre_actividad AND id_actividad <> @id
		)
		BEGIN
			SELECT 'Error' AS Resultado, 'Ya existe una actividad con ese nombre' AS Mensaje;
			RETURN -4;
		END

		-- Verifico que el costo sea valido (>0)
		IF @costo_mensual IS NULL OR @costo_mensual <= 0
		BEGIN
			SELECT 'Error' AS Resultado, 'El costo mensual debe ser mayor a cero' AS Mensaje;
			RETURN -5;
		END

		UPDATE actividades.actividad
		SET nombre = @nombre_actividad,
			costo_mensual = @costo_mensual
		WHERE id_actividad = @id;

		SELECT 'Exito' AS Resultado, 'Actividad modificada correctamente' AS Mensaje;
		RETURN 0;

	END TRY

	BEGIN CATCH
		SELECT 
			'Error' AS Resultado,
			ERROR_MESSAGE() AS Mensaje,
			ERROR_NUMBER() AS CodigoError,
			ERROR_LINE() AS Linea,
			ERROR_PROCEDURE() AS Procedimiento;
		RETURN -999;
	END CATCH
END;
GO
/*
* Nombre: EliminarActividad
* Descripcion: Realiza una eliminaci�n l�gica de una actividad, cambiando su estado a inactiva.
* Parametros:
*   @id INT - ID de la actividad a eliminar.
* Valores de retorno:
*    0: �xito.
*   -1: ID nulo.
*   -2: ID no existente o ya eliminada.
*  -999: Error desconocido.
*/
CREATE OR ALTER PROCEDURE actividades.EliminarActividad
	@id INT
AS
BEGIN
	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que exista en la tabla y que est� activa
		IF NOT EXISTS (SELECT 1 FROM actividades.actividad WHERE id_actividad = @id AND estado = 1)
		BEGIN
			SELECT 'Error' AS Resultado, 'id no existente o ya eliminada' AS Mensaje;
			RETURN -2;
		END

		-- Eliminaci�n logica
		UPDATE actividades.actividad SET estado = 0 WHERE id_actividad = @id;

		SELECT 'Exito' AS Resultado, 'Actividad eliminada l�gicamente correctamente' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		SELECT 
			'Error' AS Resultado,
			ERROR_MESSAGE() AS Mensaje,
			ERROR_NUMBER() AS CodigoError,
			ERROR_LINE() AS Linea,
			ERROR_PROCEDURE() AS Procedimiento;
		RETURN -999;
	END CATCH
END;
GO
-- ############################################################
-- ######################## SP CLASE ##########################
-- ############################################################
GO
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
		
		-- 1) Validar actividad (incluyendo estado activo)
		IF NOT EXISTS (SELECT 1 FROM actividades.actividad WHERE id_actividad = @id_actividad AND estado = 1)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La actividad no existe o no est� activa' AS Mensaje, '404' AS Estado;
			RETURN -1;
		END;
		
		-- 2) Validar categoria (asumiendo que tambi�n tiene estado)
		IF NOT EXISTS (SELECT 1 FROM actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La categoria no existe' AS Mensaje, '404' AS Estado;
			RETURN -2;
		END;
		
		-- 3) Validar usuario
		IF NOT EXISTS (SELECT 1 FROM usuarios.usuario WHERE id_usuario = @id_usuario)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El usuario no existe' AS Mensaje, '404' AS Estado;
			RETURN -3;
		END;
		
		-- 4) Normalizar d�a (la validaci�n la hace el constraint de la tabla)
		SET @dia = LOWER(LTRIM(RTRIM(@dia)));
		
		-- 5) Validar horario
		IF @horario < '06:00:00' OR @horario >= '22:00:00'
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Horario invalido (debe ser entre 06:00 y 22:00)' AS Mensaje, '400' AS Estado;
			RETURN -4;
		END;
		
		-- 6) Conflicto exacto
		IF EXISTS (
			SELECT 1 
			FROM actividades.clase 
			WHERE id_actividad = @id_actividad
			AND id_categoria = @id_categoria
			AND dia = @dia
			AND horario = @horario
			AND estado = 1
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe una clase activa con la misma actividad, categoria, dia y horario' AS Mensaje, '409' AS Estado;
			RETURN -5;
		END;
		
		-- 7) Conflicto profesor
		IF EXISTS (
			SELECT 1 
			FROM actividades.clase 
			WHERE id_usuario = @id_usuario
			AND dia = @dia
			AND horario = @horario
			AND estado = 1
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El profesor ya tiene otra clase activa en ese dia y horario' AS Mensaje, '409' AS Estado;
			RETURN -6;
		END;
		
		-- Insertar la nueva clase
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
GO
-- ############################################################
-- #################### SP METODO PAGO ########################
-- ############################################################
GO	
/*
* Nombre: CrearMetodoPago
* Descripcion: Crea un nuevo m�todo de pago, validando que el nombre no sea nulo, vac�o ni repetido.
* Parametros:
*   @nombre VARCHAR(50) - Nombre del m�todo de pago.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
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
        SELECT 'Error' AS Resultado, 'Ya existe un m�todo de pago con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO facturacion.metodo_pago(nombre)
        VALUES (LTRIM(RTRIM(@nombre)));
        SELECT 'OK' AS Resultado, 'M�todo de pago creado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
/*
* Nombre: ModificarMetodoPago
* Descripcion: Modifica el nombre de un m�todo de pago existente, validando par�metros y unicidad.
* Parametros:
*   @id_metodo_pago INT     - ID del m�todo de pago a modificar.
*   @nombre          VARCHAR(50) - Nuevo nombre. Opcional.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
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
        SELECT 'Error' AS Resultado, 'M�todo de pago no encontrado' AS Mensaje, '404' AS Estado;
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
        SELECT 'Error' AS Resultado, 'Ya existe otro m�todo de pago con ese nombre' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        UPDATE facturacion.metodo_pago
        SET nombre = LTRIM(RTRIM(@nombre))
        WHERE id_metodo_pago = @id_metodo_pago;
        SELECT 'OK' AS Resultado, 'M�todo de pago modificado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;
GO
/*
* Nombre: EliminarMetodoPago
* Descripcion: Elimina f�sicamente un m�todo de pago.
* Parametros:
*   @id_metodo_pago INT - ID del m�todo de pago a eliminar.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
*/
CREATE OR ALTER PROCEDURE facturacion.EliminarMetodoPago
    @id_metodo_pago INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido existencia
    IF NOT EXISTS (SELECT 1 FROM facturacion.metodo_pago WHERE id_metodo_pago = @id_metodo_pago)
    BEGIN
        SELECT 'Error' AS Resultado, 'M�todo de pago no encontrado' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM facturacion.metodo_pago
        WHERE id_metodo_pago = @id_metodo_pago;
        SELECT 'OK' AS Resultado, 'M�todo de pago eliminado correctamente' AS Mensaje, '200' AS Estado;
    END TRY

    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;

END;





GO
-- ############################################################
-- ###################### SP FACTURA ##########################
-- ############################################################
GO
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
-- #################### SP DESCUENTO ##########################
-- ############################################################
/*
* Nombre: CrearDescuento
* Descripcion: Inserta un nuevo descuento en la tabla facturacion.descuento, validando su informaci�n.
* Parametros:
*   @descripcion VARCHAR(100) - Descripci�n del descuento.
*   @cantidad    DECIMAL(10,2) - Valor del descuento (>= 0).
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
*/
CREATE OR ALTER PROCEDURE facturacion.CrearDescuento
    @descripcion VARCHAR(100),
    @cantidad    DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Valido descripci�n
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La descripci�n es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- Valido cantidad
    IF @cantidad < 0
    BEGIN
        SELECT 'Error' AS Resultado, 'Cantidad inv�lida. Debe ser mayor o igual a 0' AS Mensaje, '400' AS Estado;
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
*   @descripcion  VARCHAR(100)  - Nueva descripci�n. Obligatoria.
*   @cantidad     DECIMAL(10,2) - Nuevo valor del descuento (>= 0). Obligatorio.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
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

    -- Valido descripci�n
    IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La descripci�n es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    -- Valido cantidad
    IF @cantidad < 0
    BEGIN
        SELECT 'Error' AS Resultado, 'Cantidad inv�lida. Debe ser mayor o igual a 0' AS Mensaje, '400' AS Estado;
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
* Descripcion: Elimina f�sicamente un descuento de la tabla facturacion.descuento.
* Parametros:
*   @id_descuento INT - ID del descuento a eliminar.
* Aclaracion: No se utilizan transacciones expl�citas ya que solo se trabaja con una �nica tabla.
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
-- ##################### SP CLIMA ###################
-- ############################################################
GO
/*
* Nombre: RegistrarClima
* Descripci�n: Registra un nuevo registro de clima.
* Parametros:
*   @fecha   DATE         � Fecha del registro clim�tico.
*   @lluvia  DECIMAL(5,2) � Mil�metros de lluvia (>= 0).
* Aclaraci�n:
*   No se utiliza transacci�n expl�cita ya que se inserta en una �nica tabla.
*/
CREATE OR ALTER PROCEDURE facturacion.RegistrarClima
    @fecha  DATE,
    @lluvia DECIMAL(5,2)
AS BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @fecha IS NULL
    BEGIN
        SELECT 'Error' AS Resultado, 'La fecha es obligatoria.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    IF @fecha > GETDATE()
    BEGIN
        SELECT 'Error' AS Resultado, 'La fecha no puede ser futura' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    IF @lluvia IS NULL
    BEGIN
        SELECT 'Error' AS Resultado, 'La cantidad de lluvia es obligatoria' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    IF @lluvia < 0
    BEGIN
        SELECT 'Error' AS Resultado, 'La cantidad de lluvia no puede ser negativa' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO facturacion.clima(fecha, lluvia)
        VALUES(@fecha, @lluvia);

        SELECT 'OK' AS Resultado, 'Clima registrado correctamente' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
-- ############################################################
-- ####################### SP EMPRESA ###################
-- ############################################################
GO
/*
* Nombre: CrearEmpresa
* Descripci�n: Inserta una nueva empresa en la tabla facturacion.datos_empresa.
* Parsmetros:
*   @cuit_emisor         VARCHAR(20) � CUIT del emisor (obligatorio).
*   @domicilio_comercial VARCHAR(25) � Domicilio comercial (obligatorio).
*   @condicion_IVA       VARCHAR(25) � Condici�n frente al IVA (obligatorio).
*   @nombre              VARCHAR(35) � Nombre de la empresa (opcional).
* Aclaraci�n:
*   No se utiliza transacci�n expl�cita ya que solo se afecta una tabla.
*/
CREATE OR ALTER PROCEDURE facturacion.CrearEmpresa
    @cuit_emisor         VARCHAR(20),
    @domicilio_comercial VARCHAR(25),
    @condicion_IVA       VARCHAR(25),
    @nombre              VARCHAR(35) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validaciones
    IF @cuit_emisor IS NULL OR LTRIM(RTRIM(@cuit_emisor)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El CUIT del emisor es obligatorio.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    IF @domicilio_comercial IS NULL OR LTRIM(RTRIM(@domicilio_comercial)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'El domicilio comercial es obligatorio.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;
    IF @condicion_IVA IS NULL OR LTRIM(RTRIM(@condicion_IVA)) = ''
    BEGIN
        SELECT 'Error' AS Resultado, 'La condici�n frente al IVA es obligatoria.' AS Mensaje, '400' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO facturacion.datos_empresa (cuit_emisor, domicilio_comercial, condicion_IVA, nombre)
        VALUES (
            LTRIM(RTRIM(@cuit_emisor)),
            LTRIM(RTRIM(@domicilio_comercial)),
            LTRIM(RTRIM(@condicion_IVA)),
            NULLIF(LTRIM(RTRIM(@nombre)), '')
        );

        SELECT 'OK' AS Resultado, 'Empresa creada correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
/*
* Nombre: ModificarEmpresa
* Descripci�n: Modifica los datos de una empresa.
* Par�metros:
*   @id_empresa          INT         � ID de la empresa (obligatorio).
*   @cuit_emisor         VARCHAR(20) � Nuevo CUIT del emisor (opcional).
*   @domicilio_comercial VARCHAR(25) � Nuevo domicilio comercial (opcional).
*   @condicion_IVA       VARCHAR(25) � Nueva condici�n frente al IVA (opcional).
*   @nombre              VARCHAR(35) � Nuevo nombre de la empresa (opcional).
* Aclaraci�n:
*   No se utiliza transacci�n expl�cita ya que solo se trabaja con una �nica tabla.
*/
CREATE OR ALTER PROCEDURE facturacion.ModificarEmpresa
    @id_empresa          INT,
    @cuit_emisor         VARCHAR(20) = NULL,
    @domicilio_comercial VARCHAR(25) = NULL,
    @condicion_IVA       VARCHAR(25) = NULL,
    @nombre              VARCHAR(35) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM facturacion.datos_empresa WHERE id_empresa = @id_empresa)
    BEGIN
        SELECT 'Error' AS Resultado, 'Empresa no encontrada.' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        UPDATE facturacion.datos_empresa
           SET cuit_emisor         = COALESCE(NULLIF(LTRIM(RTRIM(@cuit_emisor)), ''), cuit_emisor),
               domicilio_comercial = COALESCE(NULLIF(LTRIM(RTRIM(@domicilio_comercial)), ''), domicilio_comercial),
               condicion_IVA       = COALESCE(NULLIF(LTRIM(RTRIM(@condicion_IVA)), ''), condicion_IVA),
               nombre              = COALESCE(NULLIF(LTRIM(RTRIM(@nombre)), ''), nombre)
         WHERE id_empresa = @id_empresa;

        SELECT 'OK' AS Resultado, 'Empresa modificada correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
/*
* Nombre: EliminarEmpresa
* Descripci�n: Elimina una empresa f�sicamente de la base.
* Par�metros:
*   @id_empresa INT � ID de la empresa a eliminar.
* Aclaraci�n:
*   No se utiliza transacci�n expl�cita ya que solo se afecta una tabla.
*/
CREATE OR ALTER PROCEDURE facturacion.EliminarEmpresa
    @id_empresa INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM facturacion.datos_empresa WHERE id_empresa = @id_empresa)
    BEGIN
        SELECT 'Error' AS Resultado, 'Empresa no encontrada.' AS Mensaje, '404' AS Estado;
        RETURN;
    END;

    BEGIN TRY
        DELETE FROM facturacion.datos_empresa
         WHERE id_empresa = @id_empresa;

        SELECT 'OK' AS Resultado, 'Empresa eliminada correctamente.' AS Mensaje, '200' AS Estado;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje, '500' AS Estado;
    END CATCH;
END;
GO
