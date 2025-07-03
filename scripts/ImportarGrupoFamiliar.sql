EXEC sp_configure 'Show Advanced Options', 1;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;
RECONFIGURE;
GO

USE Com5600G01;
GO
-- #################################################
-- ################### SP IMPORTAR #################
-- #################################################
USE Com5600G01;
GO
CREATE OR ALTER PROCEDURE usuarios.importarGrupoFamiliar
    @path NVARCHAR(400) 
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabla temporal para almacenar los datos importados
    CREATE TABLE #tempGrupoFamiliar (
        nro_de_socio VARCHAR(7),
		nro_de_socio_RP VARCHAR(7),
		nombre VARCHAR(35),
		apellido VARCHAR(35),
		dni INT,
		email_personal VARCHAR(255),
		fec_nac DATE,
		tel_contacto VARCHAR(20),
		tel_emerg INT,
		nom_obra_social VARCHAR(35),
		nro_socio_obra_social VARCHAR(35),
		tel_cont_emerg VARCHAR(80)
    );

    DECLARE @sql NVARCHAR(MAX);

    -- Consulta con los encabezados EXACTOS como aparecen en tu Excel
    SET @sql = N'
        INSERT INTO #tempGrupoFamiliar (
            nro_de_socio,
			nro_de_socio_RP,
			nombre,
			apellido,
			dni,
			email_personal,
			fec_nac,
			tel_contacto,
			tel_emerg,
			nom_obra_social,
			nro_socio_obra_social,
			tel_cont_emerg
        )
        SELECT
            [Nro de Socio],
			[Nro de socio RP],
			RTRIM(LTRIM(LOWER([Nombre]))),
			RTRIM(LTRIM(LOWER([ apellido]))),
			[ DNI],
			[ email personal],
			CONVERT(DATE, [ fecha de nacimiento], 103) AS fecha_nacimiento,
			[ teléfono de contacto],
			[ teléfono de contacto emergencia],
			RTRIM(LTRIM(LOWER([ Nombre de la obra social o prepaga]))),
			[nro# de socio obra social/prepaga ],
			[teléfono de contacto de emergencia ]

			
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @path + ''',
            ''SELECT * FROM [Grupo Familiar$]''
        ) AS ExcelData;
    ';

    BEGIN TRY
        EXEC sp_executesql @sql;
		
		-- Variables auxiliares:  
		DECLARE 
			@nro_de_socio VARCHAR(7),
            @nro_de_socio_RP VARCHAR(7),
            @nombre VARCHAR(35),
            @apellido VARCHAR(35),
            @dni INT,
            @email_personal VARCHAR(255),
            @fec_nac DATE,
            @tel_contacto VARCHAR(20),
            @tel_emerg INT,
            @nom_obra_social VARCHAR(35),
            @nro_socio_obra_social VARCHAR(35),
            @tel_cont_emerg VARCHAR(80);
		-- 
		DECLARE @i INT = 0; 
		-- cursor para recorrer fila por fila
        DECLARE cur CURSOR FOR
            SELECT nro_de_socio, nro_de_socio_RP, nombre, apellido, dni, email_personal, fec_nac, tel_contacto, tel_emerg, nom_obra_social, nro_socio_obra_social, tel_cont_emerg
            FROM #tempGrupoFamiliar;

        OPEN cur;

        FETCH NEXT FROM cur INTO 
            @nro_de_socio, @nro_de_socio_RP, @nombre, @apellido, @dni, @email_personal, @fec_nac, @tel_contacto, @tel_emerg, @nom_obra_social, @nro_socio_obra_social, @tel_cont_emerg;
        WHILE @@FETCH_STATUS = 0
        BEGIN
			-- Limpio el numero de los socios:  
			SET @nro_de_socio_RP = SUBSTRING(@nro_de_socio_RP, CHARINDEX('-', @nro_de_socio_RP) + 1, LEN(@nro_de_socio_RP));
			SET @nro_de_socio = SUBSTRING(@nro_de_socio, CHARINDEX('-', @nro_de_socio) + 1, LEN(@nro_de_socio));
			
			-- Obtengo el id del socio responsable: 
			DECLARE @id_socio_rp INT = NULL; 
			SELECT @id_socio_rp = id_socio
			FROM usuarios.socio	
			WHERE numero_socio = @nro_de_socio_RP;

			IF @id_socio_rp IS NOT NULL 
			BEGIN 
			
				-- Evaluo si existe el grupo familiar: 
				DECLARE @idGrupo INT = NULL;
				SELECT @idGrupo = g.id_grupo_familiar FROM usuarios.grupo_familiar  g WHERE g.id_socio_rp = @id_socio_rp;
				IF @idGrupo IS NULL -- Si no existe lo creo: 
				BEGIN
					EXEC usuarios.CrearGrupoFamiliar @id_socio_rp = @id_socio_rp;
				END

				-- Obtengo la obra social o la creo
				DECLARE @id_obra_social INT = NULL; 
				SELECT @id_obra_social = id_obra_social 
				FROM usuarios.obra_social o WHERE UPPER(o.descripcion) = UPPER(RTRIM(LTRIM(@nom_obra_social)));
				IF @id_obra_social IS NULL AND @nom_obra_social IS NOT NULL 
				BEGIN
					EXEC usuarios.CrearObraSocial @nombre = @nom_obra_social, @nro_telefono = '11';
				END

				-- Obtengo la categoria del nuevo socio: 
				DECLARE @edad INT;
				SET @edad = DATEDIFF(YEAR, @fec_nac, GETDATE());

				IF NOT EXISTS (SELECT 1 FROM usuarios.socio s WHERE s.numero_socio = @nro_de_socio)
				BEGIN
				PRINT 'creo socio';
					-- obtengo el id de la categoria que corresponde: 
					DECLARE @id_categoria INT = NULL; 

					IF @edad > 17 
					BEGIN 
						SELECT @id_categoria = c.id_categoria  
						FROM actividades.categoria c 
						WHERE LOWER(nombre_categoria) = 'mayor';
						END 
						ELSE IF @edad <= 17 AND @edad > 12 
						BEGIN
							SELECT @id_categoria = c.id_categoria  
							FROM actividades.categoria c 
							WHERE LOWER(nombre_categoria) = 'cadete';
						END 
						ELSE 
						BEGIN
							SELECT @id_categoria = c.id_categoria  
							FROM actividades.categoria c 
							WHERE LOWER(nombre_categoria) = 'menor';
						END;

						-- crear socio: 
						SET @tel_contacto = ISNULL(@tel_contacto, '11');
						DECLARE @email_new VARCHAR(255) =  'socio_' + CAST(@i AS NVARCHAR) + '@example.com';
						EXEC usuarios.CrearSocio
						@id_persona = NULL,
						@dni = @dni,
						@nombre = @nombre,
						@apellido = @apellido,
						@email =  @email_new,
						@fecha_nac = @fec_nac,
						@telefono = @tel_contacto, 
						@numero_socio = @nro_de_socio,
						@telefono_emergencia = @tel_cont_emerg,
						@obra_nro_socio = @nro_socio_obra_social,
						@id_obra_social = @id_obra_social,  
						@id_categoria = @id_categoria,
						@id_grupo = @idGrupo;
						
					SET @i = @i +1; 	
					END  
				ELSE 
				BEGIN
					UPDATE usuarios.socio
					SET  id_grupo= @idGrupo
					WHERE numero_socio = @nro_de_socio
				END; 
			END
			ELSE 
			BEGIN
				PRINT 'socio responsable NO existe' + @nro_de_socio_RP;; 
			END;

            -- Obtener siguiente fila
            FETCH NEXT FROM cur INTO  @nro_de_socio, @nro_de_socio_RP, @nombre, @apellido, @dni, @email_personal, @fec_nac, @tel_contacto, @tel_emerg, @nom_obra_social, @nro_socio_obra_social, @tel_cont_emerg;
        END

        CLOSE cur;
        DEALLOCATE cur;
        -- Mostrar los datos importados
       -- SELECT * FROM #tempGrupoFamiliar;
			
    END TRY
    BEGIN CATCH
        SELECT 
            'ERROR' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_LINE() AS LineaError,
            ERROR_NUMBER() AS CodigoError;
    END CATCH;
END;
GO

GO


GO
EXEC usuarios.importarGrupoFamiliar @path = 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx'

-- TEST: 
/*
USE Com5600G01;
EXEC actividades.CrearCategoria 
    'Junior', 
    150.00, 
    '2025-12-31';

EXEC usuarios.CrearObraSocial 	
	@nombre = 'sancor',
	@nro_telefono = '1133455';



EXEC usuarios.CrearSocio
    @id_persona = NULL,
    @dni = '40200123',
    @nombre = 'Lucía',
    @apellido = 'Fernández',
    @email = 'lucia.fernandez@example.com',
    @fecha_nac = '1990-05-20',
    @telefono = '1155555555',
    @numero_socio = '4022',
    @telefono_emergencia = '1166666666',
    @obra_nro_socio = 'OBR-9988',
    @id_obra_social = 1,   -- Debe existir
    @id_categoria = 1;     -- Debe existir 
	


	EXEC usuarios.CrearSocio
    @id_persona = NULL,
    @dni = '6543378',
    @nombre = 'Lionel',
    @apellido = 'Messi',
    @email = 'MESSI@example.com',
    @fecha_nac = '2010-05-20',
    @telefono = '234534',
    @numero_socio = '4019',
    @telefono_emergencia = '1166666666',
    @obra_nro_socio = 'OBR-9988',
    @id_obra_social = 1,   -- Debe existir
    @id_categoria = 1;     -- Debe existir
GO


*/