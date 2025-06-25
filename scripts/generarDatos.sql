USE Com5600G01;
GO

CREATE OR ALTER FUNCTION dbo.NormalizarTexto(@texto NVARCHAR(200)) RETURNS NVARCHAR(200)
AS
BEGIN
    SET @texto = UPPER(@texto)
    SET @texto = REPLACE(@texto, 'Á', 'A')
    SET @texto = REPLACE(@texto, 'É', 'E')
    SET @texto = REPLACE(@texto, 'Í', 'I')
    SET @texto = REPLACE(@texto, 'Ó', 'O')
    SET @texto = REPLACE(@texto, 'Ú', 'U')
    SET @texto = REPLACE(@texto, 'Ü', 'U')
    SET @texto = REPLACE(@texto, 'Ñ', 'N')
    RETURN @texto
END
GO

-- Crear roles según la tabla y agregar el rol de profesor
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'Jefe de Tesorería' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'Jefe de Tesorería');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'Administrativo de Cobranza' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'Administrativo de Cobranza');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'Administrativo de Morosidad' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'Administrativo de Morosidad');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'Administrativo de Facturacion' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'Administrativo de Facturacion');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'Administrativo Socio' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'Administrativo Socio');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'Socios web' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'Socios web');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'presidente' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'presidente');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'vicepresidente' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'vicepresidente');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'secretario' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'secretario');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'vocales' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'vocales');
INSERT INTO manejo_personas.rol (descripcion)
SELECT 'profesor' WHERE NOT EXISTS (SELECT 1 FROM manejo_personas.rol WHERE descripcion = 'profesor');
GO

-- Crear personas y usuarios random para todos los roles excepto profesor
DECLARE @roles TABLE (descripcion VARCHAR(100));
INSERT INTO @roles (descripcion) VALUES
('Jefe de Tesorería'), ('Administrativo de Cobranza'), ('Administrativo de Morosidad'),
('Administrativo de Facturacion'), ('Administrativo Socio'), ('Socios web'),
('presidente'), ('vicepresidente'), ('secretario'), ('vocales');

-- Listas de nombres y apellidos reales
DECLARE @nombres TABLE (nombre NVARCHAR(50));
INSERT INTO @nombres VALUES ('Juan'), ('María'), ('Pedro'), ('Lucía'), ('Carlos'), ('Ana'), ('Sofía'), ('Martín'), ('Valentina'), ('Javier');

DECLARE @apellidos TABLE (apellido NVARCHAR(50));
INSERT INTO @apellidos VALUES ('Gómez'), ('Pérez'), ('Rodríguez'), ('Fernández'), ('López'), ('Martínez'), ('García'), ('Sánchez'), ('Romero'), ('Torres');

DECLARE @i INT = 1;
DECLARE @nombre NVARCHAR(50), @apellido NVARCHAR(50), @dni VARCHAR(9), @email VARCHAR(320), @fecha_nac DATE, @telefono NVARCHAR(20);
DECLARE @id_persona INT, @id_usuario INT, @id_rol INT;
DECLARE @username VARCHAR(50), @password_hash VARCHAR(256);

