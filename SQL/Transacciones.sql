use Proyecto2;
--------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION;

BEGIN TRY
    -- Actualizar inventario de refacción
    UPDATE Refacciones
    SET CantidadDisponible = CantidadDisponible - 1
    WHERE idRefaccion = 1;

    -- Verificar que no se haya agotado la cantidad de refacción
    IF EXISTS (SELECT 1 FROM Refacciones WHERE idRefaccion = 1 AND CantidadDisponible < 0)
    BEGIN
        RAISERROR('No hay suficientes refacciones disponibles en el inventario.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Crear un nuevo ticket de reparación
    INSERT INTO TicketsReparacion (idEquipo, idTecnico, ProblemaReportado, Estado)
    VALUES (1, 2, 'Pantalla dañada', 'Pendiente');

    COMMIT TRANSACTION;
    PRINT 'Inventario actualizado y ticket de reparación creado.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;


------------------------------------------------------------------------------------------------

BEGIN TRANSACTION;

BEGIN TRY
    -- Actualizar el estado del ticket
    UPDATE TicketsReparacion
    SET Estado = 'Finalizado', FechaFinalizacion = GETDATE()
    WHERE idTicketReparacion = 1;

    -- Crear una nueva factura para el ticket
    INSERT INTO Facturas (idTicketReparacion, MontoTotal, EstadoPago)
    VALUES (1, 150.00, 'Pendiente');

    COMMIT TRANSACTION;
    PRINT 'Estado del ticket actualizado y factura generada.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;




-----------------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION;

BEGIN TRY
    -- Insertar un nuevo detalle de reparación
    INSERT INTO DetallesReparacion (idTicketReparacion, idRefaccion, CantidadUsada)
    VALUES (1, 1, 2);

    -- Actualizar el inventario de la refacción utilizada
    UPDATE Refacciones
    SET CantidadDisponible = CantidadDisponible - 2
    WHERE idRefaccion = 1;

    -- Verificar que no se quede en negativo
    IF EXISTS (SELECT 1 FROM Refacciones WHERE idRefaccion = 1 AND CantidadDisponible < 0)
    BEGIN
        RAISERROR('La cantidad de refacciones usadas excede la disponible en el inventario', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    COMMIT TRANSACTION;
    PRINT 'Detalle de reparación registrado y inventario ajustado.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;


----------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION;

BEGIN TRY
    -- Verificar si el técnico está disponible (suponiendo que solo puede estar en un ticket a la vez)
    IF EXISTS (SELECT 1 FROM TicketsReparacion WHERE idTecnico = 2 AND Estado = 'Pendiente')
    BEGIN
        RAISERROR('El técnico ya está asignado a otro ticket.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Crear un nuevo ticket de reparación
    INSERT INTO TicketsReparacion (idEquipo, idTecnico, ProblemaReportado, Estado)
    VALUES (1, 2, 'Batería defectuosa', 'Pendiente');

    COMMIT TRANSACTION;
    PRINT 'Ticket de reparación creado y técnico asignado.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;


-----------------------------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION;

BEGIN TRY
    -- Verificar si el ticket tiene detalles de reparación asociados
    IF EXISTS (SELECT 1 FROM DetallesReparacion WHERE idTicketReparacion = 1)
    BEGIN
        -- Recuperar las refacciones utilizadas y sus cantidades
        DECLARE @idRefaccion INT, @cantidadUsada INT;
        DECLARE ref_cursor CURSOR FOR
        SELECT idRefaccion, CantidadUsada
        FROM DetallesReparacion
        WHERE idTicketReparacion = 1;

        OPEN ref_cursor;
        FETCH NEXT FROM ref_cursor INTO @idRefaccion, @cantidadUsada;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Actualizar el inventario de refacciones
            UPDATE Refacciones
            SET CantidadDisponible = CantidadDisponible + @cantidadUsada
            WHERE idRefaccion = @idRefaccion;

            FETCH NEXT FROM ref_cursor INTO @idRefaccion, @cantidadUsada;
        END

        CLOSE ref_cursor;
        DEALLOCATE ref_cursor;
    END

    -- Eliminar el ticket de reparación
    DELETE FROM TicketsReparacion WHERE idTicketReparacion = 1;

    COMMIT TRANSACTION;
    PRINT 'Ticket eliminado y inventario actualizado.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;
