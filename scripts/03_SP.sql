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
		IF DATEDIFF(YEAR, @fecha_nac, GETDATE()) < 0 OR DATEDIFF(YEAR, @fecha_nac, GETDATE()) > 120 -- que la fecha de nacimiento no sea en el futuro ni la persona tenga mas de 120 a?os (se podria bajar a 90 por ejemplo)
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

GO
CREATE OR ALTER PROCEDURE manejo_actividades.ModificarClase
    @id_clase INT,
    @id_actividad INT = NULL,
    @id_categoria INT = NULL,
    @dia VARCHAR(9) = NULL,
    @horario TIME = NULL,
    @id_usuario INT = NULL
AS
BEGIN
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- verificamos que la clase exista
        IF NOT EXISTS (SELECT 1 FROM manejo_actividades.clase WHERE id_clase = @id_clase)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La clase no existe' AS Mensaje;
            RETURN -1;
        END
        
        -- verificamos actividad si se proporciona
        IF @id_actividad IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_actividades.actividad WHERE id_actividad = @id_actividad)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La actividad no existe' AS Mensaje;
            RETURN -2;
        END
        
        -- verificamos categoría si se proporciona
        IF @id_categoria IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La categoría no existe' AS Mensaje;
            RETURN -3;
        END
        
        -- verificamos usuario si se proporciona
        IF @id_usuario IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE id_usuario = @id_usuario)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El usuario no existe' AS Mensaje;
            RETURN -4;
        END
        
        -- verificamos formato del día si se proporciona y convertir a mayúsculas
        IF @dia IS NOT NULL
        BEGIN
            SET @dia = UPPER(@dia);
            IF @dia NOT IN ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO')
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El día debe ser un día de la semana válido' AS Mensaje;
                RETURN -5;
            END
        END
        
        -- verificamos horario si se proporciona
        IF @horario IS NOT NULL
        BEGIN
            DECLARE @hora_minima TIME = '06:00:00';
            DECLARE @hora_maxima TIME = '22:00:00';
          
            IF @horario < @hora_minima OR @horario > @hora_maxima
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El horario debe estar entre 06:00 y 22:00' AS Mensaje;
                RETURN -6;
            END
        END
        
        -- verificamos que no haya otra clase con la misma combinación (si cambiamos algun valor)
        IF @id_actividad IS NOT NULL OR @id_categoria IS NOT NULL OR @dia IS NOT NULL OR @horario IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM manejo_actividades.clase WHERE id_actividad = ISNULL(@id_actividad, id_actividad) 
				AND id_categoria = ISNULL(@id_categoria, id_categoria) 
				AND dia = ISNULL(@dia, dia) 
				AND horario = ISNULL(@horario, horario)
                AND id_clase <> @id_clase
            )
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'Ya existe otra clase con la misma actividad, categoría, día y horario' AS Mensaje;
                RETURN -7;
            END
        END
        
        -- verificamos que el profesor no tenga otra clase a la misma hora (solo si cambiamos profesor/día/hora)
        IF @id_usuario IS NOT NULL OR @dia IS NOT NULL OR @horario IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM manejo_actividades.clase WHERE id_usuario = ISNULL(@id_usuario, id_usuario)
                AND dia = ISNULL(@dia, dia)
                AND horario = ISNULL(@horario, horario)
                AND id_clase <> @id_clase
            )
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'El profesor ya tiene otra clase asignada en ese día y horario' AS Mensaje;
                RETURN -8;
            END
        END
        
        -- verificamos la clase
        UPDATE manejo_actividades.clase
        SET id_actividad = ISNULL(@id_actividad, id_actividad),
            id_categoria = ISNULL(@id_categoria, id_categoria),
            dia = ISNULL(@dia, dia),
            horario = ISNULL(@horario, horario),
            id_usuario = ISNULL(@id_usuario, id_usuario)
        WHERE id_clase = @id_clase;
        
        COMMIT TRANSACTION;
        
        SELECT 'Éxito' AS Resultado, 'Clase modificada correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;

    END CATCH

END;

GO
CREATE OR ALTER PROCEDURE manejo_actividades.EliminarClase
    @id_clase INT
