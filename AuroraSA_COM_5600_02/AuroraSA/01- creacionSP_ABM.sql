USE COM5600G02 
GO

---cada inserción, borrado, modificación crea un registro en la tabla bitácora
create or alter procedure registros.insertarLog 
(
	@modulo varchar(60),
	@texto	varchar(300) 
)
as
begin
	if LTRIM(RTRIM(@modulo)) = ''
		set @modulo = 'N/A';

	insert into registros.bitácora (txt, modulo)
	values	(@texto, @modulo);
end;
GO


 


CREATE OR ALTER PROCEDURE supermercado.insertarComercio
    @cuit NVARCHAR(20),
    @nombre_comercio NVARCHAR(30),
    @razon_social NVARCHAR(30),
    @email NVARCHAR(100)
AS
BEGIN
    -- Verificar que ninguno de los campos sea NULL
    IF @cuit IS NULL OR @nombre_comercio IS NULL OR @razon_social IS NULL OR @email IS NULL
    BEGIN
        PRINT 'Error: Ningún campo puede ser NULL. Todos los parámetros son obligatorios.';
    END
    ELSE
    BEGIN
        -- Verificar si ya existe un comercio con el mismo CUIT
        IF EXISTS (SELECT 1 FROM supermercado.Comercio WHERE cuit = @cuit)
        BEGIN
            PRINT 'El CUIT ya está registrado en la base de datos.';
        END
        ELSE
        BEGIN
            -- Si no existe, insertar el nuevo comercio
            INSERT INTO supermercado.Comercio (cuit, nombre_comercio, razon_social, email)
            VALUES (@cuit, @nombre_comercio, @razon_social, @email);
            
            -- Registrar mensaje de inserción
            PRINT 'Comercio insertado correctamente.';
        END
    END
END;
GO




CREATE OR ALTER PROCEDURE supermercado.insertarSucursal
    @ciudad VARCHAR(40),
    @localidad VARCHAR(40),
    @direccion VARCHAR(150),
    @horario VARCHAR(100),
    @telefono VARCHAR(20)
AS
BEGIN
    DECLARE @direccionExistente INT;
    DECLARE @telefonoExistente INT;
    DECLARE @idComercio NVARCHAR(20);

    -- Obtener el CUIT (idComercio) del único registro de la tabla Comercio
    SELECT @idComercio = cuit
    FROM supermercado.Comercio
    WHERE cuit IS NOT NULL;

    -- Verificar si ya existe una sucursal con la misma dirección
    SET @direccionExistente = (SELECT COUNT(*) 
                               FROM supermercado.sucursal 
                               WHERE direccion = @direccion);

    -- Verificar si ya existe una sucursal con el mismo teléfono
    SET @telefonoExistente = (SELECT COUNT(*) 
                               FROM supermercado.sucursal 
                               WHERE telefono = @telefono);

    -- Verificar condiciones
    IF @direccionExistente > 0 AND @telefonoExistente > 0
    BEGIN
        -- Si ambas existen, imprimir ambos mensajes
        PRINT FORMATMESSAGE('Ya existe una sucursal con la misma dirección y teléfono: Dirección: %s, Teléfono: %s', @direccion, @telefono);
    END
    ELSE IF @direccionExistente > 0
    BEGIN
        -- Si solo existe la dirección, imprimir el mensaje correspondiente
        PRINT FORMATMESSAGE('Ya existe una sucursal con la misma dirección: %s', @direccion);
    END
    ELSE IF @telefonoExistente > 0
    BEGIN
        -- Si solo existe el teléfono, imprimir el mensaje correspondiente
        PRINT FORMATMESSAGE('Ya existe una sucursal con el mismo teléfono: %s', @telefono);
    END
    ELSE
    BEGIN
        -- Si no existen duplicados, proceder a insertar la sucursal
        INSERT INTO supermercado.sucursal (idComercio, ciudad, localidad, direccion, horario, telefono)
        VALUES (@idComercio, @ciudad, @localidad, @direccion, @horario, @telefono);

        -- Registro de inserción
        DECLARE @mensajeInsercion VARCHAR(1000);
        SET @mensajeInsercion = FORMATMESSAGE('Nueva sucursal insertada en la localidad %s', @localidad);
        
        EXEC registros.insertarLog 'insertarSucursal', @mensajeInsercion;
    END;
