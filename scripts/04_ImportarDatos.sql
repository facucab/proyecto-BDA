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

-- NOTA: Aca faltaria el SP de traer la hoja de tarifas, pero necesito estos exec para probar el otro que estoy haciendo
EXEC manejo_actividades.CrearCategoria 
    @nombre_categoria = 'Menor', 
    @costo_membrecia = 10000.00, 
    @edad_maxima = 12;

EXEC manejo_actividades.CrearCategoria 
    @nombre_categoria = 'Cadete', 
    @costo_membrecia = 15000.00, 
    @edad_maxima = 17;

EXEC manejo_actividades.CrearCategoria 
    @nombre_categoria = 'Mayor', 
    @costo_membrecia = 25000.00, 
    @edad_maxima = 50;


EXEC ImportarResponsablesPago 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
select * from manejo_personas.socio
select * from manejo_personas.persona



-- Version actual insertando directamente
CREATE OR ALTER PROCEDURE ImportarResponsablesPago
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- DECLARATIVAS
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @id_persona INT;
        DECLARE @id_socio INT;

        -- Tabla temporal de datos
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

        -- Tabla temporal de errores
        CREATE TABLE #ErroresImportacion (
            DNI VARCHAR(20),
            NroSocio VARCHAR(20),
            MensajeError NVARCHAR(MAX)
        );

        -- Leer datos desde Excel
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

        -- Variables para cursor
        DECLARE @dni VARCHAR(8), @nombre NVARCHAR(50), @apellido NVARCHAR(50),
                @email VARCHAR(320), @fechaNac DATE, @telefono VARCHAR(15),
                @telefonoEmergencia VARCHAR(15), @obraSocial VARCHAR(100),
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

                IF NOT EXISTS (SELECT 1 FROM manejo_personas.socio WHERE id_persona = @id_persona)
                BEGIN
                    EXEC manejo_personas.CrearSocio
                        @id_persona = @id_persona,
                        @nro_socio = @nroSocio,
                        @telefono_emergencia = @telefonoEmergencia,
                        @id_categoria = 3;
                END

                -- Obra social
                IF @obraSocial IS NOT NULL AND TRIM(@obraSocial) <> ''
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


-- VERSION VIEJA CON SPS (No anda)
CREATE OR ALTER PROCEDURE ImportarResponsablesPago
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;
        -- BLOQUE DECLARATIVO
        DECLARE @SQL NVARCHAR(MAX); -- Aca se almacena el SQL dinamico
        DECLARE @id_persona INT; -- Para almacenar el ID de la persona creada
        DECLARE @id_socio INT; -- Para almacenar el ID del socio creado

        -- Crear tabla temporal para almacenar los datos del Excel
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

        -- BLOQUE PROCESO
        -- SQL dinamico para leer el archivo Excel
        SET @SQL = N'INSERT INTO #TempDatos (
                        [Nro de Socio], [Nombre], [ apellido], [ DNI], [ email personal],
                        [ fecha de nacimiento], [ teléfono de contacto], [ teléfono de contacto emergencia],
                        [ Nombre de la obra social o prepaga], [nro# de socio obra social/prepaga ], [telefono obra social]
                    )
                    SELECT *
                    FROM OPENROWSET(
                        ''Microsoft.ACE.OLEDB.12.0'',
                        ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                        ''SELECT * FROM [Responsables de Pago$]'')';

        -- Carga la tabla temporal con los registros que vienen del EXCEL
        EXEC sp_executesql @SQL;

        -- Crea variables para procesar registros
        DECLARE @dni VARCHAR(8), 
                @nombre NVARCHAR(50), 
                @apellido NVARCHAR(50),
                @email VARCHAR(320), 
                @fechaNac DATE, 
                @telefono VARCHAR(15),
                @telefonoEmergencia VARCHAR(15),
                @obraSocial VARCHAR(50), 
                @nroSocioObra VARCHAR(50),
                @nroSocio VARCHAR(20);

        -- Declaracion cursor
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
               [nro# de socio obra social/prepaga ]
        FROM #TempDatos;

        -- Abre el cursor y lo usa para cargar las variables
        OPEN cur;
        FETCH NEXT FROM cur INTO @nroSocio, @dni, @nombre, @apellido, @email, @fechaNac,
                                 @telefono, @telefonoEmergencia, @obraSocial, @nroSocioObra;

        -- Mientras haya algo, sigue procesando.
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Validar que el DNI no exista ya
            IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE dni = TRIM(@dni))
            BEGIN
                -- Insertar directamente en la tabla persona
                INSERT INTO manejo_personas.persona (
                    dni, nombre, apellido, email, fecha_nac, telefono, fecha_alta, activo
                )
                VALUES (
                    TRIM(@dni), TRIM(@nombre), TRIM(@apellido), TRIM(@email), @fechaNac, TRIM(@telefono), GETDATE(), 1
                );

                -- Obtener el ID de la persona recién creada
                SELECT @id_persona = id_persona 
                FROM manejo_personas.persona 
                WHERE dni = TRIM(@dni);

                -- Insertar directamente en la tabla socio
                INSERT INTO manejo_personas.socio (
                    numero_socio, id_persona, telefono_emergencia, id_categoria
                )
                VALUES (
                    TRIM(@nroSocio), @id_persona, TRIM(@telefonoEmergencia), 3
                );

                -- Si hay obra social, crearla si no existe y asociarla al socio
                IF @obraSocial IS NOT NULL AND TRIM(@obraSocial) <> ''
                BEGIN
                    DECLARE @id_obra_social INT;
                    
                    -- Verificar si la obra social ya existe
                    SELECT @id_obra_social = id_obra_social 
                    FROM manejo_personas.obra_social 
                    WHERE descripcion = TRIM(@obraSocial);

                    -- Si no existe, crearla
                    IF @id_obra_social IS NULL
                    BEGIN
                        INSERT INTO manejo_personas.obra_social (descripcion)
                        VALUES (TRIM(@obraSocial));

                        SELECT @id_obra_social = id_obra_social 
                        FROM manejo_personas.obra_social 
                        WHERE descripcion = TRIM(@obraSocial);
                    END
                    
                    -- Asociar la obra social al socio
                    IF @id_obra_social IS NOT NULL
                    BEGIN
                        UPDATE manejo_personas.socio
                        SET id_obra_social = @id_obra_social,
                            obra_nro_socio = TRIM(@nroSocioObra)
                        WHERE id_persona = @id_persona;
                    END
                END
            END

            FETCH NEXT FROM cur INTO @nroSocio, @dni, @nombre, @apellido, @email, @fechaNac,
                                     @telefono, @telefonoEmergencia, @obraSocial, @nroSocioObra;
        END

        -- BLOQUE DEVOLUCIONES Y LIMPIEZA
        CLOSE cur;
        DEALLOCATE cur;

        DROP TABLE #TempDatos;

        COMMIT TRANSACTION;
        SELECT 'Exito' AS Resultado, 'Datos importados correctamente' AS Mensaje;
END
GO