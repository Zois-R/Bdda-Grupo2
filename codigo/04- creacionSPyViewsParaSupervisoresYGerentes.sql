use COM5600G02;
go



CREATE or ALTER VIEW catalogo.vista_Producto_Resumen AS
SELECT 
    id,
    nombre,
    Precio
FROM 
    catalogo.producto;
GO




CREATE or ALTER VIEW ventas.vista_de_registros_de_ventas AS
SELECT  
    f.nroFactura as ID_Factura, 
    f.tipo_Factura as Tipo_de_factura, 
    f.fecha as Fecha, 
    f.hora as Hora, 
    mp.nombre as Medio_de_pago,
	f.idPago as identificadorDePago,
	s.idComercio as CuitEmpresa,
	p.nombre as Producto,
	lp.nombre as Linea_de_Producto,
	d.precio as Precio_unitario,
    d.cant as Cantidad, 
	d.subtotal,
	f.total as Total,
	f.totalConIva as ConIva,
	c.cuil as idCliente,
    c.tipo_cliente as Tipo_de_cliente, 
    c.genero as Genero,
    v.idEmpleado as Empleado,
    s.localidad as Sucursal
FROM 
    ventas.factura f 
JOIN 
    ventas.detalleVenta d ON f.id = d.idFactura
JOIN 
    ventas.registro_de_ventas v ON f.id = v.idFactura 
JOIN 
    supermercado.sucursal s ON v.idSucursal = s.id
JOIN 
    supermercado.empleado e ON v.idEmpleado = e.legajo
JOIN
	catalogo.producto p ON d.idProducto = p.id
JOIN
	catalogo.linea_de_producto lp ON p.id_linea = lp.id
JOIN 
	ventas.mediosDePago mp ON f.idMedio_de_pago = mp.id
LEFT JOIN
	ventas.cliente c ON v.idCliente = c.id;
go






CREATE OR ALTER PROCEDURE ventas.insertarNotaDeCredito
    @idFactura INT,
    @idProducto INT,
    @razon NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar que el valor de 'razon' sea válido
    IF @razon NOT IN ('devPago', 'devProd')
    BEGIN
        RAISERROR ('Razón inválida. Solo se permiten las razones "devPago" (devolución de pago) o "devProd" (devolución del mismo producto).', 16, 1);
        RETURN;  -- Detener la ejecución si la razón no es válida
    END;

    DECLARE @monto DECIMAL(6, 2);
    DECLARE @idDetalleVenta INT;

    -- Verificar que el detalle de venta existe para la combinación de idFactura e idProducto y obtener el monto correspondiente
    SELECT @idDetalleVenta = d.id,
           @monto = CASE 
                        WHEN @razon = 'devPago' THEN subtotal
                        WHEN @razon = 'devProd' THEN p.Precio * cant
                    END
    FROM ventas.detalleVenta d 
    JOIN catalogo.producto p ON d.idProducto = p.id
    WHERE idFactura = @idFactura 
      AND idProducto = @idProducto;

    -- Si no se encontró el detalle de venta, se sale
    IF @idDetalleVenta IS NULL
    BEGIN
        PRINT 'No se encontró un detalle de venta con la combinación de idFactura y idProducto especificada.';
        RETURN;
    END;

    -- Verificar si ya existe una nota de crédito para este detalle de venta
    IF EXISTS (SELECT 1 FROM ventas.notasDeCredito WHERE idDetalleVenta = @idDetalleVenta)
    BEGIN
        RAISERROR ('Ya existe una nota de crédito asociada a este detalle de venta.', 16, 1);
        RETURN;  -- Detener la ejecución si ya existe una nota de crédito para este detalle de venta
    END;

    -- Insertar el registro en la tabla ventas.notasDeCredito con el monto calculado
    INSERT INTO ventas.notasDeCredito (idDetalleVenta, monto, razon)
    VALUES (@idDetalleVenta, @monto, @razon);

    PRINT 'Nota de crédito insertada exitosamente.';

    -- Registrar la acción en el log
    DECLARE @mensajeInsercion VARCHAR(1000);
    SET @mensajeInsercion = FORMATMESSAGE('Devolución de cliente: Nota de crédito para factura %d y producto %d.', @idFactura, @idProducto);
    
    EXEC registros.insertarLog 'Inserción de nota_de_credito', @mensajeInsercion;
