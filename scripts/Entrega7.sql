USE Com5600G01; -- Selecciona la base de datos de trabajo
GO

-- Crea roles para distintos perfiles del club
CREATE ROLE Jefe_Tesoreria;
CREATE ROLE Administrativo_Cobranza;
CREATE ROLE Administrativo_Morosidad;
CREATE ROLE Administrativo_Facturacion;
CREATE ROLE Administrativo_Socio;
CREATE ROLE Socio_Web;
CREATE ROLE Presidente;
CREATE ROLE Vicepresidente;
CREATE ROLE Secretario;
CREATE ROLE Vocal;

-- Asigna permisos específicos según rol

-- Jefe de Tesorería: acceso total al esquema de pagos y facturas
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::facturacion TO Jefe_Tesoreria;

-- Cobranza: solo lectura sobre vista de facturas
GRANT SELECT ON facturacion.VistaFacturasCompleta TO Administrativo_Cobranza;

-- Morosidad: puede ejecutar SP de morosos recurrentes
GRANT EXECUTE ON usuarios.MorososRecurrentes TO Administrativo_Morosidad;

-- Facturación: CRUD sobre Factura + ejecución de SPs de gestión
GRANT SELECT, INSERT, UPDATE, DELETE ON facturacion.Factura TO Administrativo_Facturacion;
GRANT EXECUTE ON facturacion.CrearFactura TO Administrativo_Facturacion;
GRANT EXECUTE ON facturacion.ModificarFactura TO Administrativo_Facturacion;
GRANT EXECUTE ON facturacion.EliminarFactura TO Administrativo_Facturacion;

-- Socios: acceso total y lectura sobre usuarios
GRANT EXECUTE ON SCHEMA::usuarios TO Administrador_Socio;
GRANT SELECT ON SCHEMA::usuarios TO Administrador_Socio;

-- Socio Web: solo puede ver su propia información
GRANT SELECT ON usuarios.MiInformacion TO Socio_Web;

-- Autoridades: permisos de lectura variados
GRANT SELECT TO Presidente;
GRANT SELECT TO Vicepresidente;

-- Secretario: acceso a vistas completas e ingresos mensuales
GRANT SELECT ON usuarios.VistaSociosCompleta TO Secretario;
GRANT SELECT ON usuarios.VistaInvitadosCompleta TO Secretario;
GRANT SELECT ON actividades.VistaSociosPorClase TO Secretario;
GRANT SELECT ON facturacion.IngresosMensualesActividades TO Secretario;

/*
-- Elimina todos los roles creados
DROP ROLE Jefe_Tesoreria;
DROP ROLE Administrativo_Cobranza;
DROP ROLE Administrativo_Morosidad;
DROP ROLE Administrativo_Facturacion;
DROP ROLE Administrativo_Socio;
DROP ROLE Socio_Web;
DROP ROLE Presidente;
DROP ROLE Vicepresidente;
DROP ROLE Secretario;
DROP ROLE Vocal;
*/

/* Política de Respaldo:

Decidimos que se realiza automáticamente un respaldo completo una vez por semana, durante la madrugada del día lunes.  
Luego, se realiza un respaldo diferencial cada 24 horas (también durante la madrugada), y un respaldo del log de transacciones cada 10 minutos.

Justificación: El sistema gestiona la facturación de un local con carga de trabajo intermitente. 
Dado que opera en un servidor local donde no van a haber operaciones constantes, creemos que hace falta un RTO bajo 
que minimice la pérdida de datos, sin un uso excesivo de recursos.

Por ese motivo:
- Se realiza un respaldo diferencial diario para reducir el tiempo de restauración.
- Se respaldan los logs de transacciones cada 10 minutos, lo que nos garantiza como maximo 10 minutos de perdida de datos.
- Los respaldos completos y diferenciales se programan durante la madrugada para no alterar la performance del sistema durante los tiempos de carga
(Segun lo que pudimos ver en Google Maps, es el período de menor concurrencia en este tipo de negocios).
- Elegimos el dia lunes para el respaldo completo porque (Segun maps) es de los días de menor actividad.

En caso de poder acceder a una nube, haríamos un respaldo adicional en ella para complementar los respaldos locales en caso de que fallase uno u otro.*/

