USE Com5600G01;

-- Este SP valida los datos de entrada y realiza la inserci?n de un nuevo registro en la tabla persona.
/*
* Nombre: CrearPersona
* Descripción: Inserta una nueva persona en la tabla persona, validando su informacion. 
* Parámetros:
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
* Descripción del resultado o código de error que puede retornar
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