END;
GO



CREATE or ALTER VIEW ventas.vista_de_notas_de_credito AS
SELECT  
    f.nroFactura as ID_Factura, 
    f.tipo_Factura as Tipo_de_factura, 
    f.fecha as FechaDeVenta, 
    f.hora as Hora, 
    mp.nombre as Medio_de_pago,
	f.idPago as identificadorDePago,
	s.idComercio as CuitEmpresa,
	v.idEmpleado as Cajero,
	p.nombre as Producto,
	d.precio as Precio_unitario,
    d.cant as Cantidad, 
	d.subtotal,
	f.total as Total,
	f.totalConIva as ConIva,
	c.cuil as idCliente,
    c.tipo_cliente as Tipo_de_cliente,
    s.localidad as Sucursal,
	nc.id as nroDeNotaDeCredito,
	nc.fecha as FechaDevolucion,
	nc.monto as Perdida,
	nc.razon as Devolucion
FROM 
    ventas.factura f 
JOIN 
    ventas.detalleVenta d ON f.id = d.idFactura
JOIN 
    ventas.registro_de_ventas v ON f.id = v.idFactura 
JOIN 
    supermercado.sucursal s ON v.idSucursal = s.id
JOIN 
	catalogo.producto p ON d.idProducto = p.id
JOIN 
	ventas.mediosDePago mp ON f.idMedio_de_pago = mp.id
LEFT JOIN
	ventas.cliente c ON v.idCliente = c.id
JOIN
	ventas.notasDeCredito nc ON d.id = nc.idDetalleVenta;
go





CREATE OR ALTER PROCEDURE supermercado.obtenerValorDivisa
    @ValorDivisa DECIMAL(8, 2) OUTPUT  -- Parámetro de salida para devolver el valor de la divisa
AS
BEGIN
    DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);

    -- Crear objeto HTTP
    EXEC sp_OACreate 'WinHttp.WinHttpRequest.5.1', @WinHttpObject OUT;

    -- Configurar la solicitud
    EXEC sp_OAMethod @WinHttpObject, 'open', NULL, 'GET', 'https://dolarapi.com/v1/dolares/blue';

    -- Enviar la solicitud
    EXEC sp_OAMethod @WinHttpObject, 'send';

    -- Obtener la respuesta en formato JSON
    EXEC sp_OAMethod @WinHttpObject, 'responseText', @ResponseJsonText OUTPUT;

    -- Destruir el objeto HTTP
    EXEC sp_OADestroy @WinHttpObject;

    -- Verificar si la respuesta es un JSON válido
    IF ISJSON(@ResponseJsonText) = 1
    BEGIN
        -- Inicializar la variable @ValorDivisa con el valor de 'venta' desde el JSON
        SET @ValorDivisa = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
    ELSE
    BEGIN
        -- Abortar el procedimiento y asignar un valor por defecto si el JSON no es válido
        PRINT 'La respuesta no es un JSON válido';
        SET @ValorDivisa = NULL;  -- Asignar NULL o un valor por defecto
        RETURN;
    END
END;
GO


/*
DECLARE @Divisa DECIMAL(8, 2);

-- Llamar al procedimiento y obtener el valor de la divisa
EXEC supermercado.obtenerValorDivisa @ValorDivisa = @Divisa OUTPUT;

-- Mostrar el valor obtenido
PRINT @Divisa;
*/

--------------------------------------------------------------------------------------------------------
-- TOTAL FACTURADO EN EL MES POR DIA DE LA SEMANA
--------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE ventas.TotalFacturadoPorDiaSemana
    @mes INT,
    @anio INT