AS
BEGIN
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- verificamos que la clase exista y esté activa
        IF NOT EXISTS (SELECT 1 FROM manejo_actividades.clase WHERE id_clase = @id_clase AND activo = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La clase no existe o ya está inactiva' AS Mensaje;
            RETURN -1;
        END
        
        -- verificamos si hay socios inscritos en esta actividad y categoría
        IF EXISTS (SELECT 1 FROM manejo_personas.socio_actividad sa
            JOIN manejo_personas.socio s ON sa.id_socio = s.id_socio
            JOIN manejo_actividades.clase c ON c.id_clase = @id_clase
            WHERE sa.id_actividad = c.id_actividad
            AND s.id_categoria = c.id_categoria
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'No se puede eliminar la clase porque hay socios inscritos en esta actividad y categoría' AS Mensaje;
            RETURN -2;
        END
		-- esto casi seguro habria que cambiarlo/repensarlo porque no se eliminaria la clase aun si el socio esta inscrito en actividad y categoria pero 
		-- en otra clase, capaz habria que unir de alguna forma socio con clase. !!!
		-- aparte tiene que hacer joins y dudo que sea optimo

        -- realizamos borrado lógico cambiando el estado a inactivo
        UPDATE manejo_actividades.clase
        SET activo = 0 -- agregue atributo activo a clase para hacer borrado lógico, si les parece que no deberia de haber borrado lógico lo cambiamos
        WHERE id_clase = @id_clase;
        
        COMMIT TRANSACTION;
        
        SELECT 'Éxito' AS Resultado, 'Clase inactivada correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH

        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;


GO
CREATE OR ALTER PROCEDURE pagos_y_facturas.CrearDescuento
	@descripcion VARCHAR(50),
	@cantidad DECIMAL(4,3)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Chequeo que el descuento no sea nulo
		IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Los descuentos no pueden tener nombres nulos' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que no exista ya en la base de datos
		IF EXISTS (SELECT 1 FROM pagos_y_facturas.descuento WHERE descripcion = @descripcion)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe un descuento con esta descripcion' AS Mensaje;
			RETURN -2;
		END

		-- Verifico que el numero no sea null ni 0
		IF @cantidad IS NULL OR @cantidad = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Un descuento no puede no tener descuento' AS Mensaje;
			RETURN -3;
		END

		INSERT INTO pagos_y_facturas.descuento(descripcion, valor)
		VALUES (@descripcion, @cantidad);

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Descuento Ingresado Correctamente' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
CREATE OR ALTER PROCEDURE pagos_y_facturas.ModificarDescuento
	@id INT,
	@descripcion VARCHAR(50),
	@cantidad DECIMAL(4,3)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END
			
		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.descuento WHERE id_descuento = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -2;
		END

		-- Chequeo que el descuento no sea nulo
		IF @descripcion IS NULL OR LTRIM(RTRIM(@descripcion)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Los descuentos no pueden tener nombres nulos' AS Mensaje;
			RETURN -3;
		END

		-- Verifico que no exista ya en la base de datos
		IF EXISTS (
			SELECT 1 FROM pagos_y_facturas.descuento
			WHERE descripcion = @descripcion AND id_descuento <> @id
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe un descuento con esta descripcion' AS Mensaje;
			RETURN -4;
		END

		-- Verifico que el numero no sea null ni 0
		IF @cantidad IS NULL OR @cantidad = 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Una descuento no puede no tener descuento' AS Mensaje;
			RETURN -5;
		END

		UPDATE pagos_y_facturas.descuento
		SET descripcion = @descripcion, valor = @cantidad
		WHERE id_descuento = @id;

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Descuento modificado correctamente' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
CREATE OR ALTER PROCEDURE pagos_y_facturas.EliminarDescuento
	@id INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.descuento WHERE id_descuento = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -2;
		END

		-- Elimino el descuento
		DELETE FROM pagos_y_facturas.descuento WHERE id_descuento = @id;

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Descuento eliminado correctamente' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
CREATE OR ALTER PROCEDURE pagos_y_facturas.CreacionFactura
    @estado_pago VARCHAR(10),
    @monto_a_pagar DECIMAL(10,2),
    @id_persona INT,
    @id_metodo_pago INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
		-- Verifico el parametro del estado no sea nulo
        IF @estado_pago IS NULL OR LTRIM(RTRIM(@estado_pago)) = ''
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Estado de pago no puede ser nulo o vacio' AS Mensaje;
            RETURN -1;
        END

		-- Verifico que que el monto a pagar no sea negativo
        IF @monto_a_pagar IS NULL OR @monto_a_pagar <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Monto invalido' AS Mensaje;
            RETURN -2;
        END

		-- Verifico que que la persona a quien corresponda el pago exista en la tabla de personas
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Persona no existente' AS Mensaje;
            RETURN -3;
        END


		-- Verifico que que el metodo de pago elegido exista en la tabla de medios de pago
        IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.metodo_pago WHERE id_metodo_pago = @id_metodo_pago)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Método de pago no valido' AS Mensaje;
            RETURN -4;
        END

        INSERT INTO pagos_y_facturas.factura (estado_pago, monto_a_pagar, id_persona, id_metodo_pago)
        VALUES (@estado_pago, @monto_a_pagar, @id_persona, @id_metodo_pago);

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Factura creada correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;

GO
-- Modificacion de facturas
CREATE OR ALTER PROCEDURE pagos_y_facturas.ModificacionFactura
    @id_factura INT,
    @nuevo_estado_pago VARCHAR(10),
    @nuevo_monto DECIMAL(10,2),
    @nuevo_metodo_pago INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
		-- Verifico que la factura a modificar exista
        IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.factura WHERE id_factura = @id_factura)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Factura no existente' AS Mensaje;
            RETURN -1;
        END

		-- Verifico que el estado sea valido
        IF @nuevo_estado_pago IS NULL OR LTRIM(RTRIM(@nuevo_estado_pago)) = ''
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Estado invalido' AS Mensaje;
            RETURN -2;
        END

		-- Verifico que el monto no sea negativo
        IF @nuevo_monto IS NULL OR @nuevo_monto <= 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Monto invalido' AS Mensaje;
            RETURN -3;
        END

		-- Verifico que el metodo de pago exista en su tabla
        IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.metodo_pago WHERE id_metodo_pago = @nuevo_metodo_pago)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Metodo de pago invalido' AS Mensaje;
            RETURN -4;
        END

        UPDATE pagos_y_facturas.factura
        SET estado_pago = @nuevo_estado_pago,
            monto_a_pagar = @nuevo_monto,
            id_metodo_pago = @nuevo_metodo_pago
        WHERE id_factura = @id_factura;

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Factura actualizada correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;

GO
CREATE OR ALTER PROCEDURE pagos_y_facturas.EliminacionFactura
    @id_factura INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
		-- Verifico que la factura exista
        IF NOT EXISTS (SELECT 1 FROM pagos_y_facturas.factura WHERE id_factura = @id_factura)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La factura no existe' AS Mensaje;
            RETURN -1;
        END

        DELETE FROM pagos_y_facturas.factura
        WHERE id_factura = @id_factura;

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Factura eliminada correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;


GO
CREATE OR ALTER PROCEDURE manejo_actividades.CrearActividad
	@nombre_actividad VARCHAR(100),
	@costo_mensual DECIMAL(10,2)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Chequeo que el nombre no sea nulo ni vacio
		IF @nombre_actividad IS NULL OR LTRIM(RTRIM(@nombre_actividad)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre de actividad no puede ser nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que no exista ya en la tabla
		IF EXISTS (SELECT 1 FROM manejo_actividades.actividad WHERE nombre_actividad = @nombre_actividad)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe una actividad con ese nombre' AS Mensaje;
			RETURN -2;
		END

		-- Verifico que el costo sea valido (>0)
		IF @costo_mensual IS NULL OR @costo_mensual <= 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El costo mensual debe ser mayor a cero' AS Mensaje;
			RETURN -3;
		END

		INSERT INTO manejo_actividades.actividad(nombre_actividad, costo_mensual)
		VALUES (@nombre_actividad, @costo_mensual);

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Actividad creada correctamente' AS Mensaje;
		RETURN 0;

	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
CREATE OR ALTER PROCEDURE manejo_actividades.ModificarActividad
	@id INT,
	@nombre_actividad VARCHAR(100),
	@costo_mensual DECIMAL(10,2)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_actividades.actividad WHERE id_actividad = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -2;
		END

		-- Chequeo que el nombre no sea nulo ni vacio
		IF @nombre_actividad IS NULL OR LTRIM(RTRIM(@nombre_actividad)) = ''
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El nombre de actividad no puede ser nulo o vacio' AS Mensaje;
			RETURN -3;
		END

		-- Verifico que no exista ya en la tabla otro registro con mismo nombre
		IF EXISTS (
			SELECT 1 FROM manejo_actividades.actividad
			WHERE nombre_actividad = @nombre_actividad AND id_actividad <> @id
		)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe una actividad con ese nombre' AS Mensaje;
			RETURN -4;
		END

		-- Verifico que el costo sea valido (>0)
		IF @costo_mensual IS NULL OR @costo_mensual <= 0
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El costo mensual debe ser mayor a cero' AS Mensaje;
			RETURN -5;
		END

		UPDATE manejo_actividades.actividad
		SET nombre_actividad = @nombre_actividad,
			costo_mensual = @costo_mensual
		WHERE id_actividad = @id;

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Actividad modificada correctamente' AS Mensaje;
		RETURN 0;

	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
CREATE OR ALTER PROCEDURE manejo_actividades.EliminarActividad
	@id INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Verifico que el ID no sea nulo
		IF @id IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id nulo' AS Mensaje;
			RETURN -1;
		END

		-- Verifico que exista en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_actividades.actividad WHERE id_actividad = @id)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'id no existente' AS Mensaje;
			RETURN -2;
		END

		-- Elimino la actividad
		DELETE FROM manejo_actividades.actividad WHERE id_actividad = @id;

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Actividad eliminada correctamente' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

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
CREATE OR ALTER PROCEDURE manejo_personas.CrearUsuario
    @id_persona INT,
    @username VARCHAR(50),
    @password_hash VARCHAR(256),
    @fecha_alta_contra DATE = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verifico que el id_persona no sea nulo
        IF @id_persona IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'id_persona nulo' AS Mensaje;
            RETURN -1;
        END
        
        -- Verifico que el username no sea nulo
        IF @username IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'username nulo' AS Mensaje;
            RETURN -2;
        END
        
        -- Verifico que el password_hash no sea nulo
        IF @password_hash IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'password_hash nulo' AS Mensaje;
            RETURN -3;
        END

		-- Verifico que el password_hash tenga 256 caracteres
        IF LEN(@password_hash) != 256 -- NOTA: Como dije arriba, asumo SHA-256 como metodo de hasheo
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'password_hash debe tener 256 caracteres' AS Mensaje;
			RETURN -7;
		END
        
        -- Validar que la persona existe
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona especificada no existe' AS Mensaje;
            RETURN -4;
        END
        
        -- Validar que la persona no tenga ya un usuario
        IF EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE id_persona = @id_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona ya tiene un usuario asignado' AS Mensaje;
            RETURN -5;
        END
        
        -- Validar que el username no este en uso
        IF EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE username = @username)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El nombre de usuario ya esta en uso' AS Mensaje;
            RETURN -6;
        END
        
        -- Si no se proporciona fecha, usar la actual
        IF @fecha_alta_contra IS NULL
            SET @fecha_alta_contra = GETDATE();
        
        -- Insertar el nuevo usuario
        INSERT INTO manejo_personas.usuario (id_persona, username, password_hash, fecha_alta_contra
)
        VALUES (@id_persona, @username, @password_hash, @fecha_alta_contra);
        
        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Usuario creado correctamente' AS Mensaje;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        SELECT 
            'Error' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_NUMBER() AS CodigoError,
            ERROR_LINE() AS Linea,
            ERROR_PROCEDURE() AS Procedimiento;
        RETURN -999;
    END CATCH
