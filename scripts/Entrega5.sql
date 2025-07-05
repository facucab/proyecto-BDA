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
            [Valor cuota]    DECIMAL(10, 2),
            [Vigente hasta]  DATE
        );

        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos ([Categoria socio], [Valor cuota], [Vigente hasta])
            SELECT [Categoria socio], [Valor cuota], [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B10:D13]'')';
        EXEC sp_executesql @SQL; -- Importa los registros

        BEGIN TRANSACTION;

        -- INSERTAR CATEGORÍAS NUEVAS (que NO existían), ignorando filas inválidas
        INSERT INTO actividades.categoria (nombre_categoria, costo_membrecia, vigencia)
        SELECT
            LOWER(LTRIM(RTRIM(t.[Categoria socio]))),
            t.[Valor cuota],
            t.[Vigente hasta]
        FROM #TempDatos AS t
        LEFT JOIN actividades.categoria AS c
            ON LOWER(c.nombre_categoria) = LOWER(LTRIM(RTRIM(t.[Categoria socio])))
        WHERE t.[Categoria socio]   IS NOT NULL
          AND LTRIM(RTRIM(t.[Categoria socio])) <> ''
          AND t.[Valor cuota]      > 0
          AND t.[Vigente hasta]    IS NOT NULL
          AND c.id_categoria       IS NULL;

        -- ACTUALIZAR CATEGORÍAS EXISTENTES, ignorando filas inválidas
        UPDATE c
        SET
            c.costo_membrecia = t.[Valor cuota],
            c.vigencia        = t.[Vigente hasta]
        FROM actividades.categoria AS c
        INNER JOIN #TempDatos AS t
            ON LOWER(c.nombre_categoria) = LOWER(LTRIM(RTRIM(t.[Categoria socio])))
        WHERE t.[Categoria socio]   IS NOT NULL
          AND LTRIM(RTRIM(t.[Categoria socio])) <> ''
          AND t.[Valor cuota]      > 0
          AND t.[Vigente hasta]    IS NOT NULL;

        COMMIT TRANSACTION;

        -- Contar resultados
        DECLARE @insertados   INT = (
            SELECT COUNT(*)
            FROM #TempDatos AS t
            LEFT JOIN actividades.categoria AS c
              ON LOWER(c.nombre_categoria) = LOWER(LTRIM(RTRIM(t.[Categoria socio])))
            WHERE t.[Categoria socio]   IS NOT NULL
              AND LTRIM(RTRIM(t.[Categoria socio])) <> ''
              AND t.[Valor cuota]      > 0
              AND t.[Vigente hasta]    IS NOT NULL
              AND c.id_categoria       IS NULL
        ), 
        @actualizados INT = (
            SELECT COUNT(*)
            FROM #TempDatos AS t
            INNER JOIN actividades.categoria AS c
              ON LOWER(c.nombre_categoria) = LOWER(LTRIM(RTRIM(t.[Categoria socio])))
            WHERE t.[Categoria socio] IS NOT NULL
        );

        -- Limpieza de temp table
        DROP TABLE #TempDatos;

        SELECT
            'Éxito' AS Resultado,
            'Importación completada. Insertados: ' 
              + CAST(@insertados   AS VARCHAR(10))
              + ', Actualizados: ' 
              + CAST(@actualizados AS VARCHAR(10)) AS Mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Cleanup en caso de error
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT
            'Error' AS Resultado,
            'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO
    