AS
BEGIN
    -- Configuración de formato para devolver los nombres de días en español
    SET LANGUAGE Spanish;

    -- Declarar una variable para almacenar el valor de la divisa
    DECLARE @ValorDivisa DECIMAL(8, 2);

    -- Llamar al procedimiento supermercado.obtenerValorDivisa para obtener el valor de la divisa
    EXEC supermercado.obtenerValorDivisa @ValorDivisa OUTPUT;

    -- Verificar si la divisa es NULL (indicando que la respuesta no fue válida)
    IF @ValorDivisa IS NULL
    BEGIN
        PRINT 'No se pudo obtener el valor de la divisa o el JSON es inválido';
        RETURN;
    END

    -- Agregar punto y coma antes del WITH para evitar el error de sintaxis
    ;WITH FacturacionSemana AS (
        SELECT 
            DATENAME(weekday, f.fecha) AS DiaSemana,
            SUM(f.totalConIva - ISNULL(nc.monto, 0)) AS TotalFacturado
        FROM 
            ventas.factura AS f
        JOIN 
            ventas.detalleVenta AS d ON f.id = d.idFactura
        LEFT JOIN 
            ventas.notasDeCredito AS nc ON nc.idDetalleVenta = d.id
        WHERE 
            MONTH(f.fecha) = @mes
            AND YEAR(f.fecha) = @anio
        GROUP BY 
            DATENAME(weekday, f.fecha), DATEPART(weekday, f.fecha)
    )
    SELECT DiaSemana, TotalFacturado,
        (TotalFacturado * @ValorDivisa) AS EnPesosArgentinos
    FROM FacturacionSemana
    FOR XML PATH('DiaSemanaFactura'), ROOT('Reporte');
END;
GO



--------------------------------------------------------------------------------------------------------
-- TOTAL FACTURADO POR TURNOS DE TRABAJO EN EL MES EN UN TRIMESTRE DEL AÑO
--------------------------------------------------------------------------------------------------------

CREATE or ALTER PROCEDURE ventas.reporte_trimestral_facturacion
    @Trimestre INT,
    @Anio INT
AS
BEGIN
	-- Configuración de formato para devolver los nombres en español
    SET LANGUAGE Spanish;

	-- Declarar una variable para almacenar el valor de la divisa
    DECLARE @ValorDivisa DECIMAL(8, 2);

    -- Llamar al procedimiento supermercado.obtenerValorDivisa para obtener el valor de la divisa
    EXEC supermercado.obtenerValorDivisa @ValorDivisa OUTPUT;

    -- Declarar variables para los límites del trimestre
    DECLARE @FechaInicio DATE, @FechaFin DATE;

    -- Establecer las fechas de inicio y fin del trimestre
    SET @FechaInicio = CASE @Trimestre
                          WHEN 1 THEN CONCAT(@Anio, '-01-01')
                          WHEN 2 THEN CONCAT(@Anio, '-04-01')
                          WHEN 3 THEN CONCAT(@Anio, '-07-01')
                          WHEN 4 THEN CONCAT(@Anio, '-10-01')
                       END;

    SET @FechaFin = CASE @Trimestre
                       WHEN 1 THEN CONCAT(@Anio, '-03-31')
                       WHEN 2 THEN CONCAT(@Anio, '-06-30')
                       WHEN 3 THEN CONCAT(@Anio, '-09-30')
                       WHEN 4 THEN CONCAT(@Anio, '-12-31')
                    END;

    -- Generar el reporte en XML
	WITH Factura AS (
    SELECT 
        MONTH(f.fecha) AS Mes,
        e.turno AS Turno,
        DATENAME(MONTH, f.fecha) AS MesNombre,
        SUM(f.totalConIva) - COALESCE(SUM(n.monto), 0) AS Facturacion
    FROM ventas.factura f
    JOIN ventas.detalleVenta d ON f.id = d.idFactura
    LEFT JOIN ventas.notasDeCredito n 
        ON d.id = n.idDetalleVenta 
    JOIN ventas.registro_de_ventas vr ON f.id = vr.idFactura
    JOIN supermercado.empleado e ON vr.idEmpleado = e.legajo
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
      AND f.estadoDePago = 'pagada'
    GROUP BY MONTH(f.fecha), e.turno, DATENAME(MONTH, f.fecha)
	)
	SELECT Mes, Turno, MesNombre, Facturacion, 
				(Facturacion * @ValorDivisa) AS EnPesosArgentinos
	FROM Factura
    ORDER BY Mes, Turno
    FOR XML PATH('Reporte'), ROOT('FacturacionTrimestral');
END;
go




