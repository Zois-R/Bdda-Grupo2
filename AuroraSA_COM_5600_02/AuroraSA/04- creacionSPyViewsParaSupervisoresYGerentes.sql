/************************************************************
 *                                                            *
 *                      BASE DE DATOS APLICADA                *
 *                                                            *
 *   INTEGRANTES:                                             *
 *      - Edilberto Guzman                                    *
 *      - Zois Andres Uziel Ruggiero Bellone                  *
 *      - Karen Anabella Bursa                                *
 *      - Jonathan Ivan Aranda Robles                         *
 *                                                            *
 *   NRO. DE ENTREGA: 4                                       *
 *   FECHA DE ENTREGA: 15/11/2024                             *
 *                                                            *
 *   CONSIGNA:                                                *
 *   Se requiere que importe toda la informaci�n antes        *
 *   mencionada a la base de datos:                           *
 *   � Genere los objetos necesarios (store procedures,       *
 *     funciones, etc.) para importar los archivos antes      *
 *     mencionados. Tenga en cuenta que cada mes se           *
 *     recibir�n archivos de novedades con la misma           *
 *     estructura, pero datos nuevos para agregar a cada      *
 *     maestro.                                               *
 *   � Considere este comportamiento al generar el c�digo.    *
 *     Debe admitir la importaci�n de novedades               *
 *     peri�dicamente.                                        *
 *   � Cada maestro debe importarse con un SP distinto. No    *
 *     se aceptar�n scripts que realicen tareas por fuera     *
 *     de un SP.                                              *
 *   � La estructura/esquema de las tablas a generar ser�     *
 *     decisi�n suya. Puede que deba realizar procesos de     *
 *     transformaci�n sobre los maestros recibidos para       *
 *     adaptarlos a la estructura requerida.                  *
 *                                                            *
 *   � Los archivos CSV/JSON no deben modificarse. En caso de *
 *     que haya datos mal cargados, incompletos, err�neos,    *
 *     etc., deber� contemplarlo y realizar las correcciones  *
 *     en el fuente SQL. (Ser�a una excepci�n si el archivo   *
 *     est� malformado y no es posible interpretarlo como     *
 *     JSON o CSV).                                           *
 *                                                            *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                           *
 *   Creamos vistas, stores procedures para, por ejemplo,     *
 *	 insertar una nota de credito. Integramos la utilizaci�n  *
 *	 de la API e incluimos el c�digo para generar             *
 *	 los resportes en XML.                                    *           
 *                                                            *
 *************************************************************/

use COM5600G02;
go

 --------------------------------------------------------------------------------------------------------
  --Creamos vista para los productos 
 --------------------------------------------------------------------------------------------------------


CREATE or ALTER VIEW catalogo.vista_Producto_Resumen AS
SELECT 
    id,
    nombre,
    Precio
FROM 
    catalogo.producto;
GO


 --------------------------------------------------------------------------------------------------------
  --Creamos vista para registros de ventas
 --------------------------------------------------------------------------------------------------------

CREATE or ALTER VIEW ventas.vista_de_registros_de_ventas AS
SELECT  
	f.id as id_nro_factura,
    f.nroFactura as ID_Factura, 
    f.tipo_Factura as Tipo_de_factura, 
    f.fecha as Fecha, 
    f.hora as Hora, 
    mp.nombre as Medio_de_pago,
	f.idPago as identificadorDePago,
	s.idComercio as CuitEmpresa,
	p.id as id_producto,
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
	ventas.cliente c ON v.idCliente = c.id
WHERE
	f.activo = 1;

go



 --------------------------------------------------------------------------------------------------------
  --Creamos vista para registros para facilicitar la vista al supervirsor asignado
 --------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.mostrar_factura_segun_supervisor
	@legajoSupervisor INT
AS
BEGIN

	declare @idSucursalObjetivo int;
	set @idSucursalObjetivo = (SELECT e.idSucursal FROM supermercado.empleado e where e.legajo=@legajoSupervisor);
	
	SELECT  
		f.id as id_nro_factura,
		f.nroFactura as ID_Factura, 
		f.tipo_Factura as Tipo_de_factura, 
		f.fecha as Fecha, 
		f.hora as Hora, 
		mp.nombre as Medio_de_pago,
		f.idPago as identificadorDePago,
		s.idComercio as CuitEmpresa,
		p.id as id_producto,
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
		ventas.cliente c ON v.idCliente = c.id
	WHERE
		s.id = @idSucursalObjetivo;

END
go



 --------------------------------------------------------------------------------------------------------
  --Creamos vista para registros de ventas
 --------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.mostrar_ventas_por_cajero
	@legajoEmpleado INT
AS
BEGIN
	SELECT * FROM ventas.vista_de_registros_de_ventas where Empleado=@legajoEmpleado;
