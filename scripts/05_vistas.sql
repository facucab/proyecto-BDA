-- Vista para mostrar información completa de socios
CREATE OR ALTER VIEW manejo_personas.VistaSociosCompleta AS
SELECT 
    s.id_socio,
    s.numero_socio,
    p.dni,
    p.nombre,
    p.apellido,
    p.email,
    p.fecha_nac,
    p.telefono,
    s.telefono_emergencia,
    c.nombre_categoria,
    c.costo_membrecia,
    os.descripcion AS obra_social,
    s.obra_nro_socio,
    gf.id_grupo,
    p.fecha_alta,
    p.activo AS persona_activa,
    CASE 
        WHEN p.activo = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado_persona
FROM manejo_personas.socio s
INNER JOIN manejo_personas.persona p ON s.id_persona = p.id_persona
LEFT JOIN manejo_actividades.categoria c ON s.id_categoria = c.id_categoria
LEFT JOIN manejo_personas.obra_social os ON s.id_obra_social = os.id_obra_social
LEFT JOIN manejo_personas.grupo_familiar gf ON s.id_grupo = gf.id_grupo;
GO