--------------------------------------------------------------------------------------------------------
-- CANTIDAD DE PRODUCTOS VENDIDOS EN UN RANGO TEMPORAL
--------------------------------------------------------------------------------------------------------

CREATE or ALTER PROCEDURE ventas.reporte_producto_vendido_rango_fecha
    @FechaIni DATE,
    @FechaFinal DATE
AS
BEGIN
    -- Generar reporte en XML excluyendo productos con notas de crédito y la razón "devolución de pago"
    SELECT 
        p.nombre AS Producto,
        SUM(d.cant) AS CantidadVendida
    FROM ventas.detalleVenta d
    JOIN ventas.factura f ON d.idFactura = f.id
    JOIN catalogo.producto p ON d.idProducto = p.id
    LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devPago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
    GROUP BY p.nombre
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('ReporteProductosVendidos');
END
GO




--------------------------------------------------------------------------------------------------------
-- CANTIDAD DE PRODUCTOS VENDIDOS EN UN RANGO TEMPORAL POR SUCURSAL
--------------------------------------------------------------------------------------------------------

CREATE or ALTER PROCEDURE ventas.reporte_producto_vendido_rango_fecha_sucursal
    @FechaIni DATE,
    @FechaFinal DATE
AS
BEGIN
    -- Generar reporte en XML excluyendo productos con notas de crédito y la razón "devolución de pago"
    SELECT 
        s.localidad AS Sucursal,
        p.nombre AS Producto,
        SUM(d.cant) AS CantidadVendida
    FROM ventas.detalleVenta d
    JOIN ventas.factura f ON d.idFactura = f.id
    JOIN catalogo.producto p ON d.idProducto = p.id
    JOIN ventas.registro_de_ventas r ON d.idFactura = r.idFactura  -- Ahora se obtiene el idSucursal de la tabla 'registradas'
    JOIN supermercado.sucursal s ON r.idSucursal = s.id   -- El idSucursal está en 'registradas'
    LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devPago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
    GROUP BY s.localidad, p.nombre
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Venta'), ROOT('ReporteProductosVendidosPorSucursal');
END
GO



--------------------------------------------------------------------------------------------------------
-- 5 PRODUCTOS MAS VENDIDOS EN UN MES POR CADA SEMANA
--------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.reporte_productos_mas_vendidos_por_semana
    @Mes INT,  -- Mes en formato MM (1-12)
    @Anio INT   -- Año en formato YYYY
AS
BEGIN
    -- Generar reporte en XML para los 5 productos más vendidos por semana en un mes
    ;WITH ProductosPorSemana AS (
        SELECT 
            p.nombre AS Producto,
            SUM(d.cant) AS CantidadVendida,
            DATEPART(WEEK, f.fecha) AS Semana,
            ROW_NUMBER() OVER (PARTITION BY DATEPART(WEEK, f.fecha) ORDER BY SUM(d.cant) DESC) AS Rnk
        FROM ventas.detalleVenta d
        JOIN ventas.factura f ON d.idFactura = f.id
        JOIN catalogo.producto p ON d.idProducto = p.id
        WHERE MONTH(f.fecha) = @Mes
          AND YEAR(f.fecha) = @Anio
        GROUP BY p.nombre, DATEPART(WEEK, f.fecha)
    )
    SELECT 
        Producto,
        Semana,
        CantidadVendida
    FROM ProductosPorSemana
    WHERE Rnk <= 5
    ORDER BY Semana, CantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('ReporteProductosPorSemana');
END;
GO



--------------------------------------------------------------------------------------------------------
-- 5 PRODUCTOS MAS VENDIDOS EN UN MES 
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.reporte_productos_menos_vendidos_mes
    @Mes INT,  -- Mes en formato MM (1-12)
    @Anio INT   -- Año en formato YYYY
AS
BEGIN
    -- Generar reporte en XML para los 5 productos menos vendidos en un mes
    SELECT TOP 5
        p.nombre AS Producto,
        SUM(d.cant) AS CantidadVendida
    FROM ventas.detalleVenta d
    JOIN ventas.factura f ON d.idFactura = f.id
    JOIN catalogo.producto p ON d.idProducto = p.id
    WHERE MONTH(f.fecha) = @Mes
      AND YEAR(f.fecha) = @Anio
    GROUP BY p.nombre
    ORDER BY CantidadVendida ASC  -- Ordenar de menor a mayor cantidad vendida
    FOR XML PATH('Producto'), ROOT('ReporteProductosMenosVendidos');
