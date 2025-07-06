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

-- Importar Categorias - FUNCIONANDO - Sin Cursor
CREATE OR ALTER PROCEDURE actividades.ImportarCategorias
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
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
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Procesa los datos con CTE
        WITH DatosProcesados AS (
            SELECT 
                LTRIM(RTRIM([Categoria socio])) AS nombre_categoria,
                [Valor cuota] AS costo_membrecia,
                [Vigente hasta] AS vigencia
            FROM #TempDatos
            WHERE [Categoria socio] IS NOT NULL
              AND LTRIM(RTRIM([Categoria socio])) <> ''
              AND [Valor cuota] IS NOT NULL
        )
        -- Inserta registros nuevos
        INSERT INTO actividades.categoria (nombre_categoria, costo_membrecia, vigencia)
        SELECT 
            dp.nombre_categoria,
            dp.costo_membrecia,
            dp.vigencia
        FROM DatosProcesados dp
        WHERE NOT EXISTS (
            SELECT 1 FROM actividades.categoria c 
            WHERE LOWER(LTRIM(RTRIM(c.nombre_categoria))) = LOWER(LTRIM(RTRIM(dp.nombre_categoria)))
        );
        
        -- Actualiza registros existentes
        UPDATE actividades.categoria
        SET 
            costo_membrecia = dp.costo_membrecia,
            vigencia = dp.vigencia
        FROM (
            SELECT 
                LTRIM(RTRIM([Categoria socio])) AS nombre_categoria,
                [Valor cuota] AS costo_membrecia,
                [Vigente hasta] AS vigencia
            FROM #TempDatos
            WHERE [Categoria socio] IS NOT NULL
              AND LTRIM(RTRIM([Categoria socio])) <> ''
              AND [Valor cuota] IS NOT NULL
        ) dp
        WHERE LOWER(LTRIM(RTRIM(actividades.categoria.nombre_categoria))) = LOWER(LTRIM(RTRIM(dp.nombre_categoria)));
        
        DROP TABLE #TempDatos;
        
        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO
    
-- Importar Socios - FUNCIONANDO - Sin Cursor
CREATE OR ALTER PROCEDURE usuarios.ImportarSocios
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    DECLARE @SQL NVARCHAR(MAX);

        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos ( 
            [Nro de Socio] VARCHAR(20),
            [Nombre] VARCHAR(50),
            [ apellido] VARCHAR(50),
            [ DNI] VARCHAR(20),
            [ email personal] VARCHAR(320),
            [ fecha de nacimiento] DATE,
            [ teléfono de contacto] VARCHAR(50),
            [ teléfono de contacto emergencia] VARCHAR(50),
            [ Nombre de la obra social o prepaga] NVARCHAR(100),
            [nro# de socio obra social/prepaga ] VARCHAR(50),
            [teléfono de contacto de emergencia ] VARCHAR(50)
        );

        -- Arma el SQL dinámico con validaciones mejoradas
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
                LTRIM(RTRIM([Nro de Socio])),
                LTRIM(RTRIM([Nombre])),
                LTRIM(RTRIM([ apellido])), 
                LTRIM(RTRIM([ DNI])),
                LTRIM(RTRIM([ email personal])),
                TRY_CAST([ fecha de nacimiento] AS DATE),
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
                LTRIM(RTRIM([ Nombre de la obra social o prepaga])),
                LTRIM(RTRIM([nro# de socio obra social/prepaga ])),
                CASE 
                    WHEN ISNUMERIC([teléfono de contacto de emergencia ]) = 1 AND [teléfono de contacto de emergencia ] IS NOT NULL
                    THEN FORMAT(CAST([teléfono de contacto de emergencia ] AS BIGINT), ''0'')
                    ELSE CAST([teléfono de contacto de emergencia ] AS VARCHAR(50))
                END
                FROM OPENROWSET(
                    ''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0;HDR=YES;IMEX=1;TypeGuessRows=0;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Responsables de Pago$]'')
            WHERE [Nro de Socio] IS NOT NULL 
              AND LTRIM(RTRIM([Nro de Socio])) <> ''''
              AND [ DNI] IS NOT NULL 
              AND LTRIM(RTRIM([ DNI])) <> ''''
              AND TRY_CAST([ fecha de nacimiento] AS DATE) IS NOT NULL';
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Procesa los datos y crea obras sociales nuevas con validación mejorada
        INSERT INTO usuarios.obra_social (descripcion, nro_telefono)
        SELECT DISTINCT 
            LTRIM(RTRIM([ Nombre de la obra social o prepaga])),
            LEFT(ISNULL([teléfono de contacto de emergencia ], '11'), 20)
        FROM #TempDatos
        WHERE [ Nombre de la obra social o prepaga] IS NOT NULL 
          AND LTRIM(RTRIM([ Nombre de la obra social o prepaga])) <> ''
          AND NOT EXISTS (
              SELECT 1 FROM usuarios.obra_social os 
              WHERE LOWER(LTRIM(RTRIM(os.descripcion))) = LOWER(LTRIM(RTRIM([ Nombre de la obra social o prepaga])))
        );
        
        -- Crear tabla temporal para datos procesados
        CREATE TABLE #DatosProcesados (
            numero_socio VARCHAR(20),
            dni VARCHAR(20),
            nombre NVARCHAR(50),
            apellido NVARCHAR(50),
            email VARCHAR(320),
            fecha_nac DATE,
            telefono VARCHAR(50),
            telefono_emergencia VARCHAR(50),
            nro_socio_obra VARCHAR(50),
            id_obra_social INT,
            categoria_nombre VARCHAR(20)
        );
        
        -- Insertar datos procesados en tabla temporal
        INSERT INTO #DatosProcesados
        SELECT 
            REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', '') AS numero_socio,
            REPLACE(REPLACE(LTRIM(RTRIM([ DNI])), '.', ''), '-', '') AS dni,
            UPPER(LEFT(LTRIM(RTRIM([Nombre])), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM([Nombre])), 2, LEN([Nombre]))) AS nombre,
            UPPER(LEFT(LTRIM(RTRIM([ apellido])), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM([ apellido])), 2, LEN([ apellido]))) AS apellido,
            CASE 
                WHEN [ email personal] IS NULL OR LTRIM(RTRIM([ email personal])) = '' THEN
                    'socio_' + REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', '') + '@example.com'
                ELSE
                    LOWER(REPLACE(LTRIM(RTRIM([ email personal])), ' ', ''))
            END AS email,
            [ fecha de nacimiento] AS fecha_nac,
            CASE 
                WHEN [ teléfono de contacto] IS NULL OR LTRIM(RTRIM([ teléfono de contacto])) = '' THEN '11'
                ELSE [ teléfono de contacto]
            END AS telefono,
            [ teléfono de contacto emergencia] AS telefono_emergencia,
            [nro# de socio obra social/prepaga ] AS nro_socio_obra,
            os.id_obra_social,
            CASE 
                WHEN DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()) >= 18 THEN 'mayor'
                WHEN DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()) >= 13 THEN 'cadete'
                ELSE 'menor'
            END AS categoria_nombre
        FROM #TempDatos
        LEFT JOIN usuarios.obra_social os ON LOWER(LTRIM(RTRIM(os.descripcion))) = LOWER(LTRIM(RTRIM([ Nombre de la obra social o prepaga])))
        WHERE [Nro de Socio] IS NOT NULL
          AND LTRIM(RTRIM([Nro de Socio])) <> ''
          AND [ DNI] IS NOT NULL
          AND LTRIM(RTRIM([ DNI])) <> ''
          AND [ fecha de nacimiento] IS NOT NULL;
        
        -- Crear personas si no existen (manejo de duplicados)
        INSERT INTO usuarios.persona (dni, nombre, apellido, email, fecha_nac, telefono)
        SELECT 
            dni,
            nombre,
            apellido,
            email,
            fecha_nac,
            telefono
        FROM (
            SELECT 
                dp.dni,
                dp.nombre,
                dp.apellido,
                dp.email,
                dp.fecha_nac,
                dp.telefono,
                ROW_NUMBER() OVER (PARTITION BY dp.dni ORDER BY dp.numero_socio) AS rn
            FROM #DatosProcesados dp
            WHERE NOT EXISTS (
                SELECT 1 FROM usuarios.persona p WHERE p.dni = dp.dni
            )
            AND dp.dni IS NOT NULL 
            AND dp.dni <> ''
        ) ranked
        WHERE rn = 1;
        
        -- Crear o actualizar socios con validación mejorada
        MERGE usuarios.socio AS target
        USING (
            SELECT 
                dp.numero_socio,
                dp.dni,
                dp.nombre,
                dp.apellido,
                dp.email,
                dp.fecha_nac,
                dp.telefono,
                dp.telefono_emergencia,
                dp.nro_socio_obra,
                dp.id_obra_social,
                c.id_categoria
            FROM #DatosProcesados dp
            LEFT JOIN actividades.categoria c ON LOWER(c.nombre_categoria) = LOWER(dp.categoria_nombre)
            WHERE dp.numero_socio IS NOT NULL 
              AND dp.numero_socio <> ''
              AND dp.dni IS NOT NULL 
              AND dp.dni <> ''
        ) AS source
        ON target.numero_socio = source.numero_socio
        WHEN NOT MATCHED THEN
            INSERT (numero_socio, id_persona, telefono_emergencia, obra_nro_socio, id_obra_social, id_categoria)
            VALUES (
                source.numero_socio,
                (SELECT id_persona FROM usuarios.persona WHERE dni = source.dni),
                source.telefono_emergencia,
                source.nro_socio_obra,
                source.id_obra_social,
                source.id_categoria
            )
        WHEN MATCHED THEN
            UPDATE SET
                telefono_emergencia = source.telefono_emergencia,
                obra_nro_socio = source.nro_socio_obra,
                id_obra_social = source.id_obra_social,
                id_categoria = source.id_categoria;
        
        DROP TABLE #DatosProcesados;
        
            DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Grupo Familiar - FUNCIONANDO - Sin Cursor
