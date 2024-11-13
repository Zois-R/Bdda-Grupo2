use COM5600G02;
go


CREATE or ALTER VIEW ventas.vista_factura_detalle AS
SELECT 
    f.id AS IdFactura, 
    f.nroFactura, 
    f.tipo_Factura, 
    f.fecha, 
    f.hora, 
    f.idMedio_de_pago, 
    f.idPago, 
    f.estadoDePago,
    d.id AS idDetalle_venta, 
    d.idProducto, 
    d.idLineaProducto, 
    d.subtotal, 
    d.cant, 
    d.precio, 
    s.localidad, 
    v.tipo_cliente, 
    v.genero,
    v.idEmpleado AS legajoEmpleado
FROM 
    ventas.factura f 
JOIN 
    ventas.detalleVenta d ON f.id = d.idFactura
JOIN 
    ventas.ventas_registradas v ON f.id = v.idFactura 
JOIN 
    supermercado.sucursal s ON v.idSucursal = s.id
JOIN 
    supermercado.empleado e ON v.idEmpleado = e.legajo;
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
    FROM ventas.detalleVenta d join catalogo.producto p on d.idProducto = p.id
    WHERE idFactura = @idFactura 
      AND idProducto = @idProducto;

    -- Si no se encontró el detalle de venta, se sale
    IF @idDetalleVenta IS NULL
    BEGIN
        PRINT 'No se encontró un detalle de venta con la combinación de idFactura y idProducto especificada.';
        RETURN;
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

	DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);
    DECLARE @Venta DECIMAL(8, 2); -- Variable para almacenar el valor de 'venta'

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
        -- Inicializar la variable @Venta con el valor de 'venta'
        SET @Venta = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
	ELSE
	BEGIN
		-- Abortar el procedimiento
		PRINT 'La respuesta no es un JSON válido';
		RETURN;
	END;

	-- Calcular el total facturado por día de la semana
	WITH FacturacionSemana AS (
		SELECT 
			DATENAME(weekday, f.fecha) AS DiaSemana,
			SUM(d.subtotal - ISNULL(nc.monto, 0)) AS TotalFacturado
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
        (TotalFacturado * @Venta) AS EnPesosArgentinos
	FROM FacturacionSemana
	FOR XML PATH('DiaSemanaFactura'), ROOT('Reporte');
END;
GO


/*
CREATE or ALTER PROCEDURE ventas.TotalFacturadoPorDiaSemana
    @mes INT,
    @anio INT
AS
BEGIN
	-- Configuración de formato para devolver los nombres de días en español
    SET LANGUAGE Spanish;

	DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);
    DECLARE @Venta DECIMAL(8, 2); -- Variable para almacenar el valor de 'venta'

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
        -- Inicializar la variable @Venta con el valor de 'venta'
        SET @Venta = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
	ELSE
	BEGIN
		-- Abortar el procedimiento
		PRINT 'La respuesta no es un JSON válido';
		return
	END;

    -- Consulta para calcular el total facturado por día de la semana, considerando las notas de crédito
    WITH FacturacionSemana AS (
        SELECT 
            DATENAME(weekday, f.fecha) AS DiaSemana,
            SUM(d.subtotal - ISNULL(nc.monto, 0)) AS TotalFacturado,
            DATEPART(weekday, f.fecha) AS DiaNumero
        FROM 
            ventas.factura AS f
        JOIN 
            ventas.detalleVenta AS d ON f.id = d.idFactura
        LEFT JOIN 
            ventas.notasDeCredito AS nc 
                ON nc.idFactura = f.id AND nc.idProducto = d.idProducto
        WHERE 
            MONTH(f.fecha) = @mes
            AND YEAR(f.fecha) = @anio
        GROUP BY 
            DATENAME(weekday, f.fecha), DATEPART(weekday, f.fecha)
    )
    SELECT 
        DiaSemana, 
        TotalFacturado,
        (TotalFacturado * @Venta) AS EnPesosArgentinos
    FROM 
        FacturacionSemana
    ORDER BY 
        DiaNumero -- Ordena numéricamente por el día de la semana (1-7)
    FOR XML AUTO, ROOT('Reporte');
END
GO
*/





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

	DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);
    DECLARE @Venta DECIMAL(8, 2); -- Variable para almacenar el valor de 'venta'

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
        -- Inicializar la variable @Venta con el valor de 'venta'
        SET @Venta = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
	ELSE
	BEGIN
		-- Abortar el procedimiento
		PRINT 'La respuesta no es un JSON válido';
		return
	END;

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
        SUM(d.subtotal) - COALESCE(SUM(n.monto), 0) AS Facturacion
    FROM ventas.factura f
    JOIN ventas.detalleVenta d ON f.id = d.idFactura
    LEFT JOIN ventas.notasDeCredito n 
        ON d.id = n.idDetalleVenta 
    JOIN ventas.ventas_registradas vr ON f.id = vr.idFactura
    JOIN supermercado.empleado e ON vr.idEmpleado = e.legajo
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
      AND f.estadoDePago = 'pagada'
    GROUP BY MONTH(f.fecha), e.turno, DATENAME(MONTH, f.fecha)
	)
	SELECT Mes, Turno, MesNombre, Facturacion, 
				(Facturacion * @Venta) AS EnPesosArgentinos
	FROM Factura
    ORDER BY Mes, Turno
    FOR XML PATH('Reporte'), ROOT('FacturacionTrimestral');