END
GO



--------------------------------------------------------------------------------------------------------
-- ACUMULADO TOTAL DE LAS VENTAS HASTA UNA FECHA 
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.reporte_total_acumulado_ventas
    @Fecha DATE,
    @SucursalID INT
AS
BEGIN
	-- Declarar una variable para almacenar el valor de la divisa
    DECLARE @ValorDivisa DECIMAL(8, 2);

    -- Llamar al procedimiento supermercado.obtenerValorDivisa para obtener el valor de la divisa
    EXEC supermercado.obtenerValorDivisa @ValorDivisa OUTPUT;

    ;WITH VentasPorProducto AS (
        SELECT 
            p.nombre AS Producto,               -- Nombre del producto
            SUM(d.cant) AS CantidadVendida,     -- Total de productos vendidos
            f.totalConIva AS TotalVenta -- Total de ventas por producto
        FROM ventas.detalleVenta d
        JOIN ventas.factura f ON d.idFactura = f.id
        JOIN catalogo.producto p ON d.idProducto = p.id
        JOIN ventas.registro_de_ventas r ON d.idFactura = r.idFactura
        LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
        AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
        WHERE f.fecha <= @Fecha
          AND r.idSucursal = @SucursalID  -- Filtro por sucursal
        GROUP BY p.nombre, f.totalConIva
    ),
    TotalVentasAcumulado AS (
        SELECT SUM(TotalVenta) AS TotalVentas
        FROM VentasPorProducto
    )
    SELECT 
        vp.Producto AS 'Producto',               -- Nombre del producto
        vp.CantidadVendida AS 'CantidadVendida',  -- Total de productos vendidos
        vp.TotalVenta AS 'TotalVenta',           -- Total de ventas por producto
		(vp.TotalVenta * @ValorDivisa) AS EnPesosArgentinos,
        ta.TotalVentas AS 'AcumuladoTotalVentas', -- Total acumulado de todas las ventas
		(TotalVentas * @ValorDivisa) AS TotalEnPesosArgentinos
    FROM VentasPorProducto vp
    CROSS JOIN TotalVentasAcumulado ta
    ORDER BY vp.TotalVenta DESC
    FOR XML PATH('Venta'), ROOT('ReporteVentasPorSucursal');
END
GO


---------------------------------------------------------------------------------------
-- MOSTRAR EMPLEADOS DESENCRIPTADOS SOLO DE LA SUCURSAL DEL GERENTE QUE LO SOLICITA
---------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.mostrarEmpleadosDesencriptadosDelGerente
    @FraseClave NVARCHAR(128),
    @idSucursalGerente INT,  -- Parámetro para la sucursal del gerente
    @idEmpleado INT          -- Si se requiere el legajo o ID del empleado
AS
BEGIN
    -- Verificamos que el gerente solo pueda ver empleados de su sucursal
    IF EXISTS (SELECT 1 FROM supermercado.empleado WHERE legajo = @idEmpleado AND idSucursal = @idSucursalGerente)
    BEGIN
        SELECT
            legajo,
            nombre = CONVERT(VARCHAR(30), DecryptByPassPhrase(@FraseClave, nombre)),
            apellido = CONVERT(VARCHAR(30), DecryptByPassPhrase(@FraseClave, apellido)),
            dni = CONVERT(INT, DecryptByPassPhrase(@FraseClave, dni)),
            direccion = CONVERT(VARCHAR(100), DecryptByPassPhrase(@FraseClave, direccion)),
            email_personal = CONVERT(VARCHAR(80), DecryptByPassPhrase(@FraseClave, email_personal)),
            email_empresa = CONVERT(VARCHAR(80), DecryptByPassPhrase(@FraseClave, email_empresa)),
            cargo,
            idSucursal,
            turno
        FROM supermercado.empleado
        WHERE idSucursal = @idSucursalGerente -- Filtro por sucursal del gerente
          AND nombre IS NOT NULL
          AND apellido IS NOT NULL
          AND dni IS NOT NULL
          AND direccion IS NOT NULL
          AND email_personal IS NOT NULL
          AND email_empresa IS NOT NULL;
    END
    ELSE
    BEGIN
        PRINT 'Acceso denegado: El gerente no tiene permisos para ver empleados de otras sucursales.';
    END
