-- CREA LOS SPS PARA LA IMPORTACION DE DATOS

USE Com5600G01;
GO

-- CONFIGURACIONES NECESARIAS PARA PODER LA IMPORTACION
EXEC sp_configure 'Show Advanced Options', 1;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
EXEC sp_MSSet_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;
RECONFIGURE;
GO

-- Funcion aux para quitar acentos y pasar a mayus
CREATE OR ALTER FUNCTION dbo.NormalizarTexto(@texto NVARCHAR(200)) RETURNS NVARCHAR(200)
AS
BEGIN
    -- Reemplaza acentos y pasa a mayúsculas
    SET @texto = UPPER(@texto)
    SET @texto = REPLACE(@texto, 'Á', 'A')
    SET @texto = REPLACE(@texto, 'É', 'E')
    SET @texto = REPLACE(@texto, 'Í', 'I')
    SET @texto = REPLACE(@texto, 'Ó', 'O')
    SET @texto = REPLACE(@texto, 'Ú', 'U')
    SET @texto = REPLACE(@texto, 'Ü', 'U')
    SET @texto = REPLACE(@texto, 'Ñ', 'N')
    RETURN @texto
END
GO

-- Importar Categorias - FUNCIONANDO
CREATE OR ALTER PROCEDURE manejo_actividades.ImportarCategorias
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
                -- Antes de insertar, normalizar los campos de texto
                SET @nombre_categoria = dbo.NormalizarTexto(@nombre_categoria);
                SET @costo_membrecia = @costo_membrecia;
                SET @vigencia = @vigencia;
                
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

-- Importar Actividades -- FUNCIONADO
CREATE OR ALTER PROCEDURE manejo_actividades.ImportarActividades
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
            -- Antes de insertar, normalizar los campos de texto
            SET @nombre_actividad = dbo.NormalizarTexto(@nombre_actividad);
            SET @costo_actividad = @costo_actividad;
            SET @vigencia = @vigencia;
            
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

-- Importar Facturas
CREATE OR ALTER PROCEDURE pagos_y_facturas.ImportarFacturas
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorOcurrido BIT = 0;
    DECLARE @MensajeError NVARCHAR(MAX) = '';

    BEGIN TRY
        -- 1. Crear tabla temporal para los datos
        CREATE TABLE #TempDatos (
            [fecha] DATE,
            [Responsable de pago] VARCHAR(20),
            [Valor] DECIMAL(10,2),
            [Medio de pago] VARCHAR(50)
        );

        -- 2. Leer los datos desde la hoja "pago cuotas"
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            INSERT INTO #TempDatos ([fecha], [Responsable de pago], [Valor], [Medio de pago])
            SELECT [fecha], [Responsable de pago], [Valor], [Medio de pago]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [pago cuotas$B1:E10000]'')';
        EXEC sp_executesql @SQL;

        -- 3. Recorrer los datos e insertar en factura
        DECLARE @fecha DATE, @numero_socio VARCHAR(20), @valor DECIMAL(10,2), @medio_pago VARCHAR(50);
        DECLARE @id_persona INT, @id_metodo_pago INT;
        DECLARE @ContadorExitosos INT = 0;
        DECLARE @ContadorErrores INT = 0;

        DECLARE cur CURSOR FOR
            SELECT [fecha], [Responsable de pago], [Valor], [Medio de pago]
            FROM #TempDatos
            WHERE [Responsable de pago] IS NOT NULL;

        OPEN cur;
        FETCH NEXT FROM cur INTO @fecha, @numero_socio, @valor, @medio_pago;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- Antes de insertar, normalizar los campos de texto
                SET @numero_socio = dbo.NormalizarTexto(@numero_socio);
                SET @medio_pago = dbo.NormalizarTexto(@medio_pago);
                
                -- Buscar id_persona a partir del numero_socio
                SELECT @id_persona = s.id_persona
                FROM manejo_personas.socio s
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
                FROM pagos_y_facturas.metodo_pago
                WHERE LOWER(nombre) = LOWER(@medio_pago);

                IF @id_metodo_pago IS NULL
                BEGIN
                    SET @ContadorErrores = @ContadorErrores + 1;
                    SET @ErrorOcurrido = 1;
                    SET @MensajeError = @MensajeError + 
                        'No se encontró método de pago "' + ISNULL(@medio_pago, 'NULL') + '".' + CHAR(13) + CHAR(10);
                    GOTO SIGUIENTE;
                END

                -- Insertar la factura (estado por defecto: 'Pendiente')
                EXEC pagos_y_facturas.CreacionFactura
                    @estado_pago = 'Pendiente',
                    @monto_a_pagar = @valor,
                    @id_persona = @id_persona,
                    @id_metodo_pago = @id_metodo_pago;

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
            FETCH NEXT FROM cur INTO @fecha, @numero_socio, @valor, @medio_pago;
        END

        CLOSE cur;
        DEALLOCATE cur;
        DROP TABLE #TempDatos;

        -- Generar reporte final
        IF @ErrorOcurrido = 0
        BEGIN
            SELECT 'Exito' AS Resultado, 
                   'Todas las facturas importadas correctamente (' + 
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