END;
go


/*
CREATE or ALTER PROCEDURE ventas.reporte_trimestral_facturacion
    @Trimestre INT,
    @Anio INT
AS
BEGIN
	-- Configuración de formato para devolver los nombres en español
    SET LANGUAGE Spanish;

	DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);
    DECLARE @Venta DECIMAL(8, 2); -- Variable para almacenar el valor de 'venta'

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
        -- Inicializar la variable @Venta con el valor de 'venta'
        SET @Venta = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
	ELSE
	BEGIN
		-- Abortar el procedimiento
		PRINT 'La respuesta no es un JSON válido';
		return
	END;

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

    -- Generar el reporte en XML usando el modo AUTO
	WITH Factura AS (
    SELECT 
        MONTH(f.fecha) AS Mes,
        e.turno AS Turno,
        DATENAME(MONTH, f.fecha) AS MesNombre,
        SUM(d.subtotal) - COALESCE(SUM(n.monto), 0) AS Facturacion
    FROM ventas.factura f
    JOIN ventas.detalleVenta d ON f.id = d.idFactura
    LEFT JOIN ventas.notasDeCredito n 
        ON f.id = n.idFactura 
        AND d.idProducto = n.idProducto
    JOIN ventas.ventas_registradas vr ON f.id = vr.idFactura
    JOIN supermercado.empleado e ON vr.idEmpleado = e.legajo
    WHERE f.fecha BETWEEN @FechaInicio AND @FechaFin
      AND f.estadoDePago = 'pagada'
    GROUP BY MONTH(f.fecha), e.turno, DATENAME(MONTH, f.fecha)
	)
	SELECT Mes, Turno, MesNombre, Facturacion, 
				(Facturacion * @Venta) AS EnPesosArgentinos
	INTO #Reporte
	FROM Factura
    ORDER BY Mes, Turno
    -- Devolver el reporte en XML usando el modo AUTO
    SELECT * FROM #Reporte
    FOR XML AUTO, ROOT('FacturacionTrimestral');

    -- Eliminar la tabla temporal después de generar el reporte
    DROP TABLE #Reporte;
END;
go
*/




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
    AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
    GROUP BY p.nombre
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Producto'), ROOT('ReporteProductosVendidos');
END
GO


