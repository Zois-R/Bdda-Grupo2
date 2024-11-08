USE COM5600G02 
GO

CREATE OR ALTER PROCEDURE ventas.importarMedios_de_Pago
    @direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal
    CREATE TABLE #medios_de_Pago
    (
        vacio           varchar(30) null,
        ingles          varchar(30) COLLATE Latin1_General_CI_AI,
        español			varchar(30)
    );

    -- Declarar una variable para el SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construir la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #medios_de_Pago
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [medios de pago$]'');';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

	-- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contar el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM ventas.mediosDePago);

    -- Insertar los datos en la tabla de empleados
    INSERT INTO ventas.mediosDePago (nombre)
	SELECT ingles 
	FROM #medios_de_Pago AS source
	WHERE NOT EXISTS (
		SELECT 1 
		FROM ventas.mediosDePago AS target
		WHERE target.nombre = source.ingles 
	);

	-- Contar el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM ventas.mediosDePago);

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) medio(s) de pago', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarMediosDePago', @mensajeInsercion;
    END;

    -- Eliminamos la tabla temporal
    DROP TABLE #medios_de_Pago;

END;
go