WHILE @i <= (SELECT COUNT(*) FROM @roles)
BEGIN
    -- Seleccionar nombre y apellido realista
    SELECT TOP 1 @nombre = nombre FROM (SELECT nombre, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn FROM @nombres) n WHERE n.rn = @i;
    SELECT TOP 1 @apellido = apellido FROM (SELECT apellido, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn FROM @apellidos) a WHERE a.rn = @i;

    -- Si hay más roles que nombres/apellidos, cicla la lista
    IF @nombre IS NULL SELECT TOP 1 @nombre = nombre FROM @nombres;
    IF @apellido IS NULL SELECT TOP 1 @apellido = apellido FROM @apellidos;

    SET @dni = RIGHT('00000000' + CAST(40000000 + @i AS VARCHAR(9)), 9);
    SET @email = LOWER(@nombre + '.' + @apellido + '@mail.com');
    SET @fecha_nac = DATEADD(YEAR, -25 - @i, GETDATE());
    SET @telefono = '11' + RIGHT('00000000' + CAST(10000000 + @i AS VARCHAR(8)), 8);

    -- Crear persona
    IF @nombre IS NOT NULL
        SET @nombre = dbo.NormalizarTexto(LTRIM(RTRIM(@nombre)));
    IF @apellido IS NOT NULL
        SET @apellido = dbo.NormalizarTexto(LTRIM(RTRIM(@apellido)));
    EXEC manejo_personas.CrearPersona
        @dni = @dni,
        @nombre = @nombre,
        @apellido = @apellido,
        @email = @email,
        @fecha_nac = @fecha_nac,
        @telefono = @telefono;

    -- Obtener id_persona
    SELECT @id_persona = id_persona FROM manejo_personas.persona WHERE dni = @dni;

    -- Crear usuario
    SET @username = dbo.NormalizarTexto(LTRIM(RTRIM(@nombre + @apellido)));
    SET @password_hash = REPLICATE('A', 256); -- Hash dummy
    EXEC manejo_personas.CrearUsuario
        @id_persona = @id_persona,
        @username = @username,
        @password_hash = @password_hash;

    -- Obtener id_usuario
    SELECT @id_usuario = id_usuario FROM manejo_personas.usuario WHERE id_persona = @id_persona;

    -- Obtener id_rol
    SELECT @id_rol = id_rol FROM manejo_personas.rol WHERE descripcion = (SELECT descripcion FROM (SELECT ROW_NUMBER() OVER (ORDER BY descripcion) AS rn, descripcion FROM @roles) r WHERE r.rn = @i);

    -- Asignar rol
    INSERT INTO manejo_personas.Usuario_Rol (id_usuario, id_rol) VALUES (@id_usuario, @id_rol);

    SET @i = @i + 1;
END

-- Crear personas específicas para el rol de profesor
DECLARE @profesores TABLE (nombre NVARCHAR(50), apellido NVARCHAR(50));
INSERT INTO @profesores VALUES
('Pablo', 'Rodrigez'),
('Ana Paula', 'Alvarez'),
('Kito', 'Mihaji'),
('Carolina', 'Herreta'),
('Paula', 'Quiroga'),
('Hector', 'Alvarez'),
('Roxana', 'Guiterrez');

DECLARE @prof_nombre NVARCHAR(50), @prof_apellido NVARCHAR(50);

DECLARE prof_cursor CURSOR FOR SELECT nombre, apellido FROM @profesores;
OPEN prof_cursor;
FETCH NEXT FROM prof_cursor INTO @prof_nombre, @prof_apellido;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @dni = RIGHT('00000000' + CAST(50000000 + ABS(CHECKSUM(NEWID())) % 1000000 AS VARCHAR(9)), 9);
    SET @email = LOWER(REPLACE(@prof_nombre, ' ', '') + '.' + REPLACE(@prof_apellido, ' ', '') + '@mail.com');
    SET @fecha_nac = DATEADD(YEAR, -30, GETDATE());
    SET @telefono = '11' + RIGHT('00000000' + CAST(20000000 + ABS(CHECKSUM(NEWID())) % 1000000 AS VARCHAR(8)), 8);

    -- Crear persona
    IF @prof_nombre IS NOT NULL
        SET @prof_nombre = dbo.NormalizarTexto(LTRIM(RTRIM(@prof_nombre)));
    IF @prof_apellido IS NOT NULL
        SET @prof_apellido = dbo.NormalizarTexto(LTRIM(RTRIM(@prof_apellido)));
    EXEC manejo_personas.CrearPersona
        @dni = @dni,
        @nombre = @prof_nombre,
        @apellido = @prof_apellido,
        @email = @email,
        @fecha_nac = @fecha_nac,
        @telefono = @telefono;

    -- Obtener id_persona
    SELECT @id_persona = id_persona FROM manejo_personas.persona WHERE dni = @dni;

    -- Crear usuario
    SET @username = dbo.NormalizarTexto(LTRIM(RTRIM(REPLACE(@prof_nombre, ' ', '') + REPLACE(@prof_apellido, ' ', ''))));
    SET @password_hash = REPLICATE('B', 256); -- Hash dummy
    EXEC manejo_personas.CrearUsuario
        @id_persona = @id_persona,
        @username = @username,
        @password_hash = @password_hash;

    -- Obtener id_usuario
    SELECT @id_usuario = id_usuario FROM manejo_personas.usuario WHERE id_persona = @id_persona;

    -- Obtener id_rol de profesor
    SELECT @id_rol = id_rol FROM manejo_personas.rol WHERE descripcion = 'profesor';

    -- Asignar rol
    INSERT INTO manejo_personas.Usuario_Rol (id_usuario, id_rol) VALUES (@id_usuario, @id_rol);

    FETCH NEXT FROM prof_cursor INTO @prof_nombre, @prof_apellido;
