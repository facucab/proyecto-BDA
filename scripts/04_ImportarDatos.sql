USE Com5600G01;
GO

-- Habilitar Ad Hoc Distributed Queries (necesario para OPENROWSET)
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

EXEC ImportarPagos 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
EXEC ImportarTodosLosDatos

SELECT * from manejo_actividades.actividad


-- Procedimiento para importar responsables de pago (primera hoja)
CREATE OR ALTER PROCEDURE ImportarResponsablesPago
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Crea un SQL dinamico
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'SELECT 
            [Nro de Socio],
            TRIM([Nombre]),
            TRIM([apellido]),
            [DNI],
            TRIM([email personal]),
            CONVERT(DATE, [fecha de nacimiento], 103),
            [teléfono de contacto],
            [teléfono de contacto emergencia],
            TRIM([Nombre de la obra social o prepaga]),
            [nro. de socio obra social/prepaga],
            [teléfono de contacto de emergencia]
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [Responsables de Pago$]'')';

        -- Crear tabla temporal para almacenar los datos del Excel
        CREATE TABLE #TempDatos (
            NroSocio VARCHAR(20),
            Nombre NVARCHAR(50),
            Apellido NVARCHAR(50),
            DNI VARCHAR(8),
            Email VARCHAR(320),
            FechaNacimiento DATE,
            TelefonoContacto VARCHAR(15),
            TelefonoEmergencia VARCHAR(15),
            ObraSocial VARCHAR(50),
            NroSocioObra VARCHAR(50),
            TelefonoObra VARCHAR(15)
        );

        -- Importar datos del Excel a la tabla temporal
        INSERT INTO #TempDatos
        EXEC sp_executesql @SQL;

        -- Procesar cada registro
        DECLARE @dni VARCHAR(8), @nombre NVARCHAR(50), @apellido NVARCHAR(50),
                @email VARCHAR(320), @fechaNac DATE, @telefono VARCHAR(15),
                @obraSocial VARCHAR(50), @nroSocioObra VARCHAR(50);

        DECLARE cur CURSOR FOR 
        SELECT DNI, Nombre, Apellido, Email, FechaNacimiento, TelefonoContacto,
               ObraSocial, NroSocioObra
        FROM #TempDatos;

        OPEN cur;
        FETCH NEXT FROM cur INTO @dni, @nombre, @apellido, @email, @fechaNac,
                                @telefono, @obraSocial, @nroSocioObra;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Crear la persona usando el SP existente
            EXEC manejo_personas.CrearPersona 
                @dni = @dni,
                @nombre = @nombre,
                @apellido = @apellido,
                @email = @email,
                @fecha_nac = @fechaNac,
                @telefono = @telefono;

            -- Si hay obra social, crearla si no existe
            IF @obraSocial IS NOT NULL AND LTRIM(RTRIM(@obraSocial)) <> ''
            BEGIN
                EXEC manejo_personas.CreacionObraSocial @nombre = @obraSocial;
            END

            FETCH NEXT FROM cur INTO @dni, @nombre, @apellido, @email, @fechaNac,
                                    @telefono, @obraSocial, @nroSocioObra;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- Limpiar
        DROP TABLE #TempDatos;

        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Datos importados correctamente' AS Mensaje;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO

