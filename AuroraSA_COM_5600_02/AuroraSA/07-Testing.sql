/*
Base de datos aplicada
Grupo 2
Integrantes:
	Edilberto Guzman
	Zois Andres Uziel Ruggiero Bellon
	Karen Anabella Bursa
	Jonathan Ivan Aranda Robles

Nro de entrega: 3 , 4  5
Fecha de entraga: 15/11/2024
*/

--------------------------------------------------------------------------------------------------------------
--TEST STORES DE CREACIÓN  , entrega 3
--------------------------------------------------------------------------------------------------------------

/*
CASO DE TESTING : Descripción breve de la prueba (qué estás probando)
VARIABLES DE ENTRADA:
    - @Parametro1: valor de ejemplo
    - @Parametro2: valor de ejemplo
RESULTADO ESPERADO: Resultado esperado de la operación (ej. filas afectadas, mensajes, etc.)
DESCRIPCIÓN: Explicación de lo que debería suceder (detalles sobre la prueba específica y el objetivo)
*/

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
----no insertar duplicado
EXEC supermercado.insertarComercio 
    @cuit = '20-12345678-9',
    @nombre_comercio = 'Aurora',
    @razon_social = 'Aurora S.A.',
    @email = 'contacto@aurora.com.ar';
go

select * from supermercado.Comercio;

----probando un cuit de correspondiente 
EXEC supermercado.insertarComercio 
    @cuit = '20-123456-8-4',
    @nombre_comercio = 'Aurora',
    @razon_social = 'Aurora S.A.',
    @email = 'contacto@aurora.com.ar';
go





---------------------------------------------------------------------
--TEST INSERCIÓN SUCURSAL
---------------------------------------------------------------------

/*
CASO DE TESTING : Descripción breve de la prueba (qué estás probando)
VARIABLES DE ENTRADA:
    - @Parametro1: valor de ejemplo
    - @Parametro2: valor de ejemplo
RESULTADO ESPERADO: Resultado esperado de la operación (ej. filas afectadas, mensajes, etc.)
DESCRIPCIÓN: Explicación de lo que debería suceder (detalles sobre la prueba específica y el objetivo)
*/
------------------ se debe insertar por unica vez, y no debe poder duplicarse

EXEC supermercado.insertarSucursal 'hong king', 
	'Gonzales Catan',
	'Juan Manuel de Rosas 14.457, Ruta 3 km 29 (1759) Gonzalez Catán' ,
	'L a V 8 a. m. – 9 p. m. S y D 9 a. m. – 8 p. m.',
	'123-484-4132';
GO
select * from supermercado.sucursal;
------------------actualizacion de sucursal
EXEC supermercado.modificarDatosSucursal 
	2,'horario 9 a.m- 10p.m','174-8-3585';
GO
select * from supermercado.sucursal;

go
-------------------borrado logico
exec supermercado.borrado_logico_sucursal 4;






---------------

use COM5600G02;
---------------------------------------------------------------------
--TEST INSERCIÓN EMPLEADO
---------------------------------------------------------------------

/*
CASO DE TESTING : Testeamos que ni el dni ni el email se puedan repetir
VARIABLES DE ENTRADA:
    - @Parametro1: valor de ejemplo
    - @Parametro2: valor de ejemplo
RESULTADO ESPERADO: Que no nos deje insertar un empleado con legajo duplicado

*/

select * from supermercado.empleado;

EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';

EXEC supermercado.mostrarEmpleadosDesencriptadosDelGerente
	@FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.',
    @idSucursalGerente = 2,
    @idEmpleado = 257032;

------------------------------

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


---------------------borrado logico 
exec supermercado.borrado_logico_empleado 18;









