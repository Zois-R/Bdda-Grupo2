use COM5600G02 
GO
CREATE OR ALTER PROCEDURE catalogo.insertarLinea_de_producto
    @direccion VARCHAR(1000)
AS
BEGIN
    DECLARE @nombre VARCHAR(100);
    DECLARE @categoria VARCHAR(100);
    DECLARE @separatorIndex INT;
    DECLARE @filasAntes INT;
    DECLARE @filasDespues INT;

    -- Encontrar la posici�n de la coma
    SET @separatorIndex = CHARINDEX(',', @direccion);

    -- Si se encuentra una coma, separar el nombre y la categor�a
    IF @separatorIndex > 0
    BEGIN
        SET @nombre = LTRIM(RTRIM(SUBSTRING(@direccion, 1, @separatorIndex - 1))); -- Parte antes de la coma
        SET @categoria = LTRIM(RTRIM(SUBSTRING(@direccion, @separatorIndex + 1, LEN(@direccion)))); -- Parte despu�s de la coma
    END
    ELSE
    BEGIN
        SET @nombre = LTRIM(RTRIM(@direccion)); -- Si no hay coma, asignar toda la cadena al nombre
        SET @categoria = ''; -- Asignar una categor�a vac�a
    END;

    -- Contar el n�mero de filas antes de la posible inserci�n
    SET @filasAntes = (SELECT COUNT(*) FROM catalogo.linea_de_producto);

    -- Verificar si la l�nea de producto ya existe
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
    END;

    -- Contar el n�mero de filas despu�s de la posible inserci�n
    SET @filasDespues = (SELECT COUNT(*) FROM catalogo.linea_de_producto);

    -- Registrar en el log si se realiz� una inserci�n
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserci�n de %d nueva(s) l�nea de producto(s)', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'insertarLinea_de_producto', @mensajeInsercion;
    END;
END;
GO
