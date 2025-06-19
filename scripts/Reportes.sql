USE Com5600G01;
GO

--Reporte1

DECLARE @fecha_inicio DATE = '2024-01-01';
DECLARE @fecha_fin DATE = '2024-12-31';

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
--Reporte 2

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
    nombre_actividad as 'Actividad Deportiva',
    nombre_mes as 'Mes',
    año as 'Año',
    ingreso_mensual as 'Ingreso Mensual',
    SUM(ingreso_mensual) OVER (
        PARTITION BY id_actividad 
        ORDER BY año, mes 
        ROWS UNBOUNDED PRECEDING
    ) as 'Ingreso Acumulado'
FROM IngresosMensuales
ORDER BY nombre_actividad, año, mes;

--Reporte 3

SELECT 
    c.nombre_categoria as 'Categoría',
    a.nombre_actividad as 'Actividad',
    COUNT(DISTINCT s.id_socio) as 'Cantidad de Socios con Inasistencias',
    COUNT(*) as 'Total de Inasistencias'
FROM manejo_actividades.categoria c
INNER JOIN manejo_personas.socio s ON c.id_categoria = s.id_categoria
INNER JOIN manejo_personas.socio_actividad sa ON s.id_socio = sa.id_socio
INNER JOIN manejo_actividades.actividad a ON sa.id_actividad = a.id_actividad
INNER JOIN manejo_actividades.clase cl ON a.id_actividad = cl.id_actividad AND c.id_categoria = cl.id_categoria
WHERE 
    sa.estado = 0  -- Estado 0 indica inasistencia/inactividad en la relación socio-actividad
    AND s.id_persona IN (SELECT id_persona FROM manejo_personas.persona WHERE activo = 1)
    AND a.estado = 1
    AND cl.activo = 1
GROUP BY  c.nombre_categoria, a.nombre_actividad
ORDER BY  COUNT(*) DESC, COUNT(DISTINCT s.id_socio) DESC;

--Reporte 4

SELECT 
    p.nombre as 'Nombre',
    p.apellido as 'Apellido',
    DATEDIFF(YEAR, p.fecha_nac, GETDATE()) as 'Edad',
    c.nombre_categoria as 'Categoría',
    a.nombre_actividad as 'Actividad'
FROM manejo_personas.persona p
INNER JOIN manejo_personas.socio s ON p.id_persona = s.id_persona
INNER JOIN manejo_actividades.categoria c ON s.id_categoria = c.id_categoria
INNER JOIN manejo_personas.socio_actividad sa ON s.id_socio = sa.id_socio
INNER JOIN manejo_actividades.actividad a ON sa.id_actividad = a.id_actividad
WHERE sa.estado = 0   AND p.activo = 1 AND a.estado = 1
ORDER BY p.apellido, p.nombre;