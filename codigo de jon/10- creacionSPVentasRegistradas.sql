USE COM5600G02 
GO

CREATE OR ALTER PROCEDURE ventas.importarVentas_registradas   
	@direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal
     CREATE TABLE #ventas
    (
		factura			varchar(20) COLLATE Latin1_General_CI_AI,
		tipo_Factura	char(1),
		ciudad			varchar(20) COLLATE Latin1_General_CI_AI,
		tipo_cliente	varchar(20) COLLATE Latin1_General_CI_AI,
		genero			varchar(15) COLLATE Latin1_General_CI_AI,
		Producto		nvarchar(200) COLLATE Latin1_General_CI_AI,
		precio_unitario	DECIMAL(20, 2),
		cantidad		int,
		fecha			varchar(15),
		hora			time,
		Medio_de_pago	varchar(20) COLLATE Latin1_General_CI_AI,
		idEmpleado		int,
		idPago			varchar(100) COLLATE Latin1_General_CI_AI
    );

	DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    BULK INSERT #ventas
    FROM ''' + @direccion + '''
    WITH
    (
        FIELDTERMINATOR = '';'', -- Especifica el delimitador de campo
        ROWTERMINATOR = ''0x0a'', -- Especifica el terminador de fila
        CODEPAGE = ''65001'', -- Especifica la página de códigos del archivo
        FIRSTROW = 2 -- Número de la primera fila de datos
    );'

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

	 -- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contar el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM ventas.ventas_registradas);

	-- Limpiar el campo de idPago en la tabla temporal directamente 
	UPDATE #ventas
	SET idPago = REPLACE(LTRIM(RTRIM(idPago)), '''', '');

	insert into ventas.ventasProductosNoRegistrados	--me guardo aquellos producto no encontrados 
	select * from #ventas v where v.producto not in (select nombre from catalogo.producto);

	WITH cte1 AS (
    SELECT id, nombre, ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY id) AS fila
    FROM catalogo.producto),
	ct2 AS (select * from cte1 where fila=1)
    -- Insertar los datos en la tabla de empleados
    INSERT INTO ventas.ventas_registradas (factura, tipo_Factura, idSucursal, tipo_cliente, genero, idProducto, 
                                        precio_unitario, cantidad, fecha, hora, idMedio_de_pago, idEmpleado, idPago)
	SELECT 
		v.factura,
		v.tipo_Factura,  
		s.id,  -- Buscar la sucursal por ciudad
		v.tipo_cliente, 
		v.genero,
		p.id,  -- Buscar el id del producto por nombre
		v.precio_unitario, 
		v.cantidad,
		CONVERT(DATE, v.fecha, 101),  
		v.hora,  
		mp.id,  
		v.idEmpleado,
		v.idPago  
	FROM #ventas v
	JOIN supermercado.sucursal s 
		ON v.ciudad = s.ciudad  -- Coincidencia por ciudad
	JOIN ct2 p
        ON v.Producto  = p.nombre -- Coincidencia por nombre de producto
	JOIN ventas.mediosDePago mp
    ON v.Medio_de_pago = mp.nombre -- Coincidencia por medio de pago
	WHERE NOT EXISTS (
		SELECT 1 
		FROM ventas.ventas_registradas vr 
		WHERE vr.factura = v.factura
	);

	-- Contar el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM catalogo.producto);

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) producto(s) en ventas_registradas', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarVentas', @mensajeInsercion;
    END;

    -- Eliminamos la tabla temporal
    DROP TABLE #ventas;

END;
go



