USE Com5600G01;

/*
* Nombre: CrearPersona
* Descripcion: Inserta una nueva persona en la tabla persona, validando su informacion. 
* Parametros:
*	@dni  VARCHAR(8) - DNI de la persona.
*	@nombre NVARCHAR(50) - Nombre de la persona. 
*	@apellido NVARCHAR(50) - Apellido de la persona. 
* 	@email VARCHAR(320) - Email de la persona. 
* 	@fecha_nac DATE - Fecha de nacimiento.
*	@telefono VARCHAR(15) - Telefono de la persona
* Valores de retorno:
*	 0: Exito. 
*	-1: DNI Invalido. 
*	-2: Formato de email incorrecto.
*	-3: Fecha de nacimienta invalida.
*	-99: Error desconocido.
*/
GO
CREATE or ALTER PROCEDURE manejo_personas.CrearPersona
	@dni VARCHAR(8),
	@nombre NVARCHAR(50),
	@apellido NVARCHAR(50),
	@email VARCHAR(320),
	@fecha_nac DATE,
	@telefono VARCHAR(15)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED; 
		-- comenzamos transaccion en read comitted, q se pueda leer la tabla pero no el nuevo registro hasta confirmarlo
	BEGIN TRANSACTION;

	BEGIN TRY
		--validar dni
		IF LEN(@dni) < 7 OR LEN(@dni) > 8 or ISNUMERIC(@dni) = 0 -- dni es numero y entre 1.000.000 y 99.999.999
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'DNI Invalido. Debe contener entre 7 y 8 digitos numericos.' AS Mensaje;
			RETURN -1;
		END

		--validar email
		IF @email NOT LIKE '%_@%.__%' --que email siga formato email@.fin (con fin por lo menos 2 letras)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El formato del email no es valido.' AS Mensaje;
			RETURN -2;
		END

		--validar fecha de nacimiento
		IF DATEDIFF(YEAR, @fecha_nac, GETDATE()) < 0 OR DATEDIFF(YEAR, @fecha_nac, GETDATE()) > 120 -- que la fecha de nacimiento no sea en el futuro ni la persona tenga mas de 120 a�os (se podria bajar a 90 por ejemplo)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La fecha de nacimiento no es valida.' AS Mensaje;
			RETURN -3;
		END

		-- se podrian verificar si email y dni existen pero no se si es necesario porque el atributo es unique, si es necesario lo agrego


		--insertar persona luego de todas las verificaciones
		INSERT INTO manejo_personas.persona (dni, nombre, apellido, email, fecha_nac, telefono, fecha_alta)
		VALUES (@dni, @nombre, @apellido, @email, @fecha_nac, @telefono, GETDATE());

		COMMIT TRANSACTION;

		SELECT 'Exito' AS RESULTADO, 'Persona registrada correctamente.' AS Mensaje;
		RETURN 0;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'error' AS Resultado, ERROR_MESSAGE() AS Mensaje; -- devuelvo que error hubo
		RETURN -99;
	END CATCH
END;