-- Importar Socios - FUNCIONANDO
CREATE OR ALTER PROCEDURE usuarios.ImportarSocios
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQL NVARCHAR(MAX);

    BEGIN TRY
        -- Tabla temporal para poner los datos
        CREATE TABLE #TempDatos ( 
            [Nro de Socio]                    VARCHAR(20),
            [Nombre]                          NVARCHAR(50),
            [ apellido]                       NVARCHAR(50),
            [ DNI]                            VARCHAR(20),
            [ email personal]                 VARCHAR(320),
            [ fecha de nacimiento]            DATE,
            [ teléfono de contacto]           VARCHAR(50),
            [ teléfono de contacto emergencia] VARCHAR(50),
            [ Nombre de la obra social o prepaga] NVARCHAR(100),
            [nro# de socio obra social/prepaga ] VARCHAR(50),
            [teléfono de contacto de emergencia ] VARCHAR(50)
        );

        -- Arma el SQL para la ruta
        SET @SQL = N'
            INSERT INTO #TempDatos (
                [Nro de Socio],[Nombre],[ apellido],[ DNI],
                [ email personal],[ fecha de nacimiento],
                [ teléfono de contacto],[ teléfono de contacto emergencia],
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
                CASE WHEN ISNUMERIC([ teléfono de contacto]) = 1 AND [ teléfono de contacto] IS NOT NULL
                     THEN FORMAT(CAST([ teléfono de contacto] AS BIGINT), ''0'')
                     ELSE CAST([ teléfono de contacto] AS VARCHAR(50))
                END,
                CASE WHEN ISNUMERIC([ teléfono de contacto emergencia]) = 1 AND [ teléfono de contacto emergencia] IS NOT NULL
                     THEN FORMAT(CAST([ teléfono de contacto emergencia] AS BIGINT), ''0'')
                     ELSE CAST([ teléfono de contacto emergencia] AS VARCHAR(50))
                END,
                [ Nombre de la obra social o prepaga],
                [nro# de socio obra social/prepaga ],
                CASE WHEN ISNUMERIC([teléfono de contacto de emergencia ]) = 1 AND [teléfono de contacto de emergencia ] IS NOT NULL
                     THEN FORMAT(CAST([teléfono de contacto de emergencia ] AS BIGINT), ''0'')
                     ELSE CAST([teléfono de contacto de emergencia ] AS VARCHAR(50))
                END
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;TypeGuessRows=0;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Responsables de Pago$]'')';
        EXEC sp_executesql @SQL;  -- Importa los registros

        -- Antes de insertar, normalizar los campos de texto
        UPDATE #TempDatos
        SET
            [Nro de Socio]                    = REPLACE(LTRIM(RTRIM([Nro de Socio])), 'SN-', ''),
            [ DNI]                            = REPLACE(REPLACE(LTRIM(RTRIM([ DNI])), '.', ''), '-', ''),
            [ email personal]                 = LOWER(REPLACE(LTRIM(RTRIM([ email personal])), ' ', '')),
            [ Nombre de la obra social o prepaga] = LTRIM(RTRIM([ Nombre de la obra social o prepaga]));

        BEGIN TRANSACTION;

        -- PASO 1: Procesar obras sociales
        -- 1.1 Crear obras sociales nuevas
        INSERT INTO usuarios.obra_social(descripcion, nro_telefono)
        SELECT DISTINCT
            UPPER(LTRIM(RTRIM(t.[ Nombre de la obra social o prepaga]))),
            COALESCE(t.[teléfono de contacto de emergencia ], '11')
        FROM #TempDatos AS t
        WHERE t.[ Nombre de la obra social o prepaga] IS NOT NULL
          AND LTRIM(RTRIM(t.[ Nombre de la obra social o prepaga])) <> ''
          AND NOT EXISTS (
              SELECT 1 FROM usuarios.obra_social os
              WHERE os.descripcion = UPPER(LTRIM(RTRIM(t.[ Nombre de la obra social o prepaga])))
          );

        -- 1.2 Actualizar teléfonos de obras sociales existentes
        UPDATE os
        SET nro_telefono = COALESCE(src.[teléfono de contacto de emergencia ], os.nro_telefono)
        FROM usuarios.obra_social AS os
        INNER JOIN (
            SELECT DISTINCT
                UPPER(LTRIM(RTRIM([ Nombre de la obra social o prepaga]))) AS descripcion,
                [teléfono de contacto de emergencia ]
            FROM #TempDatos
            WHERE [ Nombre de la obra social o prepaga] IS NOT NULL
              AND LTRIM(RTRIM([ Nombre de la obra social o prepaga])) <> ''
              AND [teléfono de contacto de emergencia ] IS NOT NULL
        ) AS src
          ON os.descripcion = src.descripcion;

        -- PASO 2: Agregar columnas calculadas a la tabla temporal
        ALTER TABLE #TempDatos ADD 
            id_persona_existente INT,
            id_obra_social_calc  INT,
            id_categoria_calc    INT,
            edad_calc            INT;

        -- Buscar personas existentes
        UPDATE t
        SET t.id_persona_existente = p.id_persona
        FROM #TempDatos AS t
        INNER JOIN usuarios.persona AS p
          ON p.dni = TRY_CAST(t.[ DNI] AS INT)
         AND p.activo = 1;

        -- Buscar obras sociales
        UPDATE t
        SET t.id_obra_social_calc = os.id_obra_social
        FROM #TempDatos AS t
        INNER JOIN usuarios.obra_social AS os
          ON os.descripcion = UPPER(LTRIM(RTRIM(t.[ Nombre de la obra social o prepaga])))
        WHERE t.[ Nombre de la obra social o prepaga] IS NOT NULL;

        -- Calcular edad y categoría
        UPDATE #TempDatos
        SET
            edad_calc = DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()),
            id_categoria_calc = CASE
                WHEN DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()) >= 18
                    THEN (SELECT id_categoria FROM actividades.categoria WHERE nombre_categoria = 'mayor')
                WHEN DATEDIFF(YEAR, [ fecha de nacimiento], GETDATE()) >= 13
                    THEN (SELECT id_categoria FROM actividades.categoria WHERE nombre_categoria = 'cadete')
                ELSE
                    (SELECT id_categoria FROM actividades.categoria WHERE nombre_categoria = 'menor')
            END
        WHERE [ fecha de nacimiento] IS NOT NULL;

        -- PASO 3: Crear personas nuevas
        ;WITH CTE_PersonasValidas AS (
            SELECT DISTINCT
                dni_int   = TRY_CAST([ DNI] AS INT),
                nombre    = UPPER(LEFT([Nombre],1)) + LOWER(SUBSTRING([Nombre],2,LEN([Nombre]))),
                apellido  = UPPER(LEFT([ apellido],1)) + LOWER(SUBSTRING([ apellido],2,LEN([ apellido]))),
                email     = [ email personal],
                fecha_nac = [ fecha de nacimiento],
                telefono  = [ teléfono de contacto]
            FROM #TempDatos
            WHERE TRY_CAST([ DNI] AS INT)    IS NOT NULL
              AND [ fecha de nacimiento]      IS NOT NULL
        )
        INSERT INTO usuarios.persona(dni, nombre, apellido, email, fecha_nac, telefono, activo)
        SELECT
            vp.dni_int,
            vp.nombre,
            vp.apellido,
            LOWER(vp.email),
            vp.fecha_nac,
            vp.telefono,
            1
        FROM CTE_PersonasValidas AS vp
        WHERE NOT EXISTS (
            SELECT 1 FROM usuarios.persona p WHERE p.dni = vp.dni_int
        );

        -- Actualizar los IDs de las personas recién creadas
        UPDATE t
        SET t.id_persona_existente = p.id_persona
        FROM #TempDatos AS t
        INNER JOIN usuarios.persona AS p
          ON p.dni = TRY_CAST(t.[ DNI] AS INT)
        WHERE t.id_persona_existente IS NULL;

        -- PASO 4: Crear socios nuevos
        ;WITH CTE_SociosValidos AS (
            SELECT
                numero_socio       = [Nro de Socio],
                id_persona         = id_persona_existente,
                telefono_emergencia= [ teléfono de contacto emergencia],
                obra_nro_socio     = [nro# de socio obra social/prepaga ],
                id_obra_social     = id_obra_social_calc,
                id_categoria       = id_categoria_calc
            FROM #TempDatos
            WHERE [Nro de Socio] IS NOT NULL
              AND id_persona_existente IS NOT NULL
        )
        INSERT INTO usuarios.socio(
            numero_socio, id_persona, telefono_emergencia,
            obra_nro_socio, id_obra_social, id_categoria, id_grupo
        )
        SELECT
            vs.numero_socio,
            vs.id_persona,
            vs.telefono_emergencia,
            vs.obra_nro_socio,
            vs.id_obra_social,
            vs.id_categoria,
            NULL
        FROM CTE_SociosValidos AS vs
        WHERE NOT EXISTS (
            SELECT 1 FROM usuarios.socio s WHERE s.numero_socio = vs.numero_socio
        );

        COMMIT TRANSACTION;

        -- Cleanup de tabla temporal
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Resultado, 'Proceso completado correctamente' AS Mensaje;

    END TRY
    BEGIN CATCH
        -- Cleanup en caso de error general
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado, 
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO

-- Importar Grupo Familiar - FUNCIONANDO
CREATE OR ALTER PROCEDURE usuarios.importarGrupoFamiliar
    @path NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Tabla temporal para almacenar los datos importados
        CREATE TABLE #tempGrupoFamiliar (
            nro_de_socio             VARCHAR(7),
            nro_de_socio_RP          VARCHAR(7),
            nombre                   VARCHAR(35),
            apellido                 VARCHAR(35),
            dni                      INT,
            email_personal           VARCHAR(255),
            fec_nac                  DATE,
            tel_contacto             VARCHAR(20),
            tel_emerg                VARCHAR(20),
            nom_obra_social          VARCHAR(35),
            nro_socio_obra_social    VARCHAR(35),
            tel_cont_emerg           VARCHAR(80)
        );

        DECLARE @sql NVARCHAR(MAX);

        -- Consulta con los encabezados EXACTOS como aparecen en el excel
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
                CONVERT(DATE, [ fecha de nacimiento], 103),
                [ teléfono de contacto],
                CAST([ teléfono de contacto emergencia] AS VARCHAR(20)),
                RTRIM(LTRIM(LOWER([ Nombre de la obra social o prepaga]))),
                [nro# de socio obra social/prepaga ],
                [teléfono de contacto de emergencia ]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @path + ''',
                ''SELECT * FROM [Grupo Familiar$]''
            ) AS ExcelData;';
        EXEC sp_executesql @sql; -- Importa los registros

        BEGIN TRANSACTION;

        -- Normalizar campos y filtrar filas con responsable válido
        ;WITH CTE_Normalizado AS (
            SELECT
                ROW_NUMBER() OVER(ORDER BY (SELECT 1))                   AS rn,
                SUBSTRING(nro_de_socio, CHARINDEX('-', nro_de_socio)+1, 7)      AS nro_socio,
                SUBSTRING(nro_de_socio_RP, CHARINDEX('-', nro_de_socio_RP)+1,7) AS nro_socio_rp,
                nombre,
                apellido,
                dni,
                email_personal,
                fec_nac,
                ISNULL(tel_contacto, '11')                                AS tel_contacto,
                tel_emerg,
                nom_obra_social,
                nro_socio_obra_social,
                tel_cont_emerg
            FROM #tempGrupoFamiliar
            WHERE nro_de_socio IS NOT NULL
              AND nro_de_socio_RP IS NOT NULL
        ), CTE_Validos AS (
            SELECT n.*
            FROM CTE_Normalizado n
            INNER JOIN usuarios.socio srp
              ON srp.numero_socio = n.nro_socio_rp
        )

        -- Crear grupos familiares faltantes
        MERGE usuarios.grupo_familiar AS target
        USING (
            SELECT DISTINCT nro_socio_rp AS id_socio_rp
            FROM CTE_Validos
        ) AS src
          ON target.id_socio_rp = src.id_socio_rp
        WHEN NOT MATCHED THEN
          INSERT (id_socio_rp) VALUES (src.id_socio_rp);

        -- Crear obras sociales faltantes
        MERGE usuarios.obra_social AS target
        USING (
            SELECT DISTINCT UPPER(nom_obra_social) AS descripcion
            FROM CTE_Validos
            WHERE nom_obra_social IS NOT NULL AND nom_obra_social <> ''
        ) AS src_os
          ON target.descripcion = src_os.descripcion
        WHEN NOT MATCHED THEN
          INSERT (descripcion, nro_telefono) VALUES (src_os.descripcion, '11');

        -- Preparar datos finales con ID de grupo, obra y categoría
        ;WITH CTE_Datos AS (
            SELECT
                v.*,
                gf.id_grupo_familiar,
                os.id_obra_social,
                CASE 
                    WHEN DATEDIFF(YEAR, v.fec_nac, GETDATE()) > 17 THEN 
                        (SELECT id_categoria FROM actividades.categoria WHERE LOWER(nombre_categoria) = 'mayor')
                    WHEN DATEDIFF(YEAR, v.fec_nac, GETDATE()) > 12 THEN 
                        (SELECT id_categoria FROM actividades.categoria WHERE LOWER(nombre_categoria) = 'cadete')
                    ELSE 
                        (SELECT id_categoria FROM actividades.categoria WHERE LOWER(nombre_categoria) = 'menor')
                END AS id_categoria
            FROM CTE_Validos v
            INNER JOIN usuarios.grupo_familiar gf 
                ON gf.id_socio_rp = v.nro_socio_rp
            LEFT JOIN usuarios.obra_social os 
                ON UPPER(os.descripcion) = UPPER(v.nom_obra_social)
        )

        -- Insertar socios nuevos (ignorando los ya existentes)
        INSERT INTO usuarios.socio (
            id_persona,
            dni,
            nombre,
            apellido,
            email,
            fecha_nac,
            telefono,
            numero_socio,
            telefono_emergencia,
            obra_nro_socio,
            id_obra_social,
            id_categoria,
            id_grupo
        )
        SELECT
            NULL,
            d.dni,
            d.nombre,
            d.apellido,
            d.email_personal,
            d.fec_nac,
            d.tel_contacto,
            d.nro_socio,
            d.tel_cont_emerg,
            d.nro_socio_obra_social,
            d.id_obra_social,
            d.id_categoria,
            d.id_grupo_familiar
        FROM CTE_Datos d
        LEFT JOIN usuarios.socio s 
          ON s.numero_socio = d.nro_socio
        WHERE s.numero_socio IS NULL;

        -- Actualizar sólo id_grupo en los socios que ya existen
        UPDATE s
        SET s.id_grupo = d.id_grupo_familiar
        FROM usuarios.socio s
        INNER JOIN CTE_Datos d 
          ON d.nro_socio = s.numero_socio;

        COMMIT TRANSACTION;

        DROP TABLE #tempGrupoFamiliar;

        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#tempGrupoFamiliar') IS NOT NULL
            DROP TABLE #tempGrupoFamiliar;

        SELECT 
            'ERROR' AS Resultado,
            ERROR_MESSAGE() AS Mensaje,
            ERROR_LINE() AS LineaError,
            ERROR_NUMBER() AS CodigoError;
    END CATCH;
END;
GO


-- Importar Actividades - FUNCIONANDO
CREATE OR ALTER PROCEDURE actividades.ImportarActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);

        -- Tabla temporal donde importar los datos
        CREATE TABLE #TempDatos (
            [Actividad]       VARCHAR(50),
            [Valor por mes]   DECIMAL(10,2),
            [Vigente hasta]   DATE
        );

        -- Arma el SQL dinámico
        SET @SQL = N'
            INSERT INTO #TempDatos ([Actividad], [Valor por mes], [Vigente hasta])
            SELECT [Actividad], [Valor por mes], [Vigente hasta]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [Tarifas$B2:D8]'')';
        EXEC sp_executesql @SQL; -- Importa los registros

        BEGIN TRANSACTION;

        -- CTE con filas válidas
        ;WITH CTE_Validas AS (
            SELECT
                [Actividad],
                [Valor por mes]
            FROM #TempDatos
            WHERE [Actividad]       IS NOT NULL
              AND LTRIM(RTRIM([Actividad])) <> ''
              AND [Valor por mes]   >  0
        )

        -- PASO 1: Insertar actividades nuevas (que no existen)
        INSERT INTO actividades.actividad(nombre, costo_mensual)
        SELECT
            v.[Actividad],
            v.[Valor por mes]
        FROM CTE_Validas AS v
        LEFT JOIN actividades.actividad AS a
            ON a.nombre = v.[Actividad]
        WHERE a.id_actividad IS NULL;

        -- PASO 2: Actualizar actividades existentes
        UPDATE a
        SET a.costo_mensual = v.[Valor por mes]
        FROM actividades.actividad AS a
        INNER JOIN CTE_Validas AS v
            ON a.nombre = v.[Actividad];

        COMMIT TRANSACTION;

        -- Cierra objetos
        DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Resultado, 'Importación de actividades completada' AS Mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        SELECT 'Error' AS Resultado,
               'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO

-- Importar Costos de Pileta - FUNCIONADO
EXEC actividades.CrearPileta 
    @detalle = 'Pileta prueba',
    @metro_cuadrado = 10;
GO
CREATE OR ALTER PROCEDURE actividades.ImportarCostosPileta
    @RutaArchivo    NVARCHAR(260),
    @id_pileta      INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @SQL NVARCHAR(MAX);

        -- Tabla temporal donde importar crudo
        CREATE TABLE #TempDatos (
            id          INT IDENTITY(1,1) PRIMARY KEY,
            [Concepto]  NVARCHAR(100), -- nombre de tarifa
            [Grupo]     NVARCHAR(100), -- adulto o menores
            [Socios]    NVARCHAR(100),
            [Invitados] NVARCHAR(100)
        );

        -- Arma el SQL dinámico e importa registros
        SET @SQL = N'
            INSERT INTO #TempDatos(Concepto, Grupo, Socios, Invitados)
            SELECT F1, F2, F3, F4
              FROM OPENROWSET(
                   ''Microsoft.ACE.OLEDB.12.0'',
                   ''Excel 12.0;HDR=NO;IMEX=1;TypeGuessRows=0;Database=' + @RutaArchivo + ''',
                   ''SELECT * FROM [Tarifas$B16:F22]''
              )';
        EXEC sp_executesql @SQL;

        -- Validar existencia de la pileta
        IF NOT EXISTS (SELECT 1 FROM actividades.pileta WHERE id_pileta = @id_pileta)
        BEGIN
            DROP TABLE #TempDatos;
            SELECT 'Error' AS Resultado, 'Pileta no encontrada.' AS Mensaje;
            RETURN;
        END;

        BEGIN TRANSACTION;

        -- CTEs para limpieza, mapeo y filtrado de filas válidas
        ;WITH CTE_Limpio AS (
            SELECT
                id,
                [Concepto]   AS conceptoBruto,
                [Grupo]      AS grupoBruto,
                [Socios]     AS sociosBruto,
                [Invitados]  AS invitadosBruto,
                -- Propagar el último Concepto no nulo
                (
                  SELECT TOP 1 Concepto
                  FROM #TempDatos t2
                  WHERE t2.id <= t1.id
                    AND LTRIM(RTRIM(t2.Concepto)) <> ''
                  ORDER BY t2.id DESC
                ) AS conceptoProp
            FROM #TempDatos t1
        ), CTE_Mapeado AS (
            SELECT
                id,
                conceptoProp                                      AS Concepto,
                CASE WHEN LOWER(grupoBruto) LIKE '%menor%' THEN 'men' ELSE 'adu' END AS tipo_grupo,
                CASE
                    WHEN LOWER(conceptoProp) LIKE '%dia%'  OR LOWER(conceptoProp) LIKE '%día%' THEN 'dia'
                    WHEN LOWER(conceptoProp) LIKE '%temporad%'                           THEN 'tem'
                    WHEN LOWER(conceptoProp) LIKE '%mes%'                                THEN 'mes'
                    ELSE NULL
                END                                                AS tipo,
                TRY_CAST(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(REPLACE(sociosBruto, CHAR(160), ''), ' ', ''), '$', ''), '.', ''),
                    ',', '.'
                  ) AS DECIMAL(10,2)
                )                                                AS precio_socios,
                ISNULL(
                  TRY_CAST(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(REPLACE(invitadosBruto, CHAR(160), ''), ' ', ''), '$', ''), '.', ''),
                      ',', '.'
                    ) AS DECIMAL(10,2)
                  ), 0
                )                                                AS precio_invitados
            FROM CTE_Limpio
        ), CTE_Validos AS (
            SELECT *
            FROM CTE_Mapeado
            WHERE tipo        IS NOT NULL
              AND tipo_grupo  IN ('adu','men')
              AND precio_socios    > 0
              AND precio_invitados >= 0
        )

        -- INSERTAR nuevos costos (que no existían)
        INSERT INTO actividades.costo(tipo, tipo_grupo, precio_socios, precio_invitados, id_pileta)
        SELECT
            v.tipo,
            v.tipo_grupo,
            v.precio_socios,
            v.precio_invitados,
            @id_pileta
        FROM CTE_Validos v
        LEFT JOIN actividades.costo c
          ON c.tipo       = v.tipo
         AND c.tipo_grupo = v.tipo_grupo
         AND c.id_pileta   = @id_pileta
        WHERE c.id_costo IS NULL;

        -- ACTUALIZAR costos existentes
        UPDATE c
        SET
            c.precio_socios    = v.precio_socios,
            c.precio_invitados = v.precio_invitados
        FROM actividades.costo c
        INNER JOIN CTE_Validos v
          ON c.tipo       = v.tipo
         AND c.tipo_grupo = v.tipo_grupo
         AND c.id_pileta   = @id_pileta;

        COMMIT TRANSACTION;

        -- Cleanup de temp table
        DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL DROP TABLE #TempDatos;
        SELECT 'Error' AS Resultado, 'Error general en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO



