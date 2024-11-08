USE COM5600G02
go

CREATE OR ALTER PROCEDURE catalogo.importarProductosImportados
    @direccion VARCHAR(1000)
AS
BEGIN --id, category, name, price, reference_price, reference_unit, date
    CREATE TABLE #catalogoTemp
    (
        idProducto      VARCHAR(10),
        nombreProducto   NVARCHAR(200) COLLATE Latin1_General_CI_AI,
        proveedor        VARCHAR(70),
        categoria        VARCHAR(90),
        cantidad         VARCHAR(90), 
        precio           VARCHAR(50)
    );

    -- Declarar una variable para el SQL din�mico
    DECLARE @sql NVARCHAR(MAX);

    -- Construir la consulta din�mica para OPENROWSET
    SET @sql = N'
    INSERT INTO #catalogoTemp
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [Listado de Productos$]'');';

    -- Ejecutar la consulta din�mica
    EXEC sp_executesql @sql;
	
	-- Obtener el ID de la l�nea de producto donde el nombre es 'Importados'
	DECLARE @idLineaImportados INT;
	SELECT @idLineaImportados = id 
	FROM catalogo.linea_de_producto 
	WHERE nombre = 'Importados';

    -- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contar el n�mero de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM catalogo.producto);

	-- Insertar o actualizar productos seg�n corresponda
	MERGE catalogo.producto AS act
	USING (
		SELECT 
			c.nombreProducto AS nombre,
			TRY_CONVERT(DECIMAL(18, 2), REPLACE(c.precio, ',', '.')) AS Precio,
			@idLineaImportados AS id_linea
		FROM #catalogoTemp c
	) AS source
	ON act.nombre COLLATE Latin1_General_CI_AI = source.nombre COLLATE Latin1_General_CI_AI
		AND act.id_linea = source.id_linea
	WHEN MATCHED THEN
    -- Si el producto ya existe, actualizamos su precio
		UPDATE SET act.Precio = source.Precio
	WHEN NOT MATCHED THEN
    -- Si el producto no existe, insertamos un nuevo registro
		INSERT (nombre, Precio, id_linea)
		VALUES (source.nombre, source.Precio, source.id_linea);

    -- Contar el n�mero de filas despu�s del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM catalogo.producto);

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserci�n de %d nuevo(s) producto(s) importados en el cat�logo', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarProductosImportados', @mensajeInsercion;
    END;

    -- Eliminamos la tabla temporal
    DROP TABLE #catalogoTemp;

END;
GO