END


GO
CREATE OR ALTER PROCEDURE manejo_personas.ModificarUsuario
    @id_usuario INT,
    @username VARCHAR(50) = NULL,
    @password_hash VARCHAR(256) = NULL,
    @fecha_alta_contra DATE = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verifico que el id_usuario no sea nulo
        IF @id_usuario IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'id_usuario nulo' AS Mensaje;
            RETURN -1;
        END
        
        -- Validar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE id_usuario = @id_usuario)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El usuario especificado no existe' AS Mensaje;
            RETURN -2;
        END
        
        -- Validar username unico si se esta modificando
		IF EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE username = @username)
		BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El nombre de usuario ya esta en uso por otro usuario' AS Mensaje;
            RETURN -3;
        END
        
        -- Actualizar solo los campos que se proporcionaron
        UPDATE manejo_personas.usuario
        SET 
            username = ISNULL(@username, username),
            password_hash = ISNULL(@password_hash, password_hash),
            fecha_alta_contra = ISNULL(@fecha_alta_contra, @fecha_alta_contra)
        WHERE id_usuario = @id_usuario;
        
        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Usuario modificado correctamente' AS Mensaje;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
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
CREATE OR ALTER PROCEDURE manejo_personas.EliminarUsuario
    @id_usuario INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    BEGIN TRY
        BEGIN TRANSACTION;

		--Verifico que el parametro no sea null
        IF @id_usuario IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'id_usuario nulo' AS Mensaje;
            RETURN -1;
        END

		-- Verifico que el usuario exista en su tabla
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.usuario WHERE id_usuario = @id_usuario)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El usuario especificado no existe' AS Mensaje;
            RETURN -2;
        END

		-- Verifico que no tenga clases asignadas
        IF EXISTS (SELECT 1 FROM manejo_actividades.clase WHERE id_usuario = @id_usuario)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'No se puede eliminar el usuario porque tiene clases asignadas' AS Mensaje;
            RETURN -3;
        END

        -- Eliminar relaciones con roles
        DELETE FROM manejo_personas.Usuario_Rol 
        WHERE id_usuario = @id_usuario;

        -- Inactivar el usuario
        UPDATE manejo_personas.usuario
        SET estado = 0
        WHERE id_usuario = @id_usuario;

        -- Incactiva a la persona si no esta en otras tablas
        DECLARE @id_persona INT;
        SELECT @id_persona = id_persona FROM manejo_personas.usuario WHERE id_usuario = @id_usuario;

        IF NOT EXISTS (
            SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona
        ) AND NOT EXISTS (
            SELECT 1 FROM manejo_personas.invitado WHERE id_persona = @id_persona
        ) AND NOT EXISTS (
            SELECT 1 FROM manejo_personas.responsable WHERE id_persona = @id_persona
        )
        BEGIN
            UPDATE manejo_personas.persona
            SET activo = 0
            WHERE id_persona = @id_persona;
        END

        COMMIT TRANSACTION;

        SELECT 'Exito' AS Resultado, 'Usuario borrado, persona inactivada' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

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


