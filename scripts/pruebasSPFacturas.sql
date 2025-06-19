/*
	Entrega 4 - Documento de instalaci�n y configuraci�n

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rub�n 
	45234709 | Gauto, Gast�n Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tom�s Andr�s

		Luego de decidirse por un motor de base de datos relacional, lleg� el momento de generar la
	base de datos. En esta oportunidad utilizar�n SQL Server.
	Deber� instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicaci�n de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregar�a al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deber� entregar
	un archivo .sql con el script completo de creaci�n (debe funcionar si se lo ejecuta �tal cual� es
	entregado en una sola ejecuci�n). Incluya comentarios para indicar qu� hace cada m�dulo
	de c�digo.
	Genere store procedures para manejar la inserci�n, modificado, borrado (si corresponde,
	tambi�n debe decidir si determinadas entidades solo admitir�n borrado l�gico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con �SP�.
	Algunas operaciones implicar�n store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Aseg�rense de que los comentarios que acompa�en al c�digo lo expliquen.
	Genere esquemas para organizar de forma l�gica los componentes del sistema y aplique esto
	en la creaci�n de objetos. NO use el esquema �dbo�.
	Todos los SP creados deben estar acompa�ados de juegos de prueba. Se espera que
	realicen validaciones b�sicas en los SP (p/e cantidad mayor a cero, CUIT v�lido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicaci�n de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, n�mero de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la secci�n de pr�cticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
*/

-- Pruebas Facturas

USE Com5600G01;
GO

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
--Resultado: M�todo de pago no valido

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