/*
* Nombre: ModificarPersona
* Descripcion: Permite modificar de una persona los campos: nombre, apellido, email y telefono.
* Parametros:
*	@id_persona  INT - ID de persona. 
*	@nombre NVARCHAR(50) - Nombre nuevo para la persona. (Parametro opcional)
*	@apellido NVARCHAR(50) - Apellido nuevo para la persona. (Parametro opcional)
* 	@email VARCHAR(320) - Nuevo email para la persona. (Parametro opcional) 
*	@telefono VARCHAR(15) - Nuevo telefono para la persona
* Valores de retorno:
*	 0: Exito. 
*	-1: Persona no encontrada. 
*	-2: Formato de email incorrecto.
*	-3: El email ya esta en uso. 
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_personas.ModificarPersona
	@id_persona INT,
	@nombre NVARCHAR(50) = NULL,
	@apellido NVARCHAR(50) = NULL,
	@email VARCHAR(320) = NULL,
	@telefono VARCHAR(15) = NULL
	-- tienen valor default null por si solo se quiere actualizar un cmapo
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRANSACTION;

	BEGIN TRY
		--validar existencia persona (por id)
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La persona no existe' AS Mensaje;
			RETURN -1;
		END

		--validar email (si se da en el exec)
		IF @email IS NOT NULL
		BEGIN
			IF @email NOT LIKE '%_@_%.__%' --validar que  este bien escrito
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'El formato del email no es valido.' AS Mensaje;
				RETURN -2;
			END

			IF EXISTS (SELECT 1 FROM manejo_personas.persona WHERE email = @email AND id_persona <> @id_persona) --Validar que email existe pero es de otra persona (otro id)

			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'El email esta en uso por otra persona.' AS Mensaje;
				RETURN -3;
			END
		END

		UPDATE manejo_personas.persona
		SET 
			nombre = ISNULL(@nombre, nombre), --si, por ejemplo, nombre no es NULL, se usa ese valor, si es NULL, se mantiene el actual
			apellido = ISNULL(@apellido, apellido), 
			email = ISNULL(@email, email),
			telefono = ISNULL(@telefono, telefono) 
		WHERE id_persona = @id_persona;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Datos actualizados' AS Mensaje, @id_persona as id_persona;
		RETURN 0;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resulado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH

END; 

/*
* Nombre: EliminarPersona
* Descripcion: Realiza una eliminacion logica de una persona.
* Parametros:
*	@id_persona  INT - ID de persona a eliminar. 
* Valores de retorno:
*	 0: Exito. 
*	-1: Persona no encontrada. 
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_personas.EliminarPersona
	@id_persona INT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	BEGIN TRANSACTION;

	BEGIN TRY
		-- Valido si existe la persona: 
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La persona no existe' AS Mensaje;
			RETURN -1;
		END

		-- Elimacion logica: 
		UPDATE manejo_personas.persona
		SET activo = 0
		WHERE id_persona = @id_persona;

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Persona inactivada correctamente (borrado lógico)' AS Mensaje;
		RETURN 0;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;

/*
* Nombre: CreacionObraSocial
* Descripcion: Realiza una eliminacion logica de una persona.
* Parametros:
*	@nombre VARCHAR(50) - Nombre de la obra social. 
* Valores de retorno:
*	 0: Exito. 
*	-1: @nombre es nulo. 
*	-2: El nombre ya esta en uso.
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_personas.CreacionObraSocial
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
GO
CREATE OR ALTER PROCEDURE manejo_personas.ModificacionObraSocial
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
			RETURN -2;
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
			RETURN -3;
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

/*
* Nombre: ModificacionObraSocial
* Descripcion: Elimina una obra social. (Eliminacion fisica)
* Parametros:
*	@id INT - id de la obra social. (DEBE SER NO NULO)
* Valores de retorno:
*	 0: Exito. 
*	-1: @id no existente.
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_personas.EliminacionObraSocial
	@id INT
AS BEGIN
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

/*
* Nombre: CreacionMetodoPago
* Descripcion: Crea un metodo de pago. 
* Parametros:
*	@nombre VARCHAR(50) - Nombre del metodo de pago. 
* Valores de retorno:
*	 0: Exito. 
*	-1: @nombre no puede ser nulo.
*	-2: El nombre ya esta en uso.
*	-99: Error desconocido.
*/
GO
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

/*
* Nombre: ModificacionMetodoPago
* Descripcion: Modifica el nombre de un metodo de pago.
* Parametros:
*	@id INT - id del metodo de pago a modificar. 
*	@nombre VARCHAR(50) - Nombre del metodo de pago. 
* Valores de retorno:
*	 0: Exito. 
*	-1: Parametros incorrectos.
*	-99: Error desconocido.
*/
GO
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

/*
* Nombre: ModificacionMetodoPago
* Descripcion: Modifica el nombre de un metodo de pago.
* Parametros:
*	@id INT - id del metodo de pago a modificar. 
*	@nombre VARCHAR(50) - Nombre del metodo de pago. 
* Valores de retorno:
*	 0: Exito. 
*	-1: Parametros incorrectos.
*	-99: Error desconocido.
*/
GO
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

/*
* Nombre: EliminacionMetodoPago
* Descripcion: Realiza una eliminacion fisica de metodo pago
* Parametros:
*	@id INT - id del metodo de pago a eliminar. 
* Valores de retorno:
*	 0: Exito. 
*	-1: @id Parametros incorrectos.
*	-99: Error desconocido.
* Observacion: Revisar la restriccion referencial. 
*/
GO
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

/*
* Nombre: CreacionRol
* Descripcion: Crea un rol. 
* Parametros:
*	@nombre VARCHAR(50) - Nombre del rol. 
* Valores de retorno:
*	 0: Exito. 
*	-1: @nombre Parametro incorrecto.
*	-99: Error desconocido.
*/
GO
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
			RETURN -1;
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

/*
* Nombre: ModificacionRol
* Descripcion: Modifica el nombre de un rol
* Parametros:
*	@id INT - ID del rol a modificar.
*	@nombre_nuevo VARCHAR(50) - Nombre nuevo del rol. 
* Valores de retorno:
*	 0: Exito. 
*	-1: Parametros incorrectos.
*	-99: Error desconocido.
*/
GO
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

/*
* Nombre: EliminacionRol
* Descripcion: Elimina un rol. 
* Parametros:
*	@id INT - ID del rol a eliminar.
* Valores de retorno:
*	 0: Exito. 
*	-1: Parametros incorrectos.
*	-99: Error desconocido.
*/
GO
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

