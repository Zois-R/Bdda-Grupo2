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
 *   Se requiere que importe toda la información antes        *
 *   mencionada a la base de datos:                           *
 *   • Genere los objetos necesarios (store procedures,       *
 *     funciones, etc.) para importar los archivos antes      *
 *     mencionados. Tenga en cuenta que cada mes se           *
 *     recibirán archivos de novedades con la misma           *
 *     estructura, pero datos nuevos para agregar a cada      *
 *     maestro.                                               *
 *   • Considere este comportamiento al generar el código.    *
 *     Debe admitir la importación de novedades               *
 *     periódicamente.                                        *
 *   • Cada maestro debe importarse con un SP distinto. No    *
 *     se aceptarán scripts que realicen tareas por fuera     *
 *     de un SP.                                              *
 *   • La estructura/esquema de las tablas a generar será     *
 *     decisión suya. Puede que deba realizar procesos de     *
 *     transformación sobre los maestros recibidos para       *
 *     adaptarlos a la estructura requerida.                  *
 *                                                            *
 *   • Los archivos CSV/JSON no deben modificarse. En caso de *
 *     que haya datos mal cargados, incompletos, erróneos,    *
 *     etc., deberá contemplarlo y realizar las correcciones  *
 *     en el fuente SQL. (Sería una excepción si el archivo   *
 *     está malformado y no es posible interpretarlo como     *
 *     JSON o CSV).                                           *
 *                                                            *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                           *
 *   Creamos los store procedures para la importación de      *
 *   los archivos. Estos tienen tablas temporales, que        *
 *   usaremos para bajar la información de los mismos. En     *
 *   los SP tenemos el código necesario para manejar los      *
 *   conflictos de importación.                               *
 *                                                            *
 *************************************************************/


USE COM5600G02
GO




 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar la sucursal
 --------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.importarSucursal 
    @direccion VARCHAR(1000)