END;
GO


CREATE OR ALTER PROCEDURE supermercado.insertarEmpleado
    @legajo INT,
    @nombre VARCHAR(256),
    @apellido VARCHAR(256),
    @dni VARCHAR(256),
    @direccion VARCHAR(256),
    @email_personal VARCHAR(256),
    @email_empresa VARCHAR(256),
    @cargo VARCHAR(20),
    @idSucursal INT,
    @turno VARCHAR(30),
    @FraseClave NVARCHAR(128) -- Para cifrado
AS
BEGIN
    DECLARE @dniExistente INT;
    DECLARE @emailPersonalExistente INT;
    DECLARE @emailEmpresaExistente INT;

    -- Verificar si ya existe un empleado con el mismo DNI (descifrado)

    SET @dniExistente = (SELECT COUNT(*) 
                         FROM supermercado.empleado 
                         WHERE CONVERT(VARCHAR(256), DecryptByPassPhrase(@FraseClave, dni)) = @dni);

    -- Verificar si ya existe un empleado con el mismo correo personal (descifrado)
    SET @emailPersonalExistente = (SELECT COUNT(*) 
                                   FROM supermercado.empleado 
                                   WHERE CONVERT(VARCHAR(256), DecryptByPassPhrase(@FraseClave, email_personal)) = @email_personal);

    -- Verificar si ya existe un empleado con el mismo correo de empresa (descifrado)
    SET @emailEmpresaExistente = (SELECT COUNT(*) 
                                  FROM supermercado.empleado 
                                  WHERE CONVERT(VARCHAR(256), DecryptByPassPhrase(@FraseClave, email_empresa)) = @email_empresa);

    -- Verificar condiciones
    IF @dniExistente > 0 AND @emailPersonalExistente > 0 AND @emailEmpresaExistente > 0
    BEGIN
        -- Si todos existen, imprimir el mensaje
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo DNI: %s, correo personal: %s y correo de empresa: %s', 
                            @dni, @email_personal, @email_empresa);
    END
    ELSE IF @dniExistente > 0 AND @emailPersonalExistente > 0
    BEGIN
        -- Si DNI y correo personal existen
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo DNI: %s y correo personal: %s', @dni, @email_personal);
    END
    ELSE IF @dniExistente > 0 AND @emailEmpresaExistente > 0
    BEGIN
        -- Si DNI y correo de empresa existen
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo DNI: %s y correo de empresa: %s', @dni, @email_empresa);
    END
    ELSE IF @emailPersonalExistente > 0 AND @emailEmpresaExistente > 0
    BEGIN
        -- Si correos personal y empresa existen
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo correo personal: %s y correo de empresa: %s', 
                            @email_personal, @email_empresa);
    END
    ELSE IF @dniExistente > 0
    BEGIN
        -- Si solo el DNI existe
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo DNI: %s', @dni);
    END
    ELSE IF @emailPersonalExistente > 0
    BEGIN
        -- Si solo el correo personal existe
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo correo personal: %s', @email_personal);
    END
    ELSE IF @emailEmpresaExistente > 0
    BEGIN
        -- Si solo el correo de empresa existe
        PRINT FORMATMESSAGE('Ya existe un empleado con el mismo correo de empresa: %s', @email_empresa);
    END
    ELSE
    BEGIN
        -- Si no existen duplicados, proceder a insertar el empleado
        INSERT INTO supermercado.empleado 
            (legajo, nombre, apellido, dni, direccion, email_personal, email_empresa, cargo, idSucursal, turno)
        VALUES 
            (@legajo,
             EncryptByPassPhrase(@FraseClave, @nombre),
             EncryptByPassPhrase(@FraseClave, @apellido),
             EncryptByPassPhrase(@FraseClave, @dni),
             EncryptByPassPhrase(@FraseClave, @direccion),
             EncryptByPassPhrase(@FraseClave, @email_personal),
             EncryptByPassPhrase(@FraseClave, @email_empresa),
             @cargo,
             @idSucursal,
             @turno);

        -- Registro de inserciÃ³n
        DECLARE @mensajeInsercion VARCHAR(1000);
        SET @mensajeInsercion = FORMATMESSAGE('Nuevo empleado insertado con legajo %d', @legajo);
        
        EXEC registros.insertarLog 'insertarEmpleado', @mensajeInsercion;
    END;
END;
GO