---------------------------------------------------------------------
--TEST INSERCIÓN LINEA DE PRODUCTO
---------------------------------------------------------------------
/*
CASO DE TESTING : Testeamos que no se repita la categoría de la linea del producto
VARIABLES DE ENTRADA:
    - @nombre: 'Almacen'
    - @categoría: 'aceite_vinagre_y_sal'
RESULTADO ESPERADO: Que no nos deje insertar una categoría repetda
*/
EXEC catalogo.insertarLinea_de_producto @nombre = 'Almacen',@categoría = 'aceite_vinagre_y_sal';
select * from catalogo.linea_de_producto order by id desc;
select * from catalogo.linea_de_producto where categoria =  'aceite_vinagre_y_sal';



-----borrado logico
exec catalogo.borrado_logico_producto 148;


--- no puede insertar null en la linea de producto.
EXEC catalogo.insertarLinea_de_producto null,null;






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

-----se ingreso mal los datos del cuil
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
select * from catalogo.producto order by id desc ;
---insersion pero no existe linea de producto
exec catalogo.insertarProducto 'Samsumg Galaxy A04',160.00,160;
---no admite duplicados
exec catalogo.insertarProducto 'Samsumg Galaxy A03',150.00,150;
-- Modificar un producto existente , modificar precio
exec catalogo.ActualizarPrecioProducto 6524,190.00;
select * from catalogo.producto order by id desc;

-- borrado logico 
exec catalogo.borrado_logico_producto 6500;

--- no se puede poner un precio cero o negativo , resultado esperado : error por el check de precio
exec catalogo.insertarProducto 'producto generico',0,1;





---------------------------------------------------------------------
--TEST INSERCIÓN MEDIO DE PAGO
---------------------------------------------------------------------

---insercion 
EXEC ventas.insertarMedioDePago 'Debit Card';
select * from ventas.mediosDePago order by id desc ;
---no admite duplicados
EXEC ventas.insertarMedioDePago 'Cash';

---borrado (lógico)
EXEC ventas.borrado_logico_mediosDePago @id = 2;

---no se registra medio de pago, por que recibe un null;
EXEC ventas.insertarMedioDePago null;







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
    @fecha = '1/5/2019',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go



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
    @nroFactura = '645-67-8528',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '1/5/2019',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go
select * from ventas.vista_de_registros_de_ventas where ID_Factura = '645-67-8528';
---------------------generar nuevas ventas 
-- probar que no pueda subir factura sin producto
DECLARE @productosDetalle ventas.TipoProductosDetalle;

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '456-57-8528',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '1/5/2019',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-9',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go

select * from ventas.vista_de_registros_de_ventas where ID_Factura='456-67-8428';
select * from ventas.vista_de_registros_de_ventas;








---------------------------------------------------------------------
--TEST GENERAR NOTA DE CREDITO
---------------------------------------------------------------------
--verifico que exista una nota de credito
select * from ventas.detalleVenta order by id desc;
select * from ventas.factura order by id desc;
------- test se debe insertar correctamente la nota de credito en la tabla y no debe duplicarse
exec ventas.insertarNotaDeCredito 45,5637,'devProd';
select * from ventas.notasDeCredito;
------- se verfica que el idFactura sea correcto ,dando una factura incorrecta
exec ventas.insertarNotaDeCredito 2201,6529,'devProd';
------- se verfica que el producto sea correcto a pesar que el idFactura sea correcto
exec ventas.insertarNotaDeCredito 1000,2015,'devProd';



---------------------------------------------------------------------
--TEST DE INSERCION Y ACTUALIZAR DE ARCHIVOS  , entrega 4
---------------------------------------------------------------------
-- se espera que que importe los clientes 
EXEC ventas.importar_clientes 'C:\importar\DatosClientes.csv';
go
select * from ventas.cliente
go
select * from registros.bitácora
go

