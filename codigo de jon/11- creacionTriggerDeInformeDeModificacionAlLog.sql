USE COM5600G02
GO


CREATE OR ALTER TRIGGER supermercado.trg_AfterUpdate_Sucursal
ON supermercado.sucursal
AFTER UPDATE
AS
BEGIN
    -- Declarar variables para almacenar información de las filas afectadas
    DECLARE @ciudad VARCHAR(40);
    DECLARE @localidad VARCHAR(40);
    DECLARE @nuevoHorario VARCHAR(100);
    DECLARE @nuevoTelefono VARCHAR(20);
    DECLARE @horarioAntiguo VARCHAR(100);
    DECLARE @telefonoAntiguo VARCHAR(20);
    DECLARE @mensajeHorario NVARCHAR(400);
    DECLARE @mensajeTelefono NVARCHAR(400);

    -- Usar un cursor para recorrer las filas afectadas
    DECLARE cur CURSOR FOR
    SELECT 
        i.ciudad,
        i.localidad,
        i.horario,
        i.telefono,
        d.horario,
        d.telefono
    FROM inserted i
    JOIN deleted d ON i.ciudad = d.ciudad 
                   AND i.localidad = d.localidad
    WHERE i.horario <> d.horario OR i.telefono <> d.telefono; -- Cambios en horario o teléfono

    OPEN cur;
    FETCH NEXT FROM cur INTO @ciudad, @localidad, @nuevoHorario, @nuevoTelefono, @horarioAntiguo, @telefonoAntiguo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Registrar cambios en el log
        IF @nuevoHorario <> @horarioAntiguo
        BEGIN
            SET @mensajeHorario = FORMATMESSAGE('Actualización de horario en sucursal: %s, %s. Horario antiguo: %s, Nuevo horario: %s',
                                                 @ciudad, @localidad, @horarioAntiguo, @nuevoHorario);
            EXEC registros.insertarLog 'importarSucursal', @mensajeHorario;
        END
        
        IF @nuevoTelefono <> @telefonoAntiguo
        BEGIN
            SET @mensajeTelefono = FORMATMESSAGE('Actualización de teléfono en sucursal: %s, %s. Teléfono antiguo: %s, Nuevo teléfono: %s',
                                                  @ciudad, @localidad, @telefonoAntiguo, @nuevoTelefono);
            EXEC registros.insertarLog 'importarSucursal', @mensajeTelefono;
        END

        FETCH NEXT FROM cur INTO @ciudad, @localidad, @nuevoHorario, @nuevoTelefono, @horarioAntiguo, @telefonoAntiguo;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO










CREATE OR ALTER TRIGGER supermercado.trg_AfterUpdate_Empleado
ON supermercado.empleado
AFTER UPDATE
AS
BEGIN
    -- Declarar variables para almacenar información de las filas afectadas
    DECLARE @legajo INT;
    DECLARE @nombre VARCHAR(30);
    DECLARE @apellido VARCHAR(30);
    DECLARE @direccionAntigua VARCHAR(100);
    DECLARE @direccionNueva VARCHAR(100);
    DECLARE @emailPersonalAntiguo VARCHAR(80);
    DECLARE @emailPersonalNuevo VARCHAR(80);
    DECLARE @cargoAntiguo VARCHAR(20);
    DECLARE @cargoNuevo VARCHAR(20);
    DECLARE @idSucursalAntiguo VARCHAR(30);
    DECLARE @idSucursalNuevo VARCHAR(30);
    DECLARE @turnoAntiguo VARCHAR(20);
    DECLARE @turnoNuevo VARCHAR(20);
    DECLARE @localidadAntigua VARCHAR(40);
    DECLARE @localidadNueva VARCHAR(40);
    DECLARE @mensaje NVARCHAR(400);

    -- Usar un cursor para recorrer las filas afectadas
    DECLARE cur CURSOR FOR
    SELECT 
        i.legajo,
        i.nombre,
        i.apellido,
        d.direccion,
        i.direccion,
        d.email_personal,
        i.email_personal,
        d.cargo,
        i.cargo,
        d.idSucursal,
        i.idSucursal,
        d.turno,
        i.turno
    FROM inserted i
    JOIN deleted d ON i.legajo = d.legajo
    WHERE 
        i.direccion <> d.direccion OR
        i.email_personal <> d.email_personal OR
        i.cargo <> d.cargo OR
        i.idSucursal <> d.idSucursal OR
        i.turno <> d.turno; -- Cambios en los campos relevantes

    OPEN cur;
    FETCH NEXT FROM cur INTO @legajo, @nombre, @apellido, @direccionAntigua, @direccionNueva,
                               @emailPersonalAntiguo, @emailPersonalNuevo,
                               @cargoAntiguo, @cargoNuevo,
                               @idSucursalAntiguo, @idSucursalNuevo,
                               @turnoAntiguo, @turnoNuevo;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Obtener la localidad asociada a las sucursales
        SELECT @localidadAntigua = s.localidad
        FROM supermercado.sucursal s
        WHERE s.id = @idSucursalAntiguo;

        SELECT @localidadNueva = s.localidad
        FROM supermercado.sucursal s
        WHERE s.id = @idSucursalNuevo;

        -- Registrar cambios en el log
        IF @direccionAntigua <> @direccionNueva
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Dirección antigua: %s, Nueva: %s',
                                           @legajo, @nombre, @apellido, @direccionAntigua, @direccionNueva);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END
        
        IF @emailPersonalAntiguo <> @emailPersonalNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Email personal antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @emailPersonalAntiguo, @emailPersonalNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END

        IF @cargoAntiguo <> @cargoNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Cargo antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @cargoAntiguo, @cargoNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END

        IF @idSucursalAntiguo <> @idSucursalNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado (%s %s) con legajo %d: ID de sucursal antiguo: %s, Nueva sucursal: %s',
                                           @nombre, @apellido, @legajo, @localidadAntigua, @localidadNueva);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END

        IF @turnoAntiguo <> @turnoNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Turno antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @turnoAntiguo, @turnoNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END

        FETCH NEXT FROM cur INTO @legajo, @nombre, @apellido, @direccionAntigua, @direccionNueva,
                                   @emailPersonalAntiguo, @emailPersonalNuevo,
                                   @cargoAntiguo, @cargoNuevo,
                                   @idSucursalAntiguo, @idSucursalNuevo,
                                   @turnoAntiguo, @turnoNuevo;
    END

    CLOSE cur;
    DEALLOCATE cur;
END;
GO