/*
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
    LEFT JOIN ventas.notasDeCredito nc ON nc.idFactura = f.id AND nc.idProducto = d.idProducto
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
    GROUP BY p.nombre
    ORDER BY CantidadVendida DESC
    FOR XML AUTO, ROOT('ReporteProductosVendidos');
END
go
*/




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
    JOIN ventas.ventas_registradas r ON d.idFactura = r.idFactura  -- Ahora se obtiene el idSucursal de la tabla 'registradas'
    JOIN supermercado.sucursal s ON r.idSucursal = s.id   -- El idSucursal está en 'registradas'
    LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
    GROUP BY s.localidad, p.nombre
    ORDER BY CantidadVendida DESC
    FOR XML PATH('Venta'), ROOT('ReporteProductosVendidosPorSucursal');
END
GO

/*
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
    JOIN ventas.ventas_registradas r ON d.idFactura = r.idFactura  -- Ahora se obtiene el idSucursal de la tabla 'registradas'
    JOIN supermercado.sucursal s ON r.idSucursal = s.id   -- El idSucursal está en 'registradas'
    LEFT JOIN ventas.notasDeCredito nc ON nc.idFactura = f.id AND nc.idProducto = d.idProducto
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
    GROUP BY s.localidad, p.nombre
    ORDER BY CantidadVendida DESC
    FOR XML AUTO, ROOT('ReporteProductosVendidosPorSucursal');
END
GO

*/



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

/*
CREATE OR ALTER PROCEDURE ventas.reporte_productos_mas_vendidos_por_semana
    @Mes INT,  -- Mes en formato MM (1-12)
    @Anio INT   -- Año en formato YYYY
AS
BEGIN
    -- Generar reporte en XML para los 5 productos más vendidos por semana en un mes
    WITH ProductosPorSemana AS (
        SELECT 
            p.nombre AS Producto,
            SUM(d.cant) AS CantidadVendida,
            DATEPART(WEEK, f.fecha) AS Semana
        FROM ventas.detalleVenta d
        JOIN ventas.factura f ON d.idFactura = f.id
        JOIN catalogo.producto p ON d.idProducto = p.id
        WHERE MONTH(f.fecha) = @Mes
          AND YEAR(f.fecha) = @Anio
        GROUP BY p.nombre, DATEPART(WEEK, f.fecha)
    )
    SELECT TOP 5
        Producto,
        Semana,
        CantidadVendida
    FROM ProductosPorSemana
    ORDER BY CantidadVendida DESC
    FOR XML AUTO, ROOT('ReporteProductosPorSemana');
END
GO
*/



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

/*
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
    FOR XML AUTO, ROOT('ReporteProductosMenosVendidos');
END
GO
*/





--------------------------------------------------------------------------------------------------------
-- ACUMULADO TOTAL DE LAS VENTAS HASTA UNA FECHA 
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.reporte_total_acumulado_ventas
    @Fecha DATE,
    @SucursalID INT
AS
BEGIN
	DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);
    DECLARE @Venta DECIMAL(8, 2); -- Variable para almacenar el valor de 'venta'

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
        -- Inicializar la variable @Venta con el valor de 'venta'
        SET @Venta = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
	ELSE
	BEGIN
		-- Abortar el procedimiento
		PRINT 'La respuesta no es un JSON válido';
		return
	END;

    ;WITH VentasPorProducto AS (
        SELECT 
            p.nombre AS Producto,               -- Nombre del producto
            SUM(d.cant) AS CantidadVendida,     -- Total de productos vendidos
            SUM(d.cant * p.precio) AS TotalVenta -- Total de ventas por producto
        FROM ventas.detalleVenta d
        JOIN ventas.factura f ON d.idFactura = f.id
        JOIN catalogo.producto p ON d.idProducto = p.id
        JOIN ventas.ventas_registradas r ON d.idFactura = r.idFactura
        LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
        AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
        WHERE f.fecha <= @Fecha
          AND r.idSucursal = @SucursalID  -- Filtro por sucursal
        GROUP BY p.nombre
    ),
    TotalVentasAcumulado AS (
        SELECT SUM(TotalVenta) AS TotalVentas
        FROM VentasPorProducto
    )
    SELECT 
        vp.Producto AS 'Producto',               -- Nombre del producto
        vp.CantidadVendida AS 'CantidadVendida',  -- Total de productos vendidos
        vp.TotalVenta AS 'TotalVenta',           -- Total de ventas por producto
		(vp.TotalVenta * @Venta) AS EnPesosArgentinos,
        ta.TotalVentas AS 'AcumuladoTotalVentas', -- Total acumulado de todas las ventas
		(vp.TotalVenta * @Venta) AS TotalEnPesosArgentinos
    FROM VentasPorProducto vp
    CROSS JOIN TotalVentasAcumulado ta
    ORDER BY vp.TotalVenta DESC
    FOR XML PATH('Venta'), ROOT('ReporteVentasPorSucursal');
