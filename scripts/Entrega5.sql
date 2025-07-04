/*
	Entrega 5
	
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés
*/


-- REQUIERE Microsoft Access Database Engine 2016 Redistributable!!!!!!!!!!!!!!!!!!!

-- CREA LOS SPS PARA LA IMPORTACION DE DATOS

-- CONFIGURACIONES NECESARIAS PARA PODER LA IMPORTACION
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

-- Importar Categorias - FUNCIONANDO
CREATE OR ALTER PROCEDURE actividades.ImportarCategorias
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @nombre_categoria VARCHAR(50), -- Variables auxiliares
                @costo_membrecia DECIMAL(10,2), 
                @vigencia DATE,
                @id_categoria INT; -- Declarar la variable aquí
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos (
            [Categoria socio] VARCHAR(50),
            [Valor cuota] DECIMAL(10, 2),
            [Vigente hasta] DATE
        );
        
        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos ([Categoria socio], 
                                    [Valor cuota], 
                                    [Vigente hasta])
            SELECT [Categoria socio], 
                   [Valor cuota], 
                   [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B10:D13]'')';
        
        EXEC sp_executesql @SQL; -- Importa los registros
        
        DECLARE cur CURSOR FOR
            SELECT [Categoria socio], 
                   [Valor cuota], 
                   [Vigente hasta] 
            FROM #TempDatos
            WHERE [Categoria socio] IS NOT NULL;
            
        OPEN cur;
        FETCH NEXT FROM cur INTO @nombre_categoria, @costo_membrecia, @vigencia;
        
        -- Va revisando registro por registro
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                DECLARE @return_procedimiento INT;
                DECLARE @id_aux INT;
                
                -- Llamo al procedimiento y capturo el resultado
                EXEC @return_procedimiento = actividades.CrearCategoria
                    @nombre_categoria = @nombre_categoria,
                    @costo_membrecia = @costo_membrecia,
                    @vigencia = @vigencia;
                
                -- Si ya existía en la tabla
                IF @return_procedimiento = -10
                BEGIN
                    -- Captura el ID
                    SELECT @id_aux = id_categoria
                    FROM actividades.categoria 
                    WHERE nombre_categoria = @nombre_categoria;
                    
                    -- Modifica
                    EXEC actividades.ModificarCategoria
                        @id_categoria = @id_aux,
                        @nombre_categoria = @nombre_categoria,
                        @costo_membrecia = @costo_membrecia,
                        @vigencia = @vigencia;
                END
            END TRY
            BEGIN CATCH
                SELECT 'Error' AS Resultado, 
                       'Error al importar registro: ' + ISNULL(ERROR_MESSAGE(), 'Error desconocido') AS Mensaje;
            END CATCH
            
            FETCH NEXT FROM cur INTO @nombre_categoria, @costo_membrecia, @vigencia;
        END
        
        -- Cierra objetos
        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;
        
        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        -- Cleanup en caso de error
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END
        
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO
    
