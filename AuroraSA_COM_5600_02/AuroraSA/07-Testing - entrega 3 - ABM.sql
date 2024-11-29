/************************************************************
 *                                                          *
 *                      BASE DE DATOS APLICADA              *
 *                                                          *
 *   INTEGRANTES:                                           *
 *      - Edilberto Guzman                                  *
 *      - Zois Andres Uziel Ruggiero Bellone                *
 *      - Karen Anabella Bursa                              *
 *      - Jonathan Ivan Aranda Robles                       *
 *                                                          *
 *   NRO. DE ENTREGA: 3                                     *
 *   FECHA DE ENTREGA: 15/11/2024                           *
 *                                                          *
 *   TESTING                                                *
 *                                                          *
 *   LO QUE HICIMOS EN ESTE SCRIPT:                         *
 *   Realizamos diferentes tipos de testing, ya sea para    *
 *   verificar las constraints de check, en la inserción.   *
 *   Verificamos que no se generen duplicados, también      *
 *   verificamos los stores de modificación, que se generen *
 *   las ventas con múltiples productos asociados,          *
 *   verificando que se guarden correctamente en las tablas *
 *   detalleVenta y factura.                                *
 *   Probamos la inserción de notas de crédito, que estén   *
 *   asociadas a facturas que existen y productos válidos.  *
 *   Testeamos la correcta importación de los archivos,     *
 *   actualización e ingreso de nuevas sucursales,          *
 *   empleados, líneas de producto y catálogos desde los    *
 *   archivos.                                              *
 *                                                          *
 ************************************************************/

 ---------------------------------------------------------------------
--TESTING DE ABM SI SE IMPORTO LOS ARCHIVOS MAESTROS (03 - ejecucionSPdelImportacionDeMaestro.sql)
---------------------------------------------------------------------

---------------------------------------------------------------------
--TESTS RELACIONADOS CON LA CREACIÓN DE LA BITÁCORA
---------------------------------------------------------------------

/*
CASO DE TESTING 1: Insertar log con valores válidos
INPUTS:
    - @modulo: 'Autenticación'
    - @texto: 'Inicio de sesión exitoso'
RESULTADO ESPERADO: Resultado esperado de la operación 
DESCRIPCIÓN: Explicación de lo que debería suceder (detalles sobre la prueba específica y el objetivo)
*/
EXEC registros.insertarLog @modulo = 'Autenticación', @texto = 'Inicio de testing exitoso'
USE COM5600G02;
select * from registros.bitacora

/*
CASO DE TESTING 2: Insertar log con el módulo como nulo
INPUTS:
    - @modulo: ''
    - @texto: 'Intento de inicio de sesión fallido'
RESULTADO ESPERADO:  El valor de modulo debe cambiar a N/A en el registro insertado.
*/

EXEC registros.insertarLog @modulo = '', @texto = 'Testing con modulo nulo'


/*
CASO DE TESTING 3: Insertamos log con en el que la variable modulo tiene espacios en blanco 
VARIABLES DE ENTRADA:
    - @modulo1: valor de ejemplo
    - @texto: valor de ejemplo
RESULTADO ESPERADO: Resultado esperado de la operación (ej. filas afectadas, mensajes, etc.)
*/

EXEC registros.insertarLog @modulo = '   ', @texto = 'Testing con modulo nulo'
SELECT * FROM registros.bitácora



/*
CASO DE TESTING 4: Insertar log con longitud de texto mayor a 300
VARIABLES DE ENTRADA:
    - @modulo = 'Seguridad'
    - @texto = 'Texto con límite máximo de longitud... (300 caracteres)'
RESULTADO ESPERADO: El texto se registra correctamente hasta los 300 caracteres
*/
EXEC registros.insertarLog @modulo = 'Seguridad', @texto = 'Al venir al mundo fueron delicadamente mecidas por las manos de la lustral Doniazada, su buena tía, que grabó sus nombres sobre hojas de oro coloreadas de húmedas pedrerías y las cuidó bajo el terciopelo de sus pupilas hasta la adolescencia dura, para esparcirlas después, voluptuosas y libres, sobre el mundo oriental, eternizado por su sonrisa.'