-- Importar Clima - FUNCIONANDO
CREATE OR ALTER PROCEDURE facturacion.ImportarClima
    @RutaBase NVARCHAR(300) = '.\docs\',  -- Ruta base donde están los archivos
    @Anio      INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Construir la ruta del archivo dinámicamente
        DECLARE @RutaArchivo NVARCHAR(400) 
            = @RutaBase 
            + 'open-meteo-buenosaires_' 
            + CAST(@Anio AS NVARCHAR(4)) 
            + '.csv';
        
        -- Tabla temporal para importar los datos del CSV
        CREATE TABLE #TempClima (
            [time]                 VARCHAR(20),
            [temperature_2m]       VARCHAR(20) NULL,
            [rain_mm]              VARCHAR(20) NULL,
            [relative_humidity_2m] VARCHAR(20) NULL,
            [wind_speed_10m]       VARCHAR(20) NULL
        );
        
        DECLARE @SQL NVARCHAR(MAX);
        -- Importar datos desde el CSV, saltando las primeras 2 líneas (encabezados)
        SET @SQL = N'
            BULK INSERT #TempClima
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIRSTROW        = 3,
                FIELDTERMINATOR = '','',
                ROWTERMINATOR   = ''\n'',
                CODEPAGE        = ''65001'',
                TABLOCK
            );';
        EXEC sp_executesql @SQL;
        
        BEGIN TRANSACTION;
        
        -- CTE que limpia y parsea las filas, descartando las que queden NULL
        ;WITH CTE_Raw AS (
            SELECT
                LTRIM(RTRIM([time])) AS time_str,
                TRY_CAST(REPLACE([rain_mm], ',', '.') AS DECIMAL(5,2)) AS lluvia_raw
            FROM #TempClima
            WHERE [time] IS NOT NULL
              AND LTRIM(RTRIM([time])) <> ''
        ), CTE_Parsed AS (
            SELECT
                TRY_CAST(LEFT(time_str,10) + ' ' + RIGHT(time_str,5) AS SMALLDATETIME) AS fecha,
                lluvia_raw AS lluvia
            FROM CTE_Raw
        ), CTE_Validos AS (
            SELECT fecha, lluvia
            FROM CTE_Parsed
            WHERE fecha  IS NOT NULL
              AND fecha <= GETDATE()
              AND lluvia IS NOT NULL
              AND lluvia >= 0
        )
        -- Insertar en bloque sólo las filas válidas
        INSERT INTO facturacion.clima (fecha, lluvia)
        SELECT fecha, lluvia
        FROM CTE_Validos;
        
        COMMIT TRANSACTION;
        
        DROP TABLE #TempClima;
        
        SELECT 'Éxito' AS Resultado, 'Importación completada' AS Mensaje;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#TempClima') IS NOT NULL
            DROP TABLE #TempClima;
        
        SELECT 'Error' AS Resultado, 
               'Error en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO


-- Importar Facturas - FUNCIONANDO
CREATE OR ALTER PROCEDURE facturacion.ImportarFacturas
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- 1) Cargar datos crudos en tabla temporal
        CREATE TABLE #TempDatos (
            [Id de pago]           BIGINT,
            [fecha]                DATE,
            [Responsable de pago]  VARCHAR(20),
            [Valor]                DECIMAL(10,2),
            [Medio de pago]        VARCHAR(50)
        );

        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO #TempDatos(
                [Id de pago],[fecha],[Responsable de pago],[Valor],[Medio de pago]
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
                ''SELECT * FROM [pago cuotas$A1:E10000]''
            )';
        EXEC sp_executesql @SQL;  -- Importa los registros

        BEGIN TRANSACTION;

        -- 2) Normalizar texto
        UPDATE #TempDatos
        SET
            [Responsable de pago] = LTRIM(RTRIM(REPLACE([Responsable de pago], 'SN-', ''))),
            [Medio de pago]       = LTRIM(RTRIM([Medio de pago]));

        -- 3) Crear nuevos métodos de pago (si no existen)
        INSERT INTO facturacion.metodo_pago(nombre)
        SELECT DISTINCT mp.nombre
        FROM (
            SELECT LTRIM(RTRIM([Medio de pago])) AS nombre
            FROM #TempDatos
            WHERE [Medio de pago] IS NOT NULL
              AND LTRIM(RTRIM([Medio de pago])) <> ''
        ) AS mp
        WHERE NOT EXISTS (
            SELECT 1
            FROM facturacion.metodo_pago m
            WHERE LOWER(m.nombre) = LOWER(mp.nombre)
        );

        -- 4) Determinar filas válidas y hacer insert masivo
        DECLARE @total   INT = (
            SELECT COUNT(*)
            FROM #TempDatos
            WHERE [Responsable de pago] IS NOT NULL
              AND LTRIM(RTRIM([Responsable de pago])) <> ''
        );

        DECLARE @validos INT = (
            SELECT COUNT(*)
            FROM #TempDatos td
            INNER JOIN usuarios.socio  s
                ON s.numero_socio = td.[Responsable de pago]
               AND s.activo = 1
            LEFT JOIN facturacion.metodo_pago m
                ON LOWER(m.nombre) = LOWER(td.[Medio de pago])
            WHERE td.[fecha]  IS NOT NULL
              AND td.[Valor]  > 0
        );

        -- Insertar facturas válidas de una sola vez 
        INSERT INTO facturacion.factura (
            id_persona,
            id_metodo_pago,
            estado_pago,
            monto_a_pagar
        )
        SELECT
            s.id_persona,
            m.id_metodo_pago,
            'Pendiente',
            td.[Valor]
        FROM #TempDatos td
        INNER JOIN usuarios.socio  s
            ON s.numero_socio = td.[Responsable de pago]
           AND s.activo = 1
        LEFT JOIN facturacion.metodo_pago m
            ON LOWER(m.nombre) = LOWER(td.[Medio de pago])
        WHERE td.[fecha]  IS NOT NULL
          AND td.[Valor]  > 0;

        COMMIT TRANSACTION;

        DROP TABLE #TempDatos;

        -- 5) Reporte final
        SELECT
            'Exito' AS Resultado,
            'Facturas importadas: ' + CAST(@validos   AS VARCHAR(10))
          + '. Filas inválidas ignoradas: ' + CAST(@total - @validos AS VARCHAR(10))
          AS Mensaje;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL DROP TABLE #TempDatos;

        SELECT
            'Error' AS Resultado,
            'Error en el proceso: ' + ERROR_MESSAGE() AS Mensaje;
        RETURN -1;
    END CATCH
