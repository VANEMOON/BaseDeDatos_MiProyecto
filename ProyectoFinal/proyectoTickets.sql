
-- Proyecto Final - Taller de base de datos
-- Integrantes: Vannesa Tamayo Nuñez, Jesus Antonio Gutierres Orenda, Santiago Antonio Mora Nuñez
--Procedimiento realizado por Vannesa Tamayo Nuñez
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
        SELECT 'Error: El equipo ya tiene un ticket de reparación pendiente.' AS Mensaje;
        RETURN;
    END

    -- 4. Verificar que la descripción del problema no esté vacía
    IF @ProblemaReportado IS NULL OR LEN(@ProblemaReportado) = 0
    BEGIN
        SELECT 'Error: La descripción del problema no puede estar vacía.' AS Mensaje;
        RETURN;
    END

    -- 5. Verificar que el técnico exista (si se proporciona un idTecnico)
    IF @idTecnico IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM Tecnicos WHERE idTecnico = @idTecnico
    )
    BEGIN
        SELECT 'Error: El técnico no existe.' AS Mensaje;
        RETURN;
    END

    -- Iniciar la transacción
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insertar el nuevo ticket de reparación
        INSERT INTO TicketsReparacion (idEquipo, idTecnico, ProblemaReportado, Estado, FechaCreacion)
        VALUES (@idEquipo, @idTecnico, @ProblemaReportado, 'Pendiente', GETDATE());

        -- Confirmar la transacción
        COMMIT TRANSACTION;
        SELECT 'Éxito: Ticket de reparación generado correctamente.' AS Mensaje;

    END TRY
    BEGIN CATCH
        -- En caso de error, deshacer la transacción
        ROLLBACK TRANSACTION;
        SELECT 'Error: No se pudo generar el ticket de reparación.' AS Mensaje,
            ERROR_MESSAGE() AS DetalleError;
    END CATCH
END;
GO




---------------------------------------------------------INSERCION DE DATOS----------------------------------------------------


-- Insertar Usuarios
INSERT INTO Usuarios (idUsuario, Nombre, ApellidoPaterno, ApellidoMaterno, CorreoElectronico, Telefono, Direccion)
VALUES 
(1, 'Juan', 'Pérez', 'González', 'juan.perez@correo.com', '5551234567', 'Calle Ficticia 123'),
(2, 'María', 'López', 'Martínez', 'maria.lopez@correo.com', '5552345678', 'Avenida Real 456');


--Modelo de Equipo 
INSERT INTO ModelosEquipos (idModeloEquipo, Marca, Modelo, Tipo)
VALUES 
(1, 'Samsung', 'Galaxy S20', 'Teléfono móvil'),
(2, 'HP', 'Pavilion X360', 'Computadora portátil'),
(3, 'Apple', 'iPad Pro', 'Tablet');

-- Insertar Equipos
INSERT INTO Equipos (idEquipo, idUsuario, idModeloEquipo, NumeroSerie, EstadoInicial)
VALUES 
(4, 2, 2, 'SN654321', 'Teclado dañado'),
(1, 1, 1, 'SN123456', 'Pantalla rota'),
(2, 2, 2, 'SN654321', 'Teclado dañado'),
(3, 1, 3, 'SN789012', 'Sin daños aparentes');





-- Insertar Técnicos
INSERT INTO Tecnicos (idTecnico, Nombre, ApellidoPaterno, ApellidoMaterno, CorreoElectronico, Telefono, Especialidad)
VALUES 
(1, 'Carlos', 'Ramírez', 'Hernández', 'carlos.ramirez@correo.com', '5553456789', 'Electrónica'),
(2, 'Ana', 'Torres', 'Vásquez', 'ana.torres@correo.com', '5554567890', 'Mecánica');



-- Insertar Tickets de Reparación Existentes
INSERT INTO TicketsReparacion (idTicketReparacion, idEquipo, idTecnico, ProblemaReportado, Estado)
VALUES 
(1, 1, NULL, 'Pantalla rota', 'Pendiente'),
(2, 2, NULL, 'Teclado dañado', 'Pendiente'),
(3, 3, NULL, 'Sin daños aparentes', 'Pendiente');





------------------------------------------Ejecutar procedimiento------------------------------------

EXEC sp_GenerarTicketReparacion @idEquipo = 2, @idTecnico = 3, @ProblemaReportado = 'Fallo en batería';



------------------------------------SELECT* PARA VERIFICAR-----------------------------------------

-- Verificar Equipos
SELECT * FROM Equipos;

-- Verificar Usuarios
SELECT * FROM Usuarios;

-- Verificar Técnicos
SELECT * FROM Tecnicos;

-- Verificar Tickets de Reparación
SELECT * FROM TicketsReparacion;


-------------------------------ESCENARIOS DE PRUEBA--------------------------------------------------

--Errores Esperados

--1.Equipo no existe:
EXEC sp_GenerarTicketReparacion @idEquipo = 999, @idTecnico = 2, @ProblemaReportado = 'Fallo en batería';

--2.Equipo sin cliente asignado:
INSERT INTO Equipos (idEquipo, idUsuario, idModeloEquipo, NumeroSerie, FechaRegistro)
VALUES (3, NULL, 3, 'SN000789', '2024-06-03');
EXEC sp_GenerarTicketReparacion @idEquipo = 3, @idTecnico = 2, @ProblemaReportado = 'Fallo en batería';

--3.Ticket pendiente existente:
EXEC sp_GenerarTicketReparacion @idEquipo = 1, @idTecnico = 2, @ProblemaReportado = 'Otro fallo';

--4.Descripción vacía:
EXEC sp_GenerarTicketReparacion @idEquipo = 4, @idTecnico = 2, @ProblemaReportado = NULL;

--5.Técnico no existente:
EXEC sp_GenerarTicketReparacion @idEquipo = 4, @idTecnico = 999, @ProblemaReportado = 'Fallo en batería'