/*
* Nombre: CrearCategoria
* Descripcion: Crea una nueva categoria, valida la informacion ingresada.
* Parametros:
*	@nombre_categoria VARCHAR(50) - Nombre de la categoria.
*	@costo_membrecia DECIMAL(10, 2) -  Costo de la membresia. 
*	@edad_maxima INT - Edad maxima para la categoria. 
* Valores de retorno:
*	 0: Exito. 
*	-1: Parametros incorrectos.
*	-2: Costo negativo.
*	-3: Edad negativa. 	 
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_actividades.CrearCategoria
	@nombre_categoria VARCHAR(50),
	@costo_membrecia DECIMAL(10, 2),
	@edad_maxima INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRANSACTION;

	BEGIN TRY
		-- validamos nombre de la categoria
		IF @nombre_categoria IS NULL OR LTRIM(RTRIM(@nombre_categoria)) = '' -- que no sea null ni vacio
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre de la categoría no puede estar vacío' AS Mensaje;
			RETURN -1;
		END

		-- validar costo de membresía
		IF @costo_membrecia <= 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El costo de membresía debe ser mayor a cero' AS Mensaje;
			RETURN -2;
		END

		-- validamos edad maxima
		IF @edad_maxima <= 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La edad maxima debe ser mayor a cero' AS Mensaje;
			RETURN -3;
		END

		-- validamos categoria unica

		IF EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE nombre_categoria = @nombre_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe una categoría con ese nombre' AS Mensaje;
			RETURN -4;
		END

		-- calculamos edad minima para esta categoria
		DECLARE @edad_minima INT = 0;

		-- si EXISTE una categoria con la edad maxima MENOR a la que queremos agregar, nuestra "edad minima" sera la edad maxima existente + 1
		IF EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE edad_maxima < @edad_maxima)
		BEGIN
			SELECT @edad_minima = MAX(edad_maxima) + 1
			FROM manejo_actividades.categoria
			WHERE edad_maxima < @edad_maxima;
		END

		-- verificamos que no haya solapamiento de edades (que ninguna categoria tenga edad_maxima dentro de nuestro rango)
		IF EXISTS ( SELECT 1 FROM manejo_actividades.categoria WHERE edad_maxima BETWEEN @edad_minima AND @edad_maxima AND edad_maxima <> @edad_maxima) -- se busca si existe alguna categoria donde la edad maxima este entre nuestra edad minima y maxima actuales (excluyendo las que tienen nuestra misma maxima)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El rango de edad se solapa con otra categoria existente' AS Mensaje;
			RETURN -5;
		END

		-- verificamos ademas que no haya "huecos" entre los rangos (por ejemplo, que no haya categoria de 14-16 y otra de 20-22 dejando 17-19)
		IF EXISTS ( 
			SELECT 1 FROM manejo_actividades.categoria WHERE edad_maxima > @edad_maxima)
		AND NOT EXISTS ( 
			SELECT 1 FROM manejo_actividades.categoria WHERE edad_maxima = @edad_maxima + 1)
	
		-- este if lo que hace es buscar primero si hay categorias con edades maximas superiores a la nuestra, y si falta la categoria que tiene que empezar luego de la actual

		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Hay un hueco en el rango de edades entre esta categoria y la siguiente' AS Mensaje;
			RETURN -6;
		END

		-- luego de las validaciones insertamos

		INSERT INTO manejo_actividades.categoria (nombre_categoria, costo_membrecia, edad_maxima)
		VALUES (@nombre_categoria, @costo_membrecia, @edad_maxima);

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Categoria creada correctamente' AS Mensaje;
		RETURN 0;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;

/*
* Nombre: ModificarCategoria
* Descripcion: Modifica los campos nombre y costo de una categoria. 
* Parametros:
* 	@id_categoria INT - ID de la categoria a modificar. (Parametro obligatorio)
*	@nombre_categoria VARCHAR(50) - Nombre nuevo para la categoria. (Parametro opcional)
*	@costo_membrecia DECIMAL(10, 2) -  Nuevo costo de la membresia (Parametro opcional). 
* Valores de retorno:
*	 0: Exito. 
*	-1: @nombre_categoria incorrecto.
*	-2: El nombre de la categoria esta en uso.
*	-3: El costo de la membresia debe ser mayor a cero. 	 
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_actividades.ModificarCategoria
	@id_categoria INT,
	@nombre_categoria VARCHAR(50) = NULL,
	@costo_membrecia DECIMAL(10, 2) = NULL
AS
BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRANSACTION;

	BEGIN TRY
	-- verificamos que la categoria exista
		IF NOT EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La categoria no existe' AS Mensaje;
			RETURN -1
		END

	--si nos dan un nombre para cambiar, lo validamos
		IF @nombre_categoria IS NOT NULL
		BEGIN
			IF LTRIM(RTRIM(@nombre_categoria)) = ''
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'El nombre de la categoria no puede estar vacio' AS Mensaje;
				RETURN -1;
			END

	-- verificamos que no exista ora categoria con el nombre a cambiar (excepto si es la actual)
			IF EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE nombre_categoria = @nombre_categoria AND id_categoria <> @id_categoria)
			BEGIN
				ROLLBACK TRANSACTION;
				SELECT 'Error' AS Resultado, 'Ya existe otra categoría con ese nombre' AS Mensaje;
				RETURN -2;
			END
		END

		-- si nos dan costo, que no sea negativo
		IF @costo_membrecia IS NOT NULL AND @costo_membrecia <= 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El costo de membresía debe ser mayor a cero' AS Mensaje;
			RETURN -3;
		END

		UPDATE manejo_actividades.categoria
		SET nombre_categoria = ISNULL(@nombre_categoria, nombre_categoria),
			costo_membrecia = ISNULL(@costo_membrecia, costo_membrecia)
		WHERE id_categoria = @id_categoria;

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Categoria modificada correctamente' AS Mensaje;
		RETURN 0;
		
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH

END;

/*
* Nombre: CrearClase
* Descripcion: Modifica los campos nombre y costo de una categoria. 
* Parametros:
* 	@id_actividad INT - ID de la actividad que se realiza en la clase.
*	@id_categoria INT - ID de la categoria. 
*	@dia VARCHAR(9) - Dia que se realiza la actividad. 
*	@horario TIME - Horario de la clase. 
* 	@id_usuario INT - ID del usuario que es responsable de la clase.
*	
* Valores de retorno:
*	 0: Exito. 
*	-1: Actividad no existe.
*	-2: Categoria no existe.
*	-3: El usuario no existe. 
*	-4: Dia invalido. 
*	-5: Horario invalido. 
*	-6: 'Ya existe una clase con la misma actividad, categoría, día y horario.
*	-7: El profesor ya tiene otra clase asignada en ese dia y horario
*	-99: Error desconocido.
*/
GO
CREATE OR ALTER PROCEDURE manejo_actividades.CrearClase
	@id_actividad INT,
	@id_categoria INT,
	@dia VARCHAR(9),
	@horario TIME,
	@id_usuario INT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRANSACTION;

	BEGIN TRY
		-- validar que la actividad exista
		IF NOT EXISTS (SELECT 1 FROM manejo_actividades.actividad WHERE id_actividad = @id_actividad)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La actividad no existe' AS Mensaje;
			RETURN -1;
		END

		-- validar que la categoria exista

		IF NOT EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'La categoría no existe' AS Mensaje;
			RETURN -2;
		END

		-- validar que el usuario profesor exista
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE id_usuario = @id_usuario)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El usuario no existe' AS Mensaje;
			RETURN -3;
		END

		-- valdar formato del dia

		SET @dia = UPPER(@dia);

		IF @dia NOT IN ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO')
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El dia debe ser un dia de la semana valido' AS Mensaje;
			RETURN -4;
		END

		--validar horario (entre 6am y 22pm por ejemplo)

		DECLARE @hora_minima TIME = '06:00:00';
		DECLARE @hora_maxima TIME = '22:00:00';

		IF @horario < @hora_minima OR @horario > @hora_maxima
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El horario debe ser entre 06 am y 22 pm' AS Mensaje;
			RETURN -5;
		END

		-- verficar la no existencia de otra clase con misma actividad, categoria, dia y horario
		IF EXISTS ( SELECT 1 FROM manejo_actividades.clase WHERE id_actividad = @id_actividad AND id_categoria = @id_categoria AND dia = @dia AND horario = @horario)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe una clase con la misma actividad, categoría, día y horario' AS Mensaje;
			RETURN -6;
		END

		-- verificar que el profesor no tenga otra clase a la misma hora
		IF EXISTS (SELECT 1 FROM manejo_actividades.clase WHERE id_usuario = @id_usuario AND dia = @dia AND horario = @horario)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El profesor ya tiene otra clase asignada en ese dia y horario' AS Mensaje;
			RETURN -7;
		END

		-- insertar la nueva clase

		INSERT INTO manejo_actividades.clase(id_actividad, id_categoria, dia, horario, id_usuario)
		VALUES (@id_actividad, @id_categoria, @dia, @horario, @id_usuario);

		COMMIT TRANSACTION;

		SELECT 'Exito' AS Resultado, 'Clase creada correctamente' AS Mensaje;
		RETURN 0;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
		RETURN -99;
	END CATCH
END;