-------- STORED PROCEDURES PARA ACTIVIDAD
-- Crear Invitado
CREATE OR ALTER PROCEDURE manejo_personas.CrearInvitado
	@id_persona INT,
	@id_socio INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Valido que los ids sean validos
		IF @id_persona IS NULL OR @id_socio IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Id de persona nulo' AS Mensaje;
			RETURN -1;
		END

		-- Comprueblo que ese id existe en persona
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'El invitado tiene que ser persona' AS Mensaje;
			RETURN -2;
		END

		-- Compruebo que el socio que lo invita exista
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_socio = @id_socio)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Socio no existe' AS Mensaje;
			RETURN -3;
		END

		-- Compruebo que no se lo este invitando dos veces
		IF EXISTS (SELECT 1 FROM manejo_personas.invitado WHERE id_persona = @id_persona)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Ya existe invitado para esa persona' AS Mensaje;
			RETURN -4;
		END

		-- Metodo los datos
		INSERT INTO manejo_personas.invitado (id_persona, id_socio)
		VALUES (@id_persona, @id_socio);

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Invitado creado' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje,
			   ERROR_NUMBER() AS CodigoError, ERROR_LINE() AS Linea,
			   ERROR_PROCEDURE() AS Procedimiento;
		RETURN -999;
	END CATCH
