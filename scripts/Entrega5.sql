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

