/*
	Entrega 6 - Reportes

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Ruben 
	45234709 | Gauto, Gaston Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomas Andres
*/

-- Reporte 1: Morosos Recurrentes
IF OBJECT_ID('reportes.morosos_recurrentes', 'P') IS NOT NULL
    DROP PROCEDURE reportes.morosos_recurrentes;
GO
CREATE SCHEMA IF NOT EXISTS reportes;
GO
CREATE PROCEDURE reportes.morosos_recurrentes
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL OR @fecha_inicio > @fecha_fin OR @fecha_fin > GETDATE() OR DATEDIFF(YEAR, @fecha_inicio, @fecha_fin) > 5
    BEGIN
        RAISERROR('Fechas invalidas', 16, 1);
        RETURN;
    END
    BEGIN TRY
        ;WITH MorososDetalle AS (
            SELECT 
                s.numero_socio,
                p.nombre,
                p.apellido,
                CONCAT(DATENAME(MONTH, f.fecha_emision), ' ', YEAR(f.fecha_emision)) as mes_incumplido,
                f.fecha_emision,
                COUNT(*) OVER (PARTITION BY s.id_socio) as total_incumplimientos
            FROM usuarios.socio s
            INNER JOIN usuarios.persona p ON s.id_persona = p.id_persona
            INNER JOIN facturacion.factura f ON p.id_persona = f.id_persona
            WHERE 
                f.estado_pago IN ('pendiente', 'vencido')
                AND f.fecha_emision BETWEEN @fecha_inicio AND @fecha_fin
                AND s.activo = 1
        ),
        MorososRecurrentes AS (
            SELECT 
                numero_socio,
                nombre,
                apellido,
                mes_incumplido,
                total_incumplimientos,
                DENSE_RANK() OVER (ORDER BY total_incumplimientos DESC) as ranking_morosidad
            FROM MorososDetalle
            WHERE total_incumplimientos > 2
        )
        SELECT 
            'Morosos Recurrentes' as nombre_reporte,
            CONCAT(FORMAT(@fecha_inicio, 'dd/MM/yyyy'), ' - ', FORMAT(@fecha_fin, 'dd/MM/yyyy')) as periodo,
            numero_socio as nro_socio,
            CONCAT(nombre, ' ', apellido) as nombre_apellido,
            mes_incumplido,
            ranking_morosidad
        FROM MorososRecurrentes
        ORDER BY ranking_morosidad;
        IF @@ROWCOUNT = 0
        BEGIN
            SELECT 'Morosos Recurrentes' as nombre_reporte,
                   CONCAT(FORMAT(@fecha_inicio, 'dd/MM/yyyy'), ' - ', FORMAT(@fecha_fin, 'dd/MM/yyyy')) as periodo,
                   'No se encontraron morosos recurrentes en el periodo especificado' as mensaje;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Reporte 2: Ingresos Mensuales Acumulados por Actividad
IF OBJECT_ID('reportes.ingresos_mensuales_actividades', 'V') IS NOT NULL
    DROP VIEW reportes.ingresos_mensuales_actividades;
GO
CREATE VIEW reportes.ingresos_mensuales_actividades AS
WITH IngresosMensuales AS (
    SELECT 
        a.id_actividad,
        a.nombre as nombre_actividad,
        YEAR(f.fecha_emision) as anio,
        MONTH(f.fecha_emision) as mes,
        DATENAME(MONTH, f.fecha_emision) as nombre_mes,
        SUM(f.monto_a_pagar) as ingreso_mensual
    FROM actividades.actividad a
    INNER JOIN actividades.actividad_socio sa ON a.id_actividad = sa.id_actividad
    INNER JOIN usuarios.socio s ON sa.id_socio = s.id_socio
    INNER JOIN usuarios.persona p ON s.id_persona = p.id_persona
    INNER JOIN facturacion.factura f ON p.id_persona = f.id_persona
    WHERE 
        f.estado_pago = 'pagado'
        AND YEAR(f.fecha_emision) = YEAR(GETDATE())
        AND f.fecha_emision >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
        AND f.fecha_emision <= GETDATE()
        AND a.estado = 1
        AND s.activo = 1
    GROUP BY 
        a.id_actividad,
        a.nombre,
        YEAR(f.fecha_emision),
        MONTH(f.fecha_emision),
        DATENAME(MONTH, f.fecha_emision)
)
SELECT 
    nombre_actividad as ActividadDeportiva,
    nombre_mes as Mes,
    anio as Anio,
    ingreso_mensual as IngresoMensual,
    SUM(ingreso_mensual) OVER (
        PARTITION BY id_actividad 
        ORDER BY anio, mes 
        ROWS UNBOUNDED PRECEDING
    ) as IngresoAcumulado