-- Importar Socios - Funcionando Parcialmente (Se cargan mal los numeros de telefono. Posiblemente algo relacionado con el tipo de dato)
CREATE OR ALTER PROCEDURE manejo_personas.ImportarSocios
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
            [ teléfono de contacto] VARCHAR(50),
            [ teléfono de contacto emergencia] VARCHAR(50),
            [ Nombre de la obra social o prepaga] NVARCHAR(100),
            [nro# de socio obra social/prepaga ] VARCHAR(50),
            [telefono obra social] VARCHAR(50)
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
                -- Antes de insertar, normalizar los campos de texto
                SET @dni = REPLACE(REPLACE(LTRIM(RTRIM(@dni)), '.', ''), '-', '');
                SET @nombre = dbo.NormalizarTexto(@nombre);
                SET @apellido = dbo.NormalizarTexto(@apellido);
                SET @email = LOWER(REPLACE(LTRIM(RTRIM(@email)), ' ', ''));
                
                -- Corregir teléfonos de notación científica y limpiar
                IF @telefono IS NOT NULL AND CHARINDEX('E', @telefono) > 0
                BEGIN
                    SET @telefono = FORMAT(TRY_CAST(@telefono AS FLOAT), '0', 'en-US');
                END
                SET @telefono = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(@telefono, ''))), '-', ''), '/', ''), ' ', '');

                IF @telefonoEmergencia IS NOT NULL
                BEGIN
                    IF CHARINDEX('E', @telefonoEmergencia) > 0
                    BEGIN
                        SET @telefonoEmergencia = FORMAT(TRY_CAST(@telefonoEmergencia AS FLOAT), '0', 'en-US');
                    END
                    SET @telefonoEmergencia = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@telefonoEmergencia)), '-', ''), '/', ''), ' ', '');
                    IF @telefonoEmergencia = '' SET @telefonoEmergencia = NULL;
                END

                SET @obraSocial = dbo.NormalizarTexto(@obraSocial);
                SET @nroSocioObra = LTRIM(RTRIM(@nroSocioObra));
                SET @nroSocio = UPPER(LTRIM(RTRIM(@nroSocio)));

                -- VALIDACIONES
                IF LEN(@dni) NOT BETWEEN 7 AND 9 OR ISNUMERIC(@dni) = 0
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
                END
                
                SELECT @id_persona = id_persona FROM manejo_personas.persona WHERE dni = @dni;

                -- CREAR SOCIO
                IF @id_persona IS NOT NULL AND NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona)
                BEGIN
                    -- Determinar la categoría por edad
                    DECLARE @edad INT = DATEDIFF(YEAR, @fechaNac, GETDATE());
                    DECLARE @id_categoria INT;

                    IF @edad <= 12
                        SELECT @id_categoria = id_categoria FROM manejo_actividades.categoria WHERE dbo.NormalizarTexto(nombre_categoria) LIKE 'MENOR%';
                    ELSE IF @edad <= 17
                        SELECT @id_categoria = id_categoria FROM manejo_actividades.categoria WHERE dbo.NormalizarTexto(nombre_categoria) LIKE 'CADETE%';
                    ELSE
                        SELECT @id_categoria = id_categoria FROM manejo_actividades.categoria WHERE dbo.NormalizarTexto(nombre_categoria) LIKE 'MAYOR%';

                    IF @id_categoria IS NULL
                    BEGIN
                        INSERT INTO #ErroresImportacion VALUES (@dni, @nroSocio, 'No se pudo determinar una categoría válida para la edad de la persona.');
                        GOTO SIGUIENTE;
                    END

                    EXEC manejo_personas.CrearSocio
                        @id_persona = @id_persona,
                        @nro_socio = @nroSocio,
                        @telefono_emergencia = @telefonoEmergencia,
                        @id_categoria = @id_categoria;
                END

                -- CREAR OBRA SOCIAL
                IF @obraSocial IS NOT NULL AND @obraSocial <> ''
                BEGIN
                    DECLARE @id_obra_social INT;
                    -- Eliminar espacios en blanco antes de usar la obra social
                    SET @obraSocial = LTRIM(RTRIM(@obraSocial));
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

