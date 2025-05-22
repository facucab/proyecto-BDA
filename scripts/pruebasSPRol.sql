-- PRUEBAS Rol
-- CREACION
-- Casos normales con roles válidos
EXEC manejo_personas.CreacionRol @nombre = 'profesor';
EXEC manejo_personas.CreacionRol @nombre = 'jefe de tesoreria';
EXEC manejo_personas.CreacionRol @nombre = 'administrativo de cobranza';
EXEC manejo_personas.CreacionRol @nombre = 'administrativo de morosidad';
EXEC manejo_personas.CreacionRol @nombre = 'administrativo de facturacion';
EXEC manejo_personas.CreacionRol @nombre = 'administrativo socio';
EXEC manejo_personas.CreacionRol @nombre = 'socio web';
EXEC manejo_personas.CreacionRol @nombre = 'presidente';
EXEC manejo_personas.CreacionRol @nombre = 'vicepresidente';
EXEC manejo_personas.CreacionRol @nombre = 'secretario';
EXEC manejo_personas.CreacionRol @nombre = 'vocal';

-- Nombre vacío
EXEC manejo_personas.CreacionRol @nombre = ''; -- Resultado: El nombre no puede ser nulo

-- Nombre ya existente
EXEC manejo_personas.CreacionRol @nombre = 'profesor'; -- Resultado: Ese rol ya existe

-- MODIFICACION
-- Caso normal
EXEC manejo_personas.ModificacionRol 
@id = 1,
@nombre_nuevo = 'profesor titular'; -- Resultado: Rol modificado

-- Id inexistente
EXEC manejo_personas.ModificacionRol 
@id = 999999,
@nombre_nuevo = 'tesorero'; -- Resultado: id no existente

-- Nombre repetido
EXEC manejo_personas.ModificacionRol 
@id = 2,
@nombre_nuevo = 'profesor'; -- Resultado: Ese rol ya esta registrado

-- ELIMINACION
-- Caso normal
EXEC manejo_personas.EliminacionRol
@id = 11; -- Resultado: Rol eliminado

-- Id inexistente
EXEC manejo_personas.EliminacionRol
@id = 999999; -- Resultado: id no existente