go
CREATE OR ALTER PROCEDURE catalogo.insertarProducto
    @nombre NVARCHAR(200),
    @Precio DECIMAL(18, 2),
    @id_linea INT
AS
BEGIN
    -- Verificar si ya existe un producto con el mismo nombre, misma línea y mismo precio
    IF EXISTS (
        SELECT 1
        FROM catalogo.producto
        WHERE nombre = @nombre
        AND id_linea = @id_linea
        AND Precio = @Precio
    )
    BEGIN
        PRINT FORMATMESSAGE('Ya existe un producto con el mismo nombre: %s, línea: %d y precio: %s', @nombre, @id_linea, CONVERT(VARCHAR(20), @Precio, 1));
    END
    ELSE
    BEGIN
        -- Si no existe, insertar el nuevo producto
        INSERT INTO catalogo.producto (nombre, Precio, id_linea)
        VALUES (@nombre, @Precio, @id_linea);

        -- Registro de inserción
        DECLARE @mensajeInsercion VARCHAR(1000);
        SET @mensajeInsercion = FORMATMESSAGE('Nuevo producto insertado con nombre %s, precio %s y línea %d', @nombre, CONVERT(VARCHAR(20), @Precio, 1), @id_linea);
        
        EXEC registros.insertarLog 'insertarProducto', @mensajeInsercion;
    END
END;
GO


-- Procedimiento para insertar en ventas.mediosDePago
CREATE OR ALTER PROCEDURE ventas.insertarMedioDePago
    @nombre VARCHAR(15)
AS
BEGIN
    -- Verificar si ya existe un medio de pago con el mismo nombre
    IF EXISTS (
        SELECT 1
        FROM ventas.mediosDePago
        WHERE nombre = @nombre
    )
    BEGIN
        PRINT FORMATMESSAGE('El medio de pago con el nombre %s ya existe.', @nombre);
    END
    ELSE
    BEGIN
        -- Si no existe, insertar el nuevo medio de pago
        INSERT INTO ventas.mediosDePago (nombre)
        VALUES (@nombre);

        -- Registro de inserción
        DECLARE @mensajeInsercion VARCHAR(1000);
        SET @mensajeInsercion = FORMATMESSAGE('Nuevo medio de pago insertado: %s', @nombre);

        EXEC registros.insertarLog 'insertarMedioDePago', @mensajeInsercion;
    END
END;
GO



CREATE OR ALTER PROCEDURE catalogo.insertarLinea_de_producto
    @nombre VARCHAR(100),
    @categoria VARCHAR(100)
AS
BEGIN
    -- Verificar si la línea de producto ya existe
    IF NOT EXISTS (
        SELECT 1 
        FROM catalogo.linea_de_producto
        WHERE nombre = @nombre 
        AND categoria = @categoria
    )
    BEGIN
        -- Insertar en la tabla linea_de_producto
        INSERT INTO catalogo.linea_de_producto (nombre, categoria)
        VALUES (@nombre, @categoria);

        -- Registrar en el log que se realizó una inserción
        DECLARE @mensajeInsercion VARCHAR(1000);
        SET @mensajeInsercion = FORMATMESSAGE('Inserción de una nueva línea de producto: %s - %s', @nombre, @categoria);
        
        EXEC registros.insertarLog 'insertarLinea_de_producto', @mensajeInsercion;
    END;
    ELSE
    BEGIN
        -- Mostrar un mensaje si la línea de producto ya existe
        PRINT FORMATMESSAGE('La línea de producto %s - %s, ya existe', @nombre, @categoria);
    END;
END;
GO






CREATE OR ALTER PROCEDURE ventas.insertar_cliente
    @cuil VARCHAR(20),
    @tipoCliente VARCHAR(15),
    @genero VARCHAR(15),
    @idCliente INT OUTPUT,
    @clienteExistente BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar si el cliente ya existe
    IF EXISTS (SELECT 1 FROM ventas.cliente WHERE cuil = @cuil)
    BEGIN
        -- El cliente ya existe, no se inserta y se retorna el ID del cliente existente
        SELECT @idCliente = id FROM ventas.cliente WHERE cuil = @cuil;
        SET @clienteExistente = 1;  -- Indicar que el cliente ya existe
		
    END
    ELSE
    BEGIN
        -- Insertar nuevo cliente si no existe
        INSERT INTO ventas.cliente (cuil, tipo_cliente, genero)
        VALUES (@cuil, @tipoCliente, @genero);

        -- Obtener el ID del cliente recién insertado
        SELECT @idCliente = SCOPE_IDENTITY();
        SET @clienteExistente = 0;  -- Indicar que el cliente fue insertado
    END