END;
GO

-- Modificar Invitado
CREATE OR ALTER PROCEDURE manejo_personas.ModificarInvitado
	@id_invitado INT,
	@id_socio INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

	BEGIN TRY
		BEGIN TRANSACTION;

		-- Compruebo que los ids que me pasaron sean validos
		IF @id_invitado IS NULL OR @id_socio IS NULL
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Parametros nulos' AS Mensaje;
			RETURN -1;
		END

		-- Compruebo que el invitado que quiero modificar existe en la tabla
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.invitado WHERE id_invitado = @id_invitado)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Invitado no existe' AS Mensaje;
			RETURN -2;
		END

		-- Compruebo que el socio que lo invita existe
		IF NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_socio = @id_socio)
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'Error' AS Resultado, 'Socio no existe' AS Mensaje;
			RETURN -3;
		END

		-- Inserto los datos
		UPDATE manejo_personas.invitado
		SET id_socio = @id_socio
		WHERE id_invitado = @id_invitado;

		COMMIT TRANSACTION;
		SELECT 'Exito' AS Resultado, 'Invitado modificado' AS Mensaje;
		RETURN 0;
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje,
			   ERROR_NUMBER() AS CodigoError, ERROR_LINE() AS Linea,
			   ERROR_PROCEDURE() AS Procedimiento;
		RETURN -999;
	END CATCH
END;
GO

-- Eliminar Invitado
CREATE OR ALTER PROCEDURE manejo_personas.EliminarInvitado
    @id_invitado INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verifico que el id que me pasaron no es null
        IF @id_invitado IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'id_invitado nulo' AS Mensaje;
            RETURN -1;
        END
		
		-- Verifico que el invitado existe en su tabla
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.invitado WHERE id_invitado = @id_invitado)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Invitado no existe' AS Mensaje;
            RETURN -2;
        END

        -- Obtengo la persona asociada al invitado
        DECLARE @id_persona INT;
        SELECT @id_persona = id_persona
        FROM manejo_personas.invitado
        WHERE id_invitado = @id_invitado;

        -- Eliminar de invitado
        DELETE FROM manejo_personas.invitado
        WHERE id_invitado = @id_invitado;

        -- Intentar eliminar persona si no está referenciada en otras tablas
		-- NOTA: Agregue esto porque si bien creo que un usuario o socio no deberian ser invitados
		-- el DER plantea que si porque son una jerarquia de subconjuntos.
        IF NOT EXISTS (
            SELECT 1 FROM manejo_personas.usuario WHERE id_persona = @id_persona
        ) AND NOT EXISTS (
            SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona
        ) AND NOT EXISTS (
            SELECT 1 FROM manejo_personas.responsable WHERE id_persona = @id_persona
        )
        BEGIN
            DELETE FROM manejo_personas.persona
            WHERE id_persona = @id_persona;
            SELECT 'Exito' AS Resultado, 'Invitado y persona eliminados' AS Mensaje;
        END
        ELSE
        BEGIN
            UPDATE manejo_personas.persona
            SET activo = 0
            WHERE id_persona = @id_persona;
            SELECT 'Exito' AS Resultado, 'Invitado eliminado. Persona inactivada (borrado logico)' AS Mensaje;
        END

        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

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

