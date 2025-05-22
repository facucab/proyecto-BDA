/*
Entrega 4 - Documento de instalación y configuración
Fecha de entrega: 23/05/2025
Grupo: 01
Materia: Bases de Datos Aplicadas (3641)
Integrantes:
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

Enunciado:
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
	fecha_alta DATE NOT NULL DEFAULT GETDATE(),
	activo BIT NOT NULL DEFAULT 1
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
    fecha_alta_contraseña DATE NOT NULL DEFAULT GETDATE(),
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
CREATE TABLE manejo_personas.Rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL
);

-- USUARIO <-N----N-> ROL
CREATE TABLE manejo_personas.Usuario_Rol (
    id_usuario INT NOT NULL,
    id_rol INT NOT NULL,
    PRIMARY KEY (id_usuario, id_rol),
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Usuario_Rol_Usuario FOREIGN KEY (id_usuario) REFERENCES manejo_personas.usuario(id_usuario),
    CONSTRAINT FK_Usuario_Rol_Rol FOREIGN KEY (id_rol) REFERENCES manejo_personas.rol(id_rol)
);

-- SOCIO <-N----N-> ACTIVIDAD
CREATE TABLE manejo_personas.socio_actividad (  
    id_socio INT NOT NULL,
    id_actividad INT NOT NULL,
    fecha_inicio DATE NOT NULL DEFAULT GETDATE(),
    PRIMARY KEY (id_socio, id_actividad),
	-- SCHEMA PARA PERSONAS
    CONSTRAINT FK_Socio_Actividad_Socio FOREIGN KEY (id_socio) REFERENCES manejo_personas.socio(id_socio),
	-- SCHEMA PARA ACTIVIDADES
    CONSTRAINT FK_Socio_Actividad_Actividad FOREIGN KEY (id_actividad) REFERENCES manejo_actividades.actividad(id_actividad)
);


-- METODO_PAGO
CREATE TABLE pagos_y_facturas.metodo_pago (
	id_metodo_pago INT IDENTITY(1,1) PRIMARY KEY,
	nombre VARCHAR(50) NOT NULL
);

-- DESCUENTO
CREATE TABLE pagos_y_facturas.descuento (
	id_descuento INT IDENTITY(1,1) PRIMARY KEY,
	descripcion VARCHAR(100) NOT NULL,
	valor DECIMAL(10,2) NOT NULL -- esto era cantidad pero lo vole y puse valor porque no veo mucho sentido en el atributo cantidad, capaz me equivoco.
);

-- FACTURA
CREATE TABLE pagos_y_facturas.factura (
	id_factura INT IDENTITY(1,1) PRIMARY KEY,
	estado_pago VARCHAR(10) NOT NULL, -- no le pongo bit porque asumo que puede ser: pagado, pendiente, vencido y tal vez alguna mas
	fecha_emision DATE NOT NULL DEFAULT GETDATE(), -- que cada vez que se cree un nuevo registro tome la fecha del dia
	monto_a_pagar DECIMAL(10, 2) NOT NULL,
	id_persona INT NOT NULL UNIQUE,
	id_metodo_pago INT NOT NULL,
	
	CONSTRAINT FK_Factura_Persona FOREIGN KEY (id_persona) REFERENCES manejo_personas.persona(id_persona),
	CONSTRAINT FK_Factura_Metodo_Pago FOREIGN KEY (id_metodo_pago) REFERENCES pagos_y_facturas.metodo_pago(id_metodo_pago)
);

-- FACTURA <-N----N-> DESCUENTO
create table pagos_y_facturas.factura_descuento (
	id_factura INT NOT NULL,
	id_descuento INT NOT NULL,
	monto_aplicado DECIMAL(10, 2) NOT NULL, -- guardar que cantidad se desconto del importe total dependiendo el porcentaje. La podriamos sacar

	PRIMARY KEY (id_factura, id_descuento),

	CONSTRAINT FK_Factura_Descuento_Factura FOREIGN KEY (id_factura) REFERENCES pagos_y_facturas.factura(id_factura),
	CONSTRAINT FK_Factura_Descuento_Descuento FOREIGN KEY (id_descuento) REFERENCES pagos_y_facturas.descuento(id_descuento)
);




-------- STORE PROCEDURES PARA PERSONAS

-- SP TABLA PERSONAS INSERTAR

-- Este SP valida los datos de entrada y realiza la inserción de un nuevo registro en la tabla persona.
CREATE or ALTER PROCEDURE manejo_personas.CrearPersona
	@dni VARCHAR(8),
	@nombre NVARCHAR(50),
	@apellido NVARCHAR(50),
	@email VARCHAR(320),
	@fecha_nac DATE,
	@telefono VARCHAR(15)
AS
BEGIN
	--validar dni
	IF LEN(@dni) < 7 OR LEN(@dni) > 8 or ISNUMERIC(@dni) = 0 -- dni es numero y entre 1.000.000 y 99.999.999
	BEGIN
		SELECT 'Error' AS Resultado, 'DNI Invalido. Debe contener entre 7 y 8 digitos númericos.' AS Mensaje;
		RETURN -1;
	END

	--validar email
	IF @email NOT LIKE '%_@%.__%' --que email siga formato email@.fin (con fin por lo menos 2 letras)
	BEGIN
		SELECT 'Error' AS Resultado, 'El formato del email no es valido.' AS Mensaje;
		RETURN -2;
	END

	--validar fecha de nacimiento
	IF DATEDIFF(YEAR, @fecha_nac, GETDATE()) < 0 OR DATEDIFF(YEAR, @fecha_nac, GETDATE()) > 120 -- que la fecha de nacimiento no sea en el futuro ni la persona tenga mas de 120 años (se podria bajar a 90 por ejemplo)
	BEGIN
		SELECT 'Error' AS Resultado, 'La fecha de nacimiento no es valida.' AS Mensaje;
		RETURN -3;
	END

	-- se podrian verificar si email y dni existen pero no se si es necesario porque el atributo es unique, si es necesario lo agrego

	-- comenzamos transaccion en read comitted, q se pueda leer la tabla pero no el nuevo registro hasta confirmarlo
	
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRANSACTION;

	--insertar persona luego de todas las verificaciones
	INSERT INTO manejo_personas.persona (dni, nombre, apellido, email, fecha_nac, telefono, fecha_alta)
	VALUES (@dni, @nombre, @apellido, @email, @fecha_nac, @telefono, GETDATE());

	COMMIT TRANSACTION;

	SELECT 'Exito' AS RESULTADO, 'Persona registrada correctamente.' AS Mensaje;
	RETURN 0;
END;
GO


-- SP TABLA PERSONAS MODIFICAR
CREATE OR ALTER PROCEDURE manejo_personas.ModificarPersona
	@id_persona int,
	@nombre NVARCHAR(50) = NULL,
	@apellido NVARCHAR(50) = NULL,
	@email VARCHAR(320) = NULL,
	@telefono VARCHAR(15) = NULL
	-- tienen valor default null por si solo se quiere actualizar un cmapo
AS
BEGIN
	
	--validar existencia persona (por id)
	IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
	BEGIN
		SELECT 'Error' AS Resultado, 'La persona no existe' AS Mensaje;
		RETURN -1;
	END

	--validar email (si se da en el exec)
	IF @email IS NOT NULL
	BEGIN
		IF @email NOT LIKE '%_@_%.__%' --validar que  este bien escrito
		BEGIN
			SELECT 'Error' AS Resultado, 'El formato del email no es valido.' AS Mensaje;
			RETURN -2;
		END

		IF EXISTS (SELECT 1 FROM manejo_personas.persona WHERE email = @email AND id_persona <> @id_persona) --Validar que email existe pero es de otra persona (otro id)

		BEGIN
			SELECT 'Error' AS Resultado, 'El email esta en uso por otra persona.' AS Mensaje;
			RETURN -3;
		END
	END

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED; --al igual que agregar, que no pueda leer el update hasta confirmado
	BEGIN TRANSACTION;

		UPDATE manejo_personas.persona
		SET -- 
			nombre = ISNULL(@nombre, nombre), --si, por ejemplo, nombre no es NULL, se usa ese valor, si es NULL, se mantiene el actual
			apellido = ISNULL(@apellido, apellido), 
			email = ISNULL(@email, email),
			telefono = ISNULL(@telefono, telefono) 
		WHERE id_persona = @id_persona;

	COMMIT TRANSACTION;

	SELECT 'Exito' AS Resultado, 'Datos actualizados' AS Mensaje, @id_persona as id_persona;
	
	RETURN 0;
	
END;
GO

-- SP ELIMINAR PERSONA
CREATE or ALTER PROCEDURE manejo_personas.EliminarPersona
	@id_persona INT
AS
BEGIN
	-- Validar existencia persona
	IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
	BEGIN
		SELECT 'Error' AS Resultado, 'La persona no existe' AS Mensaje;
		RETURN -1;
	END

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- no estoy seguro de si deberia ser este lvl, hace q no se puedan leer datos modificados pero no confirmados, y que ninguna transac pueda modificar los datos leidos por la actual
	BEGIN TRANSACTION;

		--verificamos si la persona tiene alguna relacion en ora tabla aun
	IF EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona) OR
	EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE id_persona = @id_persona) OR
	EXISTS (SELECT 1 FROM manejo_personas.invitado WHERE id_persona = @id_persona) OR
	EXISTS (SELECT 1 FROM manejo_personas.responsable WHERE id_persona = @id_persona)

	BEGIN -- si tiene relaciones, hacemos borrado logico, pero necesitariamos agregar un atributo a persona (no estoy seguro de q esto se haga asi, si coinciden lo agregamos a la tabla persona)

		UPDATE manejo_personas.persona
		SET activo = 0
		WHERE id_persona = @id_persona
		
		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Persona inactivada correctamente (borrado logico ya que tiene registros relacionados)' AS Mensaje;
	
	END
	ELSE
	BEGIN
			-- si no tiene relaciones hacemos borrado fisico
		DELETE FROM manejo_personas.persona
		WHERE id_persona = @id_persona;			
		
		COMMIT TRANSACTION;
	
		SELECT 'Exito' as Resultado, 'Persona eliminada completamente.' AS Mensaje;
		
	END
	RETURN 0;

END;
GO

-------- STORED PROCEDURES PARA OBRA SOCIALES
-- Creacion de nueva obra social
CREATE OR ALTER PROCEDURE manejo_personas.CreacionRol
	@nombre VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que no sea nulo
		IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no exista ya
		IF EXISTS (SELECT 1 FROM manejo_personas.obra_social WHERE descripcion = @nombre)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya hay una obra social con ese nombre' AS Mensaje;
			RETURN -2;
		END

		

		INSERT INTO manejo_personas.obra_social(descripcion)
		VALUES (@nombre);

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Obra Social Ingresada' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-- Modificacion de obra social
CREATE OR ALTER PROCEDURE manejo_personas.ModificacionRol
	@id INT,
	@nombre_nuevo VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.obra_social WHERE id_obra_social = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no sea nulo
		IF @nombre_nuevo IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM manejo_personas.obra_social WHERE descripcion = @nombre_nuevo)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Esa obra social ya esta registrada' AS Mensaje;
			RETURN -1;
		END

		UPDATE manejo_personas.obra_social
		SET descripcion = @nombre_nuevo
		WHERE obra_social.id_obra_social = @id;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Obra Social Ingresada' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-- Eliminacion de obra social
CREATE OR ALTER PROCEDURE manejo_personas.EliminacionRol
	@id INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.obra_social WHERE id_obra_social = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		DELETE FROM manejo_personas.obra_social
		WHERE obra_social.id_obra_social = @id;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Obra Social eliminada' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-------- STORED PROCEDURES PARA METODO PAGO
-- Creacion de un metodo pago
CREATE OR ALTER PROCEDURE pagos_y_facturas.CreacionMetodoPago
	@nombre VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que no sea nulo
		IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no exista ya
		IF EXISTS (SELECT 1 FROM pagos_y_facturas.metodo_pago WHERE nombre = @nombre)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya hay un metodo de pago con ese nombre' AS Mensaje;
			RETURN -2;
		END

		

		INSERT INTO pagos_y_facturas.metodo_pago(nombre)
		VALUES (@nombre);

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Nuevo metodo de pago creado' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-- Modificacion metodo pago
CREATE OR ALTER PROCEDURE pagos_y_facturas.ModificacionMetodoPago
	@id INT,
	@nombre_nuevo VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.metodo_pago WHERE id_metodo_pago = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no sea nulo
		IF @nombre_nuevo IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM pagos_y_facturas.metodo_pago WHERE nombre = @nombre_nuevo)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ese metodo de pago ya esta registrado' AS Mensaje;
			RETURN -1;
		END

		UPDATE pagos_y_facturas.metodo_pago
		SET nombre = @nombre_nuevo
		WHERE metodo_pago.id_metodo_pago = @id;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Metodo de pago modificado' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-- Eliminacion metodo de pago
CREATE OR ALTER PROCEDURE pagos_y_facturas.EliminacionMetodoPago
	@id INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.metodo_pago WHERE id_metodo_pago = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		DELETE FROM pagos_y_facturas.metodo_pago
		WHERE metodo_pago.id_metodo_pago = @id;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Metodo de pago eliminado' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-------- STORED PROCEDURES PARA ROL
-- Creacion de un rol
CREATE OR ALTER PROCEDURE manejo_personas.CreacionRol
	@nombre VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que no sea nulo
		IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no exista ya
		IF EXISTS (SELECT 1 FROM manejo_personas.Rol WHERE descripcion = @nombre)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ese rol ya existe' AS Mensaje;
			RETURN -2;
		END

		

		INSERT INTO manejo_personas.Rol(descripcion)
		VALUES (@nombre);

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Nuevo rol creado' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-- Modificacion rol
CREATE OR ALTER PROCEDURE manejo_personas.ModificacionRol
	@id INT,
	@nombre_nuevo VARCHAR(50)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE id_rol = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no sea nulo
		IF @nombre_nuevo IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que el nombre no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = @nombre_nuevo)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ese rol ya esta registrado' AS Mensaje;
			RETURN -1;
		END

		UPDATE manejo_personas.Rol
		SET descripcion = @nombre_nuevo
		WHERE rol.id_rol = @id;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Rol modificado' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO

-- Eliminacion rol
CREATE OR ALTER PROCEDURE manejo_personas.EliminacionRol
	@id INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRANSACTION;

	BEGIN TRY
		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
		
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.Rol WHERE id_rol = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -1;
		END

		DELETE FROM manejo_personas.rol
		WHERE Rol.id_rol = @id;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Rol eliminado' AS Mensaje;
		RETURN 0;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
GO