END;
GO



CREATE OR ALTER PROCEDURE ventas.generar_venta_con_factura
    @nroFactura CHAR(11),
    @tipoFactura CHAR(1),
    @fecha DATE,
    @hora TIME,
    @idMedioDePago INT,
    @idPago VARCHAR(50),
    @idEmpleado INT,
    @idSucursal INT,
    @tipoCliente VARCHAR(15),
    @genero VARCHAR(15),
    @cuil VARCHAR(20),
    @productosDetalle TipoProductosDetalle READONLY
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @idFactura INT;
    DECLARE @total DECIMAL(10, 2) = 0.0;
    DECLARE @totalConIVA DECIMAL(10, 2) = 0.0;
    DECLARE @IVA DECIMAL(4, 2) = 1.21;  -- Tasa de IVA (21%)
    DECLARE @idCliente INT;
    DECLARE @clienteExistente BIT;
    DECLARE @idProducto INT;
    DECLARE @precio DECIMAL(6, 2);
    DECLARE @cantidad SMALLINT;
    DECLARE @subtotal DECIMAL(10, 2);
    DECLARE @subtotalConIVA DECIMAL(10, 2);

	IF NOT EXISTS (SELECT 1 FROM @productosDetalle)
	BEGIN
		PRINT('no hay producto asociado');
		RETURN;
	END

    -- Validar si el número de factura ya existe
    IF EXISTS (SELECT 1 FROM ventas.factura WHERE nroFactura = @nroFactura)
    BEGIN
        PRINT('YA EXISTE LA FACTURA');
        RETURN;
    END

    -- 1. Insertar la factura sin total ni totalConIVA (aún por calcular)
    INSERT INTO ventas.factura (nroFactura, tipo_Factura, fecha, hora, idMedio_de_pago, idPago, estadoDePago)
    VALUES (@nroFactura, @tipoFactura, @fecha, @hora, @idMedioDePago, @idPago, 'pagada');

    -- Obtener el ID de la factura recién creada
    SET @idFactura = SCOPE_IDENTITY();

    -- 2. Insertar o verificar el cliente
    EXEC ventas.insertar_cliente 
        @cuil = @cuil, 
        @tipoCliente = @tipoCliente, 
        @genero = @genero, 
        @idCliente = @idCliente OUTPUT, 
        @clienteExistente = @clienteExistente OUTPUT;

    -- 3. Insertar detalles de venta para cada producto y calcular subtotales
    DECLARE product_cursor CURSOR FOR 
    SELECT idProducto, cantidad
    FROM @productosDetalle;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @idProducto, @cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Verificar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM catalogo.producto WHERE id = @idProducto)
        BEGIN
            PRINT('Producto con id ' + CAST(@idProducto AS VARCHAR) + ' no existe');
            RETURN;
        END

        -- Obtener el precio del producto
        SELECT @precio = Precio FROM catalogo.producto WHERE id = @idProducto;

        -- Calcular el subtotal y el subtotal con IVA para cada producto
        SET @subtotal = @precio * @cantidad;
        SET @subtotalConIVA = @subtotal * @IVA;

        -- Insertar detalle de venta
        INSERT INTO ventas.detalleVenta (idProducto, idFactura, subtotal, cant, precio)
        VALUES (@idProducto, @idFactura, @subtotal, @cantidad, @precio);

        -- Acumular totales para la factura
        SET @total = @total + @subtotal;
        SET @totalConIVA = @totalConIVA + @subtotalConIVA;

        FETCH NEXT FROM product_cursor INTO @idProducto, @cantidad;
    END;

    CLOSE product_cursor;
    DEALLOCATE product_cursor;

    -- 4. Actualizar la factura con los totales calculados
    UPDATE ventas.factura
    SET total = @total,
        totalConIVA = @totalConIVA
    WHERE id = @idFactura;

    -- 5. Insertar el registro de la venta en ventas_registradas
    INSERT INTO ventas.registro_de_ventas (idFactura, idEmpleado, idSucursal, idCliente)
    VALUES (@idFactura, @idEmpleado, @idSucursal, @idCliente);

    -- Registrar en el log que se realizó una inserción
    DECLARE @mensajeInsercion VARCHAR(1000);
    SET @mensajeInsercion = FORMATMESSAGE('Inserción de una nueva venta con factura %d', @idFactura);
        
    EXEC registros.insertarLog 'insertarVenta', @mensajeInsercion;
