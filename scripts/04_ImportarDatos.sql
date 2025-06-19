USE Com5600G01;
GO

-- CONFIGURACIONES NECESARIAS PARA PODER LA IMPORTACION
EXEC sp_configure 'Show Advanced Options', 1
GO
RECONFIGURE
GO

EXEC sp_configure 'Ad Hoc Distributed Queries', 1
GO
RECONFIGURE
GO

EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
GO
RECONFIGURE
GO

EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
GO
RECONFIGURE
GO


-- Importar Categorias - FUNCIONANDO
CREATE OR ALTER PROCEDURE ImportarCategorias
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorOcurrido BIT = 0;
    DECLARE @MensajeError NVARCHAR(MAX) = '';
    
    BEGIN TRY
        -- 1. Crear tabla temporal para los datos
        CREATE TABLE #TempDatos (
            [Categoria socio] VARCHAR(50),
            [Valor cuota] DECIMAL(10, 2),
            [Vigente hasta] DATE
        );
        
        -- 2. Leer solo las filas B10:D13 del Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            INSERT INTO #TempDatos ([Categoria socio], [Valor cuota], [Vigente hasta])
            SELECT [Categoria socio], [Valor cuota], [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B10:D13]'')';
        
        EXEC sp_executesql @SQL;
        
        -- 3. Recorrer los datos e insertar en categoria
        DECLARE @nombre_categoria VARCHAR(50), @costo_membrecia DECIMAL(10,2), @vigencia DATE;
        DECLARE @ContadorExitosos INT = 0;
        DECLARE @ContadorErrores INT = 0;
        
        DECLARE cur CURSOR FOR
            SELECT [Categoria socio], [Valor cuota], [Vigente hasta] 
            FROM #TempDatos
            WHERE [Categoria socio] IS NOT NULL;
        
        OPEN cur;
        FETCH NEXT FROM cur INTO @nombre_categoria, @costo_membrecia, @vigencia;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                EXEC manejo_actividades.CrearCategoria
                    @nombre_categoria = @nombre_categoria,
                    @costo_membrecia = @costo_membrecia,
                    @vigencia = @vigencia;
                
                SET @ContadorExitosos = @ContadorExitosos + 1;
            END TRY
            BEGIN CATCH
                SET @ContadorErrores = @ContadorErrores + 1;
                SET @ErrorOcurrido = 1;
                
                -- Concatenar errores para reporte final
                SET @MensajeError = @MensajeError + 
                    'Error en categoria "' + ISNULL(@nombre_categoria, 'NULL') + '": ' + 
                    ERROR_MESSAGE() + CHAR(13) + CHAR(10);
            END CATCH
            
            FETCH NEXT FROM cur INTO @nombre_categoria, @costo_membrecia, @vigencia;
        END
        
        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;
        
        -- Generar reporte final
        IF @ErrorOcurrido = 0
        BEGIN
            SELECT 'Exito' AS Resultado, 
                   'Todas las categorias importadas correctamente (' + 
                   CAST(@ContadorExitosos AS VARCHAR(10)) + ' registros)' AS Mensaje;
            RETURN 0;
        END
        ELSE
        BEGIN
            SELECT 'Parcial' AS Resultado, 
                   'Proceso completado con errores. Exitosos: ' + 
                   CAST(@ContadorExitosos AS VARCHAR(10)) + 
                   ', Errores: ' + CAST(@ContadorErrores AS VARCHAR(10)) + 
                   CHAR(13) + CHAR(10) + @MensajeError AS Mensaje;
            RETURN 1;
        END
        
    END TRY
    BEGIN CATCH
        -- Limpieza en caso de error general
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
EXEC ImportarCategorias 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO
select * from manejo_actividades.categoria