-- Importar Socios - FUNCIONANDO
CREATE OR ALTER PROCEDURE usuarios.ImportarSocios
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @id_persona INT;
    DECLARE @id_socio INT;
    DECLARE @id_ObSo INT;
    DECLARE @id_categoria INT;

    BEGIN TRY
        -- Tabla temporal para poner los datos
        CREATE TABLE #TempDatos ( 
            [Nro de Socio] VARCHAR(20),
            [Nombre] NVARCHAR(50),
            [ apellido] NVARCHAR(50),
            [ DNI] VARCHAR(20),
            [ email personal] VARCHAR(320),
            [ fecha de nacimiento] DATE,
            [ teléfono de contacto] VARCHAR(50),
            [ teléfono de contacto emergencia] VARCHAR(50),
            [ Nombre de la obra social o prepaga] NVARCHAR(100),
            [nro# de socio obra social/prepaga ] VARCHAR(50),
            [teléfono de contacto de emergencia ] VARCHAR(50)
        );

        -- Variables auxiliares
        DECLARE @dni VARCHAR(20), 
                @nombre NVARCHAR(100), 
                @apellido NVARCHAR(100),
                @email VARCHAR(320), 
                @fechaNac DATE, 
                @telefono VARCHAR(50),
                @telefonoEmergencia VARCHAR(50), 
                @obraSocial NVARCHAR(100),
                @nroSocioObra VARCHAR(50), 
                @nroSocio VARCHAR(20),
                @telefonoObraSocial VARCHAR(50);
        -- Arma el SQL para la ruta
        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Nro de Socio], [Nombre], 
                [ apellido], 
                [ DNI], 
                [ email personal],
                [ fecha de nacimiento], 
                [ teléfono de contacto], 
                [ teléfono de contacto emergencia],
                [ Nombre de la obra social o prepaga], 
                [nro# de socio obra social/prepaga ], 
                [teléfono de contacto de emergencia ]
            )
            SELECT 
                [Nro de Socio],
                [Nombre],
                [ apellido], 
                [ DNI],
                [ email personal],
                [ fecha de nacimiento],
                CASE 
                    WHEN ISNUMERIC([ teléfono de contacto]) = 1 AND [ teléfono de contacto] IS NOT NULL
                    THEN FORMAT(CAST([ teléfono de contacto] AS BIGINT), ''0'')
                    ELSE CAST([ teléfono de contacto] AS VARCHAR(50))
                END,
                CASE 
                    WHEN ISNUMERIC([ teléfono de contacto emergencia]) = 1 AND [ teléfono de contacto emergencia] IS NOT NULL
                    THEN FORMAT(CAST([ teléfono de contacto emergencia] AS BIGINT), ''0'')
                    ELSE CAST([ teléfono de contacto emergencia] AS VARCHAR(50))
                END,
                [ Nombre de la obra social o prepaga],
                [nro# de socio obra social/prepaga ],
                CASE 
                    WHEN ISNUMERIC([teléfono de contacto de emergencia ]) = 1 AND [teléfono de contacto de emergencia ] IS NOT NULL
                    THEN FORMAT(CAST([teléfono de contacto de emergencia ] AS BIGINT), ''0'')
                    ELSE CAST([teléfono de contacto de emergencia ] AS VARCHAR(50))
                END
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;TypeGuessRows=0;Database=' + @RutaArchivo + ''',
                    ''SELECT * FROM [Responsables de Pago$]'')';
        
        EXEC sp_executesql @SQL;  -- Importa los registros

        -- Declara el cursor para la tabla
        DECLARE cur CURSOR FOR 
        SELECT [Nro de Socio], 
               [ DNI], 
               [Nombre], 
               [ apellido], 
               [ email personal],
               [ fecha de nacimiento], 
               [ teléfono de contacto], 
               [ teléfono de contacto emergencia],
               [ Nombre de la obra social o prepaga], 
               [nro# de socio obra social/prepaga ],
               [teléfono de contacto de emergencia ]
        FROM #TempDatos;

        OPEN cur;
        FETCH NEXT FROM cur INTO @nroSocio, 
                                 @dni, 
                                 @nombre, 
                                 @apellido, 
                                 @email, 
                                 @fechaNac,
                                 @telefono, 
                                 @telefonoEmergencia, 
                                 @obraSocial, 
                                 @nroSocioObra,
                                 @telefonoObraSocial;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- Reinicializar variables para cada iteración (si no queda usando la misma)
                SET @id_ObSo = NULL;

                -- Antes de insertar, normalizar los campos de texto
                SET @nroSocio = REPLACE(LTRIM(RTRIM(@nroSocio)), 'SN-', '');
                SET @dni = REPLACE(REPLACE(LTRIM(RTRIM(@dni)), '.', ''), '-', '');
                SET @email = LOWER(REPLACE(LTRIM(RTRIM(@email)), ' ', ''));
                SET @obraSocial = LTRIM(RTRIM(@obraSocial)); -- Corregido: faltaba paréntesis de cierre

                -- Buscar IDs existentes
                SELECT @id_persona = id_persona FROM usuarios.persona WHERE dni = @dni;
                SELECT @id_ObSo = id_obra_social FROM usuarios.obra_social WHERE descripcion = @obraSocial;

                -- Si la obra social no existe, crearla y obtener el id
                IF @obraSocial IS NOT NULL AND @obraSocial <> ''
                BEGIN
                    IF @id_ObSo IS NULL
                    BEGIN
                        DECLARE @new_id_obra_social INT;
                        EXEC usuarios.CrearObraSocial
                            @nombre = @obraSocial,
                            @nro_telefono = @telefonoObraSocial,
                            @id_obra_social = @new_id_obra_social OUTPUT;
                        SET @id_ObSo = @new_id_obra_social;
                    END
                    ELSE
                    BEGIN
                        DECLARE @mod_id_obra_social INT;
                        EXEC usuarios.ModificarObraSocial
                            @id = @id_ObSo,
                            @nombre_nuevo = @obraSocial,
                            @nro_telefono = @telefonoObraSocial,
                            @id_obra_social = @mod_id_obra_social OUTPUT;
                        SET @id_ObSo = @mod_id_obra_social;
                    END
                END

                -- Calcular categoría segun edad
                DECLARE @edad INT = DATEDIFF(YEAR, @fechaNac, GETDATE());
                
                -- Logica para determinar categoría según edad
                IF @edad >= 18
                    SELECT @id_categoria = id_categoria FROM actividades.categoria WHERE nombre_categoria = 'mayor';
                ELSE IF @edad >= 13
                    SELECT @id_categoria = id_categoria FROM actividades.categoria WHERE nombre_categoria = 'cadete';
                ELSE
                    SELECT @id_categoria = id_categoria FROM actividades.categoria WHERE nombre_categoria = 'menor';

                -- Crea o modifica el socio
                EXEC usuarios.CrearSocio
                     @id_persona = @id_persona,
                     @dni = @dni,
                     @nombre = @nombre,
                     @apellido = @apellido,
                     @email = @email,
                     @fecha_nac = @fechaNac,
                     @telefono = @telefono,
                     @numero_socio = @nroSocio,
                     @telefono_emergencia = @telefonoEmergencia,
                     @obra_nro_socio = @nroSocioObra,
                     @id_obra_social = @id_ObSo,
                     @id_categoria = @id_categoria;

                FETCH NEXT FROM cur INTO @nroSocio, 
                                         @dni, 
                                         @nombre, 
                                         @apellido, 
                                         @email, 
                                         @fechaNac,
                                         @telefono, 
                                         @telefonoEmergencia, 
                                         @obraSocial, 
                                         @nroSocioObra,
                                         @telefonoObraSocial;

            END TRY
            BEGIN CATCH
                -- Continuar con el siguiente registro
                FETCH NEXT FROM cur INTO @nroSocio, 
                                         @dni, 
                                         @nombre, 
                                         @apellido, 
                                         @email, 
                                         @fechaNac,
                                         @telefono, 
                                         @telefonoEmergencia, 
                                         @obraSocial, 
                                         @nroSocioObra,
                                         @telefonoObraSocial;
            END CATCH
        END

        -- Cleanup del cursor
        CLOSE cur;
        DEALLOCATE cur;

        -- Cleanup de tabla temporal
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Resultado, 'Proceso completado correctamente' AS Mensaje;

    END TRY
    BEGIN CATCH
        -- Cleanup en caso de error general
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END

        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Grupo Familiar - FUNCIONANDO
CREATE OR ALTER PROCEDURE usuarios.importarGrupoFamiliar
    @path NVARCHAR(260) 
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

-- Importar Actividades - FUNCIONADO
CREATE OR ALTER PROCEDURE actividades.ImportarActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @nombre_actividad VARCHAR(50),
                @costo_mensual DECIMAL(10,2),
                @SQL NVARCHAR(MAX);

        CREATE TABLE #TempDatos (
            [Actividad] VARCHAR(50),
            [Valor por mes] DECIMAL(10,2),
            [Vigente hasta] DATE
        );

        SET @SQL = N'
            INSERT INTO #TempDatos ([Actividad], [Valor por mes], [Vigente hasta])
            SELECT [Actividad], [Valor por mes], [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B2:D8]'')';

        EXEC sp_executesql @SQL;

        DECLARE cur CURSOR FOR
            SELECT [Actividad], [Valor por mes]
            FROM #TempDatos
            WHERE [Actividad] IS NOT NULL;

        OPEN cur;
        FETCH NEXT FROM cur INTO @nombre_actividad, @costo_mensual;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                DECLARE @return_procedimiento INT;
                DECLARE @id_aux INT;

                EXEC @return_procedimiento = actividades.CrearActividad
                    @nombre_actividad = @nombre_actividad,
                    @costo_mensual = @costo_mensual;

                IF @return_procedimiento = -2
                BEGIN
                    SELECT @id_aux = id_actividad
                    FROM actividades.actividad 
                    WHERE nombre = @nombre_actividad;

                    EXEC actividades.ModificarActividad
                        @id = @id_aux,
                        @nombre_actividad = @nombre_actividad,
                        @costo_mensual = @costo_mensual;
                END
            END TRY
            BEGIN CATCH
                SELECT 'Error' AS Resultado, 
                       'Error al importar registro: ' + ISNULL(ERROR_MESSAGE(), 'Error desconocido') AS Mensaje;
            END CATCH

            FETCH NEXT FROM cur INTO @nombre_actividad, @costo_mensual;
        END

        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Resultado, 'Importación de actividades completada' AS Mensaje;

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END

        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Costos de Pileta - FUNCIONADO
