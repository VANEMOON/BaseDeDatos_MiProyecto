CREATE PROCEDURE sp_GenerarTicketReparacion
    @idEquipo INT,
    @idTecnico INT = NULL,
    @ProblemaReportado NVARCHAR(255)
AS
BEGIN
    -- 1. Verificar que el equipo exista
    IF NOT EXISTS (SELECT 1 FROM Equipos WHERE idEquipo = @idEquipo)
    BEGIN
        SELECT 'Error: El equipo no existe.' AS Mensaje;
        RETURN;
    END

    -- 2. Verificar que el equipo tenga un cliente asignado
    IF NOT EXISTS (SELECT 1 FROM Equipos WHERE idEquipo = @idEquipo AND idUsuario IS NOT NULL)
    BEGIN
        SELECT 'Error: El equipo no tiene un cliente asignado.' AS Mensaje;
        RETURN;
    END

    -- 3. Verificar que el equipo no tenga ya un ticket pendiente
    IF EXISTS (SELECT 1 FROM TicketsReparacion WHERE idEquipo = @idEquipo AND Estado = 'Pendiente')
    BEGIN
        SELECT 'Error: El equipo ya tiene un ticket de reparaci�n pendiente.' AS Mensaje;
        RETURN;
    END

    -- 4. Verificar que la descripci�n del problema no est� vac�a
    IF @ProblemaReportado IS NULL OR LEN(@ProblemaReportado) = 0
    BEGIN
        SELECT 'Error: La descripci�n del problema no puede estar vac�a.' AS Mensaje;
        RETURN;
    END

    -- 5. Verificar que el t�cnico exista (si se proporciona un idTecnico)
    IF @idTecnico IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Tecnicos WHERE idTecnico = @idTecnico
    )
    BEGIN
        SELECT 'Error: El t�cnico no existe.' AS Mensaje;
        RETURN;
    END

    -- Iniciar la transacci�n
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insertar el nuevo ticket de reparaci�n
        INSERT INTO TicketsReparacion (idEquipo, idTecnico, ProblemaReportado, Estado, FechaCreacion)
        VALUES (@idEquipo, @idTecnico, @ProblemaReportado, 'Pendiente', GETDATE());

        -- Confirmar la transacci�n
        COMMIT TRANSACTION;
        SELECT '�xito: Ticket de reparaci�n generado correctamente.' AS Mensaje;

    END TRY
    BEGIN CATCH
        -- En caso de error, deshacer la transacci�n
        ROLLBACK TRANSACTION;
        SELECT 'Error: No se pudo generar el ticket de reparaci�n.' AS Mensaje,
               ERROR_MESSAGE() AS DetalleError;
    END CATCH
END;
GO




---------------------------------------------------------INSERCION DE DATOS----------------------------------------------------


-- Insertar Usuarios
INSERT INTO Usuarios (idUsuario, Nombre, ApellidoPaterno, ApellidoMaterno, CorreoElectronico, Telefono, Direccion)
VALUES 
(1, 'Juan', 'P�rez', 'Gonz�lez', 'juan.perez@correo.com', '5551234567', 'Calle Ficticia 123'),
(2, 'Mar�a', 'L�pez', 'Mart�nez', 'maria.lopez@correo.com', '5552345678', 'Avenida Real 456');


--Modelo de Equipo 
INSERT INTO ModelosEquipos (idModeloEquipo, Marca, Modelo, Tipo)
VALUES 
(1, 'Samsung', 'Galaxy S20', 'Tel�fono m�vil'),
(2, 'HP', 'Pavilion X360', 'Computadora port�til'),
(3, 'Apple', 'iPad Pro', 'Tablet');

-- Insertar Equipos
INSERT INTO Equipos (idEquipo, idUsuario, idModeloEquipo, NumeroSerie, EstadoInicial)
VALUES 
(4, 2, 2, 'SN654321', 'Teclado da�ado'),
(1, 1, 1, 'SN123456', 'Pantalla rota'),
(2, 2, 2, 'SN654321', 'Teclado da�ado'),
(3, 1, 3, 'SN789012', 'Sin da�os aparentes');





-- Insertar T�cnicos
INSERT INTO Tecnicos (idTecnico, Nombre, ApellidoPaterno, ApellidoMaterno, CorreoElectronico, Telefono, Especialidad)
VALUES 
(1, 'Carlos', 'Ram�rez', 'Hern�ndez', 'carlos.ramirez@correo.com', '5553456789', 'Electr�nica'),
(2, 'Ana', 'Torres', 'V�squez', 'ana.torres@correo.com', '5554567890', 'Mec�nica');



-- Insertar Tickets de Reparaci�n Existentes
INSERT INTO TicketsReparacion (idTicketReparacion, idEquipo, idTecnico, ProblemaReportado, Estado)
VALUES 
(1, 1, NULL, 'Pantalla rota', 'Pendiente'),
(2, 2, NULL, 'Teclado da�ado', 'Pendiente'),
(3, 3, NULL, 'Sin da�os aparentes', 'Pendiente');





------------------------------------------Ejecutar procedimiento------------------------------------

EXEC sp_GenerarTicketReparacion @idEquipo = 2, @idTecnico = 3, @ProblemaReportado = 'Fallo en bater�a';



------------------------------------SELECT* PARA VERIFICAR-----------------------------------------

-- Verificar Equipos
SELECT * FROM Equipos;

-- Verificar Usuarios
SELECT * FROM Usuarios;

-- Verificar T�cnicos
SELECT * FROM Tecnicos;

-- Verificar Tickets de Reparaci�n
SELECT * FROM TicketsReparacion;


-------------------------------ESCENARIOS DE PRUEBA--------------------------------------------------

--Errores Esperados

--1.Equipo no existe:
EXEC sp_GenerarTicketReparacion @idEquipo = 999, @idTecnico = 2, @ProblemaReportado = 'Fallo en bater�a';

--2.Equipo sin cliente asignado:
INSERT INTO Equipos (idEquipo, idUsuario, idModeloEquipo, NumeroSerie, FechaRegistro)
VALUES (3, NULL, 3, 'SN000789', '2024-06-03');
EXEC sp_GenerarTicketReparacion @idEquipo = 3, @idTecnico = 2, @ProblemaReportado = 'Fallo en bater�a';

--3.Ticket pendiente existente:
EXEC sp_GenerarTicketReparacion @idEquipo = 1, @idTecnico = 2, @ProblemaReportado = 'Otro fallo';

--4.Descripci�n vac�a:
EXEC sp_GenerarTicketReparacion @idEquipo = 4, @idTecnico = 2, @ProblemaReportado = NULL;

--5.T�cnico no existente:
EXEC sp_GenerarTicketReparacion @idEquipo = 4, @idTecnico = 999, @ProblemaReportado = 'Fallo en bater�a'