AS
BEGIN
    -- Crear la tabla temporal sin el campo idComercio
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

    -- Obtener el idComercio del único registro de la tabla Comercio
    DECLARE @idComercio NVARCHAR(20);
    SELECT @idComercio = cuit
    FROM supermercado.Comercio
    WHERE cuit IS NOT NULL;

    -- Insertar o actualizar en la tabla sucursal
    MERGE supermercado.sucursal AS act
    USING #sucursal AS source
    ON act.ciudad = source.ciudad 
    AND act.localidad = source.reemplazar  -- Asegúrate de usar 'reemplazar' en lugar de 'localidad'
    AND act.direccion = source.direccion
    AND act.idComercio = @idComercio -- Asignar idComercio directamente en el MERGE
    WHEN MATCHED AND (act.horario <> source.horario OR act.telefono <> source.telefono) THEN 
        -- Actualizar solo si el horario o el teléfono son distintos
        UPDATE SET 
            act.horario = source.horario,
            act.telefono = source.telefono
    WHEN NOT MATCHED THEN 
        -- Si no existe, insertar un nuevo registro
        INSERT (idComercio, ciudad, localidad, direccion, horario, telefono)
        VALUES (@idComercio, source.ciudad, source.reemplazar, source.direccion, 
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




 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar los empleados
 --------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.importarEmpleados @direccion VARCHAR(1000), @FraseClave NVARCHAR(128)
AS
BEGIN
    -- Crear la tabla temporal
    CREATE TABLE #empleados
    (
        legajo          INT,
        nombre          VARCHAR(30) COLLATE Latin1_General_CI_AI,
        apellido        VARCHAR(30) COLLATE Latin1_General_CI_AI,
        dni             INT,
        direccion       VARCHAR(100) COLLATE Latin1_General_CI_AI,
        email_personal  VARCHAR(100) COLLATE Latin1_General_CI_AI,
        email_empresa   VARCHAR(100) COLLATE Latin1_General_CI_AI,
        cuil            VARCHAR(20) NULL,
        cargo           VARCHAR(20) COLLATE Latin1_General_CI_AI,
        idSucursal      VARCHAR(30) COLLATE Latin1_General_CI_AI,
        turno           VARCHAR(20) COLLATE Latin1_General_CI_AI
    );

    -- Declaramos una variable para SQL dinámico
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #empleados
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [Empleados$]'');';

    
    EXEC sp_executesql @sql;

    -- Contamos los registros en la tabla empleados antes del MERGE
    DECLARE @countBefore INT, @countAfter INT;
    SELECT @countBefore = COUNT(*) FROM supermercado.empleado;

    -- Insertamos o actualizamos los datos en la tabla empleados con encriptación usando frase clave
    MERGE supermercado.empleado AS act
    USING (
        SELECT e.legajo,
               EncryptByPassPhrase(@FraseClave, e.nombre) AS nombre,
               EncryptByPassPhrase(@FraseClave, e.apellido) AS apellido,
               EncryptByPassPhrase(@FraseClave, CAST(e.dni AS VARCHAR(10))) AS dni,
               EncryptByPassPhrase(@FraseClave, e.direccion) AS direccion,
               EncryptByPassPhrase(@FraseClave, e.email_personal) AS email_personal,
			   EncryptByPassPhrase(@FraseClave, e.email_empresa) AS email_empresa,
               e.cuil,
               e.cargo,
               s.id AS idSucursal,
               e.turno
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
        -- Actualizamos solo si algún campo es distinto
        UPDATE SET 
            act.direccion = source.direccion,
            act.email_personal = source.email_personal,
            act.cargo = source.cargo,
            act.idSucursal = source.idSucursal,
            act.turno = source.turno
    WHEN NOT MATCHED THEN
        -- Si el empleado no existe, insertamos un nuevo registro encriptado
        INSERT (legajo, nombre, apellido, dni, direccion, email_personal, email_empresa, cargo, idSucursal, turno)
        VALUES (source.legajo, source.nombre, source.apellido, source.dni, source.direccion, 
                source.email_personal, source.email_empresa, source.cargo, source.idSucursal, source.turno);

    -- Contamos registros en la tabla empleados después del MERGE
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





 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar Línea de Producto
 --------------------------------------------------------------------------------------------------------


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









 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar el Catálogo
 --------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE catalogo.importarCatalogo
    @direccion VARCHAR(1000)
AS
BEGIN
    -- Creamos la tabla temporal para cargar los datos desde el archivo
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

   
    EXEC sp_executesql @sql;

    -- Limpiamos datos incompletos
    DELETE FROM #catalogoTemp
    WHERE idProducto IS NULL
      OR categoria IS NULL
      OR nombreProducto IS NULL
      OR Precio IS NULL
      OR Precio_refer IS NULL
      OR unidad_refer IS NULL
      OR fecha IS NULL;

    -- Variable para controlar las inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contamos el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM catalogo.producto);

	UPDATE #catalogoTemp
	SET nombreProducto = REPLACE(nombreProducto, 'Ã³', 'ó')
	WHERE nombreProducto LIKE '%Ã³%';

	UPDATE #catalogoTemp
	SET nombreProducto = REPLACE(nombreProducto, N'単', 'ñ')
	WHERE nombreProducto LIKE N'%単%';

	UPDATE #catalogoTemp
	SET nombreProducto = REPLACE(nombreProducto, N'Ãº', 'u')
	WHERE nombreProducto LIKE N'%Ãº%';
	
	UPDATE #catalogoTemp
	SET nombreProducto = REPLACE(nombreProducto, N'Ã¡', 'á')
	WHERE nombreProducto LIKE N'%Ã¡%';
	
	UPDATE #catalogoTemp
	SET nombreProducto = REPLACE(nombreProducto, N'Ã±', 'ñ')
	WHERE nombreProducto LIKE N'%Ã±%';

    -- Realizamos el MERGE
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

    -- Contamos el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM catalogo.producto);

    -- Registramos en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) producto(s) en el catálogo', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarCatalogo', @mensajeInsercion;
    END;

    -- Eliminamos la tabla temporal de datos importados
    DROP TABLE #catalogoTemp;
