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
            SELECT [Categoria socio], [Valor cuota], [Vigente hasta] 
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
GO

select * from actividades.categoria


EXEC manejo_personas.ImportarSocios 'C:\Users\tomas\Desktop\proyecto-BDA\docs\Datos socios.xlsx' 
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