-- Importar Actividades -- FUNCIONADO
CREATE OR ALTER PROCEDURE ImportarActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorOcurrido BIT = 0;
    DECLARE @MensajeError NVARCHAR(MAX) = '';
    
    BEGIN TRY
        -- 1. Crear tabla temporal para los datos
        CREATE TABLE #TempDatos (
            [Actividad] VARCHAR(50),
            [Valor por mes] DECIMAL(10, 2),
            [Vigente hasta] DATE
        );
        
        -- 2. Leer solo las filas B2:D8 del Excel
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            INSERT INTO #TempDatos ([Actividad], [Valor por mes], [Vigente hasta])
            SELECT [Actividad], [Valor por mes], [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B2:D8]'')';
        
        EXEC sp_executesql @SQL;
        
        -- 3. Recorrer los datos e insertar en actividad
        DECLARE @nombre_actividad VARCHAR(50), @costo_actividad DECIMAL(10,2), @vigencia DATE;
        DECLARE @ContadorExitosos INT = 0;
        DECLARE @ContadorErrores INT = 0;
        
        DECLARE cur CURSOR FOR
            SELECT [Actividad], [Valor por mes], [Vigente hasta] 
            FROM #TempDatos
            WHERE [Actividad] IS NOT NULL;
        
        OPEN cur;
        FETCH NEXT FROM cur INTO @nombre_actividad, @costo_actividad, @vigencia;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                EXEC manejo_actividades.CrearActividad
                    @nombre_actividad = @nombre_actividad,
                    @costo_mensual = @costo_actividad,
                    @vigencia = @vigencia;
                
                SET @ContadorExitosos = @ContadorExitosos + 1;
            END TRY
            BEGIN CATCH
                SET @ContadorErrores = @ContadorErrores + 1;
                SET @ErrorOcurrido = 1;
                
                -- Concatenar errores para reporte final
                SET @MensajeError = @MensajeError + 
                    'Error en actividad "' + ISNULL(@nombre_actividad, 'NULL') + '": ' + 
                    ERROR_MESSAGE() + CHAR(13) + CHAR(10);
            END CATCH
            
            FETCH NEXT FROM cur INTO @nombre_actividad, @costo_actividad, @vigencia;
        END
        
        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;
        
        -- Generar reporte final
        IF @ErrorOcurrido = 0
        BEGIN
            SELECT 'Exito' AS Resultado, 
                   'Todas las actividades importadas correctamente (' + 
                   CAST(@ContadorExitosos AS VARCHAR(10)) + ' registros)' AS Mensaje;
            RETURN 0;
        END
        ELSE
        BEGIN
            SELECT 'Parcial' AS Resultado, 
                   'Proceso completado con errores. Exitosos: ' + 
                   CAST(@ContadorExitosos AS VARCHAR(10)) + 
                   ', Errores: ' + CAST(@ContadorErrores AS VARCHAR(10)) + 
                   CHAR(13) + CHAR(10) + @MensajeError AS Mensaje;
            RETURN 1;
        END
        
    END TRY
    BEGIN CATCH
        -- Limpieza en caso de error general
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
EXEC ImportarActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO
select * from manejo_actividades.actividad
GO