EXEC actividades.CrearPileta 
    @detalle = 'Pileta prueba',
    @metro_cuadrado = 10;
GO
CREATE OR ALTER PROCEDURE actividades.ImportarCostosPileta
    @RutaArchivo NVARCHAR(260),
    @id_pileta    INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE 
            @SQL            NVARCHAR(MAX),
            @conceptoBruto  NVARCHAR(100),
            @grupoBruto     NVARCHAR(100),
            @sociosBruto    NVARCHAR(100),
            @invitadosBruto NVARCHAR(100),
            @lastConcepto   NVARCHAR(100)   = NULL, -- para rellenar nulls
            @tipo           CHAR(3),
            @tipo_grupo     CHAR(3),
            @precio_socios  DECIMAL(10,2),
            @precio_invitados DECIMAL(10,2),
            @return_sp      INT,
            @id_aux         INT;

        -- Tabla temporal donde importar crudo
        CREATE TABLE #TempDatos (
            [Concepto]  NVARCHAR(100), --nombre de tarifa
            [Grupo]     NVARCHAR(100), --adulto o menores
            [Socios]    NVARCHAR(100),
            [Invitados] NVARCHAR(100)
        );

        SET @SQL = N'
            INSERT INTO #TempDatos(Concepto,Grupo,Socios,Invitados)
            SELECT F1,F2,F3,F4
              FROM OPENROWSET(
                   ''Microsoft.ACE.OLEDB.12.0'',
                   ''Excel 12.0;HDR=NO;IMEX=1;TypeGuessRows=0;Database=' + @RutaArchivo + ''',
                   ''SELECT * FROM [Tarifas$B16:F22]''
              )';
        EXEC sp_executesql @SQL;

        DECLARE cur CURSOR FOR
            SELECT Concepto,Grupo,Socios,Invitados
              FROM #TempDatos
             WHERE Grupo IS NOT NULL;  -- descartar fila de título

        OPEN cur;
        FETCH NEXT FROM cur INTO @conceptoBruto,@grupoBruto,@sociosBruto,@invitadosBruto;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- relleanr Concepto
                IF @conceptoBruto IS NOT NULL AND LTRIM(RTRIM(@conceptoBruto)) <> ''
                    SET @lastConcepto = @conceptoBruto;
                SET @conceptoBruto = @lastConcepto;

                -- mapear tipo (dia/tem/mes)
                SET @tipo = CASE
                    WHEN @conceptoBruto LIKE '%dia%'  OR @conceptoBruto LIKE '%día%'      THEN 'dia'
                    WHEN @conceptoBruto LIKE '%temporad%'                            THEN 'tem'
                    WHEN @conceptoBruto LIKE '%mes%'                                 THEN 'mes'
                    ELSE NULL
                END;

                -- mapear grupo (adu/men)
                SET @tipo_grupo = CASE
                    WHEN @grupoBruto LIKE '%menor%' THEN 'men'
                    ELSE 'adu'
                END;

                -- limpiar y convertir Socios a DECIMAL
                SET @precio_socios = TRY_CAST(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(REPLACE(@sociosBruto, CHAR(160), ''), ' ', ''), '$', ''), '.', ''
                        ), ',', '.')
                  AS DECIMAL(10,2));

                -- limpiar y convertir Invitados (0 si vacío)
                SET @precio_invitados = ISNULL(
                  TRY_CAST(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(REPLACE(@invitadosBruto, CHAR(160), ''), ' ', ''), '$', ''), '.', ''
                        ), ',', '.')
                  AS DECIMAL(10,2))
                , 0);

                IF @tipo IS NOT NULL
                BEGIN
                    -- alta o modificación
                    SELECT @id_aux = id_costo
                      FROM actividades.costo
                     WHERE tipo       = @tipo
                       AND tipo_grupo = @tipo_grupo
                       AND id_pileta   = @id_pileta;

                    IF @id_aux IS NULL
                        EXEC @return_sp = actividades.CrearCosto
                            @tipo             = @tipo,
                            @tipo_grupo       = @tipo_grupo,
                            @precio_socios    = @precio_socios,
                            @precio_invitados = @precio_invitados,
                            @id_pileta        = @id_pileta;
                    ELSE
                        EXEC @return_sp = actividades.ModificarCosto
                            @id_costo         = @id_aux,
                            @tipo             = @tipo,
                            @tipo_grupo       = @tipo_grupo,
                            @precio_socios    = @precio_socios,
                            @precio_invitados = @precio_invitados,
                            @id_pileta        = @id_pileta;
                END
            END TRY
            BEGIN CATCH
                SELECT 'Error' AS Resultado, 
                       'Error al importar registro: ' 
                       + ISNULL(ERROR_MESSAGE(),'Error desconocido') AS Mensaje;
            END CATCH

            FETCH NEXT FROM cur INTO @conceptoBruto,@grupoBruto,@sociosBruto,@invitadosBruto;
        END

        -- Cierra objetos
        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;

        -- Resultado final
        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        -- Cleanup en caso de error
        IF CURSOR_STATUS('local','cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' 
               + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Clima - FUNCIONANDO
CREATE OR ALTER PROCEDURE facturacion.ImportarClima
    @RutaBase NVARCHAR(300) = '.\docs\',  -- Ruta base donde están los archivos
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Construir la ruta del archivo dinámicamente
        DECLARE @RutaArchivo NVARCHAR(400);
        SET @RutaArchivo = @RutaBase + 'open-meteo-buenosaires_' + CAST(@Anio AS NVARCHAR(4)) + '.csv';
        
        -- Tabla temporal para importar los datos del CSV
        CREATE TABLE #TempClima (
            [time] VARCHAR(20),
            [temperature_2m] VARCHAR(20) NULL,
            [rain_mm] VARCHAR(20) NULL,
            [relative_humidity_2m] VARCHAR(20) NULL,
            [wind_speed_10m] VARCHAR(20) NULL
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Importar datos desde el CSV, saltando las primeras 2 líneas (encabezados)
        SET @SQL = N'
            BULK INSERT #TempClima
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIRSTROW = 3,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                TABLOCK
            );';
        
        EXEC sp_executesql @SQL;
        
        -- Variables para el cursor
        DECLARE @fechaHora SMALLDATETIME, @lluvia DECIMAL(5,2), @hora VARCHAR(20), @rain VARCHAR(20);
        
        DECLARE cur CURSOR FOR
            SELECT [time], 
                   [rain_mm]
            FROM #TempClima
            WHERE [time] IS NOT NULL AND [rain_mm] IS NOT NULL AND LTRIM(RTRIM([time])) <> '';
        
        OPEN cur;
        FETCH NEXT FROM cur INTO @hora, @rain;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- Limpiar espacios y caracteres extraños
                SET @hora = LTRIM(RTRIM(@hora));
                
                -- Convertir el campo time a SMALLDATETIME
                DECLARE @fechaStr NVARCHAR(10), @horaStr NVARCHAR(5), @fechaHoraStr NVARCHAR(20);
                
                -- Extraer fecha y hora por separado
                SET @fechaStr = LEFT(@hora, 10);  -- 2025-01-01
                SET @horaStr = RIGHT(@hora, 5);   -- 03:00
                
                -- Combinar en formato estándar
                SET @fechaHoraStr = @fechaStr + ' ' + @horaStr;
                
                -- Convertir a SMALLDATETIME
                SET @fechaHora = CAST(@fechaHoraStr AS SMALLDATETIME);
                
                -- Convertir lluvia a decimal
                SET @lluvia = TRY_CAST(REPLACE(@rain, ',', '.') AS DECIMAL(5,2));
                
                -- Llamar al SP de registro de clima
                EXEC facturacion.RegistrarClima @fecha = @fechaHora, @lluvia = @lluvia;
            END TRY
            BEGIN CATCH
                -- Continuar con el siguiente registro
            END CATCH
            
            FETCH NEXT FROM cur INTO @hora, @rain;
        END
        
        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempClima;
        
        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
               
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END
        
        IF OBJECT_ID('tempdb..#TempClima') IS NOT NULL
            DROP TABLE #TempClima;
            
        SELECT 'Error' AS Resultado, 'Error en el proceso' AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Facturas - FUNCIONANDO