-- Procedimiento para importar grupo familiar (segunda hoja)
CREATE OR ALTER PROCEDURE ImportarGrupoFamiliar
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'SELECT 
            [Nro de Socio],
            [Nro de socio RP],
            TRIM([Nombre]),
            TRIM([apellido]),
            [DNI],
            NULLIF(TRIM([email personal]), ''''),
            CONVERT(DATE, [fecha de nacimiento], 103),
            NULLIF([teléfono de contacto], ''''),
            NULLIF([teléfono de contacto emergencia], ''''),
            NULLIF(TRIM([Nombre de la obra social o prepaga]), ''''),
            NULLIF([nro. de socio obra social/prepaga], ''''),
            NULLIF([teléfono de contacto de emergencia], '''')
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [Grupo Familiar$]'')';

        -- Crear tabla temporal para almacenar los datos del Excel
        CREATE TABLE #TempDatos (
            NroSocio VARCHAR(20),
            NroSocioRP VARCHAR(20),
            Nombre NVARCHAR(50),
            Apellido NVARCHAR(50),
            DNI VARCHAR(8),
            Email VARCHAR(320),
            FechaNacimiento DATE,
            TelefonoContacto VARCHAR(15),
            TelefonoEmergencia VARCHAR(15),
            ObraSocial VARCHAR(50),
            NroSocioObra VARCHAR(50),
            TelefonoObra VARCHAR(15)
        );

        -- Importar datos del Excel a la tabla temporal
        INSERT INTO #TempDatos
        EXEC sp_executesql @SQL;

        -- Procesar cada registro
        DECLARE @dni VARCHAR(8), @nombre NVARCHAR(50), @apellido NVARCHAR(50),
                @email VARCHAR(320), @fechaNac DATE, @telefono VARCHAR(15),
                @obraSocial VARCHAR(50);

        DECLARE cur CURSOR FOR 
        SELECT DNI, Nombre, Apellido, Email, FechaNacimiento, TelefonoContacto, ObraSocial
        FROM #TempDatos;

        OPEN cur;
        FETCH NEXT FROM cur INTO @dni, @nombre, @apellido, @email, @fechaNac, @telefono, @obraSocial;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @emailTemp VARCHAR(320);
            DECLARE @telefonoTemp VARCHAR(15);
            
            SET @emailTemp = ISNULL(@email, @dni + '_temp@club.com');
            SET @telefonoTemp = ISNULL(@telefono, '');

            -- Crear la persona usando el SP existente
            EXEC manejo_personas.CrearPersona 
                @dni = @dni,
                @nombre = @nombre,
                @apellido = @apellido,
                @email = @emailTemp,
                @fecha_nac = @fechaNac,
                @telefono = @telefonoTemp;

            -- Si hay obra social, crearla si no existe
            IF @obraSocial IS NOT NULL
            BEGIN
                EXEC manejo_personas.CreacionObraSocial @nombre = @obraSocial;
            END

            FETCH NEXT FROM cur INTO @dni, @nombre, @apellido, @email, @fechaNac, @telefono, @obraSocial;
        END

        CLOSE cur;
        DEALLOCATE cur;

        -- Limpiar
        DROP TABLE #TempDatos;

        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Datos del grupo familiar importados correctamente' AS Mensaje;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO

-- Procedimiento para importar pagos (tercera hoja)
CREATE OR ALTER PROCEDURE ImportarPagos
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SQL NVARCHAR(MAX);
        
        -- Primero insertamos los métodos de pago si no existen
        SET @SQL = 'INSERT INTO pagos_y_facturas.metodo_pago (nombre)
        SELECT DISTINCT TRIM(datos.[Medio de pago])
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [pago cuotas$]'') AS datos
        WHERE NOT EXISTS (
            SELECT 1 FROM pagos_y_facturas.metodo_pago mp 
            WHERE mp.nombre = TRIM(datos.[Medio de pago])
        )';

        EXEC sp_executesql @SQL;

        -- Luego insertamos las facturas
        SET @SQL = 'INSERT INTO pagos_y_facturas.factura (
            estado_pago,
            fecha_emision,
            monto_a_pagar,
            id_persona,
            id_metodo_pago
        )
        SELECT 
            ''PAGADO'',
            CONVERT(DATE, datos.fecha, 103),
            datos.Valor,
            p.id_persona,
            mp.id_metodo_pago
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [pago cuotas$]'') AS datos
        INNER JOIN manejo_personas.socio s ON RIGHT(s.id_socio, 4) = RIGHT(datos.[Responsable de pago], 4)
        INNER JOIN manejo_personas.persona p ON p.id_persona = s.id_persona
        INNER JOIN pagos_y_facturas.metodo_pago mp ON mp.nombre = TRIM(datos.[Medio de pago])
        WHERE NOT EXISTS (
            SELECT 1 FROM pagos_y_facturas.factura f 
            WHERE f.id_persona = p.id_persona 
            AND f.fecha_emision = CONVERT(DATE, datos.fecha, 103)
        )';

        EXEC sp_executesql @SQL;

        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Datos de pagos importados correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 
            'Error' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_LINE() AS Linea;
        
        THROW;
    END CATCH
END;
GO

-- Procedimiento para importar asistencias (quinta hoja)
CREATE OR ALTER PROCEDURE ImportarAsistencias
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SQL NVARCHAR(MAX);
        
        -- Primero insertamos las actividades si no existen
        SET @SQL = 'INSERT INTO manejo_actividades.actividad (nombre_actividad, costo_mensual)
        SELECT DISTINCT 
            TRIM(datos.Actividad),
            0 -- El costo mensual deberá ser actualizado posteriormente
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [presentismo_actividades$]'') AS datos
        WHERE NOT EXISTS (
            SELECT 1 FROM manejo_actividades.actividad a 
            WHERE a.nombre_actividad = TRIM(datos.Actividad)
        )';

        EXEC sp_executesql @SQL;

        -- Luego insertamos las relaciones socio-actividad
        SET @SQL = 'INSERT INTO manejo_personas.socio_actividad (
            id_socio,
            id_actividad,
            fecha_inicio
        )
        SELECT DISTINCT
            s.id_socio,
            a.id_actividad,
            CONVERT(DATE, datos.[fecha de asistencia], 103)
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [presentismo_actividades$]'') AS datos
        INNER JOIN manejo_personas.socio s ON RIGHT(s.id_socio, 4) = RIGHT(datos.[Nro de Socio], 4)
        INNER JOIN manejo_actividades.actividad a ON a.nombre_actividad = TRIM(datos.Actividad)
        WHERE NOT EXISTS (
            SELECT 1 FROM manejo_personas.socio_actividad sa 
            WHERE sa.id_socio = s.id_socio 
            AND sa.id_actividad = a.id_actividad
        )';

        EXEC sp_executesql @SQL;

        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Datos de asistencias importados correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 
            'Error' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_LINE() AS Linea;
        
        THROW;
    END CATCH
END;
GO

-- Procedimiento maestro para importar todos los datos
CREATE OR ALTER PROCEDURE ImportarTodosLosDatos
AS
BEGIN
    DECLARE @RutaArchivo NVARCHAR(260) = N'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx';
    
    BEGIN TRY
        -- Importar en orden para mantener integridad referencial
        EXEC ImportarResponsablesPago @RutaArchivo;
        EXEC ImportarGrupoFamiliar @RutaArchivo;
        EXEC ImportarPagos @RutaArchivo;
        EXEC ImportarAsistencias @RutaArchivo;
        
        SELECT 'Éxito' AS Resultado, 'Todos los datos fueron importados correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 
            'Error' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_LINE() AS Linea;
        
        THROW;
    END CATCH
END;
GO
