USE COM5600G02
GO

CREATE OR ALTER PROCEDURE supermercado.importarEmpleados @direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal
    CREATE TABLE #empleados
    (
        legajo          INT,
        nombre          VARCHAR(30)COLLATE Latin1_General_CI_AI,
        apellido        VARCHAR(30)COLLATE Latin1_General_CI_AI,
        dni             INT,
        direccion       VARCHAR(100)COLLATE Latin1_General_CI_AI,
        email_personal  VARCHAR(80)COLLATE Latin1_General_CI_AI,
        email_empresa   VARCHAR(80)COLLATE Latin1_General_CI_AI,
        cuil            VARCHAR(20) NULL,
        cargo           VARCHAR(20)COLLATE Latin1_General_CI_AI,
        idSucursal      VARCHAR(30)COLLATE Latin1_General_CI_AI,
        turno           VARCHAR(20)COLLATE Latin1_General_CI_AI
    );

    -- Declarar una variable para el SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construir la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #empleados
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [Empleados$]'');';

    -- Ejecutar la consulta dinámica
    EXEC sp_executesql @sql;

    -- Contar registros en la tabla empleados antes del MERGE
    DECLARE @countBefore INT, @countAfter INT;
    SELECT @countBefore = COUNT(*) FROM supermercado.empleado;

    -- Insertar o actualizar los datos en la tabla empleados
    MERGE supermercado.empleado AS act
    USING (
        SELECT e.legajo, e.nombre, e.apellido, e.dni, e.direccion, e.email_personal, 
               e.email_empresa, e.cargo, s.id AS idSucursal, e.turno
        FROM #empleados e
        JOIN supermercado.sucursal s
        ON e.idSucursal COLLATE Latin1_General_CI_AI = s.localidad COLLATE Latin1_General_CI_AI
    ) AS source
    ON act.legajo = source.legajo
    WHEN MATCHED AND (
        act.direccion <> source.direccion OR
        act.email_personal <> source.email_personal OR
        act.cargo <> source.cargo OR
        act.idSucursal <> source.idSucursal OR
        act.turno <> source.turno
    ) THEN 
        -- Actualizar solo si algún campo es distinto
        UPDATE SET 
            act.direccion = source.direccion,
            act.email_personal = source.email_personal,
            act.cargo = source.cargo,
            act.idSucursal = source.idSucursal,
            act.turno = source.turno
    WHEN NOT MATCHED THEN
        -- Si el empleado no existe, insertar un nuevo registro
        INSERT (legajo, nombre, apellido, dni, direccion, email_personal, email_empresa, cargo, idSucursal, turno)
        VALUES (source.legajo, source.nombre, source.apellido, source.dni, source.direccion, 
                source.email_personal, source.email_empresa, source.cargo, source.idSucursal, source.turno);

    -- Contar registros en la tabla empleados después del MERGE
    SELECT @countAfter = COUNT(*) FROM supermercado.empleado;

    -- Registrar en el log según el resultado
    IF @countAfter > @countBefore
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) empleado(s)', @countAfter - @countBefore);
    
		EXEC registros.insertarLog 'importarEmpleados', @mensajeInsercion;
    END

    -- Eliminar la tabla temporal
    DROP TABLE #empleados;
END;
GO