END;
go




--------------------------------------------------------------------------------------------------------
-- REPORTE DE VENTAS 
--------------------------------------------------------------------------------------------------------

CREATE or ALTER VIEW ventas.reporte_de_ventas AS
SELECT  
    f.nroFactura as ID_Factura, 
    f.tipo_Factura as Tipo_de_factura, 
	s.ciudad as Ciudad,
    c.tipo_cliente as Tipo_de_cliente, 
    c.genero as Genero,
	lp.nombre as Linea_de_Producto,
	p.nombre as Producto,
	p.Precio as Precio_unitario,
    d.cant as Cantidad, 
    f.fecha as Fecha, 
    f.hora as Hora, 
    mp.nombre as Medio_de_pago, 
    v.idEmpleado as Empleado,
    s.localidad as Sucursal
FROM 
    ventas.factura f 
JOIN 
    ventas.detalleVenta d ON f.id = d.idFactura
JOIN 
    ventas.registro_de_ventas v ON f.id = v.idFactura 
JOIN 
    supermercado.sucursal s ON v.idSucursal = s.id
JOIN 
    supermercado.empleado e ON v.idEmpleado = e.legajo
JOIN
	catalogo.producto p ON d.idProducto = p.id
JOIN
	catalogo.linea_de_producto lp ON p.id_linea = lp.id
JOIN 
	ventas.mediosDePago mp ON f.idMedio_de_pago = mp.id
LEFT JOIN
	ventas.cliente c ON v.idCliente = c.id;
go



--------------------------------------------------------------------------------------------------------
-- SPs PARA EL DBA
--------------------------------------------------------------------------------------------------------

--- MOSTRAR EMPLEADOS DESENCRIPTADOS

CREATE OR ALTER PROCEDURE supermercado.mostrarEmpleadosDesencriptados
    @FraseClave NVARCHAR(128)
AS
BEGIN
    SELECT
        legajo,
        nombre = CONVERT(VARCHAR(30), DecryptByPassPhrase(@FraseClave, nombre)),
        apellido = CONVERT(VARCHAR(30), DecryptByPassPhrase(@FraseClave, apellido)),
        dni = CONVERT(INT, DecryptByPassPhrase(@FraseClave, dni)),
        direccion = CONVERT(VARCHAR(100), DecryptByPassPhrase(@FraseClave, direccion)),
        email_personal = CONVERT(VARCHAR(80), DecryptByPassPhrase(@FraseClave, email_personal)),
        email_empresa = CONVERT(VARCHAR(80), DecryptByPassPhrase(@FraseClave, email_empresa)),
        cargo,
        idSucursal,
        turno
    FROM supermercado.empleado;
END;
GO



--- este sp sirve para cifrar con una nueva frase clave, mandandole la anterior clave para que descifre antes de cifrar

CREATE OR ALTER PROCEDURE supermercado.CambiarCifradoTablaEmpleado
    @FraseClaveVieja NVARCHAR(128),
    @FraseClaveNueva NVARCHAR(128)
AS
BEGIN
    -- Actualizar cada fila: primero descifrar con la FraseClaveVieja y luego cifrar con la FraseClaveNueva
    UPDATE supermercado.empleado
    SET 
        nombre = EncryptByPassPhrase(@FraseClaveNueva, CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClaveVieja, nombre))),
        apellido = EncryptByPassPhrase(@FraseClaveNueva, CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClaveVieja, apellido))),
        dni = EncryptByPassPhrase(@FraseClaveNueva, CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClaveVieja, dni))),
        direccion = EncryptByPassPhrase(@FraseClaveNueva, CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClaveVieja, direccion))),
        email_personal = EncryptByPassPhrase(@FraseClaveNueva, CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClaveVieja, email_personal))),
        email_empresa = EncryptByPassPhrase(@FraseClaveNueva, CONVERT(NVARCHAR(256), DecryptByPassPhrase(@FraseClaveVieja, email_empresa)));