END 
go
 --------------------------------------------------------------------------------------------------------
  --Creamos SP para insertar la nota de cr�dito
 --------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.insertarNotaDeCredito
    @idFactura INT,
    @idProducto INT,
    @razon NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificamos que el valor de 'razon' sea v�lido
    IF @razon NOT IN ('devPago', 'devProd')
    BEGIN
        RAISERROR ('Raz�n inv�lida. Solo se permiten las razones "devPago" (devoluci�n de pago) o "devProd" (devoluci�n del mismo producto).', 16, 1);
        RETURN;  -- Detener la ejecuci�n si la raz�n no es v�lida
    END;

    DECLARE @monto DECIMAL(6, 2);
    DECLARE @idDetalleVenta INT;

    -- Verificamos que el detalle de venta existe para la combinaci�n de idFactura e idProducto y obtener el monto correspondiente
    SELECT @idDetalleVenta = d.id,
           @monto = CASE 
                        WHEN @razon = 'devPago' THEN subtotal
                        WHEN @razon = 'devProd' THEN p.Precio * cant
                    END
    FROM ventas.detalleVenta d 
    JOIN catalogo.producto p ON d.idProducto = p.id
    WHERE idFactura = @idFactura 
      AND idProducto = @idProducto;

    -- Si no se encontr� el detalle de venta, se sale
    IF @idDetalleVenta IS NULL
    BEGIN
        PRINT 'No se encontr� un detalle de venta con la combinaci�n de idFactura y idProducto especificada.';
        RETURN;
    END;

    -- Verificamos si ya existe una nota de cr�dito para este detalle de venta
    IF EXISTS (SELECT 1 FROM ventas.notasDeCredito WHERE idDetalleVenta = @idDetalleVenta)
    BEGIN
        RAISERROR ('Ya existe una nota de cr�dito asociada a este detalle de venta.', 16, 1);
        RETURN;  -- Detener la ejecuci�n si ya existe una nota de cr�dito para este detalle de venta
    END;

    -- Insertamos el registro en la tabla ventas.notasDeCredito con el monto calculado
    INSERT INTO ventas.notasDeCredito (idDetalleVenta, monto, razon)
    VALUES (@idDetalleVenta, @monto, @razon);

    PRINT 'Nota de cr�dito insertada exitosamente.';

    -- Registra la acci�n en el log
    DECLARE @mensajeInsercion VARCHAR(1000);
    SET @mensajeInsercion = FORMATMESSAGE('Devoluci�n de cliente: Nota de cr�dito para factura %d y producto %d.', @idFactura, @idProducto);
    
    EXEC registros.insertarLog 'Inserci�n de nota_de_credito', @mensajeInsercion;
END;
GO


 --------------------------------------------------------------------------------------------------------
  --Creamos vista de las notas de cr�dito
 --------------------------------------------------------------------------------------------------------

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



 --------------------------------------------------------------------------------------------------------
  --Creamos SP para consultar a la API y traernos el json que devuelve.
 --------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.obtenerValorDivisa
    @ValorDivisa DECIMAL(8, 2) OUTPUT  -- Par�metro de salida para devolver el valor de la divisa
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

    -- Verificar si la respuesta es un JSON v�lido
    IF ISJSON(@ResponseJsonText) = 1
    BEGIN
        -- Inicializar la variable @ValorDivisa con el valor de 'venta' desde el JSON
        SET @ValorDivisa = CAST(JSON_VALUE(@ResponseJsonText, '$.venta') AS DECIMAL(8, 2));
    END
    ELSE
    BEGIN
        -- Abortar el procedimiento y asignar un valor por defecto si el JSON no es v�lido
        PRINT 'La respuesta no es un JSON v�lido';
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


------------------------------------------------------------REPORTES------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
-- TOTAL FACTURADO EN EL MES POR DIA DE LA SEMANA
--------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE ventas.TotalFacturadoPorDiaSemana
    @mes INT,
    @anio INT
AS
BEGIN
    -- Configuraci�n de formato para devolver los nombres de d�as en espa�ol
    SET LANGUAGE Spanish;

    -- Declaramos una variable para almacenar el valor de la divisa
    DECLARE @ValorDivisa DECIMAL(8, 2);

    -- Llama al procedimiento supermercado.obtenerValorDivisa para obtener el valor de la divisa
    EXEC supermercado.obtenerValorDivisa @ValorDivisa OUTPUT;

    -- Verificamos si la divisa es NULL (indicando que la respuesta no fue v�lida)
    IF @ValorDivisa IS NULL
    BEGIN
        PRINT 'No se pudo obtener el valor de la divisa o el JSON es inv�lido';
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
			AND f.activo = 1
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
-- TOTAL FACTURADO POR TURNOS DE TRABAJO EN EL MES EN UN TRIMESTRE DEL A�O
--------------------------------------------------------------------------------------------------------

