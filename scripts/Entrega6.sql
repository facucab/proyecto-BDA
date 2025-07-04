
USE Com5600G01;
GO
/*
DECLARE @fechaInicio DATE ,@fechaFin DATE; 

SET @fechaInicio = '2024-01-05';
SET @fechaFin = '2025-05-04';

 SELECT
            f.id_factura,
            f.id_persona,
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_incumplido,
            f.estado_pago,
            f.fecha_emision
        FROM facturacion.factura f
        WHERE f.estado_pago = 'Pendiente'
          AND f.fecha_emision BETWEEN @fechaInicio AND @fechaFin
		  */
GO

-- SPS

-- Reporte 1
CREATE OR ALTER PROCEDURE usuarios.MorososRecurrentes
    @fechaInicio DATE,
    @fechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Agrupo personas y mes incumplido 
    WITH MESES_PERSONA_MOROSOS AS (
        SELECT 
            f.id_persona,
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_incumplido
        FROM facturacion.factura f
        WHERE f.estado_pago = 'Pendiente'
          AND f.fecha_emision BETWEEN @fechaInicio AND @fechaFin
        GROUP BY f.id_persona, FORMAT(f.fecha_emision, 'yyyy-MM')
    ),
    MESES_CONTEO AS (
        SELECT 
            id_persona, 
            mes_incumplido,
            COUNT(*) OVER (PARTITION BY id_persona) AS meses_sin_pagar
        FROM MESES_PERSONA_MOROSOS

    )
    SELECT 
        c.id_persona, 
        c.mes_incumplido, 
        c.meses_sin_pagar,
        s.numero_socio,
		p.nombre,
		p.apellido,
        RANK() OVER (ORDER BY c.meses_sin_pagar DESC) AS ranking
    FROM MESES_CONTEO c
    INNER JOIN usuarios.socio s ON s.id_persona = c.id_persona
	INNER JOIN usuarios.persona p ON p.id_persona = c.id_persona
	ORDER BY ranking, c.id_persona, c.mes_incumplido;
	
END;
GO

--Reporte 2
CREATE OR ALTER PROCEDURE facturacion.IngresosMensualesActividades
BEGIN
    
END
GO

-- PRUEBAS

-- Rerpote 1
EXEC usuarios.MorososRecurrentes @fechaInicio = '2024-01-05', @fechaFin= '2024-02-06' 
GO

EXEC facturacion.IngresosPorActividad;
GO