END;
GO









 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar el otro catálogo de productos importados
 --------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE catalogo.importarProductosImportados
    @direccion VARCHAR(1000)
AS
BEGIN
    CREATE TABLE #catalogoTemp
    (
        idProducto      VARCHAR(10),
        nombreProducto   NVARCHAR(200) COLLATE Latin1_General_CI_AI,
        proveedor        VARCHAR(70),
        categoria        VARCHAR(90),
        cantidad         VARCHAR(90), 
        precio           VARCHAR(50)
    );

    
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #catalogoTemp
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [Listado de Productos$]'');';

    -- Ejecutamos la consulta dinámica
    EXEC sp_executesql @sql;
	
	-- Obtenemos el ID de la línea de producto donde el nombre es 'Importados'
	DECLARE @idLineaImportados INT;
	SELECT @idLineaImportados = id 
	FROM catalogo.linea_de_producto 
	WHERE nombre = 'Importados';

    -- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contamos el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM catalogo.producto);

	-- Insertar o actualizar productos según corresponda
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

    -- Contar el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM catalogo.producto);

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) producto(s) importados en el catálogo', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarProductosImportados', @mensajeInsercion;
    END;

    -- Eliminamos la tabla temporal
    DROP TABLE #catalogoTemp;

END;
GO











 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar el catálogo de Accesorios
 --------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE catalogo.importarAccesorios
    @direccion VARCHAR(1000)
AS
BEGIN 
    create table #catalogoTemp
	(
		nombreProducto	nvarchar(200), 
		precio			varchar(50)
	);

   
    DECLARE @sql NVARCHAR(MAX);

    -- Construimos la consulta dinámica para OPENROWSET
    SET @sql = N'
    INSERT INTO #catalogoTemp
    SELECT *
    FROM OPENROWSET(''Microsoft.ACE.OLEDB.12.0'',
                    ''Excel 12.0 Xml;Database=' + @direccion + ''',
                    ''SELECT * FROM [Sheet1$]'');';

    
    EXEC sp_executesql @sql;
	
	-- Obtener el ID de la línea de producto donde el nombre es 'Accesorios'
	DECLARE @idLineaAccesorios INT;
	SELECT @idLineaAccesorios = id 
	FROM catalogo.linea_de_producto 
	WHERE nombre = 'Accesorios';

	-- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contamos el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM catalogo.producto);

	
	-- Insertar o actualizar productos según corresponda
	MERGE catalogo.producto AS target
	USING (
		SELECT 
			c.nombreProducto AS nombre,
			TRY_CONVERT(DECIMAL(18, 2), REPLACE(c.precio, ',', '.')) AS Precio,
			@idLineaAccesorios AS id_linea
		FROM #catalogoTemp c
		GROUP BY c.nombreProducto, TRY_CONVERT(DECIMAL(18, 2), REPLACE(c.precio, ',', '.'))
	) AS source
	ON target.nombre COLLATE Latin1_General_CI_AI = source.nombre COLLATE Latin1_General_CI_AI
		AND target.id_linea = source.id_linea
	WHEN MATCHED THEN
		-- Si el producto ya existe, actualizamos su precio
		UPDATE SET target.Precio = source.Precio
	WHEN NOT MATCHED THEN
		-- Si el producto no existe, insertamos un nuevo registro
		INSERT (nombre, Precio, id_linea)
		VALUES (source.nombre, source.Precio, source.id_linea);
;

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) producto(s) accesorio(s) en el catálogo', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarAccesorios', @mensajeInsercion;
    END;

    -- Eliminamos la tabla temporal
    DROP TABLE #catalogoTemp;