END;
GO











CREATE OR ALTER TRIGGER supermercado.trg_AfterUpdate_Empleado
ON supermercado.empleado
AFTER UPDATE
AS
BEGIN
    -- Declarar variables para almacenar información de las filas afectadas
    DECLARE @legajo INT;
    DECLARE @nombre NVARCHAR(30);
    DECLARE @apellido NVARCHAR(30);
    DECLARE @direccionAntigua NVARCHAR(100);
    DECLARE @direccionNueva NVARCHAR(100);
    DECLARE @emailPersonalAntiguo NVARCHAR(80);
    DECLARE @emailPersonalNuevo NVARCHAR(80);
    DECLARE @emailEmpresaAntiguo NVARCHAR(80);
    DECLARE @emailEmpresaNuevo NVARCHAR(80);
    DECLARE @cargoAntiguo NVARCHAR(20);
    DECLARE @cargoNuevo NVARCHAR(20);
    DECLARE @idSucursalAntiguo INT;
    DECLARE @idSucursalNuevo INT;
    DECLARE @turnoAntiguo NVARCHAR(20);
    DECLARE @turnoNuevo NVARCHAR(20);
    DECLARE @localidadAntigua NVARCHAR(40);
    DECLARE @localidadNueva NVARCHAR(40);
    DECLARE @mensaje NVARCHAR(400);
    DECLARE @FraseClave NVARCHAR(128) = 'La vida es como la RAM, todo es temporal y nada se queda.'; -- La clave de desencriptación

    -- Usar un cursor para recorrer las filas afectadas
    DECLARE cur CURSOR FOR
    SELECT 
        i.legajo,
        CONVERT(NVARCHAR(30), DecryptByPassPhrase(@FraseClave, i.nombre)) AS nombre,
        CONVERT(NVARCHAR(30), DecryptByPassPhrase(@FraseClave, i.apellido)) AS apellido,
        CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, d.direccion)) AS direccionAntigua,
        CONVERT(NVARCHAR(100), DecryptByPassPhrase(@FraseClave, i.direccion)) AS direccionNueva,
        CONVERT(NVARCHAR(80), DecryptByPassPhrase(@FraseClave, d.email_personal)) AS emailPersonalAntiguo,
        CONVERT(NVARCHAR(80), DecryptByPassPhrase(@FraseClave, i.email_personal)) AS emailPersonalNuevo,
        CONVERT(NVARCHAR(80), DecryptByPassPhrase(@FraseClave, d.email_empresa)) AS emailEmpresaAntiguo,
        CONVERT(NVARCHAR(80), DecryptByPassPhrase(@FraseClave, i.email_empresa)) AS emailEmpresaNuevo,
        d.cargo AS cargoAntiguo,
        i.cargo AS cargoNuevo,
        d.idSucursal AS idSucursalAntiguo,
        i.idSucursal AS idSucursalNuevo,
        d.turno AS turnoAntiguo,
        i.turno AS turnoNuevo
    FROM inserted i
    JOIN deleted d ON i.legajo = d.legajo
    WHERE 
        (i.direccion <> d.direccion) OR
        (i.email_personal <> d.email_personal) OR
        (i.email_empresa <> d.email_empresa) OR -- Nueva condición para email de empresa
        (i.cargo <> d.cargo) OR
        (i.idSucursal <> d.idSucursal) OR
        (i.turno <> d.turno); -- Cambios en los campos relevantes

    OPEN cur;
    FETCH NEXT FROM cur INTO @legajo, @nombre, @apellido, @direccionAntigua, @direccionNueva,
                               @emailPersonalAntiguo, @emailPersonalNuevo,
                               @emailEmpresaAntiguo, @emailEmpresaNuevo,
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
        END;
        
        IF @emailPersonalAntiguo <> @emailPersonalNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Email personal antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @emailPersonalAntiguo, @emailPersonalNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END;

        IF @emailEmpresaAntiguo <> @emailEmpresaNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Email empresa antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @emailEmpresaAntiguo, @emailEmpresaNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END;

        IF @cargoAntiguo <> @cargoNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Cargo antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @cargoAntiguo, @cargoNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END;

        IF @idSucursalAntiguo <> @idSucursalNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado (%s %s) con legajo %d: ID de sucursal antiguo: %s, Nueva sucursal: %s',
                                           @nombre, @apellido, @legajo, @localidadAntigua, @localidadNueva);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END;

        IF @turnoAntiguo <> @turnoNuevo
        BEGIN
            SET @mensaje = FORMATMESSAGE('Empleado legajo %d (%s %s): Turno antiguo: %s, Nuevo: %s',
                                           @legajo, @nombre, @apellido, @turnoAntiguo, @turnoNuevo);
            EXEC registros.insertarLog 'importarEmpleado', @mensaje;
        END;

        FETCH NEXT FROM cur INTO @legajo, @nombre, @apellido, @direccionAntigua, @direccionNueva,
                                   @emailPersonalAntiguo, @emailPersonalNuevo,
                                   @emailEmpresaAntiguo, @emailEmpresaNuevo,
                                   @cargoAntiguo, @cargoNuevo,
                                   @idSucursalAntiguo, @idSucursalNuevo,
                                   @turnoAntiguo, @turnoNuevo;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
