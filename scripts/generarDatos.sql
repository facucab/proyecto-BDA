USE Com5600G01;
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

DECLARE @i INT = 1;
DECLARE @nombre NVARCHAR(50), @apellido NVARCHAR(50), @dni VARCHAR(9), @email VARCHAR(320), @fecha_nac DATE, @telefono NVARCHAR(20);
DECLARE @id_persona INT, @id_usuario INT, @id_rol INT;
DECLARE @username VARCHAR(50), @password_hash VARCHAR(256);

WHILE @i <= (SELECT COUNT(*) FROM @roles)
BEGIN
    -- Datos random
    SET @nombre = 'Nombre' + CAST(@i AS NVARCHAR(10));
    SET @apellido = 'Apellido' + CAST(@i AS NVARCHAR(10));
    SET @dni = RIGHT('00000000' + CAST(40000000 + @i AS VARCHAR(9)), 9);
    SET @email = LOWER(@nombre + '.' + @apellido + '@mail.com');
    SET @fecha_nac = DATEADD(YEAR, -25 - @i, GETDATE());
    SET @telefono = '11' + RIGHT('00000000' + CAST(10000000 + @i AS VARCHAR(8)), 8);

    -- Crear persona
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
    SET @username = LOWER(@nombre + @apellido);
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
    SET @username = LOWER(REPLACE(@prof_nombre, ' ', '') + REPLACE(@prof_apellido, ' ', ''));
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