CREATE OR ALTER PROCEDURE facturacion.ImportarFacturas
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorOcurrido BIT = 0;
    DECLARE @MensajeError NVARCHAR(MAX) = '';

    BEGIN TRY
        -- Crear tabla temporal 
        CREATE TABLE #TempDatos (
            [Id de pago] BIGINT,
            [fecha] DATE,
            [Responsable de pago] VARCHAR(20),
            [Valor] DECIMAL(10,2),
            [Medio de pago] VARCHAR(50)
        );

        -- Arma la consulta
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Id de pago], [fecha], [Responsable de pago], [Valor], [Medio de pago]
            )
            SELECT 
                CAST([Id de pago] AS BIGINT), 
                [fecha], 
                [Responsable de pago], 
                [Valor], 
                [Medio de pago]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [pago cuotas$A1:E10000]'')';
        EXEC sp_executesql @SQL; -- La ejecuta
    
        --  Variables auxiliares y cursor para recorrer la tabla
        DECLARE @id_pago BIGINT, @fecha DATE, @numero_socio VARCHAR(20), @valor DECIMAL(10,2), @medio_pago VARCHAR(50);
        DECLARE @id_persona INT, @id_metodo_pago INT;
        DECLARE @ContadorExitosos INT = 0;
        DECLARE @ContadorErrores INT = 0;

        DECLARE cur CURSOR FOR
            SELECT [Id de pago], [fecha], [Responsable de pago], [Valor], [Medio de pago]
            FROM #TempDatos
            WHERE [Responsable de pago] IS NOT NULL;

        OPEN cur;
        FETCH NEXT FROM cur INTO @id_pago, @fecha, @numero_socio, @valor, @medio_pago;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- Quita el SN a los registros 'SN-'
                SET @numero_socio = REPLACE(@numero_socio, 'SN-', '');
                SET @numero_socio = LTRIM(RTRIM(@numero_socio));
                SET @medio_pago = LTRIM(RTRIM(@medio_pago));

                -- Buscar id_persona a partir del numero_socio
                SELECT @id_persona = s.id_persona
                FROM usuarios.socio s
                WHERE s.numero_socio = @numero_socio;

                IF @id_persona IS NULL
                BEGIN
                    SET @ContadorErrores = @ContadorErrores + 1;
                    SET @ErrorOcurrido = 1;
                    SET @MensajeError = @MensajeError + 
                        'No se encontró persona para socio "' + ISNULL(@numero_socio, 'NULL') + '".' + CHAR(13) + CHAR(10);
                    GOTO SIGUIENTE;
                END

                -- Buscar id_metodo_pago a partir del nombre
                SELECT @id_metodo_pago = id_metodo_pago
                FROM facturacion.metodo_pago
                WHERE LOWER(nombre) = LOWER(@medio_pago);

                -- Si no existe, crearlo y capturar el id
                IF @id_metodo_pago IS NULL
                BEGIN
                    DECLARE @nuevo_id_metodo_pago INT;
                    -- Crear el metodo de pago
                    EXEC facturacion.CrearMetodoPago @nombre = @medio_pago;
                    -- Recupera el id recién creado
                    SELECT @nuevo_id_metodo_pago = id_metodo_pago FROM facturacion.metodo_pago WHERE LOWER(nombre) = LOWER(@medio_pago);
                    SET @id_metodo_pago = @nuevo_id_metodo_pago;
                END

                -- Insertar la factura (estado por defecto: 'Pendiente')
                EXEC facturacion.CrearFactura
                    @id_persona = @id_persona,
                    @id_metodo_pago = @id_metodo_pago,
                    @estado_pago = 'Pendiente',
                    @monto_a_pagar = @valor,
                    @detalle = NULL,
                    @fecha_emision = @fecha,
                    @id_pago = @id_pago;

                SET @ContadorExitosos = @ContadorExitosos + 1;
            END TRY
            BEGIN CATCH
                SET @ContadorErrores = @ContadorErrores + 1;
                SET @ErrorOcurrido = 1;
                SET @MensajeError = @MensajeError + 
                    'Error en socio "' + ISNULL(@numero_socio, 'NULL') + '": ' + 
                    ERROR_MESSAGE() + CHAR(13) + CHAR(10);
            END CATCH

            SIGUIENTE:
            FETCH NEXT FROM cur INTO @id_pago, @fecha, @numero_socio, @valor, @medio_pago;
        END

        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;

        -- Generar reporte final
        BEGIN
            SELECT 'Exito' AS Resultado, 
                   'Facturas importadas: ' + CAST(@ContadorExitosos AS VARCHAR) + '. Errores: ' + CAST(@ContadorErrores AS VARCHAR) + CHAR(13) + CHAR(10) + @MensajeError AS Mensaje;
            RETURN;
        END
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END

        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Presentismo a Actividades - FUNCIONANDO
