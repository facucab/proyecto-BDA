USE Com5600G01;

--Reporte1

CREATE OR ALTER PROCEDURE manejo_personas.morosos_recurrentes
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    -- Validaciones de parámetros
    IF @fecha_inicio IS NULL
    BEGIN
        RAISERROR('La fecha de inicio no puede ser nula', 16, 1);
        RETURN;
    END
    
    IF @fecha_fin IS NULL
    BEGIN
        RAISERROR('La fecha de fin no puede ser nula', 16, 1);
        RETURN;
    END
    
    IF @fecha_inicio > @fecha_fin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor que la fecha de fin', 16, 1);
        RETURN;
    END
    
    IF @fecha_fin > GETDATE()
    BEGIN
        RAISERROR('La fecha de fin no puede ser mayor que la fecha actual', 16, 1);
        RETURN;
    END
    
    IF DATEDIFF(YEAR, @fecha_inicio, @fecha_fin) > 5
    BEGIN
        RAISERROR('El rango de fechas no puede ser mayor a 5 años', 16, 1);
        RETURN;
    END
    
    -- Consulta principal con manejo de errores
    BEGIN TRY
        WITH MorososDetalle AS (
            SELECT 
                s.id_socio,
                p.nombre,
                p.apellido,
                CONCAT(DATENAME(MONTH, f.fecha_emision), ' ', YEAR(f.fecha_emision)) as mes_incumplido,
                f.fecha_emision,
                COUNT(*) OVER (PARTITION BY s.id_socio) as total_incumplimientos
            FROM manejo_personas.socio s
            INNER JOIN manejo_personas.persona p ON s.id_persona = p.id_persona
            INNER JOIN pagos_y_facturas.factura f ON p.id_persona = f.id_persona
            WHERE 
                f.estado_pago IN ('pendiente', 'vencido')
                AND f.fecha_emision BETWEEN @fecha_inicio AND @fecha_fin
                AND p.activo = 1
        ),
        MorososRecurrentes AS (
            SELECT 
                id_socio,
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
            id_socio as nro_socio,
            CONCAT(nombre, ' ', apellido) as nombre_apellido,
            mes_incumplido,
            ranking_morosidad
        FROM MorososRecurrentes
        ORDER BY ranking_morosidad;
        
        -- Si no hay resultados, informar
        IF @@ROWCOUNT = 0
        BEGIN
            SELECT 
                'Morosos Recurrentes' as nombre_reporte,
                CONCAT(FORMAT(@fecha_inicio, 'dd/MM/yyyy'), ' - ', FORMAT(@fecha_fin, 'dd/MM/yyyy')) as periodo,
                'No se encontraron morosos recurrentes en el período especificado' as mensaje;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
--Reporte 2

CREATE OR ALTER VIEW pagos_y_facturas.ingresos_mensuales_actividades AS
WITH IngresosMensuales AS (
    SELECT 
        a.id_actividad,
        a.nombre_actividad,
        YEAR(f.fecha_emision) as año,
        MONTH(f.fecha_emision) as mes,
        DATENAME(MONTH, f.fecha_emision) as nombre_mes,
        SUM(f.monto_a_pagar) as ingreso_mensual
    FROM manejo_actividades.actividad a
    INNER JOIN manejo_personas.socio_actividad sa ON a.id_actividad = sa.id_actividad
    INNER JOIN manejo_personas.socio s ON sa.id_socio = s.id_socio
    INNER JOIN manejo_personas.persona p ON s.id_persona = p.id_persona
    INNER JOIN pagos_y_facturas.factura f ON p.id_persona = f.id_persona
    WHERE 
        f.estado_pago = 'pagado'
        AND YEAR(f.fecha_emision) = YEAR(GETDATE())
        AND MONTH(f.fecha_emision) >= 1
        AND f.fecha_emision <= GETDATE()
        AND sa.estado = 1
        AND a.estado = 1
    GROUP BY 
        a.id_actividad,
        a.nombre_actividad,
        YEAR(f.fecha_emision),
        MONTH(f.fecha_emision),
        DATENAME(MONTH, f.fecha_emision)
)
SELECT 
    nombre_actividad as ActividadDeportiva,
    nombre_mes as Mes,
    año as Año,
    ingreso_mensual as IngresoMensual,
    SUM(ingreso_mensual) OVER (
        PARTITION BY id_actividad 
        ORDER BY año, mes 
        ROWS UNBOUNDED PRECEDING
    ) as IngresoAcumulado
FROM IngresosMensuales;

--Reporte 3

CREATE OR ALTER VIEW manejo_actividades.inasistencias_por_actividad AS
SELECT 
    c.nombre_categoria as Categoria,
    a.nombre_actividad as Actividad,
    COUNT(DISTINCT s.id_socio) as CantidadSociosInasistencias,
    COUNT(*) as TotalInasistencias
FROM manejo_actividades.categoria c
INNER JOIN manejo_personas.socio s ON c.id_categoria = s.id_categoria
INNER JOIN manejo_personas.socio_actividad sa ON s.id_socio = sa.id_socio
INNER JOIN manejo_actividades.actividad a ON sa.id_actividad = a.id_actividad
INNER JOIN manejo_actividades.clase cl ON a.id_actividad = cl.id_actividad AND c.id_categoria = cl.id_categoria
WHERE 
    sa.estado = 0
    AND s.id_persona IN (SELECT id_persona FROM manejo_personas.persona WHERE activo = 1)
    AND a.estado = 1
    AND cl.activo = 1
GROUP BY c.nombre_categoria, a.nombre_actividad;

--Reporte 4

CREATE OR ALTER VIEW manejo_actividades.socios_inactivos_actividades AS
SELECT 
    p.nombre as Nombre,
    p.apellido as Apellido,
    DATEDIFF(YEAR, p.fecha_nac, GETDATE()) as Edad,
    c.nombre_categoria as Categoria,
    a.nombre_actividad as Actividad
FROM manejo_personas.persona p
INNER JOIN manejo_personas.socio s ON p.id_persona = s.id_persona
INNER JOIN manejo_actividades.categoria c ON s.id_categoria = c.id_categoria
INNER JOIN manejo_personas.socio_actividad sa ON s.id_socio = sa.id_socio
INNER JOIN manejo_actividades.actividad a ON sa.id_actividad = a.id_actividad
WHERE sa.estado = 0 
    AND p.activo = 1 
    AND a.estado = 1;