-- Importar Presentismo de Actividades desde Excel - FUNCIONANDO
CREATE OR ALTER PROCEDURE manejo_actividades.ImportarPresentismoActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Manejo de errores mejorado
    BEGIN TRY
        -- Tablas temporales
        CREATE TABLE #ErroresImportacion (
            NroSocio VARCHAR(20),
            Actividad NVARCHAR(100),
            Fecha DATE,
            Profesor NVARCHAR(100),
            MensajeError NVARCHAR(MAX)
        );

        CREATE TABLE #TempDatos (
            [Nro de Socio] VARCHAR(20),
            [Actividad] NVARCHAR(100),
            [fecha de asistencia] DATE,
            [Asistencia] VARCHAR(15),
            [Profesor] NVARCHAR(100)
        );

        -- Importar datos desde Excel con validación de archivo
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = N'
            INSERT INTO #TempDatos ([Nro de Socio], [Actividad], [fecha de asistencia], [Asistencia], [Profesor])
            SELECT 
                LTRIM(RTRIM(CAST([Nro de Socio] AS VARCHAR(20)))),
                LTRIM(RTRIM(CAST([Actividad] AS NVARCHAR(100)))),
                CAST([fecha de asistencia] AS DATE),
                LTRIM(RTRIM(CAST([Asistencia] AS VARCHAR(15)))),
                LTRIM(RTRIM(CAST([Profesor] AS NVARCHAR(100))))
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [presentismo_actividades$A1:E10000]'')
            WHERE [Nro de Socio] IS NOT NULL 
              AND [Actividad] IS NOT NULL 
              AND [fecha de asistencia] IS NOT NULL';
        
        EXEC sp_executesql @SQL;

        -- Variables de trabajo
        DECLARE @nroSocio VARCHAR(20), @actividad NVARCHAR(100), @fecha DATE, 
                @asistencia VARCHAR(15), @profesor NVARCHAR(100);
        DECLARE @id_socio INT, @id_actividad INT, @id_usuario INT, @estado BIT, 
                @id_clase INT, @id_categoria INT;
        DECLARE @dia VARCHAR(9) = 'LUNES', @horario TIME = '08:00:00';
        DECLARE @registrosProcesados INT = 0, @registrosExitosos INT = 0;

        -- Cursor para procesar datos
        DECLARE cur CURSOR FOR
            SELECT [Nro de Socio], [Actividad], [fecha de asistencia], [Asistencia], [Profesor]
            FROM #TempDatos
            WHERE [Nro de Socio] IS NOT NULL;

        OPEN cur;
        FETCH NEXT FROM cur INTO @nroSocio, @actividad, @fecha, @asistencia, @profesor;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @registrosProcesados = @registrosProcesados + 1;
            
            -- Limpiar variables para cada iteración
            SET @id_socio = NULL;
            SET @id_actividad = NULL;
            SET @id_usuario = NULL;
            SET @id_clase = NULL;
            SET @id_categoria = NULL;

            -- Antes de buscar, normalizar los campos de texto
            SET @nroSocio = dbo.NormalizarTexto(@nroSocio);
            SET @actividad = dbo.NormalizarTexto(@actividad);
            SET @profesor = dbo.NormalizarTexto(@profesor);
            
            -- Buscar socio
            SELECT @id_socio = id_socio, @id_categoria = id_categoria 
            FROM manejo_personas.socio 
            WHERE numero_socio = @nroSocio;

            IF @id_socio IS NULL
            BEGIN
                INSERT INTO #ErroresImportacion VALUES (@nroSocio, @actividad, @fecha, @profesor, 'Socio no encontrado');
                GOTO SIGUIENTE_REGISTRO;
            END

            -- Buscar actividad (ya no crear si no existe)
            SELECT @id_actividad = id_actividad
            FROM manejo_actividades.actividad
            WHERE DIFFERENCE(dbo.NormalizarTexto(nombre_actividad), dbo.NormalizarTexto(@actividad)) >= 3;

            IF @id_actividad IS NULL
            BEGIN
                INSERT INTO #ErroresImportacion VALUES (@nroSocio, @actividad, @fecha, @profesor, 'Actividad no encontrada');
                GOTO SIGUIENTE_REGISTRO;
            END

            -- Buscar profesor (mejorado el parsing del nombre)
            DECLARE @nombre_prof NVARCHAR(50), @apellido_prof NVARCHAR(50);
            DECLARE @posicion_espacio INT = CHARINDEX(' ', @profesor);
            
            IF @posicion_espacio > 0
            BEGIN
                SET @nombre_prof = LEFT(@profesor, @posicion_espacio - 1);
                SET @apellido_prof = LTRIM(SUBSTRING(@profesor, @posicion_espacio + 1, LEN(@profesor)));
            END
            ELSE
            BEGIN
                SET @nombre_prof = @profesor;
                SET @apellido_prof = '';
            END

            SELECT @id_usuario = u.id_usuario
            FROM manejo_personas.usuario u
            INNER JOIN manejo_personas.persona p ON u.id_persona = p.id_persona
            WHERE p.nombre LIKE @nombre_prof + '%'
              AND (@apellido_prof = '' OR p.apellido LIKE @apellido_prof + '%');

            IF @id_usuario IS NULL
            BEGIN
                INSERT INTO #ErroresImportacion VALUES (@nroSocio, @actividad, @fecha, @profesor, 'Profesor no encontrado');
                GOTO SIGUIENTE_REGISTRO;
            END

            -- Buscar o crear clase
            SELECT @id_clase = id_clase
            FROM manejo_actividades.clase
            WHERE id_actividad = @id_actividad 
              AND id_categoria = @id_categoria 
              AND id_usuario = @id_usuario;

            IF @id_clase IS NULL
            BEGIN
                BEGIN TRY
                    EXEC manejo_actividades.CrearClase
                        @id_actividad = @id_actividad,
                        @id_categoria = @id_categoria,
                        @dia = @dia,
                        @horario = @horario,
                        @id_usuario = @id_usuario;

                    -- Obtener el ID de la clase recién creada
                    SELECT @id_clase = id_clase
                    FROM manejo_actividades.clase
                    WHERE id_actividad = @id_actividad 
                      AND id_categoria = @id_categoria 
                      AND id_usuario = @id_usuario 
                      AND dia = @dia 
                      AND horario = @horario;
                END TRY
                BEGIN CATCH
                    INSERT INTO #ErroresImportacion VALUES (@nroSocio, @actividad, @fecha, @profesor, 
                        'Error al crear clase: ' + ERROR_MESSAGE());
                    GOTO SIGUIENTE_REGISTRO;
                END CATCH

                IF @id_clase IS NULL
                BEGIN
                    INSERT INTO #ErroresImportacion VALUES (@nroSocio, @actividad, @fecha, @profesor, 'No se pudo crear la clase');
                    GOTO SIGUIENTE_REGISTRO;
                END
            END

            -- Mapear estado de asistencia (mejorado)
            SET @estado = CASE 
                WHEN UPPER(LTRIM(RTRIM(@asistencia))) IN ('PRESENTE', 'P', 'SI', 'S', '1') THEN 1
                WHEN UPPER(LTRIM(RTRIM(@asistencia))) LIKE 'J%' THEN 1  -- Para "Justificada" u otras variantes
                ELSE 0
            END;

            -- Insertar o actualizar presentismo
            BEGIN TRY
                IF NOT EXISTS (
                    SELECT 1 FROM manejo_personas.socio_actividad
                    WHERE id_socio = @id_socio 
                      AND id_actividad = @id_actividad 
                      AND fecha_inicio = @fecha
                )
                BEGIN
                    INSERT INTO manejo_personas.socio_actividad (id_socio, id_actividad, fecha_inicio, estado)
                    VALUES (@id_socio, @id_actividad, @fecha, @estado);
                END
                ELSE
                BEGIN
                    UPDATE manejo_personas.socio_actividad
                    SET estado = @estado
                    WHERE id_socio = @id_socio 
                      AND id_actividad = @id_actividad 
                      AND fecha_inicio = @fecha;
                END
                
                SET @registrosExitosos = @registrosExitosos + 1;
            END TRY
            BEGIN CATCH
                INSERT INTO #ErroresImportacion VALUES (@nroSocio, @actividad, @fecha, @profesor, 
                    'Error al insertar/actualizar: ' + ERROR_MESSAGE());
            END CATCH

            SIGUIENTE_REGISTRO:
            FETCH NEXT FROM cur INTO @nroSocio, @actividad, @fecha, @asistencia, @profesor;
        END

        CLOSE cur;
        DEALLOCATE cur;
        
        -- Limpiar tabla temporal
        DROP TABLE #TempDatos;

        -- Retornar resultados
        DECLARE @cantidadErrores INT = (SELECT COUNT(*) FROM #ErroresImportacion);
        
        IF @cantidadErrores > 0
        BEGIN
            SELECT 'Parcial' AS Resultado, 
                   'Se procesaron ' + CAST(@registrosProcesados AS VARCHAR) + ' registros. ' +
                   'Exitosos: ' + CAST(@registrosExitosos AS VARCHAR) + '. ' +
                   'Errores: ' + CAST(@cantidadErrores AS VARCHAR) AS Mensaje;
            SELECT * FROM #ErroresImportacion ORDER BY NroSocio, Fecha;
        END
        ELSE
        BEGIN
            SELECT 'Exito' AS Resultado, 
                   'Se importaron correctamente ' + CAST(@registrosExitosos AS VARCHAR) + ' registros de presentismo' AS Mensaje;
        END

        DROP TABLE #ErroresImportacion;
        
    END TRY
    BEGIN CATCH
        -- Manejo de errores globales
        IF CURSOR_STATUS('global', 'cur') >= 0
        BEGIN
            CLOSE cur;
            DEALLOCATE cur;
        END
        
        -- Limpiar tablas temporales si existen
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL DROP TABLE #TempDatos;
        IF OBJECT_ID('tempdb..#ErroresImportacion') IS NOT NULL DROP TABLE #ErroresImportacion;
        
        SELECT 'Error' AS Resultado, 
               'Error crítico en la importación: ' + ERROR_MESSAGE() AS Mensaje;
        
        -- Re-lanzar el error para debugging si es necesario
        -- THROW;
    END CATCH
    
    RETURN 0;
END
GO


EXEC manejo_actividades.ImportarCategorias 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

EXEC manejo_personas.ImportarSocios 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

EXEC pagos_y_facturas.ImportarFacturas 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

EXEC manejo_actividades.ImportarActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO

-- HAY QUE EJECUTAR LO QUE ESTA EN GENERAR DATOS PARA EJECUTAR EL SIGUIENTE

EXEC manejo_actividades.ImportarPresentismoActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
GO