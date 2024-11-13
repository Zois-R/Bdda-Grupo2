USE COM5600G02
go
--FIELDTERMINATOR = '','',
CREATE OR ALTER PROCEDURE catalogo.importarCatalogo
    @direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal para cargar los datos desde el archivo
    CREATE TABLE #catalogoTemp
    (
        idProducto      VARCHAR(10),
        categoria       VARCHAR(70),
        nombreProducto  NVARCHAR(200) COLLATE Latin1_General_CI_AI,
        Precio          VARCHAR(90),
        Precio_refer    VARCHAR(90), 
        unidad_refer    VARCHAR(50),
        fecha           VARCHAR(70)
    );

    -- Consulta dinámica para BULK INSERT
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    BULK INSERT #catalogoTemp
    FROM ''' + @direccion + '''
    WITH
    (
		FORMAT = ''CSV'',
        ROWTERMINATOR = ''0x0a'', 
        CODEPAGE = ''65001'', 
        FIRSTROW = 2 
    );';

    -- Ejecutar consulta dinámica
    EXEC sp_executesql @sql;

    -- Limpiar datos incompletos
    DELETE FROM #catalogoTemp
    WHERE idProducto IS NULL
      OR categoria IS NULL
      OR nombreProducto IS NULL
      OR Precio IS NULL
      OR Precio_refer IS NULL
      OR unidad_refer IS NULL
      OR fecha IS NULL;

    -- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contar el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM catalogo.producto);

    -- Realizar el MERGE
    MERGE catalogo.producto AS target
    USING (
        SELECT 
            c.nombreProducto AS nombre,
            TRY_CONVERT(DECIMAL(18, 2), REPLACE(c.Precio_refer, ',', '.')) AS Precio,
            l.id AS id_linea
        FROM #catalogoTemp c
        INNER JOIN catalogo.linea_de_producto l 
            ON c.categoria COLLATE Latin1_General_CI_AI = l.categoria COLLATE Latin1_General_CI_AI
    ) AS source
    ON target.nombre COLLATE Latin1_General_CI_AI = source.nombre COLLATE Latin1_General_CI_AI
    WHEN NOT MATCHED THEN
        INSERT (nombre, Precio, id_linea)
        VALUES (source.nombre, source.Precio, source.id_linea);

    -- Contar el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM catalogo.producto);

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) producto(s) en el catálogo', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarCatalogo', @mensajeInsercion;
    END;

    -- Eliminar la tabla temporal de datos importados
    DROP TABLE #catalogoTemp;
END;
GO