CREATE OR ALTER PROCEDURE usuarios.importarGrupoFamiliar
    @path NVARCHAR(260) 
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos (
            [Nro de Socio] VARCHAR(20),
            [Nro de socio RP] VARCHAR(20),
            [Nombre] VARCHAR(50),
            [ apellido] VARCHAR(50),
            [ DNI] VARCHAR(20),
            [ email personal] VARCHAR(320),
            [ fecha de nacimiento] DATE,
            [ teléfono de contacto] VARCHAR(50),
            [ teléfono de contacto emergencia] VARCHAR(50),
            [ Nombre de la obra social o prepaga] VARCHAR(100),
            [nro# de socio obra social/prepaga ] VARCHAR(50),
            [teléfono de contacto de emergencia ] VARCHAR(50)
        );
        
        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Nro de Socio], [Nro de socio RP], [Nombre], 
                [ apellido], [ DNI], [ email personal],
                [ fecha de nacimiento], [ teléfono de contacto], 
                [ teléfono de contacto emergencia],
                [ Nombre de la obra social o prepaga], 
                [nro# de socio obra social/prepaga ], 
                [teléfono de contacto de emergencia ]
            )
            SELECT 
                LTRIM(RTRIM([Nro de Socio])),
                LTRIM(RTRIM([Nro de socio RP])),
                LTRIM(RTRIM([Nombre])),
                LTRIM(RTRIM([ apellido])), 
                LTRIM(RTRIM([ DNI])),
                LTRIM(RTRIM([ email personal])),
                TRY_CAST([ fecha de nacimiento] AS DATE),
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
                LTRIM(RTRIM([ Nombre de la obra social o prepaga])),
                LTRIM(RTRIM([nro# de socio obra social/prepaga ])),
                CASE 
                    WHEN ISNUMERIC([teléfono de contacto de emergencia ]) = 1 AND [teléfono de contacto de emergencia ] IS NOT NULL
                    THEN FORMAT(CAST([teléfono de contacto de emergencia ] AS BIGINT), ''0'')
                    ELSE CAST([teléfono de contacto de emergencia ] AS VARCHAR(50))
                END
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;TypeGuessRows=0;Database=' + @path + ''',
                ''SELECT * FROM [Grupo Familiar$]'')
            WHERE [Nro de Socio] IS NOT NULL 
              AND LTRIM(RTRIM([Nro de Socio])) <> ''''
              AND [ DNI] IS NOT NULL 
              AND LTRIM(RTRIM([ DNI])) <> ''''
              AND TRY_CAST([ fecha de nacimiento] AS DATE) IS NOT NULL';
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Procesa los datos y crea obras sociales
        INSERT INTO usuarios.obra_social (descripcion, nro_telefono)
        SELECT DISTINCT 
            LTRIM(RTRIM([ Nombre de la obra social o prepaga])),
            LEFT(ISNULL([teléfono de contacto de emergencia ], '11'), 20)
        FROM #TempDatos
        WHERE [ Nombre de la obra social o prepaga] IS NOT NULL 
          AND LTRIM(RTRIM([ Nombre de la obra social o prepaga])) <> ''
          AND NOT EXISTS (
              SELECT 1 FROM usuarios.obra_social os 
              WHERE LOWER(LTRIM(RTRIM(os.descripcion))) = LOWER(LTRIM(RTRIM([ Nombre de la obra social o prepaga])))
        );
        
        -- Crear tabla temporal para datos procesados
        CREATE TABLE #DatosProcesados (
            numero_socio VARCHAR(20),
            numero_socio_rp VARCHAR(20),
            dni VARCHAR(20),
            nombre NVARCHAR(50),
            apellido NVARCHAR(50),
            email VARCHAR(320),
            fecha_nac DATE,
            telefono VARCHAR(50),
            telefono_emergencia VARCHAR(50),
            nro_socio_obra VARCHAR(50),
            id_obra_social INT,
            categoria_nombre VARCHAR(20),
            id_socio_rp INT
        );
        
        -- Insertar datos procesados en tabla temporal
        INSERT INTO #DatosProcesados
        SELECT 
            REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', '') AS numero_socio,
            REPLACE(LTRIM(RTRIM([Nro de socio RP])), 'SN-', '') AS numero_socio_rp,
            CASE 
                WHEN ISNUMERIC([ DNI]) = 1 THEN 
                    CAST(CAST(CAST([ DNI] AS FLOAT) AS INT) AS VARCHAR(9))
                ELSE 
                    LEFT(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM([ DNI])), '.', ''), '-', ''), '+', ''), 9)
            END AS dni,
            UPPER(LEFT(LTRIM(RTRIM([Nombre])), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM([Nombre])), 2, LEN([Nombre]))) AS nombre,
            UPPER(LEFT(LTRIM(RTRIM([ apellido])), 1)) + LOWER(SUBSTRING(LTRIM(RTRIM([ apellido])), 2, LEN([ apellido]))) AS apellido,
            CASE 
                WHEN [ email personal] IS NULL OR LTRIM(RTRIM([ email personal])) = '' THEN
                    'socio_' + REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', '') + '@example.com'
                ELSE
                    LOWER(REPLACE(LTRIM(RTRIM([ email personal])), ' ', ''))
            END AS email,
            [ fecha de nacimiento] AS fecha_nac,
            CASE 
                WHEN [ teléfono de contacto] IS NULL OR LTRIM(RTRIM([ teléfono de contacto])) = '' THEN '11'
                ELSE [ teléfono de contacto]
            END AS telefono,
            [ teléfono de contacto emergencia] AS telefono_emergencia,
            [nro# de socio obra social/prepaga ] AS nro_socio_obra,
            os.id_obra_social,
            CASE 
                WHEN DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()) >= 18 THEN 'mayor'
                WHEN DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()) >= 13 THEN 'cadete'
                ELSE 'menor'
            END AS categoria_nombre,
            s_rp.id_socio AS id_socio_rp
        FROM #TempDatos
        LEFT JOIN usuarios.obra_social os ON LOWER(LTRIM(RTRIM(os.descripcion))) = LOWER(LTRIM(RTRIM([ Nombre de la obra social o prepaga])))
        LEFT JOIN usuarios.socio s_rp ON s_rp.numero_socio = REPLACE(LTRIM(RTRIM([Nro de socio RP])), 'SN-', '')
        WHERE [Nro de Socio] IS NOT NULL
          AND LTRIM(RTRIM([Nro de Socio])) <> ''
          AND [ DNI] IS NOT NULL
          AND LTRIM(RTRIM([ DNI])) <> ''
          AND [ fecha de nacimiento] IS NOT NULL
          AND s_rp.id_socio IS NOT NULL; -- Solo procesar si existe el socio responsable
        
        -- Crear personas si no existen (manejo de duplicados)
        INSERT INTO usuarios.persona (dni, nombre, apellido, email, fecha_nac, telefono)
        SELECT 
            dni,
            nombre,
            apellido,
            email,
            fecha_nac,
            telefono
        FROM (
            SELECT 
                dp.dni,
                dp.nombre,
                dp.apellido,
                dp.email,
                dp.fecha_nac,
                dp.telefono,
                ROW_NUMBER() OVER (PARTITION BY dp.dni ORDER BY dp.numero_socio) AS rn
            FROM #DatosProcesados dp
            WHERE NOT EXISTS (
                SELECT 1 FROM usuarios.persona p WHERE p.dni = dp.dni
            )
            AND dp.dni IS NOT NULL 
            AND dp.dni <> ''
        ) ranked
        WHERE rn = 1;
        
        -- Crear grupos familiares si no existen
        INSERT INTO usuarios.grupo_familiar (id_socio_rp)
        SELECT DISTINCT 
            dp.id_socio_rp
        FROM #DatosProcesados dp
        WHERE NOT EXISTS (
            SELECT 1 FROM usuarios.grupo_familiar gf WHERE gf.id_socio_rp = dp.id_socio_rp
        );
        
        -- Actualizar socios existentes
        UPDATE s
        SET telefono_emergencia = dp.telefono_emergencia,
            obra_nro_socio = dp.nro_socio_obra,
            id_obra_social = dp.id_obra_social,
            id_categoria = dp.id_categoria,
            id_grupo = dp.id_grupo_familiar
        FROM usuarios.socio s
        INNER JOIN (
            SELECT 
                dp.numero_socio,
                dp.dni,
                dp.nombre,
                dp.apellido,
                dp.email,
                dp.fecha_nac,
                dp.telefono,
                dp.telefono_emergencia,
                dp.nro_socio_obra,
                dp.id_obra_social,
                c.id_categoria,
                gf.id_grupo_familiar
            FROM #DatosProcesados dp
            LEFT JOIN actividades.categoria c ON LOWER(c.nombre_categoria) = LOWER(dp.categoria_nombre)
            LEFT JOIN usuarios.grupo_familiar gf ON gf.id_socio_rp = dp.id_socio_rp
            WHERE dp.numero_socio IS NOT NULL 
              AND dp.numero_socio <> ''
              AND dp.dni IS NOT NULL 
              AND dp.dni <> ''
        ) dp ON s.numero_socio = dp.numero_socio;
        
        -- Insertar nuevos socios que no existen
        INSERT INTO usuarios.socio (numero_socio, id_persona, telefono_emergencia, obra_nro_socio, id_obra_social, id_categoria, id_grupo)
        SELECT 
            dp.numero_socio,
            (SELECT id_persona FROM usuarios.persona WHERE dni = dp.dni),
            dp.telefono_emergencia,
            dp.nro_socio_obra,
            dp.id_obra_social,
            dp.id_categoria,
            dp.id_grupo_familiar
        FROM (
            SELECT 
                dp.numero_socio,
                dp.dni,
                dp.nombre,
                dp.apellido,
                dp.email,
                dp.fecha_nac,
                dp.telefono,
                dp.telefono_emergencia,
                dp.nro_socio_obra,
                dp.id_obra_social,
                c.id_categoria,
                gf.id_grupo_familiar
            FROM #DatosProcesados dp
            LEFT JOIN actividades.categoria c ON LOWER(c.nombre_categoria) = LOWER(dp.categoria_nombre)
            LEFT JOIN usuarios.grupo_familiar gf ON gf.id_socio_rp = dp.id_socio_rp
            WHERE dp.numero_socio IS NOT NULL 
              AND dp.numero_socio <> ''
              AND dp.dni IS NOT NULL 
              AND dp.dni <> ''
        ) dp
        WHERE NOT EXISTS (
            SELECT 1 FROM usuarios.socio s WHERE s.numero_socio = dp.numero_socio
        );
        
        DROP TABLE #DatosProcesados;
        DROP TABLE #TempDatos;
        
        SELECT 'Éxito' AS Resultado, 'Importación de grupo familiar completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
        IF OBJECT_ID('tempdb..#DatosProcesados') IS NOT NULL
            DROP TABLE #DatosProcesados;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO


-- Importar Actividades - FUNCIONADO - Sin Cursor
CREATE OR ALTER PROCEDURE actividades.ImportarActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos (
            [Actividad] VARCHAR(50),
            [Valor por mes] DECIMAL(10,2),
            [Vigente hasta] DATE
        );
        
        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos ([Actividad], [Valor por mes], [Vigente hasta])
            SELECT [Actividad], [Valor por mes], [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B2:D8]'')';
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Procesa los datos con CTE
        WITH DatosProcesados AS (
            SELECT 
                LTRIM(RTRIM([Actividad])) AS nombre_actividad,
                [Valor por mes] AS costo_mensual
            FROM #TempDatos
            WHERE [Actividad] IS NOT NULL
              AND LTRIM(RTRIM([Actividad])) <> ''
              AND [Valor por mes] IS NOT NULL
        )
        -- Inserta registros nuevos
        INSERT INTO actividades.actividad (nombre, costo_mensual)
        SELECT 
            dp.nombre_actividad,
            dp.costo_mensual
        FROM DatosProcesados dp
        WHERE NOT EXISTS (
            SELECT 1 FROM actividades.actividad a 
            WHERE LOWER(LTRIM(RTRIM(a.nombre))) = LOWER(LTRIM(RTRIM(dp.nombre_actividad)))
        );
        
        -- Actualiza registros existentes
        UPDATE actividades.actividad
        SET 
            costo_mensual = dp.costo_mensual
        FROM (
            SELECT 
                LTRIM(RTRIM([Actividad])) AS nombre_actividad,
                [Valor por mes] AS costo_mensual
            FROM #TempDatos
            WHERE [Actividad] IS NOT NULL
              AND LTRIM(RTRIM([Actividad])) <> ''
              AND [Valor por mes] IS NOT NULL
        ) dp
        WHERE LOWER(LTRIM(RTRIM(actividades.actividad.nombre))) = LOWER(LTRIM(RTRIM(dp.nombre_actividad)));
        
        DROP TABLE #TempDatos;
        
        SELECT 'Éxito' AS Resultado, 'Importación de actividades completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Costos de Pileta - FUNCIONADO - Sin Cursor
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
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos (
            [Concepto] VARCHAR(100),
            [Grupo] VARCHAR(100),
            [Socios] VARCHAR(100),
            [Invitados] VARCHAR(100)
        );
        
        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos (Concepto, Grupo, Socios, Invitados)
            SELECT F1, F2, F3, F4
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=NO;IMEX=1;TypeGuessRows=0;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B16:F22]'')';
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Procesa los datos con CTE
        WITH DatosProcesados AS (
            SELECT 
                LTRIM(RTRIM(Concepto)) AS concepto,
                LTRIM(RTRIM(Grupo)) AS grupo,
                Socios,
                Invitados,
                -- Mapear tipo (dia/tem/mes)
                CASE
                    WHEN LTRIM(RTRIM(Concepto)) LIKE '%dia%' OR LTRIM(RTRIM(Concepto)) LIKE '%día%' THEN 'dia'
                    WHEN LTRIM(RTRIM(Concepto)) LIKE '%temporad%' THEN 'tem'
                    WHEN LTRIM(RTRIM(Concepto)) LIKE '%mes%' THEN 'mes'
                    ELSE NULL
                END AS tipo,
                -- Mapear grupo (adu/men)
                CASE
                    WHEN LTRIM(RTRIM(Grupo)) LIKE '%menor%' THEN 'men'
                    ELSE 'adu'
                END AS tipo_grupo,
                -- Limpiar y convertir Socios a DECIMAL
                TRY_CAST(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(REPLACE(Socios, CHAR(160), ''), ' ', ''), '$', ''), '.', ''
                            ), ',', '.')
                AS DECIMAL(10,2)) AS precio_socios,
                -- Limpiar y convertir Invitados (0 si vacío)
                ISNULL(
                    TRY_CAST(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(REPLACE(Invitados, CHAR(160), ''), ' ', ''), '$', ''), '.', ''
                                ), ',', '.')
                    AS DECIMAL(10,2))
                , 0) AS precio_invitados
            FROM #TempDatos
            WHERE Grupo IS NOT NULL -- Descartar fila de título
              AND LTRIM(RTRIM(Grupo)) <> ''
              AND Socios IS NOT NULL
              AND LTRIM(RTRIM(Socios)) <> ''
        )
        -- Inserta registros nuevos
        INSERT INTO actividades.costo (tipo, tipo_grupo, precio_socios, precio_invitados, id_pileta)
        SELECT 
            dp.tipo,
            dp.tipo_grupo,
            dp.precio_socios,
            dp.precio_invitados,
            @id_pileta
        FROM DatosProcesados dp
        WHERE dp.tipo IS NOT NULL
          AND dp.tipo_grupo IS NOT NULL
          AND dp.precio_socios IS NOT NULL
          AND dp.precio_invitados > 0
          AND NOT EXISTS (
              SELECT 1 FROM actividades.costo c 
              WHERE c.tipo = dp.tipo 
                AND c.tipo_grupo = dp.tipo_grupo 
                AND c.id_pileta = @id_pileta
          );
        
        -- Actualiza registros existentes
        UPDATE actividades.costo
        SET 
            precio_socios = dp.precio_socios,
            precio_invitados = dp.precio_invitados
        FROM (
            SELECT 
                LTRIM(RTRIM(Concepto)) AS concepto,
                LTRIM(RTRIM(Grupo)) AS grupo,
                Socios,
                Invitados,
                CASE
                    WHEN LTRIM(RTRIM(Concepto)) LIKE '%dia%' OR LTRIM(RTRIM(Concepto)) LIKE '%día%' THEN 'dia'
                    WHEN LTRIM(RTRIM(Concepto)) LIKE '%temporad%' THEN 'tem'
                    WHEN LTRIM(RTRIM(Concepto)) LIKE '%mes%' THEN 'mes'
                    ELSE NULL
                END AS tipo,
                CASE
                    WHEN LTRIM(RTRIM(Grupo)) LIKE '%menor%' THEN 'men'
                    ELSE 'adu'
                END AS tipo_grupo,
                TRY_CAST(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                                REPLACE(REPLACE(Socios, CHAR(160), ''), ' ', ''), '$', ''), '.', ''
                            ), ',', '.')
                AS DECIMAL(10,2)) AS precio_socios,
                ISNULL(
                    TRY_CAST(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(REPLACE(Invitados, CHAR(160), ''), ' ', ''), '$', ''), '.', ''
                                ), ',', '.')
                    AS DECIMAL(10,2))
                , 0) AS precio_invitados
            FROM #TempDatos
            WHERE Grupo IS NOT NULL
              AND LTRIM(RTRIM(Grupo)) <> ''
              AND Socios IS NOT NULL
              AND LTRIM(RTRIM(Socios)) <> ''
        ) dp
        WHERE actividades.costo.tipo = dp.tipo 
          AND actividades.costo.tipo_grupo = dp.tipo_grupo 
          AND actividades.costo.id_pileta = @id_pileta
          AND dp.tipo IS NOT NULL
          AND dp.tipo_grupo IS NOT NULL
          AND dp.precio_socios IS NOT NULL
          AND dp.precio_invitados > 0;
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Clima - FUNCIONANDO - Sin Cursor (BULK)
CREATE OR ALTER PROCEDURE facturacion.ImportarClima
    @RutaBase NVARCHAR(300) = '.\docs\',
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @RutaArchivo NVARCHAR(400);
        SET @RutaArchivo = @RutaBase + 'open-meteo-buenosaires_' + CAST(@Anio AS NVARCHAR(4)) + '.csv';
        
        IF OBJECT_ID('tempdb..#TempClima') IS NOT NULL
            DROP TABLE #TempClima;
        
        CREATE TABLE #TempClima (
            Fecha NVARCHAR(50),
            Temperatura NVARCHAR(50),
            Lluvia NVARCHAR(50),
            Humedad NVARCHAR(50),
            Viento NVARCHAR(50)
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = '
        BULK INSERT #TempClima
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 4,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''0x0a'',
            CODEPAGE = ''65001''
        );';
        
        EXEC sp_executesql @SQL;
        
        BEGIN TRANSACTION;
        
        INSERT INTO facturacion.clima (fecha, lluvia)
        SELECT 
            TRY_CAST(REPLACE(LTRIM(RTRIM(Fecha)), 'T', ' ') AS SMALLDATETIME),
            TRY_CAST(REPLACE(LTRIM(RTRIM(Lluvia)), ',', '.') AS DECIMAL(5,2))
        FROM #TempClima
        WHERE 
            TRY_CAST(REPLACE(LTRIM(RTRIM(Fecha)), 'T', ' ') AS SMALLDATETIME) IS NOT NULL
            AND TRY_CAST(REPLACE(LTRIM(RTRIM(Lluvia)), ',', '.') AS DECIMAL(5,2)) IS NOT NULL
            AND NOT EXISTS (
                SELECT 1
                FROM facturacion.clima c
                WHERE c.fecha = TRY_CAST(REPLACE(LTRIM(RTRIM(Fecha)), 'T', ' ') AS SMALLDATETIME)
            );
        
        COMMIT TRANSACTION;
        
        DROP TABLE #TempClima;
        
        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        IF OBJECT_ID('tempdb..#TempClima') IS NOT NULL
            DROP TABLE #TempClima;
            
        SELECT 'Error' AS Resultado, 'Error en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Facturas - FUNCIONANDO - Sin Cursor
