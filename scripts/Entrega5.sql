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

-- SPS
GO

-- Importar Categorias - FUNCIONANDO (ALTA Y ACTUALIZACION)
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
    
-- Importar Socios - CASI SEGURO QUE FUNCIONANDO (Falta chequear lo que tiene que ver con la obra social)
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

        SELECT * FROM #TempDatos
        RETURN

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
                -- Antes de insertar, normalizar los campos de texto
                SET @nroSocio = REPLACE(@nroSocio, 'SN-', '');
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


-- Importar Grupo Familiar 
CREATE OR ALTER PROCEDURE usuarios.ImportarGrupoFamiliares
    @RutaArchivo VARCHAR(260)
AS
BEGIN
    -- Evita que SQL mande mensajes por insercion
    SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX);

    -- Intento prueba importacion
    BEGIN TRY
        CREATE TABLE #TempDatos (
            [Nro de Soci] VARCHAR(7),
            [Nro de Socio RP] VARCHAR(7),
            [Nombre] VARCHAR(50),
            [Apellido] VARCHAR(50),
            [DNI] VARCHAR(9),
            [email personal] VARCHAR(320),
            [fecha de nacimiento] DATE,
            [télefono de contacto] VARCHAR(30),
            [teléfono de contacto emergencia] VARCHAR(30),
            [Nombre de la obra social o prepaga] VARCHAR(50),
            [obra_social_socio] VARCHAR(20),
            [teléfono de contacto de emergencia] VARCHAR(30)
        );

        -- Arma la consulta para la ruta del archivo
        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Nro de Socio],
                [Nro de socio RP], 
                [Nombre], 
                [apellido], 
                [DNI], 
                [email personal],
                [fecha de nacimiento], 
                [teléfono de contacto], 
                [teléfono de contacto emergencia],
                [Nombre de la obra social o prepaga], 
                [nro. de socio obra social/prepaga ], 
                [teléfono de contacto de emergencia]
            )
            SELECT *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Grupo Familiar$]'')';

        EXEC sp_executesql @SQL; -- Ejecuta la consulta

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END


        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;


        SELECT 'Error' AS Resultado
        RETURN -1;
    END CATCH
END
GO


-- Importar Actividades

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



-- Importar Costos de Pileta (revisar, parece funcionar.)

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

-- Importar Clima desde CSV usando facturacion.RegistrarClima
CREATE OR ALTER PROCEDURE facturacion.ImportarClima
    @RutaBase NVARCHAR(300) = 'C:\datos\clima\',  -- Ruta base donde están los archivos
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Construir la ruta del archivo dinámicamente
        DECLARE @RutaArchivo NVARCHAR(400);
        SET @RutaArchivo = @RutaBase + 'open-meteo-buenosaires_' + CAST(@Anio AS NVARCHAR(4)) + '.csv';
        
        -- Verificar que el año sea válido
        IF @Anio < 1900 OR @Anio > YEAR(GETDATE()) + 1
        BEGIN
            SELECT 'Error' AS Resultado, 'Año inválido' AS Mensaje;
            RETURN -1;
        END
        
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
                FIRSTROW = 3, -- Salta los encabezados
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                TABLOCK
            );';
        
        EXEC sp_executesql @SQL;
        
        -- Variables para el cursor
        DECLARE @fechaHora SMALLDATETIME, @lluvia DECIMAL(5,2), @hora VARCHAR(20), @rain VARCHAR(20);
        
        DECLARE cur CURSOR FOR
            SELECT [time], [rain_mm]
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


-- IMPORTACION Y PRUEBAS

EXEC actividades.ImportarCategorias 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
select * from actividades.categoria
GO



EXEC usuarios.ImportarSocios 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
select s.*, os.descripcion AS obra_social_descripcion, os.nro_telefono AS obra_social_telefono
FROM usuarios.socio s
LEFT JOIN usuarios.obra_social os ON s.id_obra_social = os.id_obra_social
GO


EXEC pagos_y_facturas.ImportarFacturas 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

EXEC actividades.ImportarActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

-- HAY QUE EJECUTAR LO QUE ESTA EN GENERAR DATOS PARA EJECUTAR EL SIGUIENTE

EXEC actividades.ImportarPresentismoActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

EXEC manejo_personas.ImportarGrupoFamiliar 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

EXEC facturacion.ImportarClima 
    @RutaBase = N'C:\Users\tomas\Desktop\proyecto-BDA\docs\',
    @Anio = 2025;
    
select * from facturacion.clima 
GO