---------------------------------------------------------------------
--TEST INSERCIÓN COMERCIO
---------------------------------------------------------------------
use COM5600G02;
----no insertar duplicado
EXEC supermercado.insertarComercio 
    @cuit = '20-12345678-9',
    @nombre_comercio = 'Aurora',
    @razon_social = 'Aurora S.A.',
    @email = 'contacto@aurora.com.ar';
go
----probando el check del cuit 
EXEC supermercado.insertarComercio 
    @cuit = '20-123456-8-4',
    @nombre_comercio = 'Aurora',
    @razon_social = 'Aurora S.A.',
    @email = 'contacto@aurora.com.ar';
go




---------------------------------------------------------------------
--TEST INSERCIÓN SUCURSAL
---------------------------------------------------------------------
use COM5600G02;
------------------ se debe insertar por unica vez, y no debe poder duplicarse
EXEC supermercado.insertarSucursal 'hong king', 
	'Gonzales Catan',
	'Juan Manuel de Rosas 14.457, Ruta 3 km 29 (1759) Gonzalez Catán' ,
	'L a V 8 a. m. – 9 p. m. S y D 9 a. m. – 8 p. m.',
	'123-484-4132';
GO
select * from supermercado.sucursal;
GO
------------------actualizacion de sucursal
EXEC supermercado.modificarDatosSucursal 
	4,'horario 9 a.m- 10p.m','174-518-3585';
GO
select * from supermercado.sucursal;
GO
-------------------borrado logico
exec supermercado.borrado_logico_sucursal 4;
GO
select * from supermercado.sucursal;
GO


---------------------------------------------------------------------
--TEST INSERCIÓN EMPLEADO
---------------------------------------------------------------------
use COM5600G02;
---muestra los empleado de un gerente en particular
EXEC supermercado.mostrarEmpleadosDesencriptadosDelGerente		
	@FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.',
    @idSucursalGerente = 2,
    @idEmpleado = 257032;
go
---- ingreso de nuevo empleado
EXEC supermercado.insertarEmpleado
    @legajo = 258490,                     
    @nombre = 'Juan',                  
    @apellido = 'Perez',               
    @dni = '909447164',                 
    @direccion = 'Calle Falsa 123',    
    @email_personal = 'gguanperez@gmail.com',  
    @email_empresa = 'gguan.perez@superA.com', 
    @cargo = 'Cajero',                   
    @idSucursal = 2,                    
    @turno = 'TM',                  
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';    
go
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';
go

---------------------borrado logico 
exec supermercado.borrado_logico_empleado @legajo=257022;
go
select * from supermercado.empleado;
go


---------------------------------------------------------------------
--TEST INSERCIÓN LINEA DE PRODUCTO
---------------------------------------------------------------------
use COM5600G02;
---insercion de una nueva categoria
EXEC catalogo.insertarLinea_de_producto @nombre = 'Almacen',@categoría = 'enlatados';
GO
select * from catalogo.linea_de_producto order by id desc;
GO
---no admite productos repetido
EXEC catalogo.insertarLinea_de_producto @nombre = 'Almacen',@categoría = 'aceite_vinagre_y_sal';
GO
select * from catalogo.linea_de_producto where categoria =  'aceite_vinagre_y_sal';
GO
-----borrado logico
exec catalogo.borrado_logico_lineaDeProducto 'Almacen';
GO
select * from catalogo.linea_de_producto order by id desc;
GO
--- no puede insertar null en la linea de producto.
EXEC catalogo.insertarLinea_de_producto null,null;
GO


---------------------------------------------------------------------
--TEST INSERCIÓN CLIENTE
---------------------------------------------------------------------

/*
CASO DE TESTING : Testeamos que que no haya duplicados en cliente
RESULTADO ESPERADO: Que no nos deje insertar un cliente repetido
*/

declare @idCliente int;
declare @clienteExistente BIT;
EXEC ventas.insertar_cliente 
    @cuil = '20-12345678-9', 
    @tipoCliente = 'Particular', 
    @genero = 'Masculino', 
    @idCliente = @idCliente OUTPUT, 
    @clienteExistente = @clienteExistente OUTPUT;

