use COM5600G02;
go
--------------------------------------------------------------------------------------------------------
--BORRADO LOGICO SUCURSAL
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE supermercado.borrado_logico_sucursal
    @id INT,
    @modulo NVARCHAR(50) = 'sucursal'
AS
BEGIN
    
    UPDATE supermercado.sucursal
    SET activo = 0 --actualizamos el estado en 0
    WHERE id = @id;

    --si modificamos alguna fila llamamos al otro sp para registrarlo
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @ciudad NVARCHAR(40);
        DECLARE @texto NVARCHAR(255);

        -- Usamos la variable ciudad para ponerla en el texto de borrado
        SELECT @ciudad = ciudad FROM supermercado.sucursal WHERE id = @id;

        -- construimos el texto de borrado con la variable ciudad y el id
        SET @texto = CONCAT('Borrado lógico de la sucursal en ciudad: ', @ciudad, ' (ID: ', @id, ')');

        -- Llamamos al procedimiento que registra el borrado lógico en la tabla Registro
        EXEC registros.insertarLog @texto = @texto, @modulo = @modulo;
    END
END;

GO

--------------------------------------------------------------------------------------------------------
--BORRADO LOGICO MEDIOS DE PAGO
--------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE ventas.borrado_logico_mediosDePago
	@id INT,
	@modulo NVARCHAR(50) = 'mediosDePago'
AS
BEGIN 
	UPDATE ventas.mediosDePago
	SET activo = 0
	WHERE  id = @id;

--Si modificamos alguna fila entonces tenemos que llamar al sp para generar el registro
	IF @@ROWCOUNT > 0
	BEGIN
		DECLARE @nombre NVARCHAR(100);
		DECLARE @texto NVARCHAR(255);


		SELECT @nombre = nombre FROM ventas.mediosDePago WHERE id = @id;

		SET @texto = CONCAT('Borrado lógico del medio de pago: ', @nombre,' (ID: ', @id, ')');

	
		EXEC registros.insertarLog @texto = @texto , @modulo = @modulo;
	END
END;

GO
--------------------------------------------------------------------------------------------------------
--STORE PROCEDURE PARA HACER BORRADO LOGICO DE LINEA_DE_PRODUCTO POR CAMPO NOMBRE
--------------------------------------------------------------------------------------------------------


CREATE OR ALTER PROCEDURE catalogo.borrado_logico_lineaDeProducto
    @nombre NVARCHAR(100),  
    @modulo NVARCHAR(50) = 'linea_de_producto'
AS
BEGIN
    
    UPDATE catalogo.linea_de_producto
    SET activo = 0
    WHERE nombre = @nombre;

  
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado lógico de la línea de producto: ', @nombre);

        
        EXEC  registros.insertarLog @texto = @texto, @modulo = @modulo;
    END
END;

GO



---------------------------------------------------------------------------------
-- STORE PROCEDURE PARA HACER BORRADO LOGICO DE EMPLEADO POR LEGAJO
---------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE supermercado.borrado_logico_empleado
    @legajo INT, -- borra por el legajo
    @modulo NVARCHAR(50) = 'empleado'
AS
BEGIN
    --ponemos en 0 el activo 
    UPDATE supermercado.empleado
    SET activo = 0
    WHERE Legajo = @legajo;

    --si se modificó alguna linea
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado log del empleado con Legajo: ', @legajo);

        --registramos el legajo
        EXEC  registros.insertarLog @texto = @texto, @modulo = @modulo;
    END
END;
GO


----------------------------------------------------------------------------------------------------------
--STORE PROCEDURE PARA HACER EL BORRADO LOGICO DE VENTAS REGISTRADAS POR EL CAMPO FACTURA Y TIPO_FACTURA
----------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE ventas.borrado_logico_ventasRegistradas
    @factura NVARCHAR(20),            -- Número de factura
    @tipo_factura CHAR(1),             -- Tipo de factura
    @modulo NVARCHAR(50) = 'ventas_registradas'
AS
BEGIN
    -- Actualización para realizar el borrado lógico en ventas_registradas
    UPDATE ventas.ventas_registradas
    SET activo = 0
    WHERE factura = @factura AND tipo_Factura = @tipo_factura;

    -- Si se modificó alguna fila,lo registramos
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado lógico de la venta con Factura: ', @factura, ' y Tipo: ', @tipo_factura);

        -- Llamamos al proc para el registro
        EXEC registros.insertarLog @texto = @texto, @modulo = @modulo;
    END
END;

GO
----------------------------------------------------------------------------------------------------------
--PROCEDURE PARA HACER BORRADO LOGICO POR EL ID DEL PRODUCTO
----------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE catalogo.borrado_logico_producto
    @id INT,                           -- ID del producto
    @modulo NVARCHAR(50) = 'producto'
AS
BEGIN
    
    UPDATE catalogo.producto
    SET activo = 0
    WHERE id = @id;

   
    IF @@ROWCOUNT > 0
    BEGIN
        DECLARE @texto NVARCHAR(255);
        SET @texto = CONCAT('Borrado lógico del producto con ID: ', @id);

        -- Llamada al procedimiento para registrar el borrado
        EXEC registros.insertarLog @texto = @texto, @modulo = @modulo;
    END
END;
GO
----------------------------------------------------------------------------------------------------------
-- FIN
----------------------------------------------------------------------------------------------------------






