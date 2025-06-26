/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

	Pruebas para Crear, Modificar y Eliminar Factura
*/


--Creacion

--Caso normal
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pendiente', 
    @monto_a_pagar = 1500.50, 
    @id_persona = 1, 
    @id_metodo_pago = 1;
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pagado', 
    @monto_a_pagar = 2000.00, 
    @id_persona = 2, 
    @id_metodo_pago = 2;
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Vencido', 
    @monto_a_pagar = 750.25, 
    @id_persona = 3, 
    @id_metodo_pago = 3;
-- Resultado: Factura creada correctamente

--Metodo de pago inexistente
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Vencido', 
    @monto_a_pagar = 750.25, 
    @id_persona = 3, 
    @id_metodo_pago = 99999;
--Resultado: Método de pago no valido

--Persona inexistente
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pagado', 
    @monto_a_pagar = 2000.00, 
    @id_persona = 999999, 
    @id_metodo_pago = 2;
--Resultado: Persona no existente

--Monto invalido
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = 'Pendiente', 
    @monto_a_pagar = -10.25, 
    @id_persona = 1, 
    @id_metodo_pago = 1;
--Resultado: Monto invalido

--Estado invalido
EXEC pagos_y_facturas.CreacionFactura 
    @estado_pago = '', 
    @monto_a_pagar = 1000.25, 
    @id_persona = 1, 
    @id_metodo_pago = 1;
--Resultado: Estado de pago no puede ser nulo o vacio

--Modificacion

--Caso normal
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 1,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 1000.00,
    @nuevo_metodo_pago =1;
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 2,
    @nuevo_estado_pago = 'Pagado',
    @nuevo_monto = 2000.00,
    @nuevo_metodo_pago =2;
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 3000.00,
    @nuevo_metodo_pago =3;
--Resultado: Factura actualizada correctamente

--Metodo de pago inexistente
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 3000.00,
    @nuevo_metodo_pago =99993;
--Resultado: Metodo de pago invalido

--Monto invalido
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 0,
    @nuevo_metodo_pago =3;
--Resultado: Monto invalido

--Estado vacio
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 3,
    @nuevo_estado_pago = '',
    @nuevo_monto = 4000.00,
    @nuevo_metodo_pago =2;
--Resultado: Estado invalido

--Id inexistente
EXEC pagos_y_facturas.ModificacionFactura
    @id_factura = 99999,
    @nuevo_estado_pago = 'Pendiente',
    @nuevo_monto = 3000.00,
    @nuevo_metodo_pago =3;
--Resultado: Factura no existente

--Eliminacion

--Casos Normales
EXEC pagos_y_facturas.EliminacionFactura @id_factura =1;
EXEC pagos_y_facturas.EliminacionFactura @id_factura =3;
EXEC pagos_y_facturas.EliminacionFactura @id_factura =2;
--Resultado: Factura eliminada correctamente

--Id invalido
EXEC pagos_y_facturas.EliminacionFactura @id_factura =99999;
--Resultado: La factura no existe