IF @clienteExistente = 1
	PRINT( 'No se acepta duplicado')
	
SELECT * FROM ventas.cliente

-----se ingreso mal los datos del cuil, debe salir error por check de cuil
declare @idCliente int;
declare @clienteExistente BIT;
EXEC ventas.insertar_cliente 
    @cuil = '20-1234-678-9', 
    @tipoCliente = 'Particular', 
    @genero = 'Masculino', 
    @idCliente = @idCliente OUTPUT, 
    @clienteExistente = @clienteExistente OUTPUT;







---------------------------------------------------------------------
--TEST INSERCIÓN PRODUCTO
---------------------------------------------------------------------

---insercion  (nombreProducto, precio decimal, id  lal linea )
exec catalogo.insertarProducto 'Samsumg Galaxy A03',150.00,150;
GO
select * from catalogo.producto order by id desc ;
GO
---insersion pero no existe linea de producto
exec catalogo.insertarProducto 'Samsumg Galaxy A04',160.00,160;
GO
---no admite duplicados
exec catalogo.insertarProducto 'Samsumg Galaxy A03',150.00,150;
GO
-- Modificar un producto existente , modificar precio
exec catalogo.ActualizarPrecioProducto 6524,200.00;
GO
select * from catalogo.producto order by id desc;
GO
-- borrado logico 
exec catalogo.borrado_logico_producto @id = 6500;
GO
select * from catalogo.producto order by id desc ;
GO
--- no se puede poner un precio cero o negativo , resultado esperado : error por el check de precio
exec catalogo.insertarProducto @nombre = 'producto generico', @Precio = 0, @id_linea = 1;
GO




---------------------------------------------------------------------
--TEST INSERCIÓN MEDIO DE PAGO
---------------------------------------------------------------------

---insercion 
EXEC ventas.insertarMedioDePago 'Debit Card';
GO
select * from ventas.mediosDePago;
GO
---no admite duplicados
EXEC ventas.insertarMedioDePago 'Cash';
GO
---borrado (lógico)
EXEC ventas.borrado_logico_mediosDePago @id = 2;
GO
select * from ventas.mediosDePago;
GO
---no se registra medio de pago, por que recibe un null;
EXEC ventas.insertarMedioDePago null;
GO






---------------------------------------------------------------------
--TEST GENERAR VENTA CON FACTURA
---------------------------------------------------------------------
select * from ventas.detalleVenta;
select * from ventas.factura
--- testing
-- Primero, declaramos la tabla de tipo TipoProductosDetalle con los productos a insertar
DECLARE @productosDetalle ventas.TipoProductosDetalle;

-- Insertamos productos de prueba en la tabla de tipo
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES
    (1,1),  -- Producto 1,  Cantidad 2
    (2,2),   -- Producto 2, Cantidad 3
    (3,2);   -- Producto 3, Cantidad 5

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8415',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '1/5/2019',			-- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago 
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,           -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',		-- Tipo de cliente 
    @genero = 'Male',				-- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente 
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go
--borrado logico 
EXEC ventas.borrado_logico_factura 3;



---------------------generar nuevas ventas 
-- Primero, declaramos la tabla de tipo TipoProductosDetalle con los productos a insertar
DECLARE @productosDetalle ventas.TipoProductosDetalle;

-- Insertamos productos de prueba en la tabla de tipo
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES
    (1,1),  -- Producto 1,  Cantidad 2
    (2,2),   -- Producto 2, Cantidad 3
    (3,2);   -- Producto 3, Cantidad 5

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '645-67-8528',    -- Número de factura 
    @tipoFactura = 'A',             -- Tipo de factura
    @fecha = '1/5/2019',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago 
    @idEmpleado = 257020,              -- ID del empleado
    @idSucursal = 3,                -- ID de la sucursal 
    @tipoCliente = 'Normal',       -- Tipo de cliente
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente 
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go
select * from ventas.vista_de_registros_de_ventas where ID_Factura = '645-67-8528';
---------------------generar nuevas ventas 
-- probar que no pueda subir factura sin producto
DECLARE @productosDetalle ventas.TipoProductosDetalle;

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '456-57-8528',    
    @tipoFactura = 'A',             
    @fecha = '1/5/2019',          
    @hora = '13:08:00',            
    @idMedioDePago = 1,             
    @idPago = 'PAGO123456',         
    @idEmpleado = 257020,              
    @idSucursal = 3,                
    @tipoCliente = 'Normal',      
    @genero = 'Male',          
    @cuil = '20-12345678-9',        
    @productosDetalle = @productosDetalle; 
