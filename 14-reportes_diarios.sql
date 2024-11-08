use COM5600G02;
go


---------reporte diarios 
-- 1. Crear el procedimiento para dar de baja una factura y generar una nota de credito
CREATE PROCEDURE ventas.DarDeBajaFactura
    @FacturaID INT
AS
BEGIN
    -- Verifica si la factura ya esta inactiva
    IF EXISTS (SELECT 1 FROM ventas.ventas_registradas WHERE id = @FacturaID AND activo = 0)
    BEGIN
        PRINT 'La factura ya está cancelada.';
        RETURN;
    END
    
    -- Marcar la factura como inactiva (cancelada)
    UPDATE ventas.ventas_registradas
    SET activo = 0
    WHERE id = @FacturaID;

    PRINT 'La factura ha sido cancelada exitosamente.';
    
    -- Llamada para generar la nota de credito
    EXEC ventas.GenerarNotaDeCredito @FacturaID;
END;
GO

-- 2. Crear la tabla para almacenar las notas de credito
CREATE TABLE ventas.notasDeCredito (
    id INT IDENTITY(1,1) PRIMARY KEY,--poner idnotadecredito 
    idFactura INT,--agregar que traiga el numero de factura y no el id
    fecha DATE DEFAULT GETDATE(),
    monto DECIMAL(20,2),
    razon NVARCHAR(255),
    CONSTRAINT fk_factura FOREIGN KEY (idFactura) REFERENCES ventas.ventas_registradas(id)
);
GO

-- 3. Crear el procedimiento para generar una nota de credito
CREATE PROCEDURE ventas.GenerarNotaDeCredito
    @FacturaID INT
AS
BEGIN
    DECLARE @MontoTotal DECIMAL(20,2);
    
    -- Calcular el monto total de la factura
    SELECT @MontoTotal = SUM(precio_unitario * cantidad)
    FROM ventas.ventas_registradas
    WHERE id = @FacturaID;

    -- Insertar la nota de credito en la tabla
    INSERT INTO ventas.notasDeCredito (idFactura, monto, razon)
    VALUES (@FacturaID, @MontoTotal, 'Cancelación de factura');
    
    PRINT 'La nota de crédito ha sido generada exitosamente.';
END;
GO

-- Ejemplo de uso: Dar de baja una factura y generar una nota de credito
EXEC ventas.DarDeBajaFactura @FacturaID = 1;  -- Reemplaza 1 con el ID de la factura que quieras cancelar

select *
from ventas.notasDeCredito 
GO


-------reporte por dia de facturacion 
CREATE PROCEDURE ventas.ReporteTotalPorDiaDeLaSemana
    @Mes INT,
    @Anio INT
AS
BEGIN
    -- Configurar el idioma a español para que los nombres de los días de la semana se muestren en español
    --SET LANGUAGE Spanish;--no tiene que estar dentro del sp, poque es configuracion de la sesion.

    -- Definir una tabla temporal para almacenar los totales por día
    CREATE TABLE #ReporteDiasSemana (
        DiaSemana NVARCHAR(10),
        TotalFacturado DECIMAL(20,2),
        DiaOrden INT
    );

    DECLARE @FechaInicio DATE = DATEFROMPARTS(@Anio, @Mes, 1);
    DECLARE @FechaFin DATE = EOMONTH(@FechaInicio);
    
    -- Calcular el total facturado por día y asignar el orden de los días
    INSERT INTO #ReporteDiasSemana (DiaSemana, TotalFacturado, DiaOrden)
    SELECT 
        DATENAME(WEEKDAY, v.fecha) AS DiaSemana,
        SUM(v.precio_unitario * v.cantidad) - COALESCE(SUM(n.monto), 0) AS TotalFacturado,
        DATEPART(WEEKDAY, v.fecha) AS DiaOrden
    FROM ventas.ventas_registradas v
    LEFT JOIN ventas.notasDeCredito n ON v.id = n.idFactura
    WHERE YEAR(v.fecha) = @Anio
      AND MONTH(v.fecha) = @Mes
    GROUP BY DATENAME(WEEKDAY, v.fecha), DATEPART(WEEKDAY, v.fecha);

    -- Mostrar el reporte ordenado por día de la semana 
    SELECT DiaSemana, TotalFacturado
    FROM #ReporteDiasSemana
    ORDER BY DiaOrden;

    DROP TABLE #ReporteDiasSemana;
END;
GO



DROP PROCEDURE ventas.ReporteTotalPorDiaDeLaSemana;
EXEC ventas.ReporteTotalPorDiaDeLaSemana @Mes = 12, @Anio = 2019;
GO

----------reportetotal-----------------------------------------------------------------

CREATE TABLE ventas.ReporteVentasDetallado (
    factura_id INT,
    tipo_factura CHAR(1),
    ciudad VARCHAR(40),
    tipo_cliente VARCHAR(15),
    genero VARCHAR(15),
    linea_producto VARCHAR(50),
    precio_unitario DECIMAL(20, 2),
    cantidad INT,
    total DECIMAL(20, 2),
    fecha DATE,
    hora TIME,
    medio_de_pago VARCHAR(15)
);
GO