GO





--------------------------------------------------------------------------------------------------------
--STORE PARA MODIFICAR DATOS DE LA SUCURSAL (NRO TELEFONO Y HORARIO)
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.ModificarDatosSucursal
    @idSucursal INT,  -- Recibe el ID de la sucursal
    @nuevoHorario VARCHAR(100) = NULL,  
    @nuevoTelefono VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar variable para el mensaje de log
    DECLARE @mensajeLog NVARCHAR(1000);

    -- Verificamos si ambos parámetros son NULL
    IF @nuevoHorario IS NULL AND @nuevoTelefono IS NULL
    BEGIN
        PRINT 'No se proporcionaron datos para actualizar.';
        RETURN; -- No se hace ninguna actualización
    END

    -- Actualizamos los campos solo si no son NULL, y formateamos el mensaje de log
    IF @nuevoHorario IS NOT NULL
    BEGIN
        -- Actualizamos el horario
        UPDATE supermercado.sucursal
        SET horario = @nuevoHorario
        WHERE id = @idSucursal;

        -- Verificamos si se actualizó el campo y registramos el log
        IF @@ROWCOUNT > 0
        BEGIN
            SET @mensajeLog = FORMATMESSAGE('Se actualizó el horario de la sucursal con ID %d a: %s', @idSucursal, @nuevoHorario);
            EXEC registros.insertarLog 'ActualizaciónSucursal', @mensajeLog;
        END
    END

    IF @nuevoTelefono IS NOT NULL
    BEGIN
        -- Actualizamos el teléfono
        UPDATE supermercado.sucursal
        SET telefono = @nuevoTelefono
        WHERE id = @idSucursal;

        -- Verificamos si se actualizó el campo y registramos el log
        IF @@ROWCOUNT > 0
        BEGIN
            SET @mensajeLog = FORMATMESSAGE('Se actualizó el teléfono de la sucursal con ID %d a: %s', @idSucursal, @nuevoTelefono);
            EXEC registros.insertarLog 'ActualizaciónSucursal', @mensajeLog;
        END
    END

    -- Verificamos si se realizó alguna modificación en los campos de la sucursal
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'No se encontró la sucursal especificada o no se realizaron cambios.';
    END
    ELSE
    BEGIN
        PRINT 'Sucursal actualizada correctamente.';
    END
END;
GO




--------------------------------------------------------------------------------------------------------
--STORE PARA MODIFICACIÓN DE TABLA EMPLEADO 
--------------------------------------------------------------------------------------------------------

CREATE or ALTER PROCEDURE supermercado.ModificarDatosEmpleado
    @legajo INT,
    @direccionNueva NVARCHAR(256) = NULL,
    @emailPersonalNuevo NVARCHAR(256) = NULL,
    @cargoNuevo VARCHAR(20) = NULL,
    @idSucursalNueva INT = NULL,  
    @turnoNuevo VARCHAR(30) = NULL,
    @emailEmpresaNuevo NVARCHAR(256) = NULL,
    @FraseClave NVARCHAR(128) -- Para cifrado y descifrado
