-- PRUEBAS Obra Social

-- CREACION

-- Caso normal
EXEC manejo_personas.CreacionObraSocial @nombre = 'OSDE Mal Creado';
EXEC manejo_personas.CreacionObraSocial @nombre = 'Swiss Medical';
EXEC manejo_personas.CreacionObraSocial @nombre = 'Galeno';
EXEC manejo_personas.CreacionObraSocial @nombre = 'Medife';
EXEC manejo_personas.CreacionObraSocial @nombre = 'OMINT';
EXEC manejo_personas.CreacionObraSocial @nombre = 'Sancor Salud';
EXEC manejo_personas.CreacionObraSocial @nombre = 'IOMA'; 

-- Nombre vacio
EXEC manejo_personas.CreacionObraSocial @nombre = ''; -- Resultado: El nombre no puede ser nulo

-- Nombre ya existente
EXEC manejo_personas.CreacionObraSocial @nombre = 'IOMA'; -- Resultado: Ya hay una obra social con ese nombre

-- MODIFICACION

-- Caso normal
EXEC manejo_personas.ModificacionObraSocial 
@id = 1,
@nombre_nuevo = 'OSDE' -- Resultado: Obra Social Ingresada, corrigio el nombre al correcto

-- Id inexistente
EXEC manejo_personas.ModificacionObraSocial 
@id = 999999,
@nombre_nuevo = 'TEST' -- Resultado: id no existente

-- Nombre Repetido
EXEC manejo_personas.ModificacionObraSocial 
@id = 5,
@nombre_nuevo = 'OSDE' -- Resultado: Esa obra social ya esta registrada


-- ELIMINACION

-- Caso Normal
EXEC manejo_personas.EliminacionObraSocial
@id = 10 -- Resultado: Obra Social eliminada

-- id inexistente
EXEC manejo_personas.EliminacionObraSocial
@id = 999999 -- Resultado: id no existente