CREATE OR ALTER PROCEDURE facturacion.ImportarFacturas
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos (
            [Id de pago] BIGINT,
            [fecha] DATE,
            [Responsable de pago] VARCHAR(20),
            [Valor] DECIMAL(10,2),
            [Medio de pago] VARCHAR(50)
        );
        
        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos ([Id de pago], 
                                    [fecha], 
                                    [Responsable de pago], 
                                    [Valor], 
                                    [Medio de pago])
            SELECT 
                CAST([Id de pago] AS BIGINT), 
                [fecha], 
                [Responsable de pago], 
                [Valor], 
                [Medio de pago]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [pago cuotas$A1:E10000]'')
            WHERE [Responsable de pago] IS NOT NULL 
              AND LTRIM(RTRIM([Responsable de pago])) <> ''''
              AND [Valor] IS NOT NULL 
              AND [Valor] > 0';
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Crear métodos de pago si no existen
        INSERT INTO facturacion.metodo_pago (nombre)
        SELECT DISTINCT 
            LTRIM(RTRIM([Medio de pago]))
        FROM #TempDatos
        WHERE [Medio de pago] IS NOT NULL 
          AND LTRIM(RTRIM([Medio de pago])) <> ''
          AND NOT EXISTS (
              SELECT 1 FROM facturacion.metodo_pago mp 
              WHERE LOWER(LTRIM(RTRIM(mp.nombre))) = LOWER(LTRIM(RTRIM([Medio de pago])))
        );
        
        -- Crear tabla temporal para datos procesados
        CREATE TABLE #DatosProcesados (
            id_pago BIGINT,
            fecha_emision DATE,
            numero_socio VARCHAR(20),
            valor DECIMAL(10,2),
            medio_pago VARCHAR(50),
            id_persona INT,
            id_metodo_pago INT
        );
        
        -- Insertar datos procesados en tabla temporal
        INSERT INTO #DatosProcesados
        SELECT 
            [Id de pago] AS id_pago,
            [fecha] AS fecha_emision,
            REPLACE(LTRIM(RTRIM([Responsable de pago])), 'SN-', '') AS numero_socio,
            [Valor] AS valor,
            LTRIM(RTRIM([Medio de pago])) AS medio_pago,
            s.id_persona,
            mp.id_metodo_pago
        FROM #TempDatos
        INNER JOIN usuarios.socio s ON s.numero_socio = REPLACE(LTRIM(RTRIM([Responsable de pago])), 'SN-', '')
        INNER JOIN facturacion.metodo_pago mp ON LOWER(LTRIM(RTRIM(mp.nombre))) = LOWER(LTRIM(RTRIM([Medio de pago])))
        WHERE [Responsable de pago] IS NOT NULL
          AND LTRIM(RTRIM([Responsable de pago])) <> ''
          AND [Valor] IS NOT NULL 
          AND [Valor] > 0
          AND s.id_persona IS NOT NULL
          AND mp.id_metodo_pago IS NOT NULL;
        
        -- Procesa los datos con CTE
        WITH DatosProcesados AS (
            SELECT 
                dp.id_pago,
                dp.fecha_emision,
                dp.numero_socio,
                dp.valor,
                dp.medio_pago,
                dp.id_persona,
                dp.id_metodo_pago
            FROM #DatosProcesados dp
            WHERE dp.id_pago IS NOT NULL
              AND dp.fecha_emision IS NOT NULL
              AND dp.valor IS NOT NULL 
              AND dp.valor > 0
              AND dp.id_persona IS NOT NULL
              AND dp.id_metodo_pago IS NOT NULL
        )
        -- Inserta registros nuevos
        INSERT INTO facturacion.factura (id_persona, id_metodo_pago, estado_pago, monto_a_pagar, detalle, fecha_emision, id_pago)
        SELECT 
            dp.id_persona,
            dp.id_metodo_pago,
            'Pendiente' AS estado_pago,
            dp.valor AS monto_a_pagar,
            NULL AS detalle,
            dp.fecha_emision,
            dp.id_pago
        FROM DatosProcesados dp
        WHERE NOT EXISTS (
            SELECT 1 FROM facturacion.factura f 
            WHERE f.id_pago = dp.id_pago
        );
        
        -- Actualiza registros existentes
        UPDATE facturacion.factura
        SET 
            id_persona = dp.id_persona,
            id_metodo_pago = dp.id_metodo_pago,
            monto_a_pagar = dp.valor,
            fecha_emision = dp.fecha_emision
        FROM (
            SELECT 
                dp.id_pago,
                dp.id_persona,
                dp.id_metodo_pago,
                dp.valor,
                dp.fecha_emision
            FROM #DatosProcesados dp
            WHERE dp.id_pago IS NOT NULL
              AND dp.fecha_emision IS NOT NULL
              AND dp.valor IS NOT NULL 
              AND dp.valor > 0
              AND dp.id_persona IS NOT NULL
              AND dp.id_metodo_pago IS NOT NULL
        ) dp
        WHERE facturacion.factura.id_pago = dp.id_pago;
        
        DROP TABLE #DatosProcesados;
        DROP TABLE #TempDatos;
        
        SELECT 'Éxito' AS Resultado, 'Importación de facturas completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
        IF OBJECT_ID('tempdb..#DatosProcesados') IS NOT NULL
            DROP TABLE #DatosProcesados;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- Importar Presentismo a Actividades - FUNCIONANDO - Sin Cursor
CREATE OR ALTER PROCEDURE actividades.ImportarPresentismoActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);
        
        -- Tabla temporal donde importar los archivos
        CREATE TABLE #TempDatos (
            [Nro de Socio] VARCHAR(20),
            [Actividad] NVARCHAR(100),
            [fecha de asistencia] DATE,
            [Asistencia] VARCHAR(15),
            [Profesor] NVARCHAR(100)
        );
        
        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos ([Nro de Socio], 
                                    [Actividad], 
                                    [fecha de asistencia], 
                                    [Asistencia], 
                                    [Profesor])
            SELECT 
                LTRIM(RTRIM(CAST([Nro de Socio] AS VARCHAR(20)))),
                LTRIM(RTRIM(CAST([Actividad] AS NVARCHAR(100)))),
                CAST([fecha de asistencia] AS DATE),
                LTRIM(RTRIM(CAST([Asistencia] AS VARCHAR(15)))),
                LTRIM(RTRIM(CAST([Profesor] AS NVARCHAR(100))))
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [presentismo_actividades$]'')
            WHERE [Nro de Socio] IS NOT NULL 
              AND LTRIM(RTRIM([Nro de Socio])) <> ''''
              AND [Actividad] IS NOT NULL 
              AND LTRIM(RTRIM([Actividad])) <> ''''
              AND [fecha de asistencia] IS NOT NULL';
        
        EXEC sp_executesql @SQL; -- Importa los registros a la temporal
        
        -- Crear tabla temporal para datos procesados
        CREATE TABLE #DatosProcesados (
            numero_socio VARCHAR(20),
            actividad_nombre NVARCHAR(100),
            fecha_asistencia DATE,
            asistencia VARCHAR(15),
            profesor_nombre NVARCHAR(100),
            id_socio INT,
            id_actividad INT,
            id_persona_profesor INT,
            id_usuario_profesor INT,
            dia VARCHAR(9),
            id_clase INT
        );
        
        -- Insertar datos procesados en tabla temporal
        INSERT INTO #DatosProcesados
        SELECT 
            REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', '') AS numero_socio,
            LTRIM(RTRIM([Actividad])) AS actividad_nombre,
            [fecha de asistencia] AS fecha_asistencia,
            LTRIM(RTRIM([Asistencia])) AS asistencia,
            LTRIM(RTRIM([Profesor])) AS profesor_nombre,
            s.id_socio,
            a.id_actividad,
            p.id_persona AS id_persona_profesor,
            u.id_usuario AS id_usuario_profesor,
            CASE DATENAME(WEEKDAY, [fecha de asistencia])
                WHEN 'Monday' THEN 'lunes'
                WHEN 'Tuesday' THEN 'martes'
                WHEN 'Wednesday' THEN 'miercoles'
                WHEN 'Thursday' THEN 'jueves'
                WHEN 'Friday' THEN 'viernes'
                WHEN 'Saturday' THEN 'sabado'
                WHEN 'Sunday' THEN 'domingo'
                ELSE DATENAME(WEEKDAY, [fecha de asistencia])
            END AS dia,
            c.id_clase
        FROM #TempDatos
        INNER JOIN usuarios.socio s ON s.numero_socio = REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', '')
        INNER JOIN actividades.actividad a ON DIFFERENCE(a.nombre, LTRIM(RTRIM([Actividad]))) >= 3
        LEFT JOIN usuarios.persona p ON DIFFERENCE(p.nombre + ' ' + p.apellido, LTRIM(RTRIM([Profesor]))) >= 3
        LEFT JOIN usuarios.usuario u ON u.id_persona = p.id_persona
        LEFT JOIN actividades.clase c ON c.id_actividad = a.id_actividad 
                                    AND c.dia = CASE DATENAME(WEEKDAY, [fecha de asistencia])
                                        WHEN 'Monday' THEN 'lunes'
                                        WHEN 'Tuesday' THEN 'martes'
                                        WHEN 'Wednesday' THEN 'miercoles'
                                        WHEN 'Thursday' THEN 'jueves'
                                        WHEN 'Friday' THEN 'viernes'
                                        WHEN 'Saturday' THEN 'sabado'
                                        WHEN 'Sunday' THEN 'domingo'
                                        ELSE DATENAME(WEEKDAY, [fecha de asistencia])
                                    END
        WHERE [Nro de Socio] IS NOT NULL
          AND LTRIM(RTRIM([Nro de Socio])) <> ''
          AND [Actividad] IS NOT NULL
          AND LTRIM(RTRIM([Actividad])) <> ''
          AND [fecha de asistencia] IS NOT NULL
          AND s.id_socio IS NOT NULL
          AND a.id_actividad IS NOT NULL;
        
        -- Crear personas (profesores) si no existen
        INSERT INTO usuarios.persona (nombre, apellido)
        SELECT DISTINCT 
            CASE 
                WHEN CHARINDEX(' ', dp.profesor_nombre) > 0 THEN
                    LEFT(dp.profesor_nombre, CHARINDEX(' ', dp.profesor_nombre) - 1)
                ELSE
                    dp.profesor_nombre
            END AS nombre,
            CASE 
                WHEN CHARINDEX(' ', dp.profesor_nombre) > 0 THEN
                    SUBSTRING(dp.profesor_nombre, CHARINDEX(' ', dp.profesor_nombre) + 1, LEN(dp.profesor_nombre))
                ELSE
                    ''
            END AS apellido
        FROM #DatosProcesados dp
        WHERE dp.id_persona_profesor IS NULL
          AND dp.profesor_nombre IS NOT NULL
          AND LTRIM(RTRIM(dp.profesor_nombre)) <> ''
          AND NOT EXISTS (
              SELECT 1 FROM usuarios.persona p 
              WHERE DIFFERENCE(p.nombre + ' ' + p.apellido, dp.profesor_nombre) >= 3
          );
        
        -- Crear usuarios (profesores) si no existen
        INSERT INTO usuarios.usuario (id_persona, username, password_hash)
        SELECT DISTINCT 
            p.id_persona,
            LOWER(REPLACE(p.nombre, ' ', '')) + '.' + LOWER(REPLACE(p.apellido, ' ', '')) AS username,
            'default_hash' AS password_hash
        FROM usuarios.persona p
        INNER JOIN #DatosProcesados dp ON DIFFERENCE(p.nombre + ' ' + p.apellido, dp.profesor_nombre) >= 3
        WHERE dp.id_usuario_profesor IS NULL
          AND p.id_persona IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM usuarios.usuario u WHERE u.id_persona = p.id_persona
          );
        
        -- Crear clases si no existen
        INSERT INTO actividades.clase (id_actividad, id_categoria, dia, horario, id_usuario)
        SELECT DISTINCT 
            dp.id_actividad,
            s.id_categoria,
            dp.dia,
            '07:00' AS horario, -- Horario por defecto
            u.id_usuario
        FROM #DatosProcesados dp
        INNER JOIN usuarios.socio s ON s.id_socio = dp.id_socio
        INNER JOIN usuarios.usuario u ON u.id_persona = dp.id_persona_profesor
        WHERE dp.id_clase IS NULL
          AND s.id_categoria IS NOT NULL
          AND u.id_usuario IS NOT NULL
          AND dp.dia IN ('lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo')
          AND dp.id_persona_profesor IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM actividades.clase c 
              WHERE c.id_actividad = dp.id_actividad 
                AND c.dia = dp.dia
                AND c.id_categoria = s.id_categoria
          );
        
        -- Actualizar datos procesados con IDs de profesores y clases
        UPDATE #DatosProcesados
        SET 
            id_persona_profesor = p.id_persona,
            id_usuario_profesor = u.id_usuario,
            id_clase = c.id_clase
        FROM #DatosProcesados dp
        LEFT JOIN usuarios.persona p ON DIFFERENCE(p.nombre + ' ' + p.apellido, dp.profesor_nombre) >= 3
        LEFT JOIN usuarios.usuario u ON u.id_persona = p.id_persona
        LEFT JOIN actividades.clase c ON c.id_actividad = dp.id_actividad 
                                    AND c.dia = dp.dia
        WHERE dp.dia IN ('lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo');
        
        -- Procesa los datos con CTE
        WITH DatosProcesados AS (
            SELECT 
                dp.id_socio,
                dp.id_actividad,
                dp.fecha_asistencia,
                dp.asistencia,
                dp.id_clase
            FROM #DatosProcesados dp
            WHERE dp.id_socio IS NOT NULL
              AND dp.id_actividad IS NOT NULL
              AND dp.fecha_asistencia IS NOT NULL
              AND dp.asistencia IS NOT NULL
              AND LTRIM(RTRIM(dp.asistencia)) <> ''
        )
        -- Inserta registros nuevos
        INSERT INTO actividades.actividad_socio (id_socio, id_actividad, presentismo, fecha)
        SELECT 
            dp.id_socio,
            dp.id_actividad,
            dp.asistencia,
            dp.fecha_asistencia
        FROM DatosProcesados dp
        WHERE NOT EXISTS (
            SELECT 1 FROM actividades.actividad_socio as2 
            WHERE as2.id_socio = dp.id_socio 
              AND as2.id_actividad = dp.id_actividad
              AND as2.fecha = dp.fecha_asistencia
        );
        
        -- Actualiza registros existentes
        UPDATE actividades.actividad_socio
        SET 
            presentismo = dp.asistencia
        FROM (
            SELECT 
                dp.id_socio,
                dp.id_actividad,
                dp.fecha_asistencia,
                dp.asistencia
            FROM #DatosProcesados dp
            WHERE dp.id_socio IS NOT NULL
              AND dp.id_actividad IS NOT NULL
              AND dp.fecha_asistencia IS NOT NULL
              AND dp.asistencia IS NOT NULL
              AND LTRIM(RTRIM(dp.asistencia)) <> ''
        ) dp
        WHERE actividades.actividad_socio.id_socio = dp.id_socio
          AND actividades.actividad_socio.id_actividad = dp.id_actividad
          AND actividades.actividad_socio.fecha = dp.fecha_asistencia;
        
        DROP TABLE #DatosProcesados;
        DROP TABLE #TempDatos;
        
        SELECT 'Éxito' AS Resultado, 'Importación de presentismo completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;
        IF OBJECT_ID('tempdb..#DatosProcesados') IS NOT NULL
            DROP TABLE #DatosProcesados;
            
        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END
GO

-- IMPORTACION Y PRUEBAS
EXEC actividades.ImportarCategorias 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
select * from actividades.categoria
GO

EXEC usuarios.ImportarSocios'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
select s.*, os.descripcion AS obra_social_descripcion, os.nro_telefono AS obra_social_telefono
FROM usuarios.socio s
LEFT JOIN usuarios.obra_social os ON s.id_obra_social = os.id_obra_social
GO

EXEC actividades.ImportarActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
SELECT * FROM actividades.actividad
GO

-- Clima 2024
EXEC facturacion.ImportarClima 
    @RutaBase = 'C:\Users\tomas\Desktop\proyecto-BDA\docs\',
    @Anio = 2024;
-- Clima 2025
EXEC facturacion.ImportarClima 
    @RutaBase = 'C:\Users\tomas\Desktop\proyecto-BDA\docs\',
    @Anio = 2025;
select * from facturacion.clima 
GO

EXEC actividades.ImportarCostosPileta
     @RutaArchivo = 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx',
     @id_pileta = 1;
     SELECT * FROM actividades.costo
GO

EXEC usuarios.importarGrupoFamiliar 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
SELECT * FROM usuarios.grupo_familiar
GO


EXEC facturacion.ImportarFacturas 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
SELECT * FROM facturacion.factura;
GO

EXEC actividades.ImportarPresentismoActividades 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx'
SELECT * FROM actividades.actividad_socio
SELECT * FROM usuarios.usuario
GO

/*
USE Com5600G01;
GO

-- Importar categorías
EXEC actividades.ImportarCategorias 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx';
SELECT * FROM actividades.categoria;
GO

-- Importar socios
EXEC usuarios.ImportarSocios 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx';
SELECT 
    s.*, 
    os.descripcion AS obra_social_descripcion, 
    os.nro_telefono AS obra_social_telefono
FROM usuarios.socio s
LEFT JOIN usuarios.obra_social os ON s.id_obra_social = os.id_obra_social;
GO

-- Importar actividades
EXEC actividades.ImportarActividades 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx';
SELECT * FROM actividades.actividad;
GO

-- Importar clima 2024
EXEC facturacion.ImportarClima 
    @RutaBase = 'C:\Users\Usuario\Desktop\Importaciones\',
    @Anio = 2024;
GO

-- Importar clima 2025
EXEC facturacion.ImportarClima 
    @RutaBase = 'C:\Users\Usuario\Desktop\Importaciones\',
    @Anio = 2025;
GO

SELECT * FROM facturacion.clima;
GO

-- Importar costos de pileta
EXEC actividades.ImportarCostosPileta
    @RutaArchivo = 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx',
    @id_pileta = 1;
GO

SELECT * FROM actividades.costo;
GO

-- Importar grupo familiar
EXEC usuarios.importarGrupoFamiliar 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx';
SELECT * FROM usuarios.grupo_familiar;
GO

-- Importar facturas
EXEC facturacion.ImportarFacturas 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx';
SELECT * FROM facturacion.factura;
GO

-- Importar presentismo en actividades
EXEC actividades.ImportarPresentismoActividades 'C:\Users\Usuario\Desktop\Importaciones\Datos socios.xlsx';
GO

SELECT * FROM actividades.actividad_socio;
SELECT * FROM usuarios.usuario;
GO

*/