INSERT INTO ventas.ReporteVentasDetallado (
    factura_id,
    tipo_factura,
    ciudad,
    tipo_cliente,
    genero,
    linea_producto,
    precio_unitario,
    cantidad,
    total,
    fecha,
    hora,
    medio_de_pago
)
SELECT 
    v.id AS factura_id,
    v.tipo_Factura AS tipo_factura,
    s.ciudad AS ciudad,
    v.tipo_cliente,
    v.genero,
    lp.nombre AS linea_producto,
    v.precio_unitario,
    v.cantidad,
    (v.precio_unitario * v.cantidad) - COALESCE(nc.monto, 0) AS total, -- Se resta la nota de credito si existe
    v.fecha,
    v.hora,
    mp.nombre AS medio_de_pago
FROM ventas.ventas_registradas v
JOIN supermercado.sucursal s ON v.idSucursal = s.id
JOIN catalogo.producto p ON v.idProducto = p.id
JOIN catalogo.linea_de_producto lp ON p.id_linea = lp.id
JOIN ventas.mediosDePago mp ON v.idMedio_de_pago = mp.id
LEFT JOIN ventas.notasDeCredito nc ON v.id = nc.idFactura -- Unir notas de credito
WHERE v.activo = 1; -- Solo incluir ventas activas
--verlinea de producto en el join, trae categoria/linea de otra tabla 
SELECT * FROM ventas.ReporteVentasDetallado;

GO
---------------------------------------reporte venta trimestral-----------------------------------------
CREATE PROCEDURE ventas.ReporteTrimestral
    @Anio INT,
    @Trimestre INT
AS
BEGIN
    -- Crear la tabla temporal para almacenar los resultados
    CREATE TABLE #ReporteTrimestral (
        Mes VARCHAR(10),
        Turno VARCHAR(15),
        Facturacion DECIMAL(20, 2)
    );

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

    -- Insertar en la tabla temporal los datos de facturación agrupados por mes y turno
    INSERT INTO #ReporteTrimestral (Mes, Turno, Facturacion)
    SELECT 
        DATENAME(MONTH, v.fecha) AS Mes,
        e.turno,
        SUM(v.precio_unitario * v.cantidad) AS Facturacion
    FROM 
        ventas.ventas_registradas AS v
    INNER JOIN 
        supermercado.empleado AS e ON v.idEmpleado = e.legajo
    WHERE 
        v.fecha BETWEEN @FechaInicio AND @FechaFin
        AND YEAR(v.fecha) = @Anio
    GROUP BY 
        DATENAME(MONTH, v.fecha), e.turno
    ORDER BY 
        CASE DATENAME(MONTH, v.fecha)
            WHEN 'Enero' THEN 1
            WHEN 'Febrero' THEN 2
            WHEN 'Marzo' THEN 3
            WHEN 'Abril' THEN 4
            WHEN 'Mayo' THEN 5
            WHEN 'Junio' THEN 6
            WHEN 'Julio' THEN 7
            WHEN 'Agosto' THEN 8
            WHEN 'Septiembre' THEN 9
            WHEN 'Octubre' THEN 10
            WHEN 'Noviembre' THEN 11
            WHEN 'Deciembre' THEN 12
        END, e.turno;

    -- Mostrar el resultado
    SELECT * FROM #ReporteTrimestral;

    -- Eliminar la tabla temporal
    DROP TABLE #ReporteTrimestral;
END;

GO


EXEC ventas.ReporteTrimestral @Anio=2019, @Trimestre=2
--DROP PROCEDURE ventas.ReporteTrimestral

SET LANGUAGE spanish--cambie el idioma de la sesion, preguntar si es a nivel base de datos o sesion



----------REPORTE POR PRODUCTO SEGUN FECHA-------------------
CREATE OR ALTER PROCEDURE  ventas.ReporteProductoSegunFecha
    @FechaIni DATE,
    @FechaFinal DATE
AS
BEGIN
    
    CREATE TABLE #EntreRangoDeFecha (
        Nombre VARCHAR(120),
        cantidadVendida INT
    );

       INSERT INTO #EntreRangoDeFecha (Nombre, cantidadVendida)
    SELECT 
        p.nombre AS Nombre,
        SUM(v.cantidad) AS cantidadVendida
    FROM ventas.ventas_registradas v
    INNER JOIN catalogo.producto p ON v.idProducto = p.id
    WHERE v.fecha BETWEEN @FechaIni AND @FechaFinal
    GROUP BY p.nombre
    ORDER BY cantidadVendida DESC;

    -- Mostrar los resultados
    SELECT 
        Nombre AS nombre,
        cantidadVendida AS [cantidad vendida]
    FROM #EntreRangoDeFecha
	order by cantidadVendida DESC;

    -- Eliminar la tabla temporal
    DROP TABLE #EntreRangoDeFecha;
END;
GO

EXEC ventas.ReporteProductoSegunFecha @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';


--DROP PROCEDURE ventas.ReporteProductoSegunFecha





----------REPORTE POR PRODUCTO SEGUN FECHA POR SUCURSAL-------------------