END;
GO


-- Importar Presentismo a Actividades - FUNCIONANDO
CREATE OR ALTER PROCEDURE actividades.ImportarPresentismoActividades
    @RutaArchivo NVARCHAR(260)
AS
BEGIN
    SET NOCOUNT ON;
    SET LANGUAGE Spanish; -- Por las dudas

    BEGIN TRY
        -- 1) Cargo crudo desde Excel
        CREATE TABLE #TempDatos (
            [Nro de Socio]          VARCHAR(20),
            [Actividad]             NVARCHAR(100),
            [fecha de asistencia]   DATE,
            [Asistencia]            VARCHAR(15),
            [Profesor]              NVARCHAR(100)
        );

        DECLARE @SQL NVARCHAR(MAX) = N'
            INSERT INTO #TempDatos (
                [Nro de Socio], [Actividad], [fecha de asistencia], [Asistencia], [Profesor]
            )
            SELECT
                [Nro de Socio],
                [Actividad],
                [fecha de asistencia],
                [Asistencia],
                [Profesor]
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.12.0'',
                ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
                ''SELECT * FROM [presentismo_actividades$]''
            )';
        EXEC sp_executesql @SQL; -- Ejecuta la sentencia

        BEGIN TRANSACTION;

        -- 2) Normalizar y filtrar filas válidas
        ;WITH CTE_Normalizado AS (
            SELECT
                ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS fila,
                -- Quitar SN- y espacios
                LTRIM(RTRIM(REPLACE([Nro de Socio], 'SN-', ''))) AS nroSocio,
                LTRIM(RTRIM([Actividad]))             AS actividad,
                [fecha de asistencia]                  AS fecha,
                LTRIM(RTRIM([Asistencia]))             AS asistencia,
                LTRIM(RTRIM([Profesor]))               AS profesor
            FROM #TempDatos
        ), CTE_Mapeo AS (
            SELECT
                n.fila,
                n.nroSocio,
                n.actividad,
                n.fecha,
                n.asistencia,
                n.profesor,
                -- Mapear socio
                s.id_socio,
                s.id_categoria,
                -- Mapear actividad por fonético (DIFFERENCE ≥ 3)
                a.id_actividad,
                -- Separar nombre/apellido de profesor
                prof_nombre   = LEFT(n.profesor,  CHARINDEX(' ', n.profesor + ' ') - 1),
                prof_apellido = CASE 
                                  WHEN CHARINDEX(' ', n.profesor) > 0
                                  THEN SUBSTRING(n.profesor, CHARINDEX(' ',n.profesor)+1, 100)
                                  ELSE ''
                                END
            FROM CTE_Normalizado n
            LEFT JOIN usuarios.socio     s ON s.numero_socio = n.nroSocio
            LEFT JOIN actividades.actividad a 
                ON DIFFERENCE(a.nombre, n.actividad) >= 3
            WHERE n.nroSocio   <> ''
              AND n.actividad <> ''
              AND n.fecha     IS NOT NULL
        ), CTE_Validos AS (
            -- Sólo las filas con socio y actividad mapeados
            SELECT *
            FROM CTE_Mapeo
            WHERE id_socio      IS NOT NULL
              AND id_actividad  IS NOT NULL
        )

        --------
        -- 3) Insertar profesores (PERSONA) nuevos, ignorando los ya existentes
        --------
        INSERT INTO usuarios.persona (dni, nombre, apellido, email, fecha_nac, telefono, activo)
        SELECT
            NULL,  -- sin DNI
            vm.prof_nombre,
            vm.prof_apellido,
            NULL,  -- sin email
            NULL,  -- sin fecha_nac
            NULL,  -- sin teléfono
            1
        FROM (
            SELECT DISTINCT prof_nombre, prof_apellido
            FROM CTE_Validos
        ) AS vm
        LEFT JOIN usuarios.persona p
          ON LOWER(p.nombre)   = LOWER(vm.prof_nombre)
         AND LOWER(p.apellido) = LOWER(vm.prof_apellido)
        WHERE p.id_persona IS NULL;


        -- 4) Insertar usuarios (USUARIO) nuevos para esos profesores
        INSERT INTO usuarios.usuario (
            id_persona, dni, nombre, apellido, email, fecha_nac, telefono, username, password_hash
        )
        SELECT
            p.id_persona,
            NULL,  -- sin DNI
            p.nombre,
            p.apellido,
            NULL,  -- sin email
            NULL,  -- sin fecha_nac
            NULL,  -- sin teléfono
            LOWER(REPLACE(p.nombre,' ',''))
              + '.' +
            LOWER(REPLACE(p.apellido,' ','')),
            'default_hash'
        FROM (
            SELECT DISTINCT prof_nombre, prof_apellido
            FROM CTE_Validos
        ) AS vm
        INNER JOIN usuarios.persona p
          ON LOWER(p.nombre)   = LOWER(vm.prof_nombre)
         AND LOWER(p.apellido) = LOWER(vm.prof_apellido)
        LEFT JOIN usuarios.usuario u
          ON u.id_persona = p.id_persona
        WHERE u.id_usuario IS NULL;


        -- 5) Insertar clases nuevas si no existen
        INSERT INTO actividades.clase (
            id_actividad, id_categoria, dia, horario, id_usuario
        )
        SELECT DISTINCT
            vm.id_actividad,
            vm.id_categoria,
            DATENAME(WEEKDAY, vm.fecha),
            '07:00',  -- horario por defecto
            u.id_usuario
        FROM CTE_Validos vm
        INNER JOIN usuarios.persona p
          ON LOWER(p.nombre)   = LOWER(vm.prof_nombre)
         AND LOWER(p.apellido) = LOWER(vm.prof_apellido)
        INNER JOIN usuarios.usuario u
          ON u.id_persona = p.id_persona
        LEFT JOIN actividades.clase c
          ON c.id_actividad = vm.id_actividad
         AND c.dia          = DATENAME(WEEKDAY, vm.fecha)
        WHERE c.id_clase IS NULL;


        -- 6) Insertar presentismo en bloque, ignorando duplicados
        INSERT INTO actividades.actividad_socio (
            id_socio, id_actividad, presentismo, fecha
        )
        SELECT
            vm.id_socio,
            vm.id_actividad,
            vm.asistencia,
            vm.fecha
        FROM CTE_Validos vm
        LEFT JOIN actividades.actividad_socio ps
          ON ps.id_socio      = vm.id_socio
         AND ps.id_actividad  = vm.id_actividad
         AND ps.fecha         = vm.fecha
        WHERE ps.id_socio IS NULL;

        COMMIT TRANSACTION;

        -- Cleanup
        DROP TABLE #TempDatos;

        SELECT 'Éxito' AS Estado, 'Importación de presentismo completada' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#TempDatos') IS NOT NULL
            DROP TABLE #TempDatos;

        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        SELECT 'Error' AS Estado, 'Error en el proceso: ' + @Err AS Mensaje;
        RETURN -1;
    END CATCH
END;
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

EXEC facturacion.ImportarClima 
    @RutaBase = 'C:\Users\tomas\Desktop\proyecto-BDA\docs\',
    @Anio = 2024;
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