END;
GO











CREATE OR ALTER PROCEDURE supermercado.insertarUsuario
    @legajo INT,
    @usuario VARCHAR(50)
AS
BEGIN
    -- Verificar si el empleado existe
    IF NOT EXISTS (SELECT 1 FROM supermercado.empleado WHERE legajo = @legajo AND activo = 1)
    BEGIN
        PRINT 'Empleado no encontrado o inactivo';
        RETURN;
    END

    -- Insertar el nombre de usuario en el campo 'usuario'
    UPDATE supermercado.empleado
    SET usuario = @usuario
    WHERE legajo = @legajo;

    PRINT 'Nombre de usuario insertado exitosamente';

	-- Registrar la acción en el log
    DECLARE @mensajeInsercion VARCHAR(1000);
    SET @mensajeInsercion = FORMATMESSAGE('Empleado con legajo %d y usuario %s insertado.', @legajo, @usuario);
    
    EXEC registros.insertarLog 'Inserción de usuario para empleado', @mensajeInsercion;
END;
GO


/*
sp_addrolemember es un procedimiento almacenado en SQL Server que se usa para agregar 
un usuario o grupo de usuarios a un rol específico dentro de la base de datos. 
Cuando se ejecuta, concede permisos y privilegios a un usuario basados en el rol especificado. 
Esto es especialmente útil para asignar permisos de seguridad 
sin tener que configurarlos manualmente para cada usuario.

Ejemplo de uso de sp_addrolemember:

EXEC sp_addrolemember 'nombre_rol', 'nombre_usuario';
'nombre_rol': Es el rol al cual se desea agregar el usuario (por ejemplo, cajero, supervisor, db_datareader, etc.).
'nombre_usuario': Es el nombre del usuario que se quiere añadir a ese rol.
*/

CREATE OR ALTER PROCEDURE supermercado.asignarRol
    @legajo INT
AS
BEGIN
    -- Verificar si el empleado existe, está activo y tiene un usuario asignado
    IF NOT EXISTS (SELECT 1 FROM supermercado.empleado WHERE legajo = @legajo AND activo = 1 AND usuario IS NOT NULL)
    BEGIN
        PRINT 'Empleado no encontrado, inactivo o sin usuario asignado';
        RETURN;
    END

    -- Variables para almacenar datos del empleado
    DECLARE @cargo VARCHAR(20);
    DECLARE @usuario VARCHAR(50);
    DECLARE @rol VARCHAR(50);

    -- Obtener el cargo y el usuario del empleado
    SELECT @cargo = cargo,
           @usuario = usuario
    FROM supermercado.empleado
    WHERE legajo = @legajo;

    -- Verificar que el usuario no sea NULL
    IF @usuario IS NULL
    BEGIN
        PRINT 'El empleado con legajo ' + CAST(@legajo AS VARCHAR(10)) + ' no tiene un usuario asignado';
        RETURN;
    END

    -- Determinar el rol según el cargo del empleado
    SET @rol = CASE 
                    WHEN @cargo = 'Cajero' THEN 'cajero'
                    WHEN @cargo = 'Supervisor' THEN 'supervisor'
                    WHEN @cargo = 'Gerente de sucursal' THEN 'gerente'
                    ELSE NULL 
               END;

    -- Validar que el rol sea válido
    IF @rol IS NOT NULL
    BEGIN
        -- Verificar si el usuario ya es miembro del rol
        IF NOT EXISTS (
            SELECT 1 
            FROM sys.database_role_members rm
            JOIN sys.database_principals p ON rm.member_principal_id = p.principal_id
            JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
            WHERE p.name = @usuario AND r.name = @rol
        )
        BEGIN
            -- Asignar el rol al usuario si no es miembro
            EXEC sp_addrolemember @rol, @usuario;
            PRINT 'Rol ' + @rol + ' asignado exitosamente al usuario ' + @usuario;
        END
        ELSE
        BEGIN
            PRINT 'El usuario ' + @usuario + ' ya es miembro del rol ' + @rol;
        END
    END
    ELSE
    BEGIN
        PRINT 'Cargo no válido para asignación de rol para el legajo ' + CAST(@legajo AS VARCHAR(10));
    END
END;
GO







