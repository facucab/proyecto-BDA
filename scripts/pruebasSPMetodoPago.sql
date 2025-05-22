-- PRUEBAS Medios de Pago

-- CREACIÓN

-- Caso normal
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Tarjeta de Credito';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Tarjeta de Debito';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Mercado Pago';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Transferencia Bancaria';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Cuenta DNI';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Rapipago';
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Pago Fácil';
-- Resultado: Nuevo metodo de pago creado

-- Nombre vacío
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = ''; -- Resultado: El nombre no puede ser nulo

-- Nombre ya existente
EXEC pagos_y_facturas.CreacionMetodoPago @nombre = 'Mercado Pago'; -- Resultado: Ya hay un metodo de pago con ese nombre

-- MODIFICACIÓN

-- Caso normal
EXEC pagos_y_facturas.ModificacionMetodoPago
@id = 1,
@nombre_nuevo = 'Visa Crédito' -- Resultado: Metodo de pago modificado

-- Id inexistente
EXEC pagos_y_facturas.ModificacionMetodoPago
@id = 999999,
@nombre_nuevo = 'TEST' -- Resultado: id no existente

-- Nombre repetido
EXEC pagos_y_facturas.ModificacionMetodoPago 
@id = 5,
@nombre_nuevo = 'Mercado Pago' -- Resultado: Ese metodo de pago ya esta registrado


-- ELIMINACIÓN

-- Caso normal
EXEC pagos_y_facturas.EliminacionMetodoPago
@id = 3 -- Resultado: Medio de pago eliminado

-- id inexistente
EXEC pagos_y_facturas.EliminacionMetodoPago
@id = 999999 -- Resultado: id no existente
