USE Com5600G01;
GO

BEGIN TRAN TestMetodoPago;
GO

-- CrearMetodoPago

-- Caso normal 1
EXEC facturacion.CrearMetodoPago
    @nombre = 'Efectivo';
-- Resultado esperado: OK, Método de pago creado correctamente.
GO

-- Caso normal 2
EXEC facturacion.CrearMetodoPago
    @nombre = 'Tarjeta';
-- Resultado esperado: OK, Método de pago creado correctamente.
GO

-- Caso normal 3
EXEC facturacion.CrearMetodoPago
    @nombre = 'Master Card';
-- Resultado esperado: OK, Método de pago creado correctamente.
GO

-- Caso normal 4
EXEC facturacion.CrearMetodoPago
    @nombre = 'Visa';
-- Resultado esperado: OK, Método de pago creado correctamente.
GO

-- Caso normal 5
EXEC facturacion.CrearMetodoPago
    @nombre = 'American Express';
-- Resultado esperado: OK, Método de pago creado correctamente.
GO

-- Nombre vacío
EXEC facturacion.CrearMetodoPago
    @nombre = '';
-- Resultado esperado: Error, El nombre es obligatorio.
GO

-- Nombre nulo
EXEC facturacion.CrearMetodoPago
    @nombre = NULL;
-- Resultado esperado: Error, El nombre es obligatorio.
GO

-- Nombre duplicado
EXEC facturacion.CrearMetodoPago
    @nombre = 'Efectivo';
-- Resultado esperado: Error, Ya existe un método de pago con ese nombre.
GO

-- ModificarMetodoPago

-- Caso normal
EXEC facturacion.ModificarMetodoPago
    @id_metodo_pago = 1,
    @nombre         = 'EfectivoActualizado';
-- Resultado esperado: OK, Método de pago modificado correctamente.
GO

-- ID inexistente
EXEC facturacion.ModificarMetodoPago
    @id_metodo_pago = 99999,
    @nombre         = 'NoExiste';
-- Resultado esperado: Error, Método de pago no encontrado.
GO

-- Nombre vacío
EXEC facturacion.ModificarMetodoPago
    @id_metodo_pago = 1,
    @nombre         = '';
-- Resultado esperado: Error, El nombre es obligatorio.
GO

-- Nombre duplicado en otro registro
EXEC facturacion.ModificarMetodoPago
    @id_metodo_pago = 1,
    @nombre         = 'Tarjeta';
-- Resultado esperado: Error, Ya existe otro método de pago con ese nombre.
GO

-- EliminarMetodoPago

-- Caso normal 1
EXEC facturacion.EliminarMetodoPago
    @id_metodo_pago = 1;
-- Resultado esperado: OK, Método de pago eliminado correctamente.
GO

-- Caso normal 2
EXEC facturacion.EliminarMetodoPago
    @id_metodo_pago = 2;
-- Resultado esperado: OK, Método de pago eliminado correctamente.
GO

-- ID inexistente
EXEC facturacion.EliminarMetodoPago
    @id_metodo_pago = 99999;
-- Resultado esperado: Error, Método de pago no encontrado.
GO

-- Intentar eliminar nuevamente
EXEC facturacion.EliminarMetodoPago
    @id_metodo_pago = 1;
-- Resultado esperado: Error, Método de pago no encontrado.
GO

ROLLBACK TRAN TestMetodoPago;
GO

SELECT *
FROM facturacion.metodo_pago
GO