-------- STORED PROCEDURES PARA ACTIVIDAD
-- Crear Responsable
CREATE OR ALTER PROCEDURE manejo_personas.CrearResponsable
    @id_persona INT,
    @parentesco VARCHAR(10),
    @id_grupo INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Verifico que existe la persona en la tabla de personas
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Persona no encontrada' AS Mensaje;
            RETURN -1;
        END

        -- Chequeo que existe el grupo familiar
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.grupo_familiar WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje;
            RETURN -2;
        END

        -- Valido que la persona no sea ya responsable de otro grupo personal
        IF EXISTS (SELECT 1 FROM manejo_personas.responsable WHERE id_persona = @id_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona ya esta registrada como responsable' AS Mensaje;
            RETURN -3;
        END

		-- Verifico el parentesco
        IF @parentesco IS NOT NULL AND LTRIM(RTRIM(@parentesco)) = ''
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El parentesco no puede estar vacio' AS Mensaje;
            RETURN -4;
        END

        -- Insertar responsable
        INSERT INTO manejo_personas.responsable (id_persona, parentesco, id_grupo)
        VALUES (@id_persona, @parentesco, @id_grupo);

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Responsable creado correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;
GO

-- Modificar responsable
CREATE OR ALTER PROCEDURE manejo_personas.ModificarResponsable
    @id_grupo INT,
    @parentesco VARCHAR(10) = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar existencia de responsable
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.responsable WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Responsable no encontrado' AS Mensaje;
            RETURN -1;
        END

        -- Validar que parentesco no sea vacío si se pasa
        IF @parentesco IS NOT NULL AND LTRIM(RTRIM(@parentesco)) = ''
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Parentesco no puede estar vacío' AS Mensaje;
            RETURN -2;
        END

        -- Actualizar
        UPDATE manejo_personas.responsable
        SET parentesco = ISNULL(@parentesco, parentesco)
        WHERE id_grupo = @id_grupo;

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Responsable actualizado correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;
GO

-- Eliminar responsable
CREATE OR ALTER PROCEDURE manejo_personas.EliminarResponsable
    @id_grupo INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Verifico que el responsable existe en su tabla
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.responsable WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Responsable no encontrado' AS Mensaje;
            RETURN -1;
        END

        -- Obtengo su id de persona
        DECLARE @id_persona INT;
        SELECT @id_persona = id_persona FROM manejo_personas.responsable WHERE id_grupo = @id_grupo;

        -- Elimino ael responsable
        DELETE FROM manejo_personas.responsable WHERE id_grupo = @id_grupo;

        -- Si persona no está asociada a otro rol, inactivar
        IF NOT EXISTS (
            SELECT 1 FROM manejo_personas.usuario WHERE id_persona = @id_persona
        ) AND NOT EXISTS (
            SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona
        ) AND NOT EXISTS (
            SELECT 1 FROM manejo_personas.invitado WHERE id_persona = @id_persona
        )
        BEGIN
            UPDATE manejo_personas.persona
            SET activo = 0
            WHERE id_persona = @id_persona;
        END

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Responsable eliminado correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;
GO

-------- STORED PROCEDURES PARA ACTIVIDAD
-- Crear Grupo Familiar
CREATE OR ALTER PROCEDURE manejo_personas.CrearGrupoFamiliar
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
        INSERT INTO manejo_personas.grupo_familiar (fecha_alta, estado)
        VALUES (GETDATE(), 1);

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Grupo familiar creado correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;
GO

-- Modificar Grupo Familiar
CREATE OR ALTER PROCEDURE manejo_personas.ModificarEstadoGrupoFamiliar
    @id_grupo INT,
    @estado BIT = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.grupo_familiar WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje;
            RETURN -1;
        END

        -- Verificar que el estado sea valido
        IF @estado IS NOT NULL AND @estado NOT IN (0, 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Estado debe ser 0 (inactivo) o 1 (activo)' AS Mensaje;
            RETURN -2;
        END

		-- Modifico el estado
        UPDATE manejo_personas.grupo_familiar
        SET estado = @estado
        WHERE id_grupo = @id_grupo;

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Estado del Grupo familiar actualizado correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;
GO

-- Eliminar grupo familiar
CREATE OR ALTER PROCEDURE manejo_personas.EliminarGrupoFamiliar
    @id_grupo INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;

    BEGIN TRY
		-- Verifico que el grupo familiar exista en la tabla
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.grupo_familiar WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'Grupo familiar no encontrado' AS Mensaje;
            RETURN -1;
        END

        -- Validar que no tenga responsables ni socios activos
        IF EXISTS (SELECT 1 FROM manejo_personas.responsable WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'No se puede eliminar: grupo tiene responsables asignados' AS Mensaje;
            RETURN -2;
        END

		-- Verificar que no tenga socios asignados al grupo
        IF EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_grupo = @id_grupo)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'No se puede eliminar: grupo tiene socios asignados' AS Mensaje;
            RETURN -3;
        END

        -- Borrado logico
        UPDATE manejo_personas.grupo_familiar
        SET estado = 0
        WHERE id_grupo = @id_grupo;

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Grupo familiar inactivado correctamente' AS Mensaje;
        RETURN 0;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH
END;

GO
------ STORED PROCEDURES PARA SOCIO
-- crear socio
CREATE OR ALTER PROCEDURE manejo_personas.CrearSocio
    @id_persona INT,
    @telefono_emergencia VARCHAR(15),
    @obra_nro_socio VARCHAR(20) = NULL,
    @id_obra_social INT = NULL,
    @id_categoria INT,
    @id_grupo INT = NULL
AS
BEGIN
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- verificamos que la persona exista y esté activa
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE id_persona = @id_persona AND activo = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona no existe o está inactiva' AS Mensaje;
            RETURN -1;
        END
        
        -- verificamos que la persona no sea ya un socio
        IF EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La persona ya está registrada como socio' AS Mensaje;
            RETURN -2;
        END
        
        -- verificamos que la categoría exista
        IF NOT EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La categoría especificada no existe' AS Mensaje;
            RETURN -3;
        END
        
        -- verificamos que la obra social exista (si se proporciona)
        IF @id_obra_social IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_personas.obra_social WHERE id_obra_social = @id_obra_social)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La obra social especificada no existe' AS Mensaje;
            RETURN -4;
        END
        
        -- verificamos que el grupo familiar exista y esté activo (si se proporciona)
        IF @id_grupo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_personas.grupo_familiar WHERE id_grupo = @id_grupo AND estado = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El grupo familiar especificado no existe o está inactivo' AS Mensaje;
            RETURN -5;
        END
        
        -- verificamos que la edad de la persona corresponda con la categoría
        DECLARE @edad INT, @edad_maxima INT
        SELECT @edad = DATEDIFF(YEAR, fecha_nac, GETDATE()) FROM manejo_personas.persona WHERE id_persona = @id_persona
        SELECT @edad_maxima = edad_maxima FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria
        
        -- verificamos por tipo de categoría (Menor, Cadete, Mayor)
        DECLARE @nombre_categoria VARCHAR(50)
        SELECT @nombre_categoria = nombre_categoria FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria
        
        IF @nombre_categoria = 'Menor' AND (@edad < 0 OR @edad > 12)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La categoría Menor es solo para personas hasta 12 años' AS Mensaje;
            RETURN -6;
        END
        
        IF @nombre_categoria = 'Cadete' AND (@edad < 13 OR @edad > 17)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La categoría Cadete es solo para personas entre 13 y 17 años' AS Mensaje;
            RETURN -7;
        END
        
        IF @nombre_categoria = 'Mayor' AND @edad < 18
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La categoría Mayor es solo para personas a partir de 18 años' AS Mensaje;
            RETURN -8;
        END
        
        -- insertamos el nuevo socio
        INSERT INTO manejo_personas.socio ( id_persona, telefono_emergencia, obra_nro_socio, id_obra_social, id_categoria, id_grupo)
        VALUES ( @id_persona, @telefono_emergencia, @obra_nro_socio, @id_obra_social, @id_categoria, @id_grupo);

        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Socio registrado correctamente' AS Mensaje;
        RETURN 0;
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH

END;


GO
CREATE OR ALTER PROCEDURE manejo_personas.ModificarSocio
    @id_socio INT,
    @telefono_emergencia VARCHAR(15) = NULL,
    @obra_nro_socio VARCHAR(20) = NULL,
    @id_obra_social INT = NULL,
    @id_categoria INT = NULL,
    @id_grupo INT = NULL
AS
BEGIN
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- verificamos que el socio exista
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_socio = @id_socio)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El socio no existe' AS Mensaje;
            RETURN -1;
        END
        
        -- obtenemos el ID de persona para hacer validaciones
        DECLARE @id_persona INT, @categoria_actual INT
        SELECT @id_persona = id_persona, @categoria_actual = id_categoria 
        FROM manejo_personas.socio 
        WHERE id_socio = @id_socio;
        
        -- verificamos que la categoría exista (si se proporciona)
        IF @id_categoria IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'La categoría especificada no existe' AS Mensaje;
                RETURN -2;
            END
            
            -- verificamos que la edad de la persona corresponda con la nueva categoría
            DECLARE @edad INT, @nombre_categoria VARCHAR(50)
            SELECT @edad = DATEDIFF(YEAR, fecha_nac, GETDATE()) FROM manejo_personas.persona WHERE id_persona = @id_persona
            SELECT @nombre_categoria = nombre_categoria FROM manejo_actividades.categoria WHERE id_categoria = @id_categoria
            
            -- Validaciones específicas por categoría
            IF @nombre_categoria = 'Menor' AND (@edad < 0 OR @edad > 12)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'La categoría Menor es solo para personas hasta 12 años' AS Mensaje;
                RETURN -3;
            END
            
            IF @nombre_categoria = 'Cadete' AND (@edad < 13 OR @edad > 17)
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'La categoría Cadete es solo para personas entre 13 y 17 años' AS Mensaje;
                RETURN -4;
            END
            
            IF @nombre_categoria = 'Mayor' AND @edad < 18
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 'Error' AS Resultado, 'La categoría Mayor es solo para personas a partir de 18 años' AS Mensaje;
                RETURN -5;
            END
        END
        
        -- verificamos que la obra social exista (si se proporciona)
        IF @id_obra_social IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_personas.obra_social WHERE id_obra_social = @id_obra_social)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'La obra social especificada no existe' AS Mensaje;
            RETURN -6;
        END
        
        -- verificamos que el grupo familiar exista y esté activo (si se proporciona)
        IF @id_grupo IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_personas.grupo_familiar WHERE id_grupo = @id_grupo AND estado = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El grupo familiar especificado no existe o está inactivo' AS Mensaje;
            RETURN -7;
        END
        
        -- si pasa todas las verificaciones, actualizamos los datos del socio
        UPDATE manejo_personas.socio
        SET telefono_emergencia = ISNULL(@telefono_emergencia, telefono_emergencia),
            obra_nro_socio = ISNULL(@obra_nro_socio, obra_nro_socio),
            id_obra_social = ISNULL(@id_obra_social, id_obra_social),
            id_categoria = ISNULL(@id_categoria, id_categoria),
            id_grupo = ISNULL(@id_grupo, id_grupo)
        WHERE id_socio = @id_socio;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Datos del socio actualizados correctamente' AS Mensaje;
        RETURN 0;
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH

END;

GO
-- eliminar socio
CREATE OR ALTER PROCEDURE manejo_personas.EliminarSocio
    @id_socio INT
AS
BEGIN
    
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- verificamos que el socio exista
        IF NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_socio = @id_socio)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'El socio no existe' AS Mensaje;
            RETURN -1;
        END
        
        -- verificamos si el socio es responsable de un grupo familiar
        IF EXISTS (
            SELECT 1 FROM manejo_personas.responsable
            WHERE id_responsable = @id_socio
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'No se puede eliminar el socio porque es responsable de un grupo familiar' AS Mensaje;
            RETURN -2;
        END
        
        -- verificamos si hay facturas asociadas al socio
        DECLARE @id_persona INT
        SELECT @id_persona = id_persona FROM manejo_personas.socio WHERE id_socio = @id_socio
        
        IF EXISTS (
            SELECT 1 FROM pagos_y_facturas.factura
            WHERE id_persona = @id_persona
        )
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Error' AS Resultado, 'No se puede eliminar el socio porque tiene facturas asociadas' AS Mensaje;
            RETURN -3;
        END
        
        -- eliminamos primero las relaciones dependientes
        
        -- primero eliminmaos relaciones con actividades
        DELETE FROM manejo_personas.socio_actividad
        WHERE id_socio = @id_socio;
        
        -- segundo eliminamos invitados asociados
        DELETE FROM manejo_personas.invitado
        WHERE id_socio = @id_socio;
        
        -- por ultimo eliminamos el socio
        DELETE FROM manejo_personas.socio
        WHERE id_socio = @id_socio;
        
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Socio y todas sus relaciones eliminados completamente del sistema' AS Mensaje;
        RETURN 0;
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -99;
    END CATCH

END;

GO
