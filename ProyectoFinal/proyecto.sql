-- ---------------------------------------------------------------------------------------------------
-- Proyecto Final - Taller de base de datos
-- Integrantes: Vannesa Tamayo Nuñez, Jesus Antonio Gutierres Orenda, Santiago Antonio Mora Nuñez
-- 10-Diciembre-2024
-- ---------------------------------------------------------------------------------------------------

-- ---------------------------------------------------------------------------------------------------
-- Problema 1: Hecho por Jesus Antonio Gutierrez Orenda
-CREATE PROCEDURE sp_RegistraEquipo
    @IdCliente INT,                -- ID del cliente al que pertenece el equipo
    @IdModelo INT,                 -- ID del modelo del equipo
    @NumeroSerie VARCHAR(50),      -- Número de serie del equipo
    @EstadoInicial VARCHAR(255)    -- Estado inicial del equipo
AS
BEGIN
    -- Iniciar la transacción
    BEGIN TRANSACTION;

    DECLARE @ModeloExistente INT;

    -- Verificar si el modelo de equipo existe
    SELECT @ModeloExistente = COUNT(*) 
    FROM ModelosEquipos 
    WHERE IdModelo = @IdModelo;

    -- Si el modelo existe, registrar el equipo
    IF @ModeloExistente > 0
    BEGIN
        -- Insertar el equipo en la tabla Equipos
        INSERT INTO Equipos (IdCliente, IdModelo, NumeroSerie, EstadoInicial)
        VALUES (@IdCliente, @IdModelo, @NumeroSerie, @EstadoInicial);
		
        -- Confirmar la transacción
        COMMIT TRANSACTION;
	
        PRINT 'Equipo registrado correctamente.';
    END
	;     -- Estado inicial del equipo

    ELSE
    BEGIN
        -- Si el modelo no existe, revertir la transacción
        ROLLBACK TRANSACTION;
        
        PRINT 'Error: El modelo no existe en la base de datos.';
    END
END;


select*from Equipos ---------------------------------------------------------------------------------------------------


-- ---------------------------------------------------------------------------------------------------
-- Problema 2: Hecho por Vannesa Tamayo Nuñez
-- ---------------------------------------------------------------------------------------------------


-- ---------------------------------------------------------------------------------------------------
-- Problema 3: Hecho por Santiago Antonio Mora Nuñez
-- ---------------------------------------------------------------------------------------------------
-- Función para generar una factura
CREATE OR REPLACE FUNCTION generar_factura(_IdTicket INT)
RETURNS INT AS $$
DECLARE
    _MontoTotal NUMERIC(10, 2);
    _IdFactura INT;
BEGIN
    -- Validar que el ticket exista y esté finalizado
    IF NOT EXISTS (SELECT 1 FROM TicketsReparacion WHERE IdTicket = _IdTicket AND Estado = 'Finalizado') THEN
        RAISE EXCEPTION 'El ticket % no existe o no está finalizado', _IdTicket;
    END IF;
    -- Calcular el monto total basado en los detalles de reparación asociados al ticket
    SELECT SUM(d.CantidadUsada * r.PrecioUnitario)
    INTO _MontoTotal
    FROM DetallesReparacion d
    JOIN Refacciones r ON d.IdRefaccion = r.IdRefaccion
    WHERE d.IdTicket = _IdTicket;
    -- Validar que el monto sea válido
    IF _MontoTotal IS NULL OR _MontoTotal <= 0 THEN
        RAISE EXCEPTION 'El monto total para el ticket % no es válido', _IdTicket;
    END IF;
    -- Insertar la factura
    INSERT INTO Facturas (IdTicket, MontoTotal, EstadoPago)
    VALUES (_IdTicket, _MontoTotal, 'Pendiente')
    RETURNING IdFactura INTO _IdFactura;
    RETURN _IdFactura;
END;
$$ LANGUAGE plpgsql;

-- Procedimiento para procesar el pago de una factura
CREATE OR REPLACE PROCEDURE procesar_pago(_IdFactura INT)
AS $$
DECLARE
    _EstadoPago VARCHAR(50);
BEGIN
    -- Validar que la factura exista
    SELECT EstadoPago INTO _EstadoPago
    FROM Facturas
    WHERE IdFactura = _IdFactura;
    IF _EstadoPago IS NULL THEN
        RAISE EXCEPTION 'La factura % no existe', _IdFactura;
    END IF;
    -- Verificar que la factura esté pendiente
    IF _EstadoPago != 'Pendiente' THEN
        RAISE EXCEPTION 'La factura % ya ha sido pagada o no está en estado pendiente', _IdFactura;
    END IF;
    -- Actualizar el estado de la factura a pagado
    UPDATE Facturas
    SET EstadoPago = 'Pagado'
    WHERE IdFactura = _IdFactura;
    -- Actualizar el estado del ticket asociado, si aplica
    UPDATE TicketsReparacion
    SET Estado = 'Pagado'
    WHERE IdTicket = (SELECT IdTicket FROM Facturas WHERE IdFactura = _IdFactura);
    RAISE NOTICE 'El pago de la factura % se ha procesado correctamente', _IdFactura;
END;
$$ LANGUAGE plpgsql;

-- Generar una factura para un ticket finalizado
SELECT generar_factura(1);

-- Procesar el pago de una factura
CALL procesar_pago(1);
