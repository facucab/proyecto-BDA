/*
	Entrega 4 - Documento de instalación y configuración

	Trabajo Practico DDBBA Entrega 3 - Grupo 1
	Comision 5600 - Viernes Tarde 
	43990422 | Aguirre, Alex Rubén 
	45234709 | Gauto, Gastón Santiago 
	44363498 | Caballero, Facundo 
	40993965 | Cornara Perez, Tomás Andrés

		Luego de decidirse por un motor de base de datos relacional, llegó el momento de generar la
	base de datos. En esta oportunidad utilizarán SQL Server.
	Deberá instalar el DMBS y documentar el proceso. No incluya capturas de pantalla. Detalle
	las configuraciones aplicadas (ubicación de archivos, memoria asignada, seguridad, puertos,
	etc.) en un documento como el que le entregaría al DBA.
	Cree la base de datos, entidades y relaciones. Incluya restricciones y claves. Deberá entregar
	un archivo .sql con el script completo de creación (debe funcionar si se lo ejecuta “tal cual” es
	entregado en una sola ejecución). Incluya comentarios para indicar qué hace cada módulo
	de código.
	Genere store procedures para manejar la inserción, modificado, borrado (si corresponde,
	también debe decidir si determinadas entidades solo admitirán borrado lógico) de cada tabla.
	Los nombres de los store procedures NO deben comenzar con “SP”.
	Algunas operaciones implicarán store procedures que involucran varias tablas, uso de
	transacciones, etc. Puede que incluso realicen ciertas operaciones mediante varios SPs.
	Asegúrense de que los comentarios que acompañen al código lo expliquen.
	Genere esquemas para organizar de forma lógica los componentes del sistema y aplique esto
	en la creación de objetos. NO use el esquema “dbo”.
	Todos los SP creados deben estar acompañados de juegos de prueba. Se espera que
	realicen validaciones básicas en los SP (p/e cantidad mayor a cero, CUIT válido, etc.) y que
	en los juegos de prueba demuestren la correcta aplicación de las validaciones.
	Las pruebas deben realizarse en un script separado, donde con comentarios se indique en
	cada caso el resultado esperado
	El archivo .sql con el script debe incluir comentarios donde consten este enunciado, la fecha
	de entrega, número de grupo, nombre de la materia, nombres y DNI de los alumnos.
	Entregar todo en un zip (observar las pautas para nomenclatura antes expuestas) mediante
	la sección de prácticas de MIEL. Solo uno de los miembros del grupo debe hacer la entrega.
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