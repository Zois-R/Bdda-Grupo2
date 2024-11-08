use COM5600G02 
GO

CREATE OR ALTER PROCEDURE catalogo.importarLinea_de_producto
    @direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal
    CREATE TABLE #lineaProducto
    (
        linea         VARCHAR(20) COLLATE Latin1_General_CI_AI,
        categoria     VARCHAR(50) COLLATE Latin1_General_CI_AI
    );

    -- Declarar una variable para el SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construir la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #lineaProducto
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [Clasificacion productos$]'');';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

    -- Contar los registros antes del MERGE
    DECLARE @countBefore INT;
    SELECT @countBefore = COUNT(*) FROM catalogo.linea_de_producto;

    -- Insertar en la tabla linea_de_producto
    MERGE catalogo.linea_de_producto AS target
    USING #lineaProducto AS source
        ON target.nombre = source.linea
        AND target.categoria = source.categoria
    WHEN NOT MATCHED THEN
        INSERT (nombre, categoria)
        VALUES (source.linea, source.categoria);

    -- Contar los registros después del MERGE
    DECLARE @countAfter INT;
    SELECT @countAfter = COUNT(*) FROM catalogo.linea_de_producto;

    -- Registrar en el log si hubo inserciones
    IF @countAfter > @countBefore
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nueva(s) línea de producto(s)', @countAfter - @countBefore);
    
		EXEC registros.insertarLog 'importarLinea_de_producto', @mensajeInsercion;
    END;

    -- Eliminar la tabla temporal
    DROP TABLE #lineaProducto;
END;
GO

