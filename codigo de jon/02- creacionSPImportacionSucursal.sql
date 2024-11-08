USE COM5600G02
GO

CREATE OR ALTER PROCEDURE supermercado.importarSucursal @direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal
    CREATE TABLE #sucursal
    (
        ciudad         VARCHAR(40) COLLATE Latin1_General_CI_AI,
        reemplazar     VARCHAR(40) COLLATE Latin1_General_CI_AI,
        direccion      VARCHAR(150) COLLATE Latin1_General_CI_AI,
        horario        VARCHAR(100) COLLATE Latin1_General_CI_AI,
        telefono       VARCHAR(20) COLLATE Latin1_General_CI_AI
    );

    -- Declarar una variable para el SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construir la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #sucursal
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [sucursal$]'');';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

    -- Limpiar y formatear el campo 'horario'
    UPDATE #sucursal
    SET horario = REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(LTRIM(RTRIM(horario)), '?', ' '),  -- Reemplazar el carácter '?' por un espacio
                            '-', '–'  -- Reemplazar el guion corto con guion largo
                        ),
                        'a.m.', 'a.m.'  -- Asegurar que no haya espacios innecesarios dentro de 'a.m.'
                    ),
                    'p.m.', 'p.m.'  -- Asegurar que no haya espacios innecesarios dentro de 'p.m.'
                ),
                '–', ' – '  -- Asegurar espacios antes y después del guion largo
            );

    -- Contar registros en la tabla sucursal antes del MERGE
    DECLARE @countBefore INT, @countAfter INT;
    SELECT @countBefore = COUNT(*) FROM supermercado.sucursal;

    -- Insertar o actualizar en la tabla sucursal
    MERGE supermercado.sucursal AS act
    USING #sucursal AS source
    ON act.ciudad = source.ciudad 
    AND act.localidad = source.reemplazar
    AND act.direccion = source.direccion
    WHEN MATCHED AND (act.horario <> source.horario OR act.telefono <> source.telefono) THEN 
        -- Actualizar solo si el horario o el teléfono son distintos
        UPDATE SET 
            act.horario = source.horario,
            act.telefono = source.telefono
    WHEN NOT MATCHED THEN 
        -- Si no existe, insertar un nuevo registro
        INSERT (ciudad, localidad, direccion, horario, telefono)
        VALUES (source.ciudad, source.reemplazar, source.direccion, 
                source.horario, source.telefono);

    -- Contar registros en la tabla sucursal después del MERGE
    SELECT @countAfter = COUNT(*) FROM supermercado.sucursal;

    -- Determinar si hubo inserciones y registrar si hubo cambios en las actualizaciones
    IF @countAfter > @countBefore
    BEGIN
        DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nueva(s) sucursal(es)', @countAfter - @countBefore);
    
		EXEC registros.insertarLog 'importarSucursal', @mensajeInsercion;
    END

    -- Eliminar la tabla temporal
    DROP TABLE #sucursal;
END;
GO