-- Version 2 
CREATE OR ALTER PROCEDURE ImportarResponsablesPago
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @id_persona INT;
        DECLARE @id_socio INT;

        CREATE TABLE #TempDatos (
            [Nro de Socio] VARCHAR(20),
            [Nombre] NVARCHAR(50),
            [ apellido] NVARCHAR(50),
            [ DNI] VARCHAR(20),
            [ email personal] VARCHAR(320),
            [ fecha de nacimiento] DATE,
            [ teléfono de contacto] VARCHAR(30),
            [ teléfono de contacto emergencia] VARCHAR(30),
            [ Nombre de la obra social o prepaga] NVARCHAR(100),
            [nro# de socio obra social/prepaga ] VARCHAR(50),
            [telefono obra social] VARCHAR(30)
        );

        CREATE TABLE #ErroresImportacion (
            DNI VARCHAR(20),
            NroSocio VARCHAR(20),
            MensajeError NVARCHAR(MAX)
        );

        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Nro de Socio], [Nombre], [ apellido], [ DNI], [ email personal],
                [ fecha de nacimiento], [ teléfono de contacto], [ teléfono de contacto emergencia],
                [ Nombre de la obra social o prepaga], [nro# de socio obra social/prepaga ], [telefono obra social]
            )
            SELECT *
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Responsables de Pago$]'')';
        EXEC sp_executesql @SQL;

        DECLARE @dni VARCHAR(20), @nombre NVARCHAR(100), @apellido NVARCHAR(100),
                @email VARCHAR(320), @fechaNac DATE, @telefono VARCHAR(50),
                @telefonoEmergencia VARCHAR(50), @obraSocial NVARCHAR(100),
                @nroSocioObra VARCHAR(50), @nroSocio VARCHAR(20);

        DECLARE cur CURSOR FOR 
        SELECT [Nro de Socio], [ DNI], [Nombre], [ apellido], [ email personal],
               [ fecha de nacimiento], [ teléfono de contacto], [ teléfono de contacto emergencia],
               [ Nombre de la obra social o prepaga], [nro# de socio obra social/prepaga ]
        FROM #TempDatos;

        OPEN cur;
        FETCH NEXT FROM cur INTO @nroSocio, @dni, @nombre, @apellido, @email, @fechaNac,
                                 @telefono, @telefonoEmergencia, @obraSocial, @nroSocioObra;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- LIMPIEZA DE CAMPOS
                SET @dni = LTRIM(RTRIM(@dni));
                SET @nombre = UPPER(LTRIM(RTRIM(@nombre)));
                SET @apellido = UPPER(LTRIM(RTRIM(@apellido)));
                SET @email = LOWER(REPLACE(LTRIM(RTRIM(@email)), ' ', ''));
                SET @telefono = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@telefono)), '-', ''), '/', ''), ' ', '');
                SET @telefonoEmergencia = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@telefonoEmergencia)), '-', ''), '/', ''), ' ', '');
                SET @obraSocial = LTRIM(RTRIM(@obraSocial));
                SET @nroSocioObra = LTRIM(RTRIM(@nroSocioObra));
                SET @nroSocio = LTRIM(RTRIM(@nroSocio));

                -- VALIDACIONES
                IF LEN(@dni) NOT BETWEEN 7 AND 8 OR ISNUMERIC(@dni) = 0
                BEGIN
                    INSERT INTO #ErroresImportacion VALUES (@dni, @nroSocio, 'DNI inválido.');
                    GOTO SIGUIENTE;
                END

                IF @email NOT LIKE '%_@%.__%' OR CHARINDEX(' ', @email) > 0
                BEGIN
                    INSERT INTO #ErroresImportacion VALUES (@dni, @nroSocio, 'Email inválido.');
                    GOTO SIGUIENTE;
                END

                IF @fechaNac IS NULL OR TRY_CAST(@fechaNac AS DATE) IS NULL
                    OR DATEDIFF(YEAR, @fechaNac, GETDATE()) NOT BETWEEN 0 AND 120
                BEGIN
                    INSERT INTO #ErroresImportacion VALUES (@dni, @nroSocio, 'Fecha de nacimiento inválida.');
                    GOTO SIGUIENTE;
                END

                -- CREAR PERSONA
                IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE dni = @dni)
                BEGIN
                    EXEC manejo_personas.CrearPersona 
                        @dni = @dni,
                        @nombre = @nombre,
                        @apellido = @apellido,
                        @email = @email,
                        @fecha_nac = @fechaNac,
                        @telefono = @telefono;

                    SELECT @id_persona = id_persona 
                    FROM manejo_personas.persona 
                    WHERE dni = @dni;
                END
                ELSE
                BEGIN
                    SELECT @id_persona = id_persona 
                    FROM manejo_personas.persona 
                    WHERE dni = @dni;
                END

                -- CREAR SOCIO
                IF NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona)
                BEGIN
                    EXEC manejo_personas.CrearSocio
                        @id_persona = @id_persona,
                        @nro_socio = @nroSocio,
                        @telefono_emergencia = @telefonoEmergencia,
                        @id_categoria = 3;
                END

                -- CREAR OBRA SOCIAL
                IF @obraSocial IS NOT NULL AND @obraSocial <> ''
                BEGIN
                    DECLARE @id_obra_social INT;
                    EXEC manejo_personas.CreacionObraSocial @nombre = @obraSocial;

                    SELECT @id_obra_social = id_obra_social 
                    FROM manejo_personas.obra_social 
                    WHERE descripcion = @obraSocial;

                    IF @id_obra_social IS NOT NULL
                    BEGIN
                        UPDATE manejo_personas.socio
                        SET id_obra_social = @id_obra_social,
                            obra_nro_socio = @nroSocioObra
                        WHERE id_persona = @id_persona;
                    END
                END

            END TRY
            BEGIN CATCH
                INSERT INTO #ErroresImportacion (DNI, NroSocio, MensajeError)
                VALUES (@dni, @nroSocio, ERROR_MESSAGE());
            END CATCH

            SIGUIENTE:
            FETCH NEXT FROM cur INTO @nroSocio, @dni, @nombre, @apellido, @email, @fechaNac,
                                         @telefono, @telefonoEmergencia, @obraSocial, @nroSocioObra;
        END

        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;

        IF EXISTS (SELECT 1 FROM #ErroresImportacion)
        BEGIN
            SELECT 'Parcial' AS Resultado, 'Algunos registros no se pudieron importar' AS Mensaje;
            SELECT * FROM #ErroresImportacion;
        END
        ELSE
        BEGIN
            SELECT 'Exito' AS Resultado, 'Datos importados correctamente' AS Mensaje;
        END

        DROP TABLE #ErroresImportacion;
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END

        IF OBJECT_ID('tempdb..#ErroresImportacion') IS NOT NULL
        BEGIN
            SELECT 'Error parcial' AS Resultado, 'Se detectaron errores durante la importación.' AS Mensaje;
            SELECT * FROM #ErroresImportacion;
            DROP TABLE #ErroresImportacion;
        END

        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               ERROR_MESSAGE() AS Mensaje,
               ERROR_LINE() AS Linea,
               ERROR_PROCEDURE() AS Procedimiento;
        RETURN -1;
    END CATCH
END
GO
EXEC ImportarResponsablesPago 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO
select * from manejo_personas.persona
GO