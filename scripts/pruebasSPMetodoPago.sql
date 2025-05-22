-- PRUEBAS Medios de Pago

-- CREACI�N

-- Caso normal
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Tarjeta de Credito';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Tarjeta de Debito';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Mercado Pago';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Transferencia Bancaria';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Cuenta DNI';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Rapipago';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Pago F�cil';
-- Resultado: Nuevo metodo de pago creado

-- Nombre vac�o
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = ''; -- Resultado: El nombre no puede ser nulo

-- Nombre ya existente
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Mercado Pago'; -- Resultado: Ya hay un metodo de pago con ese nombre

-- MODIFICACI�N

-- Caso normal
EXEC pagos_y_facturas.ModificacionMetodoPago
@id = 1,
@nombre_nuevo = 'Visa Cr�dito' -- Resultado: Metodo de pago modificado

-- Id inexistente
EXEC pagos_y_facturas.ModificacionMetodoPago
@id = 999999,
@nombre_nuevo = 'TEST' -- Resultado: id no existente

-- Nombre repetido
EXEC pagos_y_facturas.ModificacionMetodoPago 
@id = 5,
@nombre_nuevo = 'Mercado Pago' -- Resultado: Ese metodo de pago ya esta registrado


-- ELIMINACI�N

-- Caso normal
EXEC pagos_y_facturas.EliminacionMetodoPago
@id = 3 -- Resultado: Medio de pago eliminado

-- id inexistente
EXEC pagos_y_facturas.EliminacionMetodoPago
@id = 999999 -- Resultado: id no existente