END;
go






 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar los Medios de Pago
 --------------------------------------------------------------------------------------------------------


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





 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar los clientes
 --------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.importar_clientes
    @rutaArchivo NVARCHAR(255)  
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Crear una tabla temporal para almacenar los datos del archivo CSV
    CREATE TABLE #TempCliente (
        id INT,
        cuil VARCHAR(20) COLLATE Latin1_General_CI_AI,  -- Aplicar la intercalación aquí también si es necesario
        genero VARCHAR(10),
        tipo_cliente VARCHAR(10)
    );

    -- 2. Consulta dinámica para ejecutar BULK INSERT
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    BULK INSERT #TempCliente
    FROM ''' + @rutaArchivo + '''
    WITH (
        FIELDTERMINATOR = '','',  -- Delimitador de campo
        ROWTERMINATOR = ''0x0a'', -- Delimitador de fila
        FIRSTROW = 2,             -- Empezar en la segunda fila si la primera es cabecera
        CODEPAGE = ''65001''     -- Usar UTF-8 para caracteres especiales
    );';

    -- Ejecutar consulta dinámica
    EXEC sp_executesql @sql;

    -- 3. Limpiar datos incompletos
    DELETE FROM #TempCliente
    WHERE cuil IS NULL
      OR genero IS NULL
      OR tipo_cliente IS NULL;

    -- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contar el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM ventas.cliente);

    -- 4. Realizar el MERGE para evitar duplicados de CUIL
    MERGE ventas.cliente AS target
    USING (
        SELECT cuil COLLATE Latin1_General_CI_AI AS cuil, genero, tipo_cliente
        FROM #TempCliente
    ) AS source
    ON target.cuil = source.cuil
    WHEN NOT MATCHED THEN
        INSERT (cuil, genero, tipo_cliente)
        VALUES (source.cuil, source.genero, source.tipo_cliente);

    -- Contar el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM ventas.cliente);

    -- 5. Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
        DECLARE @mensajeInsercion VARCHAR(1000);
        SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nuevo(s) cliente(s)', @filasDespues - @filasAntes);
    
        EXEC registros.insertarLog 'importarClientes', @mensajeInsercion;
    END;

    -- 6. Limpiar la tabla temporal
    DROP TABLE #TempCliente;
END;
GO





 --------------------------------------------------------------------------------------------------------
  --Creamos SP para importar las ventas registradas
 --------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE ventas.importarVentas_registradas   
    @direccion VARCHAR(1000)