--actualizacion y ingreso de nuevas sucursales por archivo
EXEC supermercado.importarSucursal 'C:\importar\nuevosDatos\Informacion_complementaria_2.xlsx';
GO
select * from supermercado.sucursal;
GO
--actualizacion y ingreso de nuevos empleados por archivo
EXEC supermercado.importarEmpleados 'C:\importar\nuevosDatos\Informacion_complementaria_2.xlsx', 'La vida es como la RAM, todo es temporal y nada se queda.';
GO
select * from supermercado.empleado;
GO
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.'
GO
--actualizacion y ingreso de nuevas lineas de producto por archivo
EXEC catalogo.importarLinea_de_producto 'C:\importar\nuevosDatos\Informacion_complementaria_2.xlsx';
GO
select * from catalogo.linea_de_producto order by id desc;
GO
--actualizacion y ingreso de nuevos productos catalogo por archivo ;
exec catalogo.importarCatalogo 'C:\importar\nuevosDatos\catalogo_2.csv';
GO
select * from catalogo.producto order by id desc;
GO
--actualizacion y ingreso de nuevos productos electronicos por archivo ;
exec catalogo.importarAccesorios 'C:\importar\nuevosDatos\Electronic accessories_2.xlsx';
GO
select * from catalogo.producto order by id desc;
GO
EXEC ventas.importarVentas_registradas 'C:\importar\nuevosDatos\Ventas_registradas_2.csv';
go

select * from ventas.factura order by id desc;
select * from ventas.detalleVenta order by id desc;
select * from catalogo.producto order by id desc;
select * from ventas.vista_de_registros_de_ventas;











---------------------------------------------------------------------
--REPORTES  , entrega 4
---------------------------------------------------------------------
-----------------
EXEC ventas.TotalFacturadoPorDiaSemana @mes = 1, @anio = 2019;
go
-----------------
EXEC ventas.reporte_trimestral_facturacion @Trimestre = 1, @Anio = 2019;
go
-----------------
EXEC ventas.reporte_producto_vendido_rango_fecha @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go
-----------------
EXEC ventas.reporte_producto_vendido_rango_fecha_sucursal @FechaIni = '2019-02-15', @FechaFinal = '2019-02-20';
go
-----------------
exec ventas.reporte_productos_mas_vendidos_por_semana 1, 2019;
go
-----------------
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
go
-----------------
exec ventas.reporte_total_acumulado_ventas '2019-02-15', 2;
go

-----------------testeo de ultimo producto vendido
---hacer una venta en el dia de hoy, y verficiar que este dentro del rango de fecha entre hoy y ayer
---primero me fijo los productos que hay
select * from catalogo.producto order by id desc;   ---!!!!!OJO PRIMERO VER EL PRODUCTO Y LUEGO PONER LOS DATOS

-- Insertamos productos de prueba en la tabla de tipo
DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES (6529, 2)   

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8425',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '14/11/2024',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-7',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go

EXEC ventas.reporte_producto_vendido_rango_fecha @FechaIni = '2024-11-14', @FechaFinal = '2024-11-20';
go







select * from ventas.vista_de_registros_de_ventas;










---------------------------------------------------------------------
--TEST DE SEGURIDAD   entrega 5
---------------------------------------------------------------------

--------------mostrar incriptados de la tabla empleados
select * from supermercado.empleado;
--------------mostrar los empleados desencriptados 
EXEC supermercado.mostrarEmpleadosDesencriptados 
    @FraseClave = 'La vida es como la RAM, todo es temporal y nada se queda.';
go








---------------------------------logins , usuarios y roles 

use COM5600G02;
use master
--------------demostrar que solo el supervisor puede hacer las notas de credito  (FALTA HACER )
go

--------primero ejecutamos con cajero
EXECUTE AS LOGIN = 'cajero1';						
SELECT CURRENT_USER;


----ver lo productos que tengo
select * from catalogo.vista_Producto_Resumen;

DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES (6520, 5)   

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-2026',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '14/11/2024',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-7',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go

select * from ventas.vista_de_registros_de_ventas where ID_Factura = '750-67-2026';

REVERT;		


-----------luego lo probamos con un supervisor 
EXECUTE AS LOGIN = 'supervisor1';						
SELECT CURRENT_USER;