-- Reporte 2: Reporte acumulado mensual de ingresos por actividad deportiva
-- desde enero hasta el momento actual
CREATE OR ALTER PROCEDURE reportes.IngresosAcumuladosPorActividad
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Obtener el año actual para calcular desde enero
    DECLARE @anioActual INT = YEAR(GETDATE());
    DECLARE @fechaInicio DATE = DATEFROMPARTS(@anioActual, 1, 1); -- 1 de enero del año actual
    DECLARE @fechaFin DATE = GETDATE(); -- Hasta hoy
    
    -- CTE para obtener los meses desde enero hasta el mes actual
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
    -- CTE para calcular ingresos por actividad y mes
    INGRESOS_POR_ACTIVIDAD AS (
        SELECT 
            a.id_actividad,
            a.nombre AS nombre_actividad,
            a.costo_mensual,
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_anio,
            COUNT(asoc.id_socio) AS cantidad_socios,
            COUNT(asoc.id_socio) * a.costo_mensual AS ingresos_mensuales,
            f.fecha_emision
        FROM actividades.actividad a
        INNER JOIN actividades.actividad_socio asoc ON a.id_actividad = asoc.id_actividad
        INNER JOIN usuarios.socio s ON asoc.id_socio = s.id_socio
        INNER JOIN usuarios.persona p ON s.id_persona = p.id_persona
        INNER JOIN facturacion.factura f ON p.id_persona = f.id_persona
        WHERE f.fecha_emision BETWEEN @fechaInicio AND @fechaFin
          AND f.estado_pago = 'Pagado' -- Solo facturas pagadas
          AND a.estado = 1 -- Solo actividades activas
          AND s.activo = 1 -- Solo socios activos
        GROUP BY a.id_actividad, a.nombre, a.costo_mensual, FORMAT(f.fecha_emision, 'yyyy-MM'), f.fecha_emision
    ),
    -- CTE para calcular acumulados mensuales
    INGRESOS_ACUMULADOS AS (
        SELECT 
            id_actividad,
            nombre_actividad,
            costo_mensual,
            mes_anio,
            cantidad_socios,
            ingresos_mensuales,
            SUM(ingresos_mensuales) OVER (
                PARTITION BY id_actividad 
                ORDER BY mes_anio 
                ROWS UNBOUNDED PRECEDING
            ) AS ingresos_acumulados
        FROM INGRESOS_POR_ACTIVIDAD
    )
    -- Resultado final
    SELECT 
        nombre_actividad AS [Actividad Deportiva],
        mes_anio AS [Mes/Año],
        cantidad_socios AS [Cantidad de Socios],
        costo_mensual AS [Costo Mensual por Socio],
        ingresos_mensuales AS [Ingresos del Mes],
        ingresos_acumulados AS [Ingresos Acumulados desde Enero],
        ROUND((ingresos_acumulados / NULLIF(ingresos_mensuales, 0)) * 100, 2) AS [Porcentaje de Crecimiento]
    FROM INGRESOS_ACUMULADOS
    ORDER BY nombre_actividad, mes_anio;
    
    -- Resumen total por actividad
    SELECT 
        nombre_actividad AS [Actividad Deportiva],
        SUM(cantidad_socios) AS [Total Socios en el Año],
        SUM(ingresos_mensuales) AS [Total Ingresos en el Año],
        AVG(costo_mensual) AS [Costo Promedio Mensual],
        COUNT(DISTINCT mes_anio) AS [Meses con Actividad]
    FROM INGRESOS_ACUMULADOS
    GROUP BY nombre_actividad
    ORDER BY SUM(ingresos_mensuales) DESC;
    
END;
GO