CREATE or ALTER PROCEDURE ventas.reporte_trimestral_facturacion
    @Trimestre INT,
    @Anio INT
AS
BEGIN
	-- Configuraci�n de formato para devolver los nombres en espa�ol
    SET LANGUAGE Spanish;

	-- Declaramos una variable para almacenar el valor de la divisa
    DECLARE @ValorDivisa DECIMAL(8, 2);

    -- Llama al procedimiento supermercado.obtenerValorDivisa para obtener el valor de la divisa
    EXEC supermercado.obtenerValorDivisa @ValorDivisa OUTPUT;

    -- Declarar variables para los l�mites del trimestre
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
	  AND f.activo = 1
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
    -- Generar reporte en XML excluyendo productos con notas de cr�dito y la raz�n "devoluci�n de pago"
    SELECT 
        p.nombre AS Producto,
        SUM(d.cant) AS CantidadVendida
    FROM ventas.detalleVenta d
    JOIN ventas.factura f ON d.idFactura = f.id
    JOIN catalogo.producto p ON d.idProducto = p.id
    LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devPago')  -- Excluir productos con notas de cr�dito con raz�n "devoluci�n de pago"
    AND f.activo = 1
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
    -- Generar reporte en XML excluyendo productos con notas de cr�dito y la raz�n "devoluci�n de pago"
    SELECT 
        s.localidad AS Sucursal,
        p.nombre AS Producto,
        SUM(d.cant) AS CantidadVendida
    FROM ventas.detalleVenta d
    JOIN ventas.factura f ON d.idFactura = f.id
    JOIN catalogo.producto p ON d.idProducto = p.id
    JOIN ventas.registro_de_ventas r ON d.idFactura = r.idFactura  -- Ahora se obtiene el idSucursal de la tabla 'registradas'
    JOIN supermercado.sucursal s ON r.idSucursal = s.id   -- El idSucursal est� en 'registradas'
    LEFT JOIN ventas.notasDeCredito nc ON nc.idDetalleVenta = d.id
    WHERE f.fecha BETWEEN @FechaIni AND @FechaFinal
    AND (nc.id IS NULL OR nc.razon != 'devPago')  -- Excluir productos con notas de cr�dito con raz�n "devoluci�n de pago"
    AND f.activo = 1
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
    @Anio INT   -- A�o en formato YYYY
AS
BEGIN
    -- Generar reporte en XML para los 5 productos m�s vendidos por semana en un mes
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
		  AND f.activo = 1
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
    @Anio INT   -- A�o en formato YYYY
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
	  AND f.activo = 1
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
        AND (nc.id IS NULL OR nc.razon != 'devoluci�n de pago')  -- Excluir productos con notas de cr�dito con raz�n "devoluci�n de pago"
        WHERE f.fecha <= @Fecha
          AND r.idSucursal = @SucursalID  -- Filtro por sucursal
		  AND f.activo = 1
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



--------------------------------------------------------------------------------------------------------
-- ACUMULADO TOTAL DE LAS VENTAS DE UNA FECHA ESPECIFICA 
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.reporte_total_acumulado_ventas_dado_fecha
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
        AND (nc.id IS NULL OR nc.razon != 'devoluci�n de pago')  -- Excluir productos con notas de cr�dito con raz�n "devoluci�n de pago"
        WHERE f.fecha = @Fecha
          AND r.idSucursal = @SucursalID  -- Filtro por sucursal
		  AND f.activo = 1
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
    @idSucursalGerente INT,  -- Par�metro para la sucursal del gerente
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
-- REPORTE DE VENTAS , VISTA
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
	ventas.cliente c ON v.idCliente = c.id
WHERE
	f.activo = 1;
go


--------------------------------------------------------------------------------------------------------
-- REPORTE DE VENTAS , EN XML
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.generar_reporte_ventas_xml
AS
BEGIN
    SELECT * FROM ventas.reporte_de_ventas
    FOR XML PATH('Venta'), ROOT('ReporteVentas');
END;

GO
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




------------------------------------------------------------------------------------------------------------------------
--- Este sp sirve para cifrar con una nueva frase clave, mandandole la anterior clave para que descifre antes de cifrar
------------------------------------------------------------------------------------------------------------------------


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


------------------------------------------------------------------------------------------------------------------------
--- Creamos SP para insertar un USUARIO
------------------------------------------------------------------------------------------------------------------------

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

	-- Registrar la acci�n en el log
    DECLARE @mensajeInsercion VARCHAR(1000);
    SET @mensajeInsercion = FORMATMESSAGE('Empleado con legajo %d y usuario %s insertado.', @legajo, @usuario);
    
    EXEC registros.insertarLog 'Inserci�n de usuario para empleado', @mensajeInsercion;
END;
GO