CREATE OR ALTER PROCEDURE actividades.ImportarPresentismoActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    SET LANGUAGE Spanish; -- Por las dudas (Voy a estar manejando mucho busqueda por palabras)

    BEGIN TRY
        -- Tabla temporal para importar los datos
        CREATE TABLE #TempDatos (
            [Nro de Socio] VARCHAR(20),
            [Actividad] NVARCHAR(100),
            [fecha de asistencia] DATE,
            [Asistencia] VARCHAR(15),
            [Profesor] NVARCHAR(100)
        );

        -- Arma el SQL para importar los datos
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Nro de Socio], 
                [Actividad], 
                [fecha de asistencia], 
                [Asistencia], 
                [Profesor]
            )
            SELECT 
                LTRIM(RTRIM(CAST([Nro de Socio] AS VARCHAR(20)))),
                LTRIM(RTRIM(CAST([Actividad] AS NVARCHAR(100)))),
                CAST([fecha de asistencia] AS DATE),
                LTRIM(RTRIM(CAST([Asistencia] AS VARCHAR(15)))),
                LTRIM(RTRIM(CAST([Profesor] AS NVARCHAR(100))))
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [presentismo_actividades$]'')';


            EXEC sp_executesql @SQL; -- Ejecuta la sentencia

            -- Variables para recorrer
            DECLARE @nroSocio VARCHAR(20), 
                    @actividad NVARCHAR(100), 
                    @fecha DATE, 
                    @asistencia VARCHAR(15), 
                    @profesor NVARCHAR(100);
            -- Variables auxiliares
            DECLARE @id_socio INT, 
                    @id_actividad INT, 
                    @id_usuario INT, 
                    @id_clase INT, 
                    @id_persona INT,
                    @id_categoria INT,
                    @dia VARCHAR(9),

                    @horario_clase TIME;

            -- Cursor para recorrer los datos
            DECLARE cur CURSOR FOR
            SELECT [Nro de Socio], 
                   [Actividad], 
                   [fecha de asistencia], 
                   [Asistencia], 
                   [Profesor]
            FROM #TempDatos

            OPEN cur; -- Abre el cursor
            FETCH NEXT FROM cur INTO @nroSocio, @actividad, @fecha, @asistencia, @profesor; -- Carga los datos dentro de las variables
            
            -- Hasta que no termine, carga los datos.
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Normaliza numero de socio
                SET @nroSocio = REPLACE(LTRIM(RTRIM(@nroSocio)), 'SN-', '');
                
                -- Buscar id de socio en tabla de socios
                SELECT @id_socio = id_socio
                FROM usuarios.socio 
                WHERE LTRIM(RTRIM(numero_socio)) = @nroSocio;
                IF @id_socio IS NULL
                BEGIN
                    SELECT 'Error' as Estado, 'El usuario no existe' as Mensaje 
                    GOTO SIGUIENTE_REGISTRO
                END

                -- Busca id de actividad en tabla de actividad
                SELECT TOP 1 @id_actividad = id_actividad
                FROM actividades.actividad
                WHERE DIFFERENCE(nombre, @actividad) >= 3; -- Busco por sonido fonetico porque el excel tiene cosas mal escritas c:
                IF @id_actividad IS NULL
                BEGIN
                    SELECT 'Error' as Estado, 'La actividad no existe' as Mensaje 
                    GOTO SIGUIENTE_REGISTRO
                END

                -- Procesar nombre y apellido del profesor
                DECLARE @profesor_nombre VARCHAR(100), @profesor_apellido VARCHAR(100), @profesor_username VARCHAR(100);
                -- Quitar espacios al principio y final
                SET @profesor = LTRIM(RTRIM(@profesor));
                -- Buscar la posición del último espacio
                DECLARE @posUltimoEspacio INT = LEN(@profesor) - CHARINDEX(' ', REVERSE(@profesor)) + 1;

                IF CHARINDEX(' ', @profesor) > 0
                BEGIN
                    SET @profesor_nombre = LEFT(@profesor, @posUltimoEspacio - 1);
                    SET @profesor_apellido = SUBSTRING(@profesor, @posUltimoEspacio + 1, LEN(@profesor) - @posUltimoEspacio);
                END
                ELSE
                BEGIN
                    SET @profesor_nombre = @profesor;
                    SET @profesor_apellido = '';
                END
                -- Generar username: nombre.apellido en minúsculas, sin espacios
                SET @profesor_username = LOWER(REPLACE(@profesor_nombre, ' ', '')) + '.' + LOWER(REPLACE(@profesor_apellido, ' ', ''));
                
                -- Busca el id de la persona (profesor)
                SELECT TOP 1 @id_persona = id_persona
                FROM usuarios.persona
                WHERE DIFFERENCE(nombre + ' ' + apellido,@profesor) >= 3;
                
                -- Si la persona no existe, crearla
                IF @id_persona IS NULL
                BEGIN
                    EXEC usuarios.CrearPersona
                        @dni = NULL,
                        @nombre = @profesor_nombre,
                        @apellido = @profesor_apellido,
                        @email = NULL,
                        @fecha_nac = NULL,
                        @telefono = NULL,
                        @id_persona = @id_persona OUTPUT;
                END

                -- Busca el id del usuario (profesor)
                SELECT TOP 1 @id_usuario = id_usuario
                FROM usuarios.usuario
                WHERE id_persona = @id_persona;
                
                -- Si el usuario no existe, crearlo
                IF @id_usuario IS NULL
                BEGIN
                    EXEC usuarios.CrearUsuario
                        @id_persona = @id_persona,
                        @dni = NULL,
                        @nombre = @profesor_nombre,
                        @apellido = @profesor_apellido,
                        @email = NULL,
                        @fecha_nac = NULL,
                        @telefono = NULL,
                        @username = @profesor_username,
                        @password_hash = 'default_hash';
                    -- Buscar el id_usuario recién creado
                    SELECT TOP 1 @id_usuario = id_usuario
                    FROM usuarios.usuario
                    WHERE id_persona = @id_persona;
                END
                IF @id_usuario IS NULL
                BEGIN
                    SELECT 'Error' as Estado, 'No se pudo crear el usuario para el profesor' as Mensaje 
                    GOTO SIGUIENTE_REGISTRO
                END

                -- Busca si existe la clase
                SET @dia = DATENAME(WEEKDAY, @fecha); -- Convierte la fecha a un dia

                SELECT TOP 1 @id_clase = id_clase
                FROM actividades.clase
                WHERE id_actividad = @id_actividad AND dia = @dia;

                -- Si la clase no existe, hay que crearla
                IF @id_clase IS NULL
                BEGIN
                    -- Busca la categoria
                    SELECT @id_categoria = id_categoria
                    FROM usuarios.socio
                    WHERE id_socio = @id_socio

                    -- Crea la clase
                    EXEC actividades.CrearClase
                        @id_actividad = @id_actividad,
                        @id_categoria = @id_categoria,
                        @dia = @dia,
                        @horario = '07:00', -- El excel no me da el horario. Realmente habria que rebotarlos todos
                        @id_usuario = @id_usuario;

                    -- Busca de nuevo
                    SELECT TOP 1 @id_clase = id_clase
                    FROM actividades.clase
                    WHERE id_actividad = @id_actividad AND dia = @dia;
                END

                -- Coloca los datos en sus respectivas tabla
                IF NOT EXISTS (
                    SELECT 1 FROM actividades.actividad_socio
                    WHERE id_socio = @id_socio AND id_actividad = @id_actividad
                )
                BEGIN
                    INSERT INTO actividades.actividad_socio(id_socio, id_actividad, [presentismo], [fecha])
                    VALUES (@id_socio, @id_actividad,@asistencia, @fecha);
                END

                SIGUIENTE_REGISTRO:
                FETCH NEXT FROM cur INTO @nroSocio, @actividad, @fecha, @asistencia, @profesor;
            END
            
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT;
        SELECT 
            @ErrMsg = ERROR_MESSAGE(), 
            @ErrSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH
END
GO

-- IMPORTACION Y PRUEBAS
EXEC actividades.ImportarCategorias 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx' --'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
select * from actividades.categoria
GO

EXEC usuarios.ImportarSocios'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx' -- 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
select s.*, os.descripcion AS obra_social_descripcion, os.nro_telefono AS obra_social_telefono
FROM usuarios.socio s
LEFT JOIN usuarios.obra_social os ON s.id_obra_social = os.id_obra_social
GO

EXEC actividades.ImportarActividades 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx' -- 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
SELECT * FROM actividades.actividad
GO

EXEC facturacion.ImportarClima 
    @RutaBase = 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx', --'C:\Users\tomas\Desktop\proyecto-BDA\docs\',
    @Anio = 2024;
select * from facturacion.clima 
GO

EXEC actividades.ImportarCostosPileta
     @RutaArchivo = 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx',
     @id_pileta = 1;
     SELECT * FROM actividades.costo
GO

EXEC usuarios.importarGrupoFamiliar'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx' -- 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
SELECT * FROM usuarios.grupo_familiar
GO


EXEC facturacion.ImportarFacturas 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx' --'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
SELECT * FROM facturacion.factura;
GO

EXEC actividades.ImportarPresentismoActividades 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx' -- 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
SELECT * FROM actividades.actividad_socio
SELECT * FROM usuarios.usuario
GO