END
GO

/*
CREATE OR ALTER PROCEDURE ventas.reporte_total_acumulado_ventas
    @Fecha DATE,
    @SucursalID INT
AS
BEGIN
	DECLARE @WinHttpObject INT;
    DECLARE @ResponseJsonText VARCHAR(8000);
    DECLARE @Venta DECIMAL(8, 2); -- Variable para almacenar el valor de 'venta'

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
        -- Inicializar la variable @Venta con el valor de 'venta'
        SET @Venta = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
	ELSE
	BEGIN
		-- Abortar el procedimiento
		PRINT 'La respuesta no es un JSON válido';
		return
	END;

    ;WITH VentasPorProducto AS (
        SELECT 
            p.nombre AS Producto,               -- Nombre del producto
            SUM(d.cant) AS CantidadVendida,     -- Total de productos vendidos
            SUM(d.cant * p.precio) AS TotalVenta -- Total de ventas por producto
        FROM ventas.detalleVenta d
        JOIN ventas.factura f ON d.idFactura = f.id
        JOIN catalogo.producto p ON d.idProducto = p.id
        JOIN ventas.ventas_registradas r ON d.idFactura = r.idFactura
        LEFT JOIN ventas.notasDeCredito nc ON nc.idFactura = f.id AND nc.idProducto = d.idProducto
        AND (nc.id IS NULL OR nc.razon != 'devolución de pago')  -- Excluir productos con notas de crédito con razón "devolución de pago"
        WHERE f.fecha <= @Fecha
          AND r.idSucursal = @SucursalID  -- Filtro por sucursal
        GROUP BY p.nombre
    ),
    TotalVentasAcumulado AS (
        SELECT SUM(TotalVenta) AS TotalVentas
        FROM VentasPorProducto
    )
    SELECT 
        vp.Producto,
        vp.CantidadVendida,
        vp.TotalVenta, 
		(vp.TotalVenta * @Venta) AS EnPesosArgentinos,
        ta.TotalVentas AS AcumuladoTotalVentas, -- Total acumulado de todas las ventas
		(vp.TotalVenta * @Venta) AS TotalEnPesosArgentinos
    FROM VentasPorProducto vp
    CROSS JOIN TotalVentasAcumulado ta
    ORDER BY vp.TotalVenta DESC
    FOR XML AUTO, ROOT('ReporteVentasPorSucursal');
END
GO
*/






--------------------------------------------------------------------------------------------------------
-- MOSTRAR EMPLEADOS DESENCRIPTADOS SOLO DE LA SUCURSAL DEL GERENTE QUE LO SOLICITA
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.mostrarEmpleadosDesencriptados
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
    v.tipo_cliente as Tipo_de_cliente, 
    v.genero as Genero,
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
    ventas.ventas_registradas v ON f.id = v.idFactura 
JOIN 
    supermercado.sucursal s ON v.idSucursal = s.id
JOIN 
    supermercado.empleado e ON v.idEmpleado = e.legajo
JOIN
	catalogo.producto p ON d.idProducto = p.id
JOIN
	catalogo.linea_de_producto lp ON d.idLineaProducto = lp.id
JOIN 
	ventas.mediosDePago mp ON f.idMedio_de_pago = mp.id;
go







