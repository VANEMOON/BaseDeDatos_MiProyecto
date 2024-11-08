-- ---------------------------------------
-- Autor: Santiago Antonio Mora Nuñez y Vannessa Tamayo Nuñez 
-- Tema: Proyecto Taller de base de datos 
-- Fecha: 18/09/2004
-- ---------------------------------------


-- Creación de la base de datos
create database Proyecto;

use Proyecto;

-- Tabla de Clientes
CREATE TABLE Usuarios (
    IdUsuario INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    ApellidoPaterno NVARCHAR(100) NOT NULL,
    ApellidoMaterno NVARCHAR(100),
    CorreoElectronico NVARCHAR(150) UNIQUE NOT NULL,
    Telefono NVARCHAR(20) NOT NULL,
    Direccion NVARCHAR(255) NOT NULL
);
GO

-- Tabla de Técnicos
CREATE TABLE Tecnicos (
    IdTecnico INT PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    ApellidoPaterno NVARCHAR(100) NOT NULL,
    ApellidoMaterno NVARCHAR(100),
    CorreoElectronico NVARCHAR(150) UNIQUE NOT NULL,
    Telefono NVARCHAR(20) NOT NULL,
    Especialidad NVARCHAR(100) NOT NULL
);
GO

-- Tabla de Modelos de Equipos
CREATE TABLE ModelosEquipos (
    IdModelo INT PRIMARY KEY,
    Marca NVARCHAR(100) NOT NULL,
    Modelo NVARCHAR(100) NOT NULL,
    Tipo NVARCHAR(100) NOT NULL -- Ej: Teléfono móvil, Computadora, Tablet
);
GO

-- Tabla de Equipos
CREATE TABLE Equipos (
    IdEquipo INT PRIMARY KEY,
    IdUsuarios INT NOT NULL,
    IdModelo INT NOT NULL,
    NumeroSerie NVARCHAR(100) NOT NULL,
    EstadoInicial NVARCHAR(255), -- Estado en el que llega el equipo (daños, condiciones generales)
    FechaRegistro DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Equipos_Clientes FOREIGN KEY (IdUsuarios) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Equipos_Modelos FOREIGN KEY (IdModelo) REFERENCES ModelosEquipos(IdModelo)
);
GO

-- Tabla de Tickets de Reparación
CREATE TABLE TicketsReparacion (
    IdTicket INT PRIMARY KEY,
    IdEquipo INT NOT NULL,
    IdTecnico INT NULL, -- Se asignará más tarde, puede ser nulo al inicio
    ProblemaReportado NVARCHAR(255) NOT NULL,
    Estado NVARCHAR(50) DEFAULT 'Pendiente', -- Ej: Pendiente, En Proceso, Finalizado
    FechaCreacion DATETIME DEFAULT GETDATE(),
    FechaFinalizacion DATETIME NULL, -- Se llena cuando el ticket es completado
    CONSTRAINT FK_Tickets_Equipos FOREIGN KEY (IdEquipo) REFERENCES Equipos(IdEquipo),
    CONSTRAINT FK_Tickets_Tecnicos FOREIGN KEY (IdTecnico) REFERENCES Tecnicos(IdTecnico)
);
GO

-- Tabla de Refacciones (para inventario)
CREATE TABLE Refacciones (
    IdRefaccion INT PRIMARY KEY,
    NombreRefaccion NVARCHAR(150) NOT NULL,
    CantidadDisponible INT NOT NULL,
    PrecioUnitario DECIMAL(10, 2) NOT NULL
);
GO

-- Tabla de Detalles de Reparación (Relaciona refacciones usadas con tickets)
CREATE TABLE DetallesReparacion (
    IdDetalle INT PRIMARY KEY,
    IdTicket INT NOT NULL,
    IdRefaccion INT NOT NULL,
    CantidadUsada INT NOT NULL,
    CONSTRAINT FK_Detalle_Tickets FOREIGN KEY (IdTicket) REFERENCES TicketsReparacion(IdTicket),
    CONSTRAINT FK_Detalle_Refacciones FOREIGN KEY (IdRefaccion) REFERENCES Refacciones(IdRefaccion)
);
GO

-- Tabla de Facturas
CREATE TABLE Facturas (
    IdFactura INT PRIMARY KEY),
    IdTicket INT NOT NULL,
    MontoTotal DECIMAL(10,2) NOT NULL,
    FechaEmision DATETIME DEFAULT GETDATE(),
    EstadoPago NVARCHAR(50) DEFAULT 'Pendiente', -- Ej: Pendiente, Pagado
    CONSTRAINT FK_Facturas_Tickets FOREIGN KEY (IdTicket) REFERENCES TicketsReparacion(IdTicket)
);
GO

-- Restricciones adicionales (Triggers y Checks)

-- Asegurar que la cantidad de refacciones disponibles no sea negativa
ALTER TABLE Refacciones
ADD CONSTRAINT CK_CantidadDisponible CHECK (CantidadDisponible >= 0);
GO

-- Asegurar que la cantidad usada de refacciones en un detalle de reparación no sea mayor que la cantidad disponible
CREATE TRIGGER TRG_ActualizarInventario
ON DetallesReparacion
AFTER INSERT
AS
BEGIN
    DECLARE @IdRefaccion INT;
    DECLARE @CantidadUsada INT;

    SELECT @IdRefaccion = i.IdRefaccion, @CantidadUsada = i.CantidadUsada
    FROM inserted i;

    UPDATE Refacciones
    SET CantidadDisponible = CantidadDisponible - @CantidadUsada
    WHERE IdRefaccion = @IdRefaccion;

    -- Verificar que no se quede en negativo
    IF EXISTS (SELECT 1 FROM Refacciones WHERE IdRefaccion = @IdRefaccion AND CantidadDisponible < 0)
    BEGIN
        RAISERROR ('La cantidad de refacciones usadas excede la disponible en el inventario', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Trigger para actualizar el estado del ticket cuando se marca como "Finalizado"
CREATE TRIGGER TRG_ActualizarEstadoTicket
ON TicketsReparacion
AFTER UPDATE
AS
BEGIN
    DECLARE @Estado NVARCHAR(50);
    DECLARE @IdTicket INT;
    
    SELECT @Estado = u.Estado, @IdTicket = u.IdTicket FROM inserted u;
    
    IF @Estado = 'Finalizado'
    BEGIN
        UPDATE TicketsReparacion
        SET FechaFinalizacion = GETDATE()
        WHERE IdTicket = @IdTicket;
    END
END;
GO