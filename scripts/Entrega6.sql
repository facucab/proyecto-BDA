
USE Com5600G01;
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

--Reporte 2: 
CREATE OR ALTER PROCEDURE facturacion.IngresosMensualesActividades
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Obtener el año actual para calcular desde enero
    DECLARE @anioActual INT = YEAR(GETDATE());
    DECLARE @fechaInicio DATE = DATEFROMPARTS(@anioActual, 1, 1); -- 1 de enero del año actual
    DECLARE @fechaFin DATE = GETDATE(); -- Hasta hoy
    
    -- Resumen total por actividad usando Windows Functions
    WITH MESES_DEL_ANIO AS (
        SELECT 
            DATEFROMPARTS(@anioActual, 1, 1) AS fecha_inicio_mes,
            EOMONTH(DATEFROMPARTS(@anioActual, 1, 1)) AS fecha_fin_mes,
            1 AS numero_mes
        UNION ALL
        SELECT 
            DATEADD(MONTH, numero_mes, DATEFROMPARTS(@anioActual, 1, 1)),
            EOMONTH(DATEADD(MONTH, numero_mes, DATEFROMPARTS(@anioActual, 1, 1))),
            numero_mes + 1
        FROM MESES_DEL_ANIO
        WHERE numero_mes < MONTH(@fechaFin)
    ),
    RESUMEN_ACTIVIDADES AS (
        SELECT 
            a.id_actividad,
            a.nombre AS nombre_actividad,
            a.costo_mensual,
            COUNT(DISTINCT asoc.id_socio) AS cantidad_socios,
            COUNT(DISTINCT asoc.id_socio) * a.costo_mensual AS total_recaudado
        FROM actividades.actividad a
        INNER JOIN actividades.actividad_socio asoc ON a.id_actividad = asoc.id_actividad
        INNER JOIN usuarios.socio s ON asoc.id_socio = s.id_socio
        CROSS JOIN MESES_DEL_ANIO m
        WHERE a.estado = 1 -- Solo actividades activas
          AND s.activo = 1 -- Solo socios activos
          AND s.fecha_alta <= m.fecha_fin_mes -- Socio debe estar activo en ese mes
          AND (s.fecha_baja IS NULL OR s.fecha_baja >= m.fecha_inicio_mes) -- Socio no debe haberse dado de baja
        GROUP BY a.id_actividad, a.nombre, a.costo_mensual
    )
    SELECT 
        nombre_actividad AS [Actividad Deportiva],
        cantidad_socios AS [Total de Socios en el Año],
        ROUND(costo_mensual, 2) AS [Costo Unitario],
        ROUND(total_recaudado, 2) AS [Total Recaudado],
        -- Windows Function para ranking final
        RANK() OVER (
            ORDER BY total_recaudado DESC
        ) AS [Ranking Final]
    FROM RESUMEN_ACTIVIDADES
    ORDER BY total_recaudado DESC;
    
END
GO
-- Reporte 3:
GO
CREATE OR ALTER PROCEDURE actividades.SociosConInasistencias
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.nombre_categoria,
        a.nombre AS nombre_actividad,
        COUNT(*) AS cantidad_inasistencias
    FROM actividades.actividad_socio act_s
    INNER JOIN usuarios.socio s ON act_s.id_socio = s.id_socio
    INNER JOIN actividades.categoria c ON s.id_categoria = c.id_categoria
    INNER JOIN actividades.actividad a ON act_s.id_actividad = a.id_actividad
    WHERE UPPER(act_s.presentismo) <> 'P'
    GROUP BY 
        c.nombre_categoria,
        a.nombre
    ORDER BY 
        cantidad_inasistencias DESC;
END;
GO
-- Reporte 4: 
CREATE OR ALTER PROCEDURE actividades.SociosConInasistenciasEnClases
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.nombre,
        p.apellido,
        DATEDIFF(YEAR, p.fecha_nac, GETDATE()) - 
            CASE 
                WHEN MONTH(p.fecha_nac) > MONTH(GETDATE()) 
                     OR (MONTH(p.fecha_nac) = MONTH(GETDATE()) AND DAY(p.fecha_nac) > DAY(GETDATE())) 
                THEN 1 ELSE 0 
            END AS edad,
        c.nombre_categoria,
        a.nombre AS nombre_actividad
    FROM actividades.actividad_socio act_s
    INNER JOIN usuarios.socio s ON act_s.id_socio = s.id_socio
    INNER JOIN usuarios.persona p ON s.id_persona = p.id_persona
    INNER JOIN actividades.categoria c ON s.id_categoria = c.id_categoria
    INNER JOIN actividades.actividad a ON act_s.id_actividad = a.id_actividad
    WHERE act_s.presentismo IS NULL OR UPPER(act_s.presentismo) <> 'P'
    GROUP BY 
        p.nombre, p.apellido, p.fecha_nac,
        c.nombre_categoria, a.nombre
    ORDER BY 
        p.apellido, p.nombre;
END;
GO

GO
-- PRUEBAS
GO
-- Reporte 1: 
-- EXEC usuarios.MorososRecurrentes @fechaInicio = '2024-01-05', @fechaFin= '2024-02-06' 
GO
-- reporte 2
--EXEC facturacion.IngresosMensualesActividades;
GO
-- Reporte 3: 
-- EXEC actividades.SociosConInasistencias
GO
-- Reporte 4: 
EXEC actividades.SociosConInasistenciasEnClases; 
GO