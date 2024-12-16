--Proyecto final
--integrantes:Jesus Antonio Gutierrez Orenda,Vannesa Tamayo Nuñez ,Santiago Mora NUñez
--Procedimiento creado por Gutierrez Orenda Jesus Antonio
--Proccedimiento Registrar un Equipo
-- Eliminar el procedimiento si ya existe (para evitar duplicados al crearlo de nuevo)
IF OBJECT_ID('sp_RegistrarEquipo', 'P') IS NOT NULL
    DROP PROCEDURE sp_RegistrarEquipo;
GO

-- Crear el procedimiento almacenado
CREATE ALTER  PROCEDURE sp_RegistrarEquipo
    @NumeroSerie NVARCHAR(50),    -- Número de serie único del equipo
    @EstadoInicial NVARCHAR(20),  -- Estado inicial del equipo (ej. "Nuevo")
    @IdCliente INT,               -- ID del cliente relacionado
    @IdModelo INT                 -- ID del modelo relacionado
AS
BEGIN
    -- Iniciar una transacción
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar que el número de serie no exista ya
        IF EXISTS (SELECT 1 FROM Equipos WHERE NumeroSerie = @NumeroSerie)
        BEGIN
            THROW 50000, 'El número de serie ya existe. Operación cancelada.', 1;
        END

        -- Insertar el nuevo equipo
        INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
        VALUES (@NumeroSerie, @EstadoInicial, GETDATE(), @IdCliente, @IdModelo);

        -- Confirmar la transacción si todo salió bien
        COMMIT;

        -- Mensaje de éxito
        PRINT 'Equipo registrado exitosamente.';
    END TRY

    BEGIN CATCH
        -- Revertir la transacción si ocurre un error
        ROLLBACK;

        -- Mostrar detalles del error
        PRINT 'Error al registrar el equipo.';
        PRINT ERROR_MESSAGE();
    END CATCH
END;
GO
--insercion de datos
-- Insertar equipo 1
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ001XYZ', 'Nuevo', GETDATE(), 1, 1);

-- Insertar equipo 2
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ002XYZ', 'Reparado', GETDATE(), 2, 1);

-- Insertar equipo 3
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ003XYZ', 'Nuevo', GETDATE(), 3, 2);

-- Insertar equipo 4
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ004XYZ', 'En mantenimiento', GETDATE(), 4, 3);

-- Insertar equipo 5
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ005XYZ', 'Nuevo', GETDATE(), 5, 4);

-- Insertar equipo 6
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ006XYZ', 'Reparado', GETDATE(), 6, 2);

-- Insertar equipo 7
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ007XYZ', 'Nuevo', GETDATE(), 7, 3);

-- Insertar equipo 8
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ008XYZ', 'En mantenimiento', GETDATE(), 8, 4);

-- Insertar equipo 9
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ009XYZ', 'Nuevo', GETDATE(), 9, 1);

-- Insertar equipo 10
INSERT INTO Equipos (NumeroSerie, EstadoInicial, FechaRegistro, IdCliente, IdModelo)
VALUES ('EQ010XYZ', 'Reparado', GETDATE(), 10, 2);
--consultar los datos
SELECT * 
FROM Equipos;

-- Probar el procedimiento almacenado con un equipo
EXEC sp_RegistrarEquipo 
    @NumeroSerie = 'EQ011XYZ',
    @EstadoInicial = 'Nuevo',
    @IdCliente = 5,
    @IdModelo = 3;
	--Pruebas 
-- Inicia pruebas
PRINT 'INICIO DE PRUEBAS';

-- Escenario 1: Registro exitoso
PRINT 'Prueba 1: Registro exitoso';
EXEC sp_RegistrarEquipo 
    @NumeroSerie = 'EQ001ABC', 
    @EstadoInicial = 'Nuevo', 
    @IdCliente = 1, 
    @IdModelo = 1;
SELECT * FROM Equipos WHERE NumeroSerie = 'EQ001ABC';

-- Escenario 2: Número de serie duplicado
PRINT 'Prueba 2: Número de serie duplicado';
BEGIN TRY
    EXEC sp_RegistrarEquipo 
        @NumeroSerie = 'EQ001ABC', 
        @EstadoInicial = 'Nuevo', 
        @IdCliente = 1, 
        @IdModelo = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 3: Cliente inexistente
PRINT 'Prueba 3: Cliente inexistente';
BEGIN TRY
    EXEC sp_RegistrarEquipo 
        @NumeroSerie = 'EQ002DEF', 
        @EstadoInicial = 'Nuevo', 
        @IdCliente = 999, -- Cliente inexistente
        @IdModelo = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 4: Modelo inexistente
PRINT 'Prueba 4: Modelo inexistente';
BEGIN TRY
    EXEC sp_RegistrarEquipo 
        @NumeroSerie = 'EQ003GHI', 
        @EstadoInicial = 'Nuevo', 
        @IdCliente = 1, 
        @IdModelo = 999; -- Modelo inexistente
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 5: Estado inicial inválido
PRINT 'Prueba 5: Estado inicial inválido';
BEGIN TRY
    EXEC sp_RegistrarEquipo 
        @NumeroSerie = 'EQ004JKL', 
        @EstadoInicial = 'Desconocido', -- Estado inválido
        @IdCliente = 1, 
        @IdModelo = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 6: Número de serie vacío
PRINT 'Prueba 6: Número de serie vacío';
BEGIN TRY
    EXEC sp_RegistrarEquipo 
        @NumeroSerie = '', -- Número de serie vacío
        @EstadoInicial = 'Nuevo', 
        @IdCliente = 1, 
        @IdModelo = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 7: Cliente y modelo inexistentes simultáneamente
PRINT 'Prueba 7: Cliente y modelo inexistentes simultáneamente';
BEGIN TRY
    EXEC sp_RegistrarEquipo
        @NumeroSerie = 'EQ005MNO', 
        @EstadoInicial = 'Nuevo', 
        @IdCliente = 999, -- Cliente inexistente
        @IdModelo = 999; -- Modelo inexistente
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 8: Longitud máxima del número de serie excedida
PRINT 'Prueba 8: Longitud máxima del número de serie excedida';
BEGIN TRY
    EXEC sp_RegistrarEquipo 
        @NumeroSerie = 'EQ12345678901234567890', -- Número de serie excede límite
        @EstadoInicial = 'Nuevo', 
        @IdCliente = 1, 
        @IdModelo = 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Escenario 9: Estado inicial en minúsculas
PRINT 'Prueba 9: Estado inicial en minúsculas';
EXEC sp_RegistrarEquipo 
    @NumeroSerie = 'EQ006PQR', 
    @EstadoInicial = 'nuevo', -- Estado en minúsculas
    @IdCliente = 1, 
    @IdModelo = 1;
SELECT * FROM Equipos WHERE NumeroSerie = 'EQ006PQR';

-- Escenario 10: Prueba de límite de datos válidos
PRINT 'Prueba 10: Límite de datos válidos';
EXEC sp_RegistrarEquipo 
    @NumeroSerie = 'EQ007STU', 
    @EstadoInicial = 'Usado', 
    @IdCliente = 2, -- Último cliente existente
    @IdModelo = 2; -- Último modelo existente
SELECT * FROM Equipos WHERE NumeroSerie = 'EQ007STU';

PRINT 'FIN DE PRUEBAS';
