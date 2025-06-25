USE Com5600G01;
GO

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

CREATE OR ALTER VIEW pagos_y_facturas.VistaFacturasCompleta AS
SELECT
    f.id_factura,
    f.estado_pago,
    f.fecha_emision,
    f.monto_a_pagar,
    f.detalle,
    p.id_persona,
    p.dni,
    p.nombre AS nombre_persona,
    p.apellido AS apellido_persona,
    mp.id_metodo_pago,
    mp.nombre AS metodo_pago,
    d.id_descuento,
    d.descripcion AS descuento_descripcion,
    d.valor AS descuento_valor,
    fd.monto_aplicado
FROM pagos_y_facturas.factura f
INNER JOIN manejo_personas.persona p ON f.id_persona = p.id_persona
INNER JOIN pagos_y_facturas.metodo_pago mp ON f.id_metodo_pago = mp.id_metodo_pago
LEFT JOIN pagos_y_facturas.factura_descuento fd ON f.id_factura = fd.id_factura
LEFT JOIN pagos_y_facturas.descuento d ON fd.id_descuento = d.id_descuento;
GO

-- Vista para mostrar información completa de usuarios
CREATE OR ALTER VIEW manejo_personas.VistaUsuariosCompleta AS
SELECT 
    u.id_usuario,
    u.username,
    u.password_hash,
    u.fecha_alta_contra,
    u.estado AS usuario_activo,
    p.id_persona,
    p.dni,
    p.nombre,
    p.apellido,
    p.email,
    p.fecha_nac,
    p.telefono,
    p.fecha_alta AS persona_fecha_alta,
    p.activo AS persona_activa,
    r.descripcion AS rol,
    CASE 
        WHEN u.estado = 1 THEN 'Activo'
        ELSE 'Inactivo'
    END AS estado_usuario
FROM manejo_personas.usuario u
INNER JOIN manejo_personas.persona p ON u.id_persona = p.id_persona
LEFT JOIN manejo_personas.Usuario_Rol ur ON u.id_usuario = ur.id_usuario
LEFT JOIN manejo_personas.Rol r ON ur.id_rol = r.id_rol;
GO

-- Vista para mostrar información completa de invitados
CREATE OR ALTER VIEW manejo_personas.VistaInvitadosCompleta AS
SELECT 
    i.id_invitado,
    i.fecha_invitacion,
    s.id_socio,
    s.numero_socio,
    p.id_persona,
    p.dni,
    p.nombre,
    p.apellido,
    p.email,
    p.fecha_nac,
    p.telefono,
    p.fecha_alta AS persona_fecha_alta,
    p.activo AS persona_activa
FROM manejo_personas.invitado i
INNER JOIN manejo_personas.persona p ON i.id_persona = p.id_persona
INNER JOIN manejo_personas.socio s ON i.id_socio = s.id_socio;
GO

-- Vista para mostrar qué socio va a cada clase y de qué actividad es
CREATE OR ALTER VIEW manejo_actividades.VistaSociosPorClase AS
SELECT
    sa.id_socio,
    p.nombre AS nombre_persona,
    p.apellido AS apellido_persona,
    c.id_clase,
    a.nombre_actividad,
    cat.nombre_categoria,
    c.dia,
    c.horario,
    c.activo AS clase_activa,
    up.id_usuario AS id_profesor,
    pp.nombre AS nombre_profesor,
    pp.apellido AS apellido_profesor
FROM manejo_personas.socio_actividad sa
INNER JOIN manejo_personas.socio s ON sa.id_socio = s.id_socio
INNER JOIN manejo_personas.persona p ON s.id_persona = p.id_persona
INNER JOIN manejo_actividades.actividad a ON sa.id_actividad = a.id_actividad
INNER JOIN manejo_actividades.clase c ON a.id_actividad = c.id_actividad AND s.id_categoria = c.id_categoria
INNER JOIN manejo_actividades.categoria cat ON c.id_categoria = cat.id_categoria
INNER JOIN manejo_personas.usuario up ON c.id_usuario = up.id_usuario
INNER JOIN manejo_personas.persona pp ON up.id_persona = pp.id_persona;
GO

-- Vista para mostrar información de grupos familiares
CREATE OR ALTER VIEW manejo_personas.VistaGruposFamiliares AS
SELECT
    gf.id_grupo,
    gf.fecha_alta AS grupo_fecha_alta,
    gf.estado AS grupo_activo,
    r.id_responsable,
    p_resp.dni AS dni_responsable,
    p_resp.nombre AS nombre_responsable,
    p_resp.apellido AS apellido_responsable,
    s.id_socio,
    s.numero_socio,
    p_socio.dni AS dni_socio,
    p_socio.nombre AS nombre_socio,
    p_socio.apellido AS apellido_socio,
    s.id_categoria,
    s.id_obra_social
FROM manejo_personas.grupo_familiar gf
LEFT JOIN manejo_personas.responsable r ON gf.id_grupo = r.id_grupo
LEFT JOIN manejo_personas.persona p_resp ON r.id_persona = p_resp.id_persona
LEFT JOIN manejo_personas.socio s ON gf.id_grupo = s.id_grupo
LEFT JOIN manejo_personas.persona p_socio ON s.id_persona = p_socio.id_persona;
GO