DECLARE @productosDetalle ventas.TipoProductosDetalle;
INSERT INTO @productosDetalle (idProducto, cantidad)
VALUES (6528, 1)   

-- Ahora, llamamos al procedimiento almacenado ventas.generar_venta_con_factura con los siguientes parámetros
EXEC ventas.generar_venta_con_factura
    @nroFactura = '750-67-8426',    -- Número de factura de ejemplo
    @tipoFactura = 'A',             -- Tipo de factura (A o B, dependiendo de la configuración)
    @fecha = '14/11/2024',          -- Fecha de la venta
    @hora = '13:08:00',             -- Hora de la venta
    @idMedioDePago = 1,             -- ID del medio de pago (puede ser un ID válido de la tabla mediosDePago)
    @idPago = 'PAGO123456',         -- ID del pago (número de transacción o similar)
    @idEmpleado = 257020,              -- ID del empleado (debe ser un ID válido de la tabla empleados)
    @idSucursal = 3,                -- ID de la sucursal (debe ser un ID válido de la tabla sucursal)
    @tipoCliente = 'Normal',       -- Tipo de cliente (ejemplo: 'Regular', 'Nuevo', etc.)
    @genero = 'Male',          -- Género del cliente
    @cuil = '20-12345678-7',        -- CUIL del cliente (dato ficticio)
    @productosDetalle = @productosDetalle; -- Detalles de los productos a insertar
go

select * from ventas.vista_de_registros_de_ventas where ID_Factura = '750-67-8426';

REVERT;		








--------------demostrar que solo el supervisor puede hacer las notas de credito 

select * from ventas.detalleVenta order by idFactura desc;	--mostrar los detalles de ventas a borrar

select * from ventas.vista_de_registros_de_ventas;

-----este es un supervisor
EXECUTE AS LOGIN = 'supervisor1';						--este es un supervisor
SELECT CURRENT_USER;										-- Muestra el actual login
exec ventas.insertarNotaDeCredito 1000,5196,'devProd';		--le tiene que dar los permisos
REVERT;														--vuelve al login anterior, es decir, al de windows

select * from ventas.vista_de_notas_de_credito;

-----este es un gerente
EXECUTE AS LOGIN = 'gerente1';
SELECT CURRENT_USER;				-- Muestra el actual login
exec ventas.insertarNotaDeCredito 1000,5196,'devProd';	
REVERT;			







--------------demostrar que solo el gerente puede hacer los reportes 

-----este es un gerente
EXECUTE AS LOGIN = 'gerente1';
SELECT CURRENT_USER;				-- Muestra el actual login
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
REVERT;								--vuelve al login anterior, es decir, al de windows

-----este es un supervisor
EXECUTE AS LOGIN = 'supervisor1';
SELECT CURRENT_USER;				-- Muestra el actual login
exec ventas.reporte_productos_menos_vendidos_mes 1, 2019;
REVERT;		











---------------- ver roles de la DB y usuarios asignados
use COM5600G02;
SELECT    roles.principal_id                            AS RolePrincipalID
    ,    roles.name                                    AS RolePrincipalName
    ,    database_role_members.member_principal_id    AS MemberPrincipalID
    ,    members.name                                AS MemberPrincipalName
FROM sys.database_role_members AS database_role_members  
JOIN sys.database_principals AS roles  
    ON database_role_members.role_principal_id = roles.principal_id  
JOIN sys.database_principals AS members  
    ON database_role_members.member_principal_id = members.principal_id;  
GO

-------- ver permisos dados a los roles 
SELECT
    perms.state_desc AS State,
    permission_name AS [Permission],
    obj.name AS [on Object],
    dp.name AS [to User Name]
FROM sys.database_permissions AS perms
JOIN sys.database_principals AS dp
    ON perms.grantee_principal_id = dp.principal_id
JOIN sys.objects AS obj
    ON perms.major_id = obj.object_id;



-----------la prueba de back-up esta en otro archivo


