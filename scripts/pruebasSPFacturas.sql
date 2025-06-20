-- Pruebas Facturas

USE Com5600G01;
GO

--Creacion

--Caso normal
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pendiente', 
    @monto_a_pagar = 1500.50, 
    @id_persona = 1, 
    @id_metodo_pago = 1;
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pagado', 
    @monto_a_pagar = 2000.00, 
    @id_persona = 2, 
    @id_metodo_pago = 2;
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Vencido', 
    @monto_a_pagar = 750.25, 
    @id_persona = 3, 
    @id_metodo_pago = 3;
-- Resultado: Factura creada correctamente

--Metodo de pago inexistente
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Vencido', 
    @monto_a_pagar = 750.25, 
    @id_persona = 3, 
    @id_metodo_pago = 99999;
--Resultado: Método de pago no valido

--Persona inexistente
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pagado', 
    @monto_a_pagar = 2000.00, 
    @id_persona = 999999, 
    @id_metodo_pago = 2;
--Resultado: Persona no existente

--Monto invalido
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pendiente', 
    @monto_a_pagar = -10.25, 
    @id_persona = 1, 
    @id_metodo_pago = 1;
--Resultado: Monto invalido

--Estado invalido
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = '', 
    @monto_a_pagar = 1000.25, 
    @id_persona = 1, 
    @id_metodo_pago = 1;
--Resultado: Estado de pago no puede ser nulo o vacio

--Modificacion

--Caso normal
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 1,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 1000.00,
    @nuevo_metodo_pago =1;
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 2,
    @nuevo_estado_pago = 'Pagado',
    @nuevo_monto = 2000.00,
    @nuevo_metodo_pago =2;
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 3000.00,
    @nuevo_metodo_pago =3;
--Resultado: Factura actualizada correctamente

--Metodo de pago inexistente
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 3000.00,
    @nuevo_metodo_pago =99993;
--Resultado: Metodo de pago invalido

--Monto invalido
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 0,
    @nuevo_metodo_pago =3;
--Resultado: Monto invalido

--Estado vacio
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = '',
    @nuevo_monto = 4000.00,
    @nuevo_metodo_pago =2;
--Resultado: Estado invalido

--Id inexistente
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 99999,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 3000.00,
    @nuevo_metodo_pago =3;
--Resultado: Factura no existente

--Eliminacion

--Casos Normales
EXEC pagos_y_facturas.EliminacionFactura @id_factura =1;
EXEC pagos_y_facturas.EliminacionFactura @id_factura =3;
EXEC pagos_y_facturas.EliminacionFactura @id_factura =2;
--Resultado: Factura eliminada correctamente

--Id invalido
EXEC pagos_y_facturas.EliminacionFactura @id_factura =99999;
--Resultado: La factura no existe

CREATE OR ALTER PROCEDURE ImportarFacturas
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
                ''SELECT * FROM [pago cuotas$A2:E10000]'')';
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