END
CLOSE prof_cursor;
DEALLOCATE prof_cursor;
GO

-- Crear personas adicionales para ser socios
PRINT 'Creando personas adicionales para ser socios...';
GO

-- Listas de nombres y apellidos para socios
DECLARE @nombres_socios TABLE (nombre NVARCHAR(50));
INSERT INTO @nombres_socios VALUES ('Alejandro'), ('Beatriz'), ('Claudio'), ('Daniela'), ('Esteban'), ('Florencia'), ('Gabriel'), ('Laura'), ('Ivan'), ('Julieta'), ('Mariano'), ('Natalia'), ('Oscar'), ('Patricia'), ('Ricardo');

DECLARE @apellidos_socios TABLE (apellido NVARCHAR(50));
INSERT INTO @apellidos_socios VALUES ('Diaz'), ('Acosta'), ('Moreno'), ('Suarez'), ('Castro'), ('Gimenez'), ('Vazquez'), ('Benitez'), ('Ramirez'), ('Rojas'), ('Heredia'), ('Flores'), ('Vega'), ('Ramos'), ('Soria');

DECLARE @k INT = 1;
DECLARE @personas_a_crear_socios INT = 25; -- Para llegar de SN-4135 a SN-4153 y un poco más

DECLARE @socio_nombre NVARCHAR(50), @socio_apellido NVARCHAR(50), @socio_dni VARCHAR(9), @socio_email VARCHAR(320), @socio_fecha_nac DATE, @socio_telefono NVARCHAR(20);

WHILE @k <= @personas_a_crear_socios
BEGIN
    -- Seleccionar nombre y apellido aleatorio
    SELECT TOP 1 @socio_nombre = nombre FROM @nombres_socios ORDER BY NEWID();
    SELECT TOP 1 @socio_apellido = apellido FROM @apellidos_socios ORDER BY NEWID();

    SET @socio_dni = RIGHT('00000000' + CAST(70000000 + @k AS VARCHAR(9)), 9); -- Nuevo rango de DNI
    SET @socio_email = LOWER(REPLACE(@socio_nombre, ' ', '') + '.' + REPLACE(@socio_apellido, ' ', '') + CAST(@k AS VARCHAR(3)) + '@sociomail.com'); -- Email único
    SET @socio_fecha_nac = DATEADD(YEAR, -(18 + ABS(CHECKSUM(NEWID())) % 40), GETDATE()); -- Edades entre 18 y 58
    SET @socio_telefono = '11' + RIGHT('00000000' + CAST(50000000 + @k AS VARCHAR(8)), 8); -- Nuevo rango de teléfonos

    -- Crear persona (asumiendo que CrearPersona se encarga de normalizar)
    IF NOT EXISTS (SELECT 1 FROM manejo_personas.persona WHERE dni = @socio_dni OR email = @socio_email)
    BEGIN
        EXEC manejo_personas.CrearPersona
            @dni = @socio_dni,
            @nombre = @socio_nombre,
            @apellido = @socio_apellido,
            @email = @socio_email,
            @fecha_nac = @socio_fecha_nac,
            @telefono = @socio_telefono;
    END

    SET @k = @k + 1;
END
GO
PRINT 'Creación de personas adicionales finalizada.';
GO

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


--Genera actividades
EXEC manejo_actividades.CrearActividad
	@nombre_actividad = dbo.NormalizarTexto(LTRIM(RTRIM('Fulbol'))),
	@costo_mensual = 2000.00,
	@vigencia = '2024-12-31';