-- Procedimiento alternativo que considera también las facturas sin relación directa con actividades
-- Este enfoque calcula los ingresos basándose en las facturas y asigna proporcionalmente a las actividades
CREATE OR ALTER PROCEDURE reportes.IngresosAcumuladosPorActividadV2
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Obtener el año actual para calcular desde enero
    DECLARE @anioActual INT = YEAR(GETDATE());
    DECLARE @fechaInicio DATE = DATEFROMPARTS(@anioActual, 1, 1); -- 1 de enero del año actual
    DECLARE @fechaFin DATE = GETDATE(); -- Hasta hoy
    
    -- CTE para obtener los meses desde enero hasta el mes actual
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
    -- CTE para calcular socios por actividad por mes
    SOCIOS_POR_ACTIVIDAD_MES AS (
        SELECT 
            a.id_actividad,
            a.nombre AS nombre_actividad,
            a.costo_mensual,
            FORMAT(m.fecha_inicio_mes, 'yyyy-MM') AS mes_anio,
            COUNT(DISTINCT asoc.id_socio) AS cantidad_socios
        FROM actividades.actividad a
        INNER JOIN actividades.actividad_socio asoc ON a.id_actividad = asoc.id_actividad
        INNER JOIN usuarios.socio s ON asoc.id_socio = s.id_socio
        CROSS JOIN MESES_DEL_ANIO m
        WHERE a.estado = 1 -- Solo actividades activas
          AND s.activo = 1 -- Solo socios activos
          AND s.fecha_alta <= m.fecha_fin_mes -- Socio debe estar activo en ese mes
          AND (s.fecha_baja IS NULL OR s.fecha_baja >= m.fecha_inicio_mes) -- Socio no debe haberse dado de baja
        GROUP BY a.id_actividad, a.nombre, a.costo_mensual, FORMAT(m.fecha_inicio_mes, 'yyyy-MM')
    ),
    -- CTE para calcular ingresos totales por mes
    INGRESOS_TOTALES_MES AS (
        SELECT 
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_anio,
            SUM(f.monto_a_pagar) AS ingresos_totales_mes
        FROM facturacion.factura f
        WHERE f.fecha_emision BETWEEN @fechaInicio AND @fechaFin
          AND f.estado_pago = 'Pagado' -- Solo facturas pagadas
        GROUP BY FORMAT(f.fecha_emision, 'yyyy-MM')
    ),
    -- CTE para calcular ingresos por actividad basados en proporción de socios
    INGRESOS_POR_ACTIVIDAD AS (
        SELECT 
            sp.id_actividad,
            sp.nombre_actividad,
            sp.costo_mensual,
            sp.mes_anio,
            sp.cantidad_socios,
            CASE 
                WHEN SUM(sp.cantidad_socios) OVER (PARTITION BY sp.mes_anio) > 0 
                THEN (sp.cantidad_socios * itm.ingresos_totales_mes) / SUM(sp.cantidad_socios) OVER (PARTITION BY sp.mes_anio)
                ELSE 0 
            END AS ingresos_mensuales
        FROM SOCIOS_POR_ACTIVIDAD_MES sp
        LEFT JOIN INGRESOS_TOTALES_MES itm ON sp.mes_anio = itm.mes_anio
    ),
    -- CTE para calcular acumulados mensuales
    INGRESOS_ACUMULADOS AS (
        SELECT 
            id_actividad,
            nombre_actividad,
            costo_mensual,
            mes_anio,
            cantidad_socios,
            ingresos_mensuales,
            SUM(ingresos_mensuales) OVER (
                PARTITION BY id_actividad 
                ORDER BY mes_anio 
                ROWS UNBOUNDED PRECEDING
            ) AS ingresos_acumulados
        FROM INGRESOS_POR_ACTIVIDAD
    )
    -- Resultado final
    SELECT 
        nombre_actividad AS [Actividad Deportiva],
        mes_anio AS [Mes/Año],
        cantidad_socios AS [Cantidad de Socios],
        costo_mensual AS [Costo Mensual por Socio],
        ROUND(ingresos_mensuales, 2) AS [Ingresos del Mes],
        ROUND(ingresos_acumulados, 2) AS [Ingresos Acumulados desde Enero],
        CASE 
            WHEN LAG(ingresos_mensuales) OVER (PARTITION BY id_actividad ORDER BY mes_anio) > 0
            THEN ROUND(((ingresos_mensuales - LAG(ingresos_mensuales) OVER (PARTITION BY id_actividad ORDER BY mes_anio)) / 
                       LAG(ingresos_mensuales) OVER (PARTITION BY id_actividad ORDER BY mes_anio)) * 100, 2)
            ELSE 0 
        END AS [Variación Mensual (%)]
    FROM INGRESOS_ACUMULADOS
    ORDER BY nombre_actividad, mes_anio;
    
    -- Resumen total por actividad
    SELECT 
        nombre_actividad AS [Actividad Deportiva],
        SUM(cantidad_socios) AS [Total Socios en el Año],
        ROUND(SUM(ingresos_mensuales), 2) AS [Total Ingresos en el Año],
        AVG(costo_mensual) AS [Costo Promedio Mensual],
        COUNT(DISTINCT mes_anio) AS [Meses con Actividad],
        ROUND(SUM(ingresos_mensuales) / COUNT(DISTINCT mes_anio), 2) AS [Promedio Mensual]
    FROM INGRESOS_ACUMULADOS
    GROUP BY nombre_actividad
    ORDER BY SUM(ingresos_mensuales) DESC;
    