AS
BEGIN
    -- Declaración de la variable de tabla para almacenar los IDs de las facturas
    DECLARE @facturaIDs TABLE (
        facturaID VARCHAR(20) COLLATE Latin1_General_CI_AI
    );

    -- Crear la tabla temporal
    CREATE TABLE #ventas
    (
        factura         VARCHAR(20) COLLATE Latin1_General_CI_AI,
        tipo_Factura    CHAR(1),
        ciudad          VARCHAR(20) COLLATE Latin1_General_CI_AI,
        tipo_cliente    VARCHAR(20) COLLATE Latin1_General_CI_AI,
        genero          VARCHAR(15) COLLATE Latin1_General_CI_AI,
        Producto        NVARCHAR(200) COLLATE Latin1_General_CI_AI,
        precio_unitario DECIMAL(20, 2),
        cantidad        INT,
        fecha           VARCHAR(15),
        hora            TIME,
        Medio_de_pago   VARCHAR(20) COLLATE Latin1_General_CI_AI,
        idEmpleado      INT,
        idPago          VARCHAR(100) COLLATE Latin1_General_CI_AI
    );

    DECLARE @sql NVARCHAR(MAX);
    SET @sql = N'
    BULK INSERT #ventas
    FROM ''' + @direccion + '''
    WITH
    (
        FIELDTERMINATOR = '';'', 
        ROWTERMINATOR = ''0x0a'', 
        CODEPAGE = ''65001'', 
        FIRSTROW = 2 
    );';

    -- Ejecutamos la consulta dinámica
    EXEC sp_executesql @sql;

	 -- Variable para control de inserciones
    DECLARE @filasAntes INT, @filasDespues INT;

    -- Contamos el número de filas en la tabla antes del MERGE
    SET @filasAntes = (SELECT COUNT(*) FROM ventas.registro_de_ventas);

    -- Se actualiza el campo idPago en la tabla temporal
    UPDATE #ventas
    SET idPago = REPLACE(LTRIM(RTRIM(idPago)), '''', '');

    -- Reemplazar caracteres en los nombres de productos
    UPDATE #ventas
    SET Producto = REPLACE(Producto, 'Ã³', 'ó');
    
    UPDATE #ventas
    SET Producto = REPLACE(Producto, N'単', 'ñ');

    UPDATE #ventas
    SET Producto = REPLACE(Producto, N'Ãº', 'ú');

    UPDATE #ventas
    SET Producto = REPLACE(Producto, N'Ã¡', 'á');

    UPDATE #ventas
    SET Producto = REPLACE(Producto, N'Ã±', 'ñ');

    -- Insertar en ventas.ventasProductosNoRegistrados los productos no encontrados en el catálogo
    INSERT INTO ventas.ventasProductosNoRegistrados
    SELECT * 
    FROM #ventas v 
    WHERE v.Producto NOT IN (SELECT nombre FROM catalogo.producto);
    
    -- Insertar las facturas sin duplicados
    INSERT INTO ventas.factura (nroFactura, tipo_Factura, fecha, hora, idMedio_de_pago, idPago, total, totalConIVA)
    SELECT 
        v.factura,
        v.tipo_Factura,
        CONVERT(DATE, v.fecha, 101),
        v.hora,
        mp.id,
        v.idPago,
        SUM(v.precio_unitario * v.cantidad),  -- Total sin IVA
        SUM(v.precio_unitario * v.cantidad * 1.21)  -- Total con IVA (21%)
    FROM #ventas v
    JOIN ventas.mediosDePago mp ON v.Medio_de_pago = mp.nombre
    WHERE NOT EXISTS (
        SELECT 1
        FROM ventas.factura f
        WHERE f.nroFactura = v.factura
    )
    GROUP BY v.factura, v.tipo_Factura, v.fecha, v.hora, mp.id, v.idPago;

    -- CTE para evitar duplicados de productos
    WITH cte1 AS (
        SELECT id, id_linea, nombre, ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY id) AS fila
        FROM catalogo.producto
    )
    INSERT INTO ventas.detalleVenta (idProducto, idFactura, subtotal, cant, precio)
    SELECT 
        p.id AS idProducto,
        f.id,
        v.precio_unitario * v.cantidad AS subtotal,
        v.cantidad,
        v.precio_unitario
    FROM #ventas v
    JOIN (SELECT id, id_linea, nombre FROM cte1 WHERE fila = 1) p ON v.Producto = p.nombre
    JOIN ventas.factura f ON v.factura = f.nroFactura
    WHERE NOT EXISTS (
        SELECT 1
        FROM ventas.detalleVenta dv
        WHERE dv.idProducto = p.id
        AND dv.idFactura = f.id
    );

    -- Insertar en ventas_registradas sin duplicados
    INSERT INTO ventas.registro_de_ventas (idFactura, idEmpleado, idSucursal, idCliente)
    SELECT DISTINCT
        f.id,
        v.idEmpleado,
        s.id,
        NULL	--- se pierden los datos porque no hay nada que identifique a un cliente de univocamente
    FROM #ventas v
    JOIN supermercado.sucursal s ON v.ciudad = s.ciudad
    JOIN ventas.factura f ON v.factura = f.nroFactura
    WHERE NOT EXISTS (
        SELECT 1
        FROM ventas.registro_de_ventas vr
        WHERE vr.idFactura = f.id
    );

	-- Contar el número de filas después del MERGE
    SET @filasDespues = (SELECT COUNT(*) FROM ventas.registro_de_ventas);

    -- Registrar en el log si hubo inserciones
    IF @filasDespues > @filasAntes
    BEGIN
		DECLARE @mensajeInsercion VARCHAR(1000);
		SET @mensajeInsercion = FORMATMESSAGE('Inserción de %d nueva(s) venta(s) en registro_de_ventas', @filasDespues - @filasAntes);
    
		EXEC registros.insertarLog 'importarVentas', @mensajeInsercion;
    END;

    -- Eliminar la tabla temporal
    DROP TABLE #ventas;
END;
GO
