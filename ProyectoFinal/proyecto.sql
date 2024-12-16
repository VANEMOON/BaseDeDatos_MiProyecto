-- ---------------------------------------------------------------------------------------------------
-- Proyecto Final - Taller de base de datos
-- Integrantes: Vannesa Tamayo Nuñez, Jesus Antonio Gutierres Orenda, Santiago Antonio Mora Nuñez
-- 10-Diciembre-2024
-- ---------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------
-- Problema 1: Hecho por Jesus Antonio Gutierrez Orenda
s ---------------------------------------------------------------------------------------------------


-- ---------------------------------------------------------------------------------------------------
-- Problema 2: Hecho por Vannesa Tamayo Nuñez
-- ---------------------------------------------------------------------------------------------------


-- ---------------------------------------------------------------------------------------------------
-- Problema 3: Hecho por Santiago Antonio Mora Nuñez
-- ---------------------------------------------------------------------------------------------------
-- Función para generar una factura
-- 2. Función para afectar inventario
CREATE OR REPLACE FUNCTION afectar_inventario_refacciones(_id_refaccion INT, _cantidad_usada INT)
RETURNS BOOLEAN AS $$
DECLARE
    _cantidad_disponible INT;
BEGIN
    SELECT CantidadDisponible INTO _cantidad_disponible FROM Refacciones WHERE IdRefaccion = _id_refaccion;

    IF _cantidad_disponible IS NULL THEN
        RAISE EXCEPTION 'La refacción % no existe', _id_refaccion;
    ELSIF _cantidad_disponible < _cantidad_usada THEN
        RAISE EXCEPTION 'No hay suficiente inventario para la refacción %', _id_refaccion;
    ELSE
        -- Actualizar inventario
        UPDATE Refacciones SET CantidadDisponible = CantidadDisponible - _cantidad_usada WHERE IdRefaccion = _id_refaccion;
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Procedimiento para generar factura
CREATE OR REPLACE PROCEDURE generar_factura(_id_ticket INT)
AS $$
DECLARE
    _monto_total NUMERIC(10, 2) := 0;
    detalle RECORD;
BEGIN
    -- Verificar si el ticket existe
    IF NOT EXISTS (SELECT 1 FROM TicketsReparacion WHERE IdTicket = _id_ticket) THEN
        RAISE EXCEPTION 'El ticket % no existe', _id_ticket;
    END IF;

    -- Verificar si hay detalles de reparación asociados al ticket
    IF NOT EXISTS (SELECT 1 FROM DetallesReparacion WHERE IdTicket = _id_ticket) THEN
        RAISE EXCEPTION 'No hay detalles de reparación asociados al ticket %', _id_ticket;
    END IF;

    -- Calcular el monto total basado en DetallesReparacion
    FOR detalle IN 
        SELECT dr.IdRefaccion, dr.CantidadUsada, r.PrecioUnitario
        FROM DetallesReparacion dr
        JOIN Refacciones r ON dr.IdRefaccion = r.IdRefaccion
        WHERE dr.IdTicket = _id_ticket
    LOOP
        _monto_total := _monto_total + (detalle.CantidadUsada * detalle.PrecioUnitario);

        -- Afectar el inventario de la refacción usada
        PERFORM afectar_inventario_refacciones(detalle.IdRefaccion, detalle.CantidadUsada);
    END LOOP;

    -- Insertar la factura
    INSERT INTO Facturas (IdTicket, MontoTotal, EstadoPago)
    VALUES (_id_ticket, _monto_total, 'Pendiente');

    RAISE NOTICE 'Factura generada para el ticket %, monto total: %', _id_ticket, _monto_total;
END;
$$ LANGUAGE plpgsql;


-- 4. Procedimiento para registrar el pago de una factura
CREATE OR REPLACE PROCEDURE pagar_factura(_id_factura INT)
AS $$
BEGIN
    -- Iniciar transacción
    BEGIN
        -- Verificar si la factura existe
        IF NOT EXISTS (SELECT 1 FROM Facturas WHERE IdFactura = _id_factura) THEN
            RAISE EXCEPTION 'La factura % no existe', _id_factura;
        END IF;

        -- Verificar si ya está pagada
        IF EXISTS (SELECT 1 FROM Facturas WHERE IdFactura = _id_factura AND EstadoPago = 'Pagado') THEN
            RAISE NOTICE 'La factura % ya está pagada', _id_factura;
            RETURN;
        END IF;

        -- Actualizar el estado de la factura a "Pagado"
        UPDATE Facturas SET EstadoPago = 'Pagado' WHERE IdFactura = _id_factura;

        RAISE NOTICE 'Factura % pagada exitosamente', _id_factura;

    EXCEPTION WHEN OTHERS THEN
        -- Revertir transacción si ocurre un error
        RAISE NOTICE 'Error al registrar pago: %', SQLERRM;
        ROLLBACK;
        RETURN;
    END;
END;
$$ LANGUAGE plpgsql;

-- Generar factura para el ticket 68
CALL generar_factura(69);

-- Pagar la factura generada (asegurando primero el ID)
CALL pagar_factura(18);

-- Verificar resultados
SELECT * FROM tecnicos;
SELECT * FROM ticketsreparacion;
SELECT * FROM Facturas;
SELECT * FROM Refacciones;
SELECT * FROM Detallesreparacion;

-- Inserciones --
INSERT INTO TicketsReparacion (IdEquipo, ProblemaReportado, IdTecnico, Estado)
VALUES 
(1, 'Pantalla rota', 72, 'Finalizado'),
(2, 'No enciende', 74, 'Finalizado'),
(3, 'No enciende', 75, 'Finalizado');

INSERT INTO DetallesReparacion (IdTicket, IdRefaccion, CantidadUsada)
VALUES 
(69, 1, 1),
(70, 2, 2),
(71, 3, 2);