AS
BEGIN
    SET NOCOUNT ON;

    -- Declaramos variables para almacenar los valores actuales descifrados
    DECLARE @direccionActual NVARCHAR(256);
    DECLARE @emailPersonalActual NVARCHAR(256);
    DECLARE @emailEmpresaActual NVARCHAR(256);
    DECLARE @cargoActual VARCHAR(20);
    DECLARE @idSucursalActual INT;
    DECLARE @turnoActual VARCHAR(30);

    -- Desencriptamos los valores actuales de dirección, email personal, email empresa, cargo, idSucursal y turno
    SELECT 
        @direccionActual = CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClave, direccion)),
        @emailPersonalActual = CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClave, email_personal)),
        @emailEmpresaActual = CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClave, email_empresa)),
        @cargoActual = cargo,
        @idSucursalActual = idSucursal,
        @turnoActual = turno
    FROM 
        supermercado.empleado
    WHERE 
        legajo = @legajo;

    -- Verificamos si todos los parámetros son NULL. Si es así, no actualizamos ningún campo.
    IF @direccionNueva IS NULL AND 
       @emailPersonalNuevo IS NULL AND 
       @emailEmpresaNuevo IS NULL AND 
       @cargoNuevo IS NULL AND 
       @idSucursalNueva IS NULL AND 
       @turnoNuevo IS NULL
    BEGIN
        PRINT 'No se proporcionaron datos para actualizar.';
        RETURN; -- No hacemos ninguna actualización
    END

    -- Actualizamos los valores solo si no son NULL, utilizando COALESCE para mantener los valores actuales si el parámetro es NULL
    UPDATE supermercado.empleado
    SET 
        direccion = CASE WHEN @direccionNueva IS NOT NULL 
                         THEN EncryptByPassPhrase(@FraseClave, @direccionNueva) 
                         ELSE direccion END,
        email_personal = CASE WHEN @emailPersonalNuevo IS NOT NULL 
                              THEN EncryptByPassPhrase(@FraseClave, @emailPersonalNuevo) 
                              ELSE email_personal END,
        email_empresa = CASE WHEN @emailEmpresaNuevo IS NOT NULL 
                             THEN EncryptByPassPhrase(@FraseClave, @emailEmpresaNuevo) 
                             ELSE email_empresa END,
        cargo = CASE WHEN @cargoNuevo IS NOT NULL THEN @cargoNuevo ELSE cargo END,
        idSucursal = CASE WHEN @idSucursalNueva IS NOT NULL THEN @idSucursalNueva ELSE idSucursal END,
        turno = CASE WHEN @turnoNuevo IS NOT NULL THEN @turnoNuevo ELSE turno END
    WHERE 
        legajo = @legajo;

    -- Verificamos si se realizó alguna modificación
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'No se encontró el empleado especificado o no se realizaron cambios.';
    END
    ELSE
    BEGIN
        PRINT 'Empleado actualizado correctamente.';
    END
END;
GO


--------------------------------------------------------------------------------------------------------
--STORE PARA MODIFICACIÓN DEL PRECIO DEL PRODUCTO 
--------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE catalogo.ActualizarPrecioProducto
    @IdProducto INT,           -- Parámetro para el id del producto
    @NuevoPrecio DECIMAL(18, 2) -- Parámetro para el nuevo precio
AS
BEGIN
    -- Variables locales
    DECLARE @nombre NVARCHAR(200);    -- Para almacenar el nombre del producto
    DECLARE @id_linea INT;            -- Para almacenar la línea del producto
    DECLARE @mensajeInsercion VARCHAR(1000);  -- Mensaje de log

    -- Obtener el nombre del producto y la línea antes de la actualización
    SELECT @nombre = nombre, @id_linea = id_linea
    FROM catalogo.producto
    WHERE id = @IdProducto;

    -- Actualiza el precio del producto con el id proporcionado
    UPDATE catalogo.producto
    SET Precio = @NuevoPrecio
    WHERE id = @IdProducto;

    -- Comprobar si el producto fue actualizado
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'No se encontró el producto con el id especificado.';
    END
    ELSE
    BEGIN
        -- Crear el mensaje para insertar en el log
        SET @mensajeInsercion = FORMATMESSAGE('Producto con nombre %s, precio nuevo %s y línea %d', @nombre, CONVERT(VARCHAR(20), @NuevoPrecio, 1), @id_linea);
        
        -- Insertar el log
        EXEC registros.insertarLog 'ModificacionProducto', @mensajeInsercion;

        -- Mensaje de éxito
        PRINT 'Precio del producto actualizado correctamente.';
    END