go
select * from ventas.vista_de_registros_de_ventas where ID_Factura='456-67-8428';
GO
select * from ventas.vista_de_registros_de_ventas;
GO

---------------------------------------------------------------------
--TEST BORRADO DE DETALLE DE VENTA
---------------------------------------------------------------------
EXEC ventas.borrado_logico_detalle_de_venta @id = 1;
GO
select * from ventas.detalleVenta;
GO


---------------------------------------------------------------------
--TEST GENERAR NOTA DE CREDITO
---------------------------------------------------------------------
--verifico que exista una nota de credito
select * from ventas.detalleVenta order by id desc;
select * from ventas.factura order by id desc;
------- test se debe insertar correctamente la nota de credito en la tabla y no debe duplicarse
exec ventas.insertarNotaDeCredito @idFactura = 45, @idProducto = 5637, @razon = 'devProd';
go
select * from ventas.notasDeCredito;
go
------- test de devolucion de pago
exec ventas.insertarNotaDeCredito @idFactura = 955, @idProducto = 2024, @razon = 'devPago';
go
select * from ventas.notasDeCredito;
go
------- se verfica que el idFactura sea correcto ,dando una factura incorrecta
exec ventas.insertarNotaDeCredito @idFactura = 2201, @idProducto = 6529, @razon = 'devProd';
go
------- se verfica que el producto sea correcto a pesar que el idFactura sea correcto
exec ventas.insertarNotaDeCredito @idFactura = 1000,  @idProducto = 2015, @razon = 'devProd';
go













---------------------------------------------------------------------
--TESTING DE ABM SI NO SE HA IMPORTADO LOS ARCHIVOS MAESTROS (03 - ejecucionSPdelImportacionDeMaestro.sql)
---------------------------------------------------------------------

-------------------- sin importar datos ,
-- insercion Comercio
EXEC supermercado.insertarComercio 
    @cuit = '20-12345678-9',
    @nombre_comercio = 'Aurora',
    @razon_social = 'Aurora S.A.',
    @email = 'contacto@aurora.com.ar';
go

---crear una sucursal
EXEC supermercado.insertarSucursal 'stefen', 
	'Liniers',
	'Juan Manuel de Rosas Av. 1234' ,
	'L a V 8 a. m. – 9 p. m. S y D 9 a. m. – 8 p. m.',
	'123-484-4132';
GO
---empleado
EXEC supermercado.insertarEmpleado
    @legajo = 300000,                     
    @nombre = 'Juan',                  
    @apellido = 'Perez',               
    @dni = '90951164',                 
    @direccion = 'Calle Falsa 123',    
    @email_personal = 'GLUCK@gmail.com',  
    @email_empresa = 'GLICK.perez@superA.com', 
    @cargo = 'Cajero',                   
    @idSucursal = 1,                    
    @turno = 'TM',                  
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';    
go
---linea de producto
EXEC catalogo.insertarLinea_de_producto @nombre = 'Almacen',@categoría = 'ropa';
GO
---insertar producto concrecto 
exec catalogo.insertarProducto 'remera',10.0,1;
GO
---insercion de medio pago
EXEC ventas.insertarMedioDePago 'Pago Generico';
GO
--insercion de la venta
DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES
    (1,5) 

EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8415',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '1/5/2019',			-- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago 
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 300000,           -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 1,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',		-- Tipo de cliente 
    @genero = 'Male',				-- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente 
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go
--se muestra que los datos estan en la tablas de registro de ventas y detalle de venta
select * from ventas.registro_de_ventas;
select * from ventas.detalleVenta;