END;
GO

-- Procedimiento simplificado que muestra solo los datos básicos
CREATE OR ALTER PROCEDURE reportes.IngresosAcumuladosPorActividadSimple
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Obtener el año actual para calcular desde enero
    DECLARE @anioActual INT = YEAR(GETDATE());
    DECLARE @fechaInicio DATE = DATEFROMPARTS(@anioActual, 1, 1); -- 1 de enero del año actual
    DECLARE @fechaFin DATE = GETDATE(); -- Hasta hoy
    
    -- Calcular ingresos por actividad basados en socios inscriptos y costo mensual
    WITH INGRESOS_POR_ACTIVIDAD AS (
        SELECT 
            a.id_actividad,
            a.nombre AS nombre_actividad,
            a.costo_mensual,
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_anio,
            COUNT(DISTINCT asoc.id_socio) AS cantidad_socios,
            COUNT(DISTINCT asoc.id_socio) * a.costo_mensual AS ingresos_mensuales
        FROM actividades.actividad a
        INNER JOIN actividades.actividad_socio asoc ON a.id_actividad = asoc.id_actividad
        INNER JOIN usuarios.socio s ON asoc.id_socio = s.id_socio
        INNER JOIN usuarios.persona p ON s.id_persona = p.id_persona
        INNER JOIN facturacion.factura f ON p.id_persona = f.id_persona
        WHERE f.fecha_emision BETWEEN @fechaInicio AND @fechaFin
          AND f.estado_pago = 'Pagado' -- Solo facturas pagadas
          AND a.estado = 1 -- Solo actividades activas
          AND s.activo = 1 -- Solo socios activos
        GROUP BY a.id_actividad, a.nombre, a.costo_mensual, FORMAT(f.fecha_emision, 'yyyy-MM')
    ),
    INGRESOS_ACUMULADOS AS (
        SELECT 
            id_actividad,
            nombre_actividad,
            costo_mensual,
            mes_anio,
            cantidad_socios,
            ingresos_mensuales,
            SUM(ingresos_mensuales) OVER (
                PARTITION BY id_actividad 
                ORDER BY mes_anio 
                ROWS UNBOUNDED PRECEDING
            ) AS ingresos_acumulados
        FROM INGRESOS_POR_ACTIVIDAD
    )
    SELECT 
        nombre_actividad AS [Actividad Deportiva],
        mes_anio AS [Mes/Año],
        cantidad_socios AS [Socios Inscriptos],
        costo_mensual AS [Costo Mensual],
        ingresos_mensuales AS [Ingresos del Mes],
        ingresos_acumulados AS [Ingresos Acumulados desde Enero]
    FROM INGRESOS_ACUMULADOS
    ORDER BY nombre_actividad, mes_anio;
    
END;
GO

-- Ejecutar los reportes
PRINT '=== REPORTE 2: INGRESOS ACUMULADOS POR ACTIVIDAD DEPORTIVA ===';
PRINT 'Reporte desde enero hasta el momento actual';
PRINT '';

EXEC reportes.IngresosAcumuladosPorActividadSimple;
GO