FROM IngresosMensuales;
GO

-- Reporte 3: Inasistencias por Categoría y Actividad
IF OBJECT_ID('reportes.inasistencias_por_actividad', 'V') IS NOT NULL
    DROP VIEW reportes.inasistencias_por_actividad;
GO
-- NOTA: Se asume que la inasistencia es la falta de registro en una tabla de asistencias respecto a las clases programadas.
-- Si no existe tabla de asistencias, este reporte es solo un ejemplo y debe adaptarse si la tabla existe.
CREATE VIEW reportes.inasistencias_por_actividad AS
SELECT 
    c.nombre_categoria as Categoria,
    a.nombre as Actividad,
    COUNT(DISTINCT s.id_socio) as CantidadSociosInasistencias,
    COUNT(*) as TotalInasistencias
FROM actividades.categoria c
INNER JOIN usuarios.socio s ON c.id_categoria = s.id_categoria
INNER JOIN actividades.actividad_socio sa ON s.id_socio = sa.id_socio
INNER JOIN actividades.actividad a ON sa.id_actividad = a.id_actividad
-- Falta JOIN a tabla de asistencias, si existe
-- Falta lógica para detectar inasistencias
WHERE s.activo = 1 AND a.estado = 1
GROUP BY c.nombre_categoria, a.nombre
ORDER BY TotalInasistencias DESC;
GO

-- Reporte 4: Socios que no han asistido a alguna clase de la actividad que realizan
IF OBJECT_ID('reportes.socios_inactivos_actividades', 'V') IS NOT NULL
    DROP VIEW reportes.socios_inactivos_actividades;
GO
-- NOTA: Se asume que la inasistencia es la falta de registro en una tabla de asistencias respecto a las clases programadas.
-- Si no existe tabla de asistencias, este reporte es solo un ejemplo y debe adaptarse si la tabla existe.
CREATE VIEW reportes.socios_inactivos_actividades AS
SELECT 
    p.nombre as Nombre,
    p.apellido as Apellido,
    DATEDIFF(YEAR, p.fecha_nac, GETDATE()) as Edad,
    c.nombre_categoria as Categoria,
    a.nombre as Actividad
FROM usuarios.persona p
INNER JOIN usuarios.socio s ON p.id_persona = s.id_persona
INNER JOIN actividades.categoria c ON s.id_categoria = c.id_categoria
INNER JOIN actividades.actividad_socio sa ON s.id_socio = sa.id_socio
INNER JOIN actividades.actividad a ON sa.id_actividad = a.id_actividad
-- Falta JOIN a tabla de asistencias, si existe
-- Falta lógica para detectar inasistencias
WHERE s.activo = 1 AND a.estado = 1;
GO

-- =============================
-- EJEMPLOS DE CONSULTA DE REPORTES
-- =============================

-- Reporte 1: Morosos Recurrentes (ejemplo de uso)
EXEC reportes.morosos_recurrentes @fecha_inicio = '2024-01-01', @fecha_fin = '2024-12-31';

-- Reporte 2: Ingresos Mensuales Acumulados por Actividad
SELECT * FROM reportes.ingresos_mensuales_actividades;

-- Reporte 3: Inasistencias por Categoría y Actividad
SELECT * FROM reportes.inasistencias_por_actividad;

-- Reporte 4: Socios que no han asistido a alguna clase de la actividad que realizan
SELECT * FROM reportes.socios_inactivos_actividades;