END;
GO



--------------------------------------------------------------------------------------------------------
--BORRADO LOGICO SUCURSAL
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.borrado_logico_sucursal
    @id INT,
    @modulo NVARCHAR(50) = 'sucursal'
AS
BEGIN
    
    UPDATE supermercado.sucursal
    SET activo = 0 --actualizamos el estado en 0
    WHERE id = @id;

    --si modificamos alguna fila llamamos al otro sp para registrarlo
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @ciudad NVARCHAR(40);
        DECLARE @texto NVARCHAR(255);

        -- Usamos la variable ciudad para ponerla en el texto de borrado
        SELECT @ciudad = ciudad FROM supermercado.sucursal WHERE id = @id;

        -- construimos el texto de borrado con la variable ciudad y el id
        SET @texto = CONCAT('Borrado lógico de la sucursal en ciudad: ', @ciudad, ' (ID: ', @id, ')');

        -- Llamamos al procedimiento que registra el borrado lógico en la tabla Registro
        EXEC registros.insertarLog @texto, @modulo;
    END
END;

GO

--------------------------------------------------------------------------------------------------------
--BORRADO LOGICO MEDIOS DE PAGO
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.borrado_logico_mediosDePago
	@id INT,
	@modulo NVARCHAR(50) = 'mediosDePago'
AS
BEGIN 
	UPDATE ventas.mediosDePago
	SET activo = 0
	WHERE  id = @id;

--Si modificamos alguna fila entonces tenemos que llamar al sp para generar el registro
	IF @@ROWCOUNT > 0
	BEGIN
		DECLARE @nombre NVARCHAR(100);
		DECLARE @texto NVARCHAR(255);


		SELECT @nombre = nombre FROM ventas.mediosDePago WHERE id = @id;

		SET @texto = CONCAT('Borrado lógico del medio de pago: ', @nombre,' (ID: ', @id, ')');

	
		EXEC registros.insertarLog @texto , @modulo;
	END
END;

GO
--------------------------------------------------------------------------------------------------------
--STORE PROCEDURE PARA HACER BORRADO LOGICO DE LINEA_DE_PRODUCTO POR CAMPO NOMBRE
--------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE catalogo.borrado_logico_lineaDeProducto
    @nombre NVARCHAR(100),  
    @modulo NVARCHAR(50) = 'linea_de_producto'
AS
BEGIN
    
    UPDATE catalogo.linea_de_producto
    SET activo = 0
    WHERE nombre = @nombre;

  
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado lógico de la línea de producto: ', @nombre);

        
        EXEC  registros.insertarLog @texto, @modulo;
    END
END;

GO



---------------------------------------------------------------------------------
-- STORE PROCEDURE PARA HACER BORRADO LOGICO DE EMPLEADO POR LEGAJO
---------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE supermercado.borrado_logico_empleado
    @legajo INT, -- borra por el legajo
    @modulo NVARCHAR(50) = 'empleado'
AS
BEGIN
    --ponemos en 0 el activo 
    UPDATE supermercado.empleado
    SET activo = 0
    WHERE Legajo = @legajo;

    --si se modificó alguna linea
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado log del empleado con Legajo: ', @legajo);

        --registramos el legajo
        EXEC  registros.insertarLog @texto, @modulo;
    END
END;
GO

----------------------------------------------------------------------------------------------------------
--PROCEDURE PARA HACER BORRADO LOGICO POR EL ID DEL PRODUCTO
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE catalogo.borrado_logico_producto
    @id INT,                           -- ID del producto
    @modulo NVARCHAR(50) = 'producto'
AS
BEGIN
    
    UPDATE catalogo.producto
    SET activo = 0
    WHERE id = @id;

   
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado lógico del producto con ID: ', @id);

        -- Llamada al procedimiento para registrar el borrado
        EXEC registros.insertarLog @texto, @modulo;
    END
END;
GO
----------------------------------------------------------------------------------------------------------
-- FIN
